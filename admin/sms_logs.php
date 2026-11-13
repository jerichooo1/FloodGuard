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

/* --------------------------------------------------------------------------
 | Shared monitoring-station status for includes/topbar.php and sidebar.php
 * -------------------------------------------------------------------------- */

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
            TIMESTAMPDIFF(SECOND, created_at, CURRENT_TIMESTAMP) AS reading_age_seconds
         FROM sensor_readings
         WHERE device_id = :device_id
         ORDER BY created_at DESC
         LIMIT 1'
    );
    $deviceStatusStmt->execute([':device_id' => $deviceId]);

    $latestDeviceStatus = $deviceStatusStmt->fetch(PDO::FETCH_ASSOC);

    if ($latestDeviceStatus) {
        $readingAgeSeconds = (int) (
            $latestDeviceStatus['reading_age_seconds'] ?? PHP_INT_MAX
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

function smsStatusLabel(string $status): string
{
    return match ($status) {
        'sent' => 'Sent',
        'failed' => 'Failed',
        default => 'Pending'
    };
}

function smsStatusClass(string $status): string
{
    return match ($status) {
        'sent' => 'sms-status-sent',
        'failed' => 'sms-status-failed',
        default => 'sms-status-pending'
    };
}

function smsTypeLabel(string $messageType): string
{
    return match ($messageType) {
        'otp' => 'Phone Verification',
        'registration' => 'Registration',
        default => 'Public Alert'
    };
}

function smsTypeClass(string $messageType): string
{
    return match ($messageType) {
        'otp' => 'sms-type-otp',
        'registration' => 'sms-type-registration',
        default => 'sms-type-alert'
    };
}

function smsTypeIcon(string $messageType): string
{
    return match ($messageType) {
        'otp' => 'bi-shield-lock-fill',
        'registration' => 'bi-person-check-fill',
        default => 'bi-bell-fill'
    };
}

function smsRecipientTypeLabel(string $recipientType): string
{
    return $recipientType === 'non_resident'
        ? 'Non-Resident'
        : 'Resident';
}

function normalizeSmsDisplayText(?string $value): string
{
    $normalized = preg_replace('/\s+/u', ' ', trim((string) $value));

    return is_string($normalized) ? $normalized : trim((string) $value);
}

function truncateSmsDisplayText(string $value, int $maximumLength = 115): string
{
    if (function_exists('mb_strlen') && function_exists('mb_substr')) {
        if (mb_strlen($value, 'UTF-8') <= $maximumLength) {
            return $value;
        }

        return rtrim(
            mb_substr($value, 0, $maximumLength - 3, 'UTF-8')
        ) . '...';
    }

    if (strlen($value) <= $maximumLength) {
        return $value;
    }

    return rtrim(substr($value, 0, $maximumLength - 3)) . '...';
}

function smsSafeMessage(array $record): string
{
    if (($record['message_type'] ?? '') === 'otp') {
        return 'Phone verification code message hidden for security.';
    }

    $message = normalizeSmsDisplayText((string) ($record['message'] ?? ''));

    return $message !== ''
        ? $message
        : 'No message content recorded.';
}

function formatMobileNumber(string $mobileNumber): string
{
    if (preg_match('/^(09\d{2})(\d{3})(\d{4})$/', $mobileNumber, $matches)) {
        return $matches[1] . ' ' . $matches[2] . ' ' . $matches[3];
    }

    return $mobileNumber;
}

function smsDateParts(?string $value): array
{
    if ($value === null || $value === '') {
        return ['date' => 'Not available', 'time' => ''];
    }

    $timestamp = strtotime($value);

    if ($timestamp === false) {
        return ['date' => $value, 'time' => ''];
    }

    return [
        'date' => date('M j, Y', $timestamp),
        'time' => date('g:i:s A', $timestamp)
    ];
}

function smsDeliveryResult(array $record): string
{
    $status = (string) ($record['delivery_status'] ?? 'pending');
    $modemResponse = normalizeSmsDisplayText(
        (string) ($record['modem_response'] ?? '')
    );

    if ($status === 'pending') {
        return !empty($record['claimed_by'])
            ? 'Claimed by the monitoring station; awaiting final result.'
            : 'Waiting in the outgoing SMS queue.';
    }

    if ($modemResponse !== '') {
        return $modemResponse;
    }

    return $status === 'sent'
        ? 'The modem reported the message as sent.'
        : 'No modem failure response was recorded.';
}

function smsDateTimeLabel(?string $value): string
{
    if ($value === null || $value === '') {
        return 'Not available';
    }

    $timestamp = strtotime($value);

    return $timestamp !== false
        ? date('M j, Y g:i:s A', $timestamp)
        : $value;
}

function smsSourceLabel(array $record): string
{
    if (!empty($record['sensor_reading_id'])) {
        return 'Sensor reading #' . (int) $record['sensor_reading_id'];
    }

    if (!empty($record['verification_id'])) {
        return 'Phone verification #' . (int) $record['verification_id'];
    }

    if (($record['message_type'] ?? '') === 'registration') {
        return 'Registration review notice';
    }

    return 'Manual or legacy SMS record';
}

function smsPaginationUrl(int $page, array $filters): string
{
    $parameters = ['page' => $page];

    foreach ($filters as $key => $value) {
        if ($value !== '') {
            $parameters[$key] = $value;
        }
    }

    return 'sms_logs.php?' . http_build_query($parameters);
}

/* --------------------------------------------------------------------------
 | Filters and pagination
 * -------------------------------------------------------------------------- */

$allowedStatuses = ['pending', 'sent', 'failed'];
$allowedMessageTypes = ['alert', 'registration', 'otp'];
$allowedRecipientTypes = ['resident', 'non_resident'];

$search = trim((string) ($_GET['search'] ?? ''));
$statusFilter = strtolower(trim((string) ($_GET['status'] ?? '')));
$messageTypeFilter = strtolower(trim((string) ($_GET['message_type'] ?? '')));
$recipientTypeFilter = strtolower(trim((string) ($_GET['recipient_type'] ?? '')));
$dateFrom = trim((string) ($_GET['date_from'] ?? ''));
$dateTo = trim((string) ($_GET['date_to'] ?? ''));

if (strlen($search) > 100) {
    $search = substr($search, 0, 100);
}

if (!in_array($statusFilter, $allowedStatuses, true)) {
    $statusFilter = '';
}

if (!in_array($messageTypeFilter, $allowedMessageTypes, true)) {
    $messageTypeFilter = '';
}

if (!in_array($recipientTypeFilter, $allowedRecipientTypes, true)) {
    $recipientTypeFilter = '';
}

if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateFrom)) {
    $dateFrom = '';
}

if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateTo)) {
    $dateTo = '';
}

$recordsPerPage = 15;
$currentPage = max(1, (int) ($_GET['page'] ?? 1));
$offset = ($currentPage - 1) * $recordsPerPage;

$activeFilters = [
    'search' => $search,
    'status' => $statusFilter,
    'message_type' => $messageTypeFilter,
    'recipient_type' => $recipientTypeFilter,
    'date_from' => $dateFrom,
    'date_to' => $dateTo
];

/* --------------------------------------------------------------------------
 | Summary counts
 * -------------------------------------------------------------------------- */

$smsCounts = [
    'total' => 0,
    'sent' => 0,
    'pending' => 0,
    'failed' => 0
];

try {
    $summaryStmt = $pdo->query(
        'SELECT
            COUNT(*) AS total_count,
            SUM(delivery_status = "sent") AS sent_count,
            SUM(delivery_status = "pending") AS pending_count,
            SUM(delivery_status = "failed") AS failed_count
         FROM sms_logs'
    );

    $summary = $summaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $smsCounts = [
        'total' => (int) ($summary['total_count'] ?? 0),
        'sent' => (int) ($summary['sent_count'] ?? 0),
        'pending' => (int) ($summary['pending_count'] ?? 0),
        'failed' => (int) ($summary['failed_count'] ?? 0)
    ];
} catch (PDOException $exception) {
    // The main table error below provides the visible error state.
}

/* --------------------------------------------------------------------------
 | Filtered SMS records
 * -------------------------------------------------------------------------- */

$whereConditions = [];
$queryParameters = [];
$effectiveMessageTypeSql =
    'CASE
        WHEN s.message_type = "alert"
         AND s.sensor_reading_id IS NULL
         AND s.verification_id IS NULL
         AND s.resident_id IS NOT NULL
            THEN "registration"
        ELSE s.message_type
     END';

if ($search !== '') {
    $searchValue = '%' . $search . '%';
    $whereConditions[] =
        '(s.mobile_number LIKE :search_mobile
          OR s.message LIKE :search_message
          OR r.full_name LIKE :search_resident_name
          OR r.reference_no LIKE :search_reference
          OR pending.full_name LIKE :search_pending_name)';
    $queryParameters[':search_mobile'] = $searchValue;
    $queryParameters[':search_message'] = $searchValue;
    $queryParameters[':search_resident_name'] = $searchValue;
    $queryParameters[':search_reference'] = $searchValue;
    $queryParameters[':search_pending_name'] = $searchValue;
}

if ($statusFilter !== '') {
    $whereConditions[] = 's.delivery_status = :delivery_status';
    $queryParameters[':delivery_status'] = $statusFilter;
}

if ($messageTypeFilter !== '') {
    $whereConditions[] = "({$effectiveMessageTypeSql}) = :message_type";
    $queryParameters[':message_type'] = $messageTypeFilter;
}

if ($recipientTypeFilter !== '') {
    $whereConditions[] = 's.recipient_type = :recipient_type';
    $queryParameters[':recipient_type'] = $recipientTypeFilter;
}

if ($dateFrom !== '') {
    $whereConditions[] = 's.created_at >= :date_from';
    $queryParameters[':date_from'] = $dateFrom . ' 00:00:00';
}

if ($dateTo !== '') {
    $whereConditions[] = 's.created_at <= :date_to';
    $queryParameters[':date_to'] = $dateTo . ' 23:59:59';
}

$whereSql = $whereConditions
    ? 'WHERE ' . implode(' AND ', $whereConditions)
    : '';

$smsRecords = [];
$totalFilteredRecords = 0;
$totalPages = 1;
$databaseError = '';

try {
    $countStmt = $pdo->prepare(
        "SELECT COUNT(*)
         FROM sms_logs s
         LEFT JOIN residents r ON r.id = s.resident_id
         LEFT JOIN pending_phone_verifications pending
            ON pending.id = s.verification_id
         {$whereSql}"
    );

    foreach ($queryParameters as $parameter => $value) {
        $countStmt->bindValue($parameter, $value, PDO::PARAM_STR);
    }

    $countStmt->execute();
    $totalFilteredRecords = (int) $countStmt->fetchColumn();
    $totalPages = max(1, (int) ceil($totalFilteredRecords / $recordsPerPage));

    if ($currentPage > $totalPages) {
        $currentPage = $totalPages;
        $offset = ($currentPage - 1) * $recordsPerPage;
    }

    $recordsStmt = $pdo->prepare(
        "SELECT
            s.id,
            s.alert_id,
            s.sensor_reading_id,
            s.resident_id,
            s.verification_id,
            s.mobile_number,
            s.recipient_type,
            {$effectiveMessageTypeSql} AS message_type,
            s.message,
            s.delivery_status,
            s.claimed_by,
            s.claimed_at,
            s.attempt_count,
            s.modem_response,
            s.sent_at,
            s.created_at,
            COALESCE(r.full_name, pending.full_name) AS recipient_name,
            r.reference_no
         FROM sms_logs s
         LEFT JOIN residents r ON r.id = s.resident_id
         LEFT JOIN pending_phone_verifications pending
            ON pending.id = s.verification_id
         {$whereSql}
         ORDER BY s.created_at DESC, s.id DESC
         LIMIT :record_limit
         OFFSET :record_offset"
    );

    foreach ($queryParameters as $parameter => $value) {
        $recordsStmt->bindValue($parameter, $value, PDO::PARAM_STR);
    }

    $recordsStmt->bindValue(':record_limit', $recordsPerPage, PDO::PARAM_INT);
    $recordsStmt->bindValue(':record_offset', $offset, PDO::PARAM_INT);
    $recordsStmt->execute();
    $smsRecords = $recordsStmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $exception) {
    error_log('[FloodGuard SMS records] ' . $exception->getMessage());
    $databaseError = 'The SMS delivery records could not be loaded.';
}

$pageTitle = 'SMS Records';
$pageSubtitle = 'Review queued, sent, and failed FloodGuard text messages.';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMS Records | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="../assets/css/sms-records.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>

<?php require __DIR__ . '/includes/sidebar.php'; ?>

<div class="admin-page">
    <?php require __DIR__ . '/includes/topbar.php'; ?>

    <main class="admin-content standard-admin-page sms-records-page">
        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error">
                <i class="bi bi-exclamation-circle-fill"></i>
                <span><?= fgEscape($databaseError) ?></span>
            </div>
        <?php endif; ?>

        <section class="sms-statistics" aria-label="SMS delivery summary">
            <article class="sms-stat-card">
                <div class="sms-stat-icon total"><i class="bi bi-chat-square-text-fill"></i></div>
                <div><span>Total Messages</span><strong><?= number_format($smsCounts['total']) ?></strong><small>All recorded SMS activity</small></div>
            </article>
            <article class="sms-stat-card">
                <div class="sms-stat-icon sent"><i class="bi bi-check-circle-fill"></i></div>
                <div><span>Sent</span><strong><?= number_format($smsCounts['sent']) ?></strong><small>Successfully reported by modem</small></div>
            </article>
            <article class="sms-stat-card">
                <div class="sms-stat-icon pending"><i class="bi bi-hourglass-split"></i></div>
                <div><span>Pending</span><strong><?= number_format($smsCounts['pending']) ?></strong><small>Waiting or being processed</small></div>
            </article>
            <article class="sms-stat-card">
                <div class="sms-stat-icon failed"><i class="bi bi-x-circle-fill"></i></div>
                <div><span>Failed</span><strong><?= number_format($smsCounts['failed']) ?></strong><small>Requires result review</small></div>
            </article>
        </section>

        <section class="content-card sms-history-card">
            <div class="content-card-header sms-history-header">
                <div>
                    <span class="section-label">Message Delivery Log</span>
                    <h2>FloodGuard SMS Records</h2>
                    <p class="sms-section-description">OTP content is hidden. Registration and public-alert messages remain visible for delivery auditing.</p>
                </div>
                <span class="sms-record-count"><?= number_format($totalFilteredRecords) ?> record<?= $totalFilteredRecords === 1 ? '' : 's' ?></span>
            </div>

            <form method="GET" class="sms-filters">
                <div class="sms-filter-search">
                    <i class="bi bi-search"></i>
                    <input type="search" name="search" value="<?= fgEscape($search) ?>" placeholder="Search recipient, mobile number, or message..." aria-label="Search SMS records">
                </div>

                <select name="message_type" aria-label="Message type">
                    <option value="">All Message Types</option>
                    <option value="alert" <?= $messageTypeFilter === 'alert' ? 'selected' : '' ?>>Public Alert</option>
                    <option value="registration" <?= $messageTypeFilter === 'registration' ? 'selected' : '' ?>>Registration</option>
                    <option value="otp" <?= $messageTypeFilter === 'otp' ? 'selected' : '' ?>>Phone Verification</option>
                </select>

                <select name="status" aria-label="Delivery status">
                    <option value="">All Delivery Statuses</option>
                    <option value="sent" <?= $statusFilter === 'sent' ? 'selected' : '' ?>>Sent</option>
                    <option value="pending" <?= $statusFilter === 'pending' ? 'selected' : '' ?>>Pending</option>
                    <option value="failed" <?= $statusFilter === 'failed' ? 'selected' : '' ?>>Failed</option>
                </select>

                <select name="recipient_type" aria-label="Recipient type">
                    <option value="">All Recipient Types</option>
                    <option value="resident" <?= $recipientTypeFilter === 'resident' ? 'selected' : '' ?>>Resident</option>
                    <option value="non_resident" <?= $recipientTypeFilter === 'non_resident' ? 'selected' : '' ?>>Non-Resident</option>
                </select>

                <div class="sms-date-field">
                    <label for="date_from">From</label>
                    <input id="date_from" type="date" name="date_from" value="<?= fgEscape($dateFrom) ?>">
                </div>

                <div class="sms-date-field">
                    <label for="date_to">To</label>
                    <input id="date_to" type="date" name="date_to" value="<?= fgEscape($dateTo) ?>">
                </div>

                <button type="submit" class="sms-filter-button"><i class="bi bi-funnel-fill"></i> Apply Filters</button>

                <?php if (array_filter($activeFilters, static fn (string $value): bool => $value !== '')): ?>
                    <a href="sms_logs.php" class="sms-clear-filter">Clear</a>
                <?php endif; ?>
            </form>

            <div class="sms-table-container">
                <table class="admin-table sms-history-table">
                    <thead>
                    <tr>
                        <th>Date and Time</th>
                        <th>Recipient</th>
                        <th>Mobile Number</th>
                        <th>Message Type</th>
                        <th>Delivery</th>
                        <th>Attempts</th>
                        <th aria-label="View details"></th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php if (!$smsRecords): ?>
                        <tr>
                            <td colspan="7" class="sms-empty-table">
                                <i class="bi bi-chat-square-text"></i>
                                <strong>No SMS records found</strong>
                                <span>Messages will appear after an OTP, registration notice, or public alert is added to the SMS queue.</span>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($smsRecords as $record): ?>
                            <?php
                            $createdParts = smsDateParts((string) $record['created_at']);
                            $recipientName = trim((string) ($record['recipient_name'] ?? ''));
                            $referenceNumber = trim((string) ($record['reference_no'] ?? ''));
                            $messageType = (string) $record['message_type'];
                            $deliveryStatus = (string) $record['delivery_status'];
                            $modalRecord = [
                                'id' => (int) $record['id'],
                                'recipient' => $recipientName !== ''
                                    ? $recipientName
                                    : 'Unlinked recipient',
                                'reference' => $referenceNumber !== ''
                                    ? $referenceNumber
                                    : 'Not linked',
                                'recipient_type' => smsRecipientTypeLabel(
                                    (string) $record['recipient_type']
                                ),
                                'mobile_number' => formatMobileNumber(
                                    (string) $record['mobile_number']
                                ),
                                'message_type' => smsTypeLabel($messageType),
                                'delivery_status' => $deliveryStatus,
                                'delivery_label' => smsStatusLabel($deliveryStatus),
                                'attempts' => (int) $record['attempt_count'],
                                'source' => smsSourceLabel($record),
                                'message' => smsSafeMessage($record),
                                'modem_result' => smsDeliveryResult($record),
                                'created_at' => smsDateTimeLabel(
                                    (string) $record['created_at']
                                ),
                                'claimed_by' => !empty($record['claimed_by'])
                                    ? (string) $record['claimed_by']
                                    : 'Not claimed',
                                'claimed_at' => smsDateTimeLabel(
                                    $record['claimed_at'] !== null
                                        ? (string) $record['claimed_at']
                                        : null
                                ),
                                'sent_at' => smsDateTimeLabel(
                                    $record['sent_at'] !== null
                                        ? (string) $record['sent_at']
                                        : null
                                )
                            ];
                            $modalJson = json_encode(
                                $modalRecord,
                                JSON_UNESCAPED_UNICODE |
                                JSON_UNESCAPED_SLASHES |
                                JSON_HEX_TAG |
                                JSON_HEX_AMP |
                                JSON_HEX_APOS |
                                JSON_HEX_QUOT
                            );

                            if (!is_string($modalJson)) {
                                $modalJson = '{}';
                            }
                            ?>
                            <tr
                                class="sms-record-row"
                                tabindex="0"
                                data-sms-record="<?= fgEscape($modalJson) ?>"
                                aria-label="View SMS record <?= (int) $record['id'] ?> details"
                            >
                                <td data-label="Date and Time" class="sms-date-cell">
                                    <strong><?= fgEscape($createdParts['date']) ?></strong>
                                    <span><?= fgEscape($createdParts['time']) ?></span>
                                </td>
                                <td data-label="Recipient" class="sms-recipient-cell">
                                    <strong><?= fgEscape($recipientName !== '' ? $recipientName : 'Unlinked recipient') ?></strong>
                                    <span>
                                        <?= fgEscape(smsRecipientTypeLabel((string) $record['recipient_type'])) ?>
                                        <?= $referenceNumber !== '' ? ' · ' . fgEscape($referenceNumber) : '' ?>
                                    </span>
                                </td>
                                <td data-label="Mobile Number" class="sms-mobile-cell"><?= fgEscape(formatMobileNumber((string) $record['mobile_number'])) ?></td>
                                <td data-label="Message Type">
                                    <span class="sms-type-badge <?= fgEscape(smsTypeClass($messageType)) ?>">
                                        <i class="bi <?= fgEscape(smsTypeIcon($messageType)) ?>"></i>
                                        <?= fgEscape(smsTypeLabel($messageType)) ?>
                                    </span>
                                </td>
                                <td data-label="Delivery">
                                    <span class="sms-status-badge <?= fgEscape(smsStatusClass($deliveryStatus)) ?>"><?= fgEscape(smsStatusLabel($deliveryStatus)) ?></span>
                                    <?php if ($deliveryStatus === 'sent' && !empty($record['sent_at'])): ?>
                                        <small><?= fgEscape(date('M j, g:i A', strtotime((string) $record['sent_at']))) ?></small>
                                    <?php endif; ?>
                                </td>
                                <td data-label="Attempts" class="sms-attempt-cell"><?= number_format((int) $record['attempt_count']) ?></td>
                                <td data-label="Details" class="sms-action-cell">
                                    <button
                                        type="button"
                                        class="sms-view-button"
                                        aria-label="View SMS record <?= (int) $record['id'] ?> details"
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

            <?php if ($totalFilteredRecords > 0): ?>
                <div class="sms-pagination">
                    <p class="sms-pagination-summary">
                        Showing <?= number_format($offset + 1) ?>–<?= number_format(min($offset + $recordsPerPage, $totalFilteredRecords)) ?> of <?= number_format($totalFilteredRecords) ?> records
                    </p>
                    <div class="sms-pagination-controls">
                        <?php if ($currentPage > 1): ?>
                            <a class="sms-page-button" href="<?= fgEscape(smsPaginationUrl($currentPage - 1, $activeFilters)) ?>" aria-label="Previous page"><i class="bi bi-chevron-left"></i></a>
                        <?php endif; ?>

                        <?php
                        $startPage = max(1, $currentPage - 2);
                        $endPage = min($totalPages, $currentPage + 2);
                        for ($page = $startPage; $page <= $endPage; ++$page):
                        ?>
                            <a class="sms-page-button <?= $page === $currentPage ? 'active' : '' ?>" href="<?= fgEscape(smsPaginationUrl($page, $activeFilters)) ?>"><?= $page ?></a>
                        <?php endfor; ?>

                        <?php if ($currentPage < $totalPages): ?>
                            <a class="sms-page-button" href="<?= fgEscape(smsPaginationUrl($currentPage + 1, $activeFilters)) ?>" aria-label="Next page"><i class="bi bi-chevron-right"></i></a>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>

<dialog class="sms-details-modal" id="smsDetailsModal" aria-labelledby="smsModalTitle">
    <div class="sms-modal-header">
        <div>
            <span class="section-label">SMS Delivery Record</span>
            <h2 id="smsModalTitle">Message Details</h2>
            <p id="smsModalRecordNumber">Record #—</p>
        </div>
        <button type="button" class="sms-modal-close" id="smsModalClose" aria-label="Close details">
            <i class="bi bi-x-lg"></i>
        </button>
    </div>

    <div class="sms-modal-status-row">
        <span class="sms-type-badge sms-type-alert" id="smsModalType">Message</span>
        <span class="sms-status-badge sms-status-pending" id="smsModalStatus">Pending</span>
    </div>

    <div class="sms-modal-grid">
        <div><span>Recipient</span><strong id="smsModalRecipient">—</strong></div>
        <div><span>Recipient Type</span><strong id="smsModalRecipientType">—</strong></div>
        <div><span>Mobile Number</span><strong id="smsModalMobile">—</strong></div>
        <div><span>Reference</span><strong id="smsModalReference">—</strong></div>
        <div><span>Source</span><strong id="smsModalSource">—</strong></div>
        <div><span>Send Attempts</span><strong id="smsModalAttempts">—</strong></div>
        <div><span>Queued At</span><strong id="smsModalCreated">—</strong></div>
        <div><span>Sent At</span><strong id="smsModalSent">—</strong></div>
        <div><span>Claimed By</span><strong id="smsModalClaimedBy">—</strong></div>
        <div><span>Claimed At</span><strong id="smsModalClaimedAt">—</strong></div>
    </div>

    <section class="sms-modal-text-block">
        <span>Message Content</span>
        <p id="smsModalMessage">—</p>
    </section>

    <section class="sms-modal-text-block modem">
        <span>Modem Result</span>
        <p id="smsModalResult">—</p>
    </section>
</dialog>

<script>
(() => {
    'use strict';

    const modal = document.getElementById('smsDetailsModal');
    const closeButton = document.getElementById('smsModalClose');

    if (!modal || !closeButton) {
        return;
    }

    const fields = {
        recordNumber: document.getElementById('smsModalRecordNumber'),
        type: document.getElementById('smsModalType'),
        status: document.getElementById('smsModalStatus'),
        recipient: document.getElementById('smsModalRecipient'),
        recipientType: document.getElementById('smsModalRecipientType'),
        mobile: document.getElementById('smsModalMobile'),
        reference: document.getElementById('smsModalReference'),
        source: document.getElementById('smsModalSource'),
        attempts: document.getElementById('smsModalAttempts'),
        created: document.getElementById('smsModalCreated'),
        sent: document.getElementById('smsModalSent'),
        claimedBy: document.getElementById('smsModalClaimedBy'),
        claimedAt: document.getElementById('smsModalClaimedAt'),
        message: document.getElementById('smsModalMessage'),
        result: document.getElementById('smsModalResult')
    };

    function setText(element, value) {
        if (element) {
            element.textContent = value ?? 'Not available';
        }
    }

    function showRecord(row) {
        let record;

        try {
            record = JSON.parse(row.dataset.smsRecord || '{}');
        } catch (error) {
            return;
        }

        setText(fields.recordNumber, `Record #${record.id ?? '—'}`);
        setText(fields.type, record.message_type);
        setText(fields.status, record.delivery_label);
        setText(fields.recipient, record.recipient);
        setText(fields.recipientType, record.recipient_type);
        setText(fields.mobile, record.mobile_number);
        setText(fields.reference, record.reference);
        setText(fields.source, record.source);
        setText(fields.attempts, String(record.attempts ?? 0));
        setText(fields.created, record.created_at);
        setText(fields.sent, record.sent_at);
        setText(fields.claimedBy, record.claimed_by);
        setText(fields.claimedAt, record.claimed_at);
        setText(fields.message, record.message);
        setText(fields.result, record.modem_result);

        const status = ['sent', 'failed', 'pending'].includes(record.delivery_status)
            ? record.delivery_status
            : 'pending';
        fields.status.className = `sms-status-badge sms-status-${status}`;

        const typeClass = record.message_type === 'Phone Verification'
            ? 'sms-type-otp'
            : record.message_type === 'Registration'
                ? 'sms-type-registration'
                : 'sms-type-alert';
        fields.type.className = `sms-type-badge ${typeClass}`;

        if (typeof modal.showModal === 'function') {
            modal.showModal();
        } else {
            modal.setAttribute('open', '');
        }
    }

    document.querySelectorAll('.sms-record-row').forEach(row => {
        row.addEventListener('click', event => {
            if (event.target.closest('button, a, input, select')) {
                return;
            }

            showRecord(row);
        });

        row.addEventListener('keydown', event => {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                showRecord(row);
            }
        });

        const viewButton = row.querySelector('.sms-view-button');
        viewButton?.addEventListener('click', event => {
            event.stopPropagation();
            showRecord(row);
        });
    });

    closeButton.addEventListener('click', () => modal.close());
    modal.addEventListener('click', event => {
        if (event.target === modal) {
            modal.close();
        }
    });
})();
</script>
</body>
</html>
