<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

date_default_timezone_set('Asia/Manila');

try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // Continue with the database server's configured timezone.
}

// Shared monitoring-station status used by the topbar and sidebar.
$deviceId = 'FG-STATION-001';
$deviceTimeout = 90;
$deviceIsOnline = false;

try {
    $deviceSettingStmt = $pdo->query(
        "SELECT setting_value
         FROM system_settings
         WHERE setting_key = 'device_id'
         LIMIT 1"
    );

    $configuredDeviceId = $deviceSettingStmt->fetchColumn();

    if (is_string($configuredDeviceId) && $configuredDeviceId !== '') {
        $deviceId = $configuredDeviceId;
    }

    $deviceStatusStmt = $pdo->prepare(
        'SELECT
            device_status,
            TIMESTAMPDIFF(
                SECOND,
                created_at,
                CURRENT_TIMESTAMP
            ) AS reading_age_seconds
         FROM sensor_readings
         WHERE device_id = :device_id
         ORDER BY created_at DESC
         LIMIT 1'
    );

    $deviceStatusStmt->execute([
        ':device_id' => $deviceId
    ]);

    $latestDeviceStatus = $deviceStatusStmt->fetch(PDO::FETCH_ASSOC);

    if ($latestDeviceStatus) {
        $readingAgeSeconds = (int) (
            $latestDeviceStatus['reading_age_seconds']
            ?? PHP_INT_MAX
        );

        $deviceIsOnline =
            strtolower((string) $latestDeviceStatus['device_status']) === 'online' &&
            $readingAgeSeconds >= 0 &&
            $readingAgeSeconds <= $deviceTimeout;
    }
} catch (PDOException $exception) {
    $deviceIsOnline = false;
}

if (!function_exists('fgEscape')) {
    function fgEscape(?string $value): string
    {
        return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
    }
}

function registrationStatusLabel(string $status): string
{
    return ucwords(str_replace('_', ' ', $status));
}

function registrationStatusClass(string $status): string
{
    return match ($status) {
        'approved' => 'status-normal',
        'pending' => 'status-warning',
        'rejected' => 'status-critical',
        'suspended', 'unsubscribed' => 'status-offline',
        default => 'status-offline'
    };
}

function applicantTypeLabel(string $type): string
{
    return $type === 'non_resident'
        ? 'Non-Resident'
        : 'Resident';
}

function notificationScopeLabel(string $scope): string
{
    return $scope === 'bridge_alerts_only'
        ? 'Bridge Closure and Unsafe-Crossing Alerts Only'
        : 'Full Community Alerts';
}

function bridgeConnectionLabel(?string $connection): string
{
    return match ($connection) {
        'resident_near_bridge' => 'Resident Near Bridge',
        'work' => 'Work',
        'school' => 'School',
        'business' => 'Business',
        'delivery_transportation' => 'Delivery or Transportation',
        'visiting_relatives' => 'Visiting Relatives',
        'regular_commute' => 'Regular Commute',
        'other' => 'Other',
        default => 'Not applicable'
    };
}

function bridgeFrequencyLabel(?string $frequency): string
{
    return match ($frequency) {
        'daily' => 'Daily',
        'several_times_week' => 'Several Times a Week',
        'weekly' => 'Weekly',
        'occasionally' => 'Occasionally',
        default => 'Not applicable'
    };
}

function formatFileSize(?int $bytes): string
{
    if ($bytes === null || $bytes <= 0) {
        return 'Not available';
    }

    if ($bytes >= 1024 * 1024) {
        return number_format($bytes / (1024 * 1024), 2) . ' MB';
    }

    return number_format($bytes / 1024, 1) . ' KB';
}

function textLength(string $value): int
{
    return function_exists('mb_strlen')
        ? mb_strlen($value, 'UTF-8')
        : strlen($value);
}

function normalizeSmsText(string $value): string
{
    $normalized = preg_replace('/\s+/u', ' ', trim($value));

    return is_string($normalized)
        ? $normalized
        : trim($value);
}

function truncateSmsText(string $value, int $maximumLength): string
{
    if (textLength($value) <= $maximumLength) {
        return $value;
    }

    if (function_exists('mb_substr')) {
        return rtrim(mb_substr($value, 0, $maximumLength - 3, 'UTF-8')) . '...';
    }

    return rtrim(substr($value, 0, $maximumLength - 3)) . '...';
}

function buildRejectionSms(string $referenceNo, string $reason): string
{
    $prefix = 'FloodGuard: Registration ' . $referenceNo .
        ' was rejected. Reason: ';
    $suffix = '. You may correct the information and register again.';
    $maximumLength = 155;
    $reasonLength = max(
        20,
        $maximumLength - textLength($prefix) - textLength($suffix)
    );

    return $prefix . truncateSmsText(
        normalizeSmsText($reason),
        $reasonLength
    ) . $suffix;
}

function queueRegistrationSms(
    PDO $pdo,
    array $registration,
    string $message
): void {
    $smsStmt = $pdo->prepare(
        'INSERT INTO sms_logs (
            alert_id,
            resident_id,
            mobile_number,
            recipient_type,
            message_type,
            message,
            delivery_status
         ) VALUES (
            NULL,
            :resident_id,
            :mobile_number,
            :recipient_type,
            "registration",
            :message,
            "pending"
         )'
    );

    $smsStmt->execute([
        ':resident_id' => $registration['id'],
        ':mobile_number' => $registration['mobile_number'],
        ':recipient_type' => $registration['applicant_type'],
        ':message' => $message
    ]);
}

function safeResidentsReturnUrl(string $queryString): string
{
    parse_str($queryString, $parameters);

    $safe = [];

    if (isset($parameters['search']) && is_string($parameters['search'])) {
        $safe['search'] = substr(trim($parameters['search']), 0, 150);
    }

    if (
        isset($parameters['status']) &&
        is_string($parameters['status']) &&
        in_array(
            $parameters['status'],
            ['pending', 'approved', 'rejected'],
            true
        )
    ) {
        $safe['status'] = $parameters['status'];
    }

    if (
        isset($parameters['type']) &&
        is_string($parameters['type']) &&
        in_array($parameters['type'], ['resident', 'non_resident'], true)
    ) {
        $safe['type'] = $parameters['type'];
    }

    if (isset($parameters['page'])) {
        $safe['page'] = max(1, (int) $parameters['page']);
    }

    $query = http_build_query($safe);

    return 'residents.php' . ($query !== '' ? '?' . $query : '');
}

/* --------------------------------------------------------------------------
 | CSRF and flash messages
 * -------------------------------------------------------------------------- */

if (empty($_SESSION['registration_action_csrf'])) {
    $_SESSION['registration_action_csrf'] = bin2hex(random_bytes(32));
}

$actionCsrfToken = $_SESSION['registration_action_csrf'];
$flashMessage = $_SESSION['registration_flash'] ?? null;
unset($_SESSION['registration_flash']);

/* --------------------------------------------------------------------------
 | Approve or reject a registration
 * -------------------------------------------------------------------------- */

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $returnUrl = safeResidentsReturnUrl((string) ($_POST['return_query'] ?? ''));

    try {
        $submittedToken = $_POST['csrf_token'] ?? '';

        if (
            !is_string($submittedToken) ||
            !hash_equals($_SESSION['registration_action_csrf'], $submittedToken)
        ) {
            throw new RuntimeException(
                'The action form expired. Refresh the page and try again.'
            );
        }

        $registrationId = filter_var(
            $_POST['registration_id'] ?? null,
            FILTER_VALIDATE_INT,
            ['options' => ['min_range' => 1]]
        );

        if ($registrationId === false) {
            throw new RuntimeException('Invalid registration record.');
        }

        $action = (string) ($_POST['action'] ?? '');

        if (!in_array($action, ['approve', 'reject'], true)) {
            throw new RuntimeException('Invalid registration action.');
        }

        $rejectionReason = trim((string) ($_POST['rejection_reason'] ?? ''));

        if ($action === 'reject') {
            if (textLength($rejectionReason) < 5) {
                throw new RuntimeException(
                    'Enter a clear rejection reason containing at least 5 characters.'
                );
            }

            if (textLength($rejectionReason) > 500) {
                throw new RuntimeException(
                    'The rejection reason must not exceed 500 characters.'
                );
            }
        }

        $pdo->beginTransaction();

        $registrationStmt = $pdo->prepare(
            'SELECT
                id,
                reference_no,
                applicant_type,
                full_name,
                mobile_number,
                notification_scope,
                proof_stored_name,
                registration_status
             FROM residents
             WHERE id = :id
             FOR UPDATE'
        );

        $registrationStmt->execute([
            ':id' => $registrationId
        ]);

        $registration = $registrationStmt->fetch(PDO::FETCH_ASSOC);

        if (!$registration) {
            throw new RuntimeException('The registration record no longer exists.');
        }

        if ($registration['registration_status'] === 'unsubscribed') {
            throw new RuntimeException(
                'An unsubscribed recipient cannot be approved or rejected from this page.'
            );
        }

        if (
            $action === 'approve' &&
            $registration['registration_status'] === 'approved'
        ) {
            throw new RuntimeException(
                'This registration is already approved.'
            );
        }

        if (
            $action === 'reject' &&
            $registration['registration_status'] === 'rejected'
        ) {
            throw new RuntimeException(
                'This registration is already rejected.'
            );
        }

        if (
            $action === 'approve' &&
            $registration['applicant_type'] === 'resident' &&
            empty($registration['proof_stored_name'])
        ) {
            throw new RuntimeException(
                'This resident cannot be approved because no proof of residency is attached.'
            );
        }

        if ($action === 'approve') {
            $updateStmt = $pdo->prepare(
                'UPDATE residents
                 SET
                    registration_status = "approved",
                    rejection_reason = NULL,
                    reviewed_by = :reviewed_by,
                    reviewed_at = NOW()
                 WHERE id = :id'
            );

            $updateStmt->execute([
                ':reviewed_by' => $_SESSION['admin_id'],
                ':id' => $registrationId
            ]);

            $alertCoverage = $registration['notification_scope'] === 'bridge_alerts_only'
                ? 'bridge closure, reopening, and unsafe-crossing alerts'
                : 'full community flood, weather, bridge, and emergency alerts';

            $approvalSms = sprintf(
                'FloodGuard: Your SMS registration %s has been approved. You will now receive %s.',
                $registration['reference_no'],
                $alertCoverage
            );

            queueRegistrationSms(
                $pdo,
                $registration,
                $approvalSms
            );

            $message = $registration['reference_no'] .
                ' was approved successfully. The approval SMS was queued.';
        } else {
            $updateStmt = $pdo->prepare(
                'UPDATE residents
                 SET
                    registration_status = "rejected",
                    rejection_reason = :rejection_reason,
                    reviewed_by = :reviewed_by,
                    reviewed_at = NOW()
                 WHERE id = :id'
            );

            $updateStmt->execute([
                ':rejection_reason' => $rejectionReason,
                ':reviewed_by' => $_SESSION['admin_id'],
                ':id' => $registrationId
            ]);

            $rejectionSms = buildRejectionSms(
                (string) $registration['reference_no'],
                $rejectionReason
            );

            queueRegistrationSms(
                $pdo,
                $registration,
                $rejectionSms
            );

            $message = $registration['reference_no'] .
                ' was rejected. The rejection SMS was queued.';
        }

        $pdo->commit();

        $_SESSION['registration_flash'] = [
            'type' => 'success',
            'message' => $message
        ];
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        $_SESSION['registration_flash'] = [
            'type' => 'error',
            'message' => $exception->getMessage()
        ];
    }

    header('Location: ' . $returnUrl);
    exit;
}

/* --------------------------------------------------------------------------
 | Filters and pagination
 * -------------------------------------------------------------------------- */

$search = trim((string) ($_GET['search'] ?? ''));
$statusFilter = trim((string) ($_GET['status'] ?? ''));
$typeFilter = trim((string) ($_GET['type'] ?? ''));

$allowedStatuses = [
    'pending',
    'approved',
    'rejected'
];

$allowedTypes = ['resident', 'non_resident'];

if (!in_array($statusFilter, $allowedStatuses, true)) {
    $statusFilter = '';
}

if (!in_array($typeFilter, $allowedTypes, true)) {
    $typeFilter = '';
}

$currentPage = max(1, (int) ($_GET['page'] ?? 1));
$recordsPerPage = 10;
$offset = ($currentPage - 1) * $recordsPerPage;

$currentReturnQuery = http_build_query(array_filter([
    'search' => $search,
    'status' => $statusFilter,
    'type' => $typeFilter,
    'page' => $currentPage
], static fn (mixed $value): bool => $value !== '' && $value !== null));

/* --------------------------------------------------------------------------
 | Summary counts
 * -------------------------------------------------------------------------- */

$registrationCounts = [
    'total' => 0,
    'pending' => 0,
    'approved' => 0,
    'rejected' => 0
];

try {
    $countSummary = $pdo->query(
        'SELECT
            COUNT(*) AS total_count,
            SUM(registration_status = "pending") AS pending_count,
            SUM(registration_status = "approved") AS approved_count,
            SUM(registration_status = "rejected") AS rejected_count
         FROM residents'
    )->fetch(PDO::FETCH_ASSOC);

    $registrationCounts = [
        'total' => (int) ($countSummary['total_count'] ?? 0),
        'pending' => (int) ($countSummary['pending_count'] ?? 0),
        'approved' => (int) ($countSummary['approved_count'] ?? 0),
        'rejected' => (int) ($countSummary['rejected_count'] ?? 0)
    ];
} catch (PDOException $exception) {
    // Leave the summary at zero and let the table error message handle it.
}

/* --------------------------------------------------------------------------
 | Filtered registrations
 * -------------------------------------------------------------------------- */

$whereConditions = [];
$queryParameters = [];

if ($search !== '') {
    $whereConditions[] =
        '(
            r.reference_no LIKE :search
            OR r.full_name LIKE :search
            OR r.mobile_number LIKE :search
            OR r.barangay LIKE :search
            OR r.municipality LIKE :search
        )';

    $queryParameters[':search'] = '%' . $search . '%';
}

if ($statusFilter !== '') {
    $whereConditions[] = 'r.registration_status = :status';
    $queryParameters[':status'] = $statusFilter;
}

if ($typeFilter !== '') {
    $whereConditions[] = 'r.applicant_type = :type';
    $queryParameters[':type'] = $typeFilter;
}

$whereSql = $whereConditions
    ? 'WHERE ' . implode(' AND ', $whereConditions)
    : '';

$totalFilteredRecords = 0;
$totalPages = 1;
$registrations = [];
$databaseError = '';

try {
    $filteredCountStmt = $pdo->prepare(
        "SELECT COUNT(*)
         FROM residents r
         {$whereSql}"
    );

    foreach ($queryParameters as $key => $value) {
        $filteredCountStmt->bindValue($key, $value, PDO::PARAM_STR);
    }

    $filteredCountStmt->execute();
    $totalFilteredRecords = (int) $filteredCountStmt->fetchColumn();
    $totalPages = max(1, (int) ceil($totalFilteredRecords / $recordsPerPage));

    if ($currentPage > $totalPages) {
        $currentPage = $totalPages;
        $offset = ($currentPage - 1) * $recordsPerPage;
    }

    $registrationsStmt = $pdo->prepare(
        "SELECT
            r.*,
            a.full_name AS reviewer_name
         FROM residents r
         LEFT JOIN admins a
            ON a.id = r.reviewed_by
         {$whereSql}
         ORDER BY
            CASE
                WHEN r.registration_status = 'pending' THEN 0
                WHEN r.registration_status = 'approved' THEN 1
                WHEN r.registration_status = 'rejected' THEN 2
                ELSE 3
            END,
            r.created_at DESC
         LIMIT :record_limit
         OFFSET :record_offset"
    );

    foreach ($queryParameters as $key => $value) {
        $registrationsStmt->bindValue($key, $value, PDO::PARAM_STR);
    }

    $registrationsStmt->bindValue(':record_limit', $recordsPerPage, PDO::PARAM_INT);
    $registrationsStmt->bindValue(':record_offset', $offset, PDO::PARAM_INT);
    $registrationsStmt->execute();

    $registrations = $registrationsStmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $exception) {
    $databaseError = 'The registration records could not be loaded.';
}

function paginationUrl(
    int $page,
    string $search,
    string $status,
    string $type
): string {
    $parameters = ['page' => $page];

    if ($search !== '') {
        $parameters['search'] = $search;
    }

    if ($status !== '') {
        $parameters['status'] = $status;
    }

    if ($type !== '') {
        $parameters['type'] = $type;
    }

    return 'residents.php?' . http_build_query($parameters);
}

$pageTitle = 'SMS Registrations';
$pageSubtitle = 'Review residents and non-residents registered for flood and bridge alerts.';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>SMS Registrations | FloodGuard</title>

    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="../assets/css/residents.css">

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    >
</head>
<body>

<?php require __DIR__ . '/includes/sidebar.php'; ?>

<div class="admin-page">

    <?php require __DIR__ . '/includes/topbar.php'; ?>

    <main class="admin-content standard-admin-page">

        <?php if (is_array($flashMessage)): ?>
            <div class="page-alert <?= ($flashMessage['type'] ?? '') === 'success'
                ? 'alert-success'
                : 'alert-error'
            ?>">
                <i class="bi <?= ($flashMessage['type'] ?? '') === 'success'
                    ? 'bi-check-circle-fill'
                    : 'bi-exclamation-circle-fill'
                ?>"></i>

                <span><?= fgEscape((string) ($flashMessage['message'] ?? '')) ?></span>
            </div>
        <?php endif; ?>

        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error">
                <i class="bi bi-exclamation-circle-fill"></i>
                <span><?= fgEscape($databaseError) ?></span>
            </div>
        <?php endif; ?>

        <section class="registration-statistics">
            <article class="registration-stat-card">
                <div class="registration-stat-icon total">
                    <i class="bi bi-people-fill"></i>
                </div>
                <div>
                    <span>Total Registrations</span>
                    <strong><?= $registrationCounts['total'] ?></strong>
                </div>
            </article>

            <article class="registration-stat-card">
                <div class="registration-stat-icon pending">
                    <i class="bi bi-hourglass-split"></i>
                </div>
                <div>
                    <span>Pending Review</span>
                    <strong><?= $registrationCounts['pending'] ?></strong>
                </div>
            </article>

            <article class="registration-stat-card">
                <div class="registration-stat-icon approved">
                    <i class="bi bi-person-check-fill"></i>
                </div>
                <div>
                    <span>Approved</span>
                    <strong><?= $registrationCounts['approved'] ?></strong>
                </div>
            </article>

            <article class="registration-stat-card">
                <div class="registration-stat-icon rejected">
                    <i class="bi bi-person-x-fill"></i>
                </div>
                <div>
                    <span>Rejected</span>
                    <strong><?= $registrationCounts['rejected'] ?></strong>
                </div>
            </article>
        </section>

        <section class="content-card registrations-card">
            <div class="content-card-header registrations-header">
                <div>
                    <span class="section-label">Recipient Management</span>
                    <h2>Registration Records</h2>
                    <p class="section-description">
                        Click any registration row to view the complete details and review the application.
                    </p>
                </div>

                <span class="records-count">
                    <?= number_format($totalFilteredRecords) ?>
                    record<?= $totalFilteredRecords === 1 ? '' : 's' ?>
                </span>
            </div>

            <form method="GET" class="registration-filters">
                <div class="filter-search">
                    <i class="bi bi-search"></i>
                    <input
                        type="search"
                        name="search"
                        value="<?= fgEscape($search) ?>"
                        placeholder="Search name, mobile number, reference number..."
                    >
                </div>

                <select name="type" aria-label="Applicant type">
                    <option value="">All Applicant Types</option>
                    <option value="resident" <?= $typeFilter === 'resident' ? 'selected' : '' ?>>
                        Resident
                    </option>
                    <option value="non_resident" <?= $typeFilter === 'non_resident' ? 'selected' : '' ?>>
                        Non-Resident
                    </option>
                </select>

                <select name="status" aria-label="Registration status">
                    <option value="">All Statuses</option>
                    <?php foreach ($allowedStatuses as $status): ?>
                        <option
                            value="<?= fgEscape($status) ?>"
                            <?= $statusFilter === $status ? 'selected' : '' ?>
                        >
                            <?= fgEscape(registrationStatusLabel($status)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <button type="submit" class="filter-button">
                    <i class="bi bi-funnel-fill"></i>
                    Apply Filters
                </button>

                <?php if ($search !== '' || $statusFilter !== '' || $typeFilter !== ''): ?>
                    <a href="residents.php" class="clear-filter-button">Clear</a>
                <?php endif; ?>
            </form>

            <div class="table-container registrations-table-container">
                <table class="admin-table registrations-table">
                    <thead>
                    <tr>
                        <th>Reference</th>
                        <th>Applicant</th>
                        <th>Mobile Number</th>
                        <th>Mobile Verification</th>
                        <th>Status</th>
                        <th>Registered</th>
                        <th aria-label="Actions"></th>
                    </tr>
                    </thead>
                    <tbody>

                    <?php if (!$registrations): ?>
                        <tr>
                            <td colspan="7" class="empty-table">
                                <i class="bi bi-person-lines-fill"></i>
                                <strong>No registration records found</strong>
                                <span>
                                    Records will appear after residents or bridge users complete the public SMS registration form.
                                </span>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($registrations as $registration): ?>
                            <?php
                            $modalData = [
                                'id' => (int) $registration['id'],
                                'reference_no' => $registration['reference_no'],
                                'applicant_type' => $registration['applicant_type'],
                                'applicant_type_label' => applicantTypeLabel($registration['applicant_type']),
                                'full_name' => $registration['full_name'],
                                'mobile_number' => $registration['mobile_number'],
                                'complete_address' => $registration['complete_address'],
                                'purok_sitio' => $registration['purok_sitio'] ?: 'Not provided',
                                'barangay' => $registration['barangay'],
                                'municipality' => $registration['municipality'],
                                'province' => $registration['province'],
                                'bridge_connection' => bridgeConnectionLabel($registration['bridge_connection']),
                                'bridge_connection_other' => $registration['bridge_connection_other'] ?: '',
                                'bridge_use_frequency' => bridgeFrequencyLabel($registration['bridge_use_frequency']),
                                'notification_scope' => notificationScopeLabel($registration['notification_scope']),
                                'proof_available' => !empty($registration['proof_stored_name']),
                                'proof_name' => $registration['proof_original_name'] ?: 'Proof of residency',
                                'proof_type' => $registration['proof_mime_type'] ?: 'Not available',
                                'proof_size' => formatFileSize(
                                    $registration['proof_file_size'] !== null
                                        ? (int) $registration['proof_file_size']
                                        : null
                                ),
                                'proof_url' => !empty($registration['proof_stored_name'])
                                    ? 'view_registration_proof.php?id=' . (int) $registration['id']
                                    : '',
                                'sms_consent' => (int) $registration['sms_consent'] === 1,
                                'privacy_consent' => (int) $registration['privacy_consent'] === 1,
                                'mobile_verified' => (int) $registration['mobile_verified'] === 1,
                                'registration_status' => $registration['registration_status'],
                                'registration_status_label' => registrationStatusLabel(
                                    $registration['registration_status']
                                ),
                                'rejection_reason' => $registration['rejection_reason'] ?: '',
                                'reviewer_name' => $registration['reviewer_name'] ?: 'Not yet reviewed',
                                'reviewed_at' => $registration['reviewed_at']
                                    ? date('M d, Y h:i A', strtotime($registration['reviewed_at']))
                                    : 'Not yet reviewed',
                                'created_at' => date(
                                    'M d, Y h:i A',
                                    strtotime($registration['created_at'])
                                )
                            ];

                            $encodedModalData = json_encode(
                                $modalData,
                                JSON_UNESCAPED_UNICODE |
                                JSON_UNESCAPED_SLASHES |
                                JSON_HEX_TAG |
                                JSON_HEX_AMP |
                                JSON_HEX_APOS |
                                JSON_HEX_QUOT
                            );
                            ?>

                            <tr
                                class="registration-row"
                                tabindex="0"
                                role="button"
                                aria-label="View <?= fgEscape($registration['reference_no']) ?> details"
                                data-registration="<?= fgEscape($encodedModalData ?: '{}') ?>"
                            >
                                <td>
                                    <strong class="reference-number">
                                        <?= fgEscape($registration['reference_no']) ?>
                                    </strong>
                                </td>

                                <td>
                                    <div class="applicant-cell">
                                        <div class="applicant-avatar">
                                            <?= fgEscape(strtoupper(substr($registration['full_name'], 0, 1))) ?>
                                        </div>
                                        <div>
                                            <strong><?= fgEscape($registration['full_name']) ?></strong>
                                            <span><?= fgEscape(applicantTypeLabel($registration['applicant_type'])) ?></span>
                                        </div>
                                    </div>
                                </td>

                                <td><?= fgEscape($registration['mobile_number']) ?></td>

                                <td>
                                    <?php if ((int) $registration['mobile_verified'] === 1): ?>
                                        <span class="verification-label verified">
                                            <i class="bi bi-check-circle-fill"></i>
                                            Verified
                                        </span>
                                    <?php else: ?>
                                        <span class="verification-label unverified">
                                            <i class="bi bi-dash-circle-fill"></i>
                                            Unverified
                                        </span>
                                    <?php endif; ?>
                                </td>

                                <td>
                                    <span class="status-badge <?= registrationStatusClass(
                                        $registration['registration_status']
                                    ) ?>">
                                        <?= fgEscape(registrationStatusLabel($registration['registration_status'])) ?>
                                    </span>
                                </td>

                                <td>
                                    <div class="date-cell">
                                        <strong><?= date('M d, Y', strtotime($registration['created_at'])) ?></strong>
                                        <span><?= date('h:i A', strtotime($registration['created_at'])) ?></span>
                                    </div>
                                </td>

                                <td>
                                    <button
                                        type="button"
                                        class="view-registration-button"
                                        aria-label="View registration details"
                                        title="View details"
                                    >
                                        <i class="bi bi-eye-fill"></i>
                                    </button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>

                    </tbody>
                </table>
            </div>

            <?php if ($totalPages > 1): ?>
                <div class="table-pagination">
                    <div class="pagination-summary">
                        Showing <?= number_format($offset + 1) ?> to
                        <?= number_format(min($offset + $recordsPerPage, $totalFilteredRecords)) ?>
                        of <?= number_format($totalFilteredRecords) ?>
                    </div>

                    <div class="pagination-links">
                        <?php if ($currentPage > 1): ?>
                            <a
                                href="<?= fgEscape(paginationUrl(
                                    $currentPage - 1,
                                    $search,
                                    $statusFilter,
                                    $typeFilter
                                )) ?>"
                                class="pagination-button"
                            >
                                <i class="bi bi-chevron-left"></i>
                            </a>
                        <?php endif; ?>

                        <?php
                        $startPage = max(1, $currentPage - 2);
                        $endPage = min($totalPages, $currentPage + 2);
                        ?>

                        <?php for ($page = $startPage; $page <= $endPage; $page++): ?>
                            <a
                                href="<?= fgEscape(paginationUrl(
                                    $page,
                                    $search,
                                    $statusFilter,
                                    $typeFilter
                                )) ?>"
                                class="pagination-button <?= $page === $currentPage ? 'active' : '' ?>"
                            >
                                <?= $page ?>
                            </a>
                        <?php endfor; ?>

                        <?php if ($currentPage < $totalPages): ?>
                            <a
                                href="<?= fgEscape(paginationUrl(
                                    $currentPage + 1,
                                    $search,
                                    $statusFilter,
                                    $typeFilter
                                )) ?>"
                                class="pagination-button"
                            >
                                <i class="bi bi-chevron-right"></i>
                            </a>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>

<div class="registration-modal" id="registrationModal" aria-hidden="true">
    <div class="registration-modal-backdrop" data-modal-close></div>

    <section
        class="registration-modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="registrationModalTitle"
    >
        <header class="registration-modal-header">
            <div>
                <span class="modal-eyebrow">Registration Review</span>
                <h2 id="registrationModalTitle">Registration Details</h2>
                <p id="modalReferenceNumber">—</p>
            </div>

            <button
                type="button"
                class="registration-modal-close"
                data-modal-close
                aria-label="Close registration details"
            >
                <i class="bi bi-x-lg"></i>
            </button>
        </header>

        <div class="registration-modal-body">
            <div class="modal-applicant-heading">
                <div class="modal-applicant-avatar" id="modalApplicantAvatar">A</div>
                <div>
                    <h3 id="modalFullName">—</h3>
                    <p>
                        <span id="modalApplicantType">—</span>
                        <span class="modal-divider">•</span>
                        <span id="modalRegisteredAt">—</span>
                    </p>
                </div>

                <span class="modal-status-badge" id="modalStatusBadge">Pending</span>
            </div>

            <div class="modal-details-grid">
                <article class="modal-detail-card">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-person-vcard-fill"></i>
                        <h4>Contact Information</h4>
                    </div>
                    <dl>
                        <div><dt>Mobile number</dt><dd id="modalMobileNumber">—</dd></div>
                        <div><dt>Mobile verification</dt><dd id="modalMobileVerified">—</dd></div>
                        <div><dt>Alert coverage</dt><dd id="modalNotificationScope">—</dd></div>
                    </dl>
                </article>

                <article class="modal-detail-card">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-geo-alt-fill"></i>
                        <h4>Address</h4>
                    </div>
                    <dl>
                        <div><dt>Complete address</dt><dd id="modalCompleteAddress">—</dd></div>
                        <div><dt>Purok or sitio</dt><dd id="modalPurokSitio">—</dd></div>
                        <div><dt>Barangay</dt><dd id="modalBarangay">—</dd></div>
                        <div><dt>Municipality / Province</dt><dd id="modalMunicipalityProvince">—</dd></div>
                    </dl>
                </article>

                <article class="modal-detail-card" id="modalBridgeCard">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-signpost-2-fill"></i>
                        <h4>Bridge Connection</h4>
                    </div>
                    <dl>
                        <div><dt>Connection</dt><dd id="modalBridgeConnection">—</dd></div>
                        <div id="modalBridgeOtherRow"><dt>Description</dt><dd id="modalBridgeConnectionOther">—</dd></div>
                        <div><dt>Use frequency</dt><dd id="modalBridgeFrequency">—</dd></div>
                    </dl>
                </article>

                <article class="modal-detail-card">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-file-earmark-check-fill"></i>
                        <h4>Verification Document</h4>
                    </div>
                    <div class="proof-information" id="modalProofAvailable">
                        <div>
                            <strong id="modalProofName">—</strong>
                            <span id="modalProofMeta">—</span>
                        </div>
                        <a
                            href="#"
                            id="modalProofLink"
                            class="proof-view-button"
                            target="_blank"
                            rel="noopener"
                        >
                            <i class="bi bi-eye-fill"></i>
                            View Proof
                        </a>
                    </div>
                    <div class="proof-empty" id="modalProofEmpty">
                        <i class="bi bi-file-earmark-x"></i>
                        <span>No proof document is required for this non-resident registration.</span>
                    </div>
                </article>

                <article class="modal-detail-card">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-shield-check"></i>
                        <h4>Consent</h4>
                    </div>
                    <dl>
                        <div><dt>SMS consent</dt><dd id="modalSmsConsent">—</dd></div>
                        <div><dt>Privacy consent</dt><dd id="modalPrivacyConsent">—</dd></div>
                    </dl>
                </article>

                <article class="modal-detail-card">
                    <div class="modal-detail-card-header">
                        <i class="bi bi-person-check-fill"></i>
                        <h4>Review Information</h4>
                    </div>
                    <dl>
                        <div><dt>Reviewed by</dt><dd id="modalReviewer">—</dd></div>
                        <div><dt>Reviewed at</dt><dd id="modalReviewedAt">—</dd></div>
                        <div id="modalRejectionReasonRow"><dt>Rejection reason</dt><dd id="modalRejectionReason">—</dd></div>
                    </dl>
                </article>
            </div>

            <form method="POST" id="registrationActionForm" class="registration-action-form">
                <input type="hidden" name="csrf_token" value="<?= fgEscape($actionCsrfToken) ?>">
                <input type="hidden" name="registration_id" id="modalRegistrationId" value="">
                <input type="hidden" name="return_query" value="<?= fgEscape($currentReturnQuery) ?>">

                <div class="reject-reason-panel" id="rejectReasonPanel">
                    <label for="rejectionReason">Reason for rejection</label>
                    <textarea
                        id="rejectionReason"
                        name="rejection_reason"
                        maxlength="500"
                        placeholder="Explain why this registration cannot be approved."
                    ></textarea>
                    <small>The reason should be clear enough for administrative records.</small>
                </div>

                <div class="registration-action-buttons" id="modalActionButtons">
                    <button
                        type="submit"
                        name="action"
                        value="approve"
                        class="registration-approve-button"
                        id="modalApproveButton"
                    >
                        <i class="bi bi-check-circle-fill"></i>
                        Approve Registration
                    </button>

                    <button
                        type="button"
                        class="registration-reject-toggle"
                        id="modalRejectToggle"
                    >
                        <i class="bi bi-x-circle-fill"></i>
                        Reject
                    </button>

                    <button
                        type="submit"
                        name="action"
                        value="reject"
                        class="registration-confirm-reject"
                        id="modalConfirmReject"
                    >
                        Confirm Rejection
                    </button>

                    <button
                        type="button"
                        class="registration-cancel-reject"
                        id="modalCancelReject"
                    >
                        Cancel
                    </button>
                </div>

                <p class="already-reviewed-message" id="alreadyReviewedMessage"></p>
            </form>
        </div>
    </section>
</div>

<div
    class="action-confirmation-modal"
    id="actionConfirmationModal"
    aria-hidden="true"
>
    <div
        class="action-confirmation-backdrop"
        data-action-confirmation-close
    ></div>

    <section
        class="action-confirmation-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="actionConfirmationTitle"
        aria-describedby="actionConfirmationMessage"
    >
        <button
            type="button"
            class="action-confirmation-close"
            data-action-confirmation-close
            aria-label="Close confirmation"
        >
            <i class="bi bi-x-lg"></i>
        </button>

        <div
            class="action-confirmation-icon approve"
            id="actionConfirmationIcon"
        >
            <i class="bi bi-check-circle-fill"></i>
        </div>

        <span class="action-confirmation-eyebrow">
            Confirm Administrative Action
        </span>

        <h2 id="actionConfirmationTitle">
            Approve registration?
        </h2>

        <p id="actionConfirmationMessage">
            Please confirm this action before continuing.
        </p>

        <div class="action-confirmation-reference">
            <span>Registration reference</span>
            <strong id="actionConfirmationReference">—</strong>
        </div>

        <div class="action-confirmation-buttons">
            <button
                type="button"
                class="action-confirmation-cancel"
                data-action-confirmation-close
            >
                Cancel
            </button>

            <button
                type="button"
                class="action-confirmation-submit approve"
                id="actionConfirmationSubmit"
            >
                <i class="bi bi-check-circle-fill"></i>
                <span>Approve Registration</span>
            </button>
        </div>
    </section>
</div>

<script src="../assets/js/admin.js"></script>
<script src="../assets/js/residents.js?v=20260803-2"></script>
</body>
</html>
