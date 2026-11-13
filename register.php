<?php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/',
        'domain' => '',
        'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
        'httponly' => true,
        'samesite' => 'Lax'
    ]);

    session_start();
}

require_once __DIR__ . '/config/database.php';

// Keep PHP and this MariaDB connection on the same project timezone.
date_default_timezone_set('Asia/Manila');

try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // The expiry comparison below is still performed entirely by MariaDB,
    // so it remains consistent with the timestamps MariaDB created.
}

function publicEscape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function publicTextLength(string $value): int
{
    return function_exists('mb_strlen')
        ? mb_strlen($value, 'UTF-8')
        : strlen($value);
}

function normalizePersonName(string $value): string
{
    $value = preg_replace('/\s+/u', ' ', trim($value)) ?? trim($value);

    if ($value === '') {
        return '';
    }

    if (function_exists('mb_convert_case')) {
        return mb_convert_case(
            mb_strtolower($value, 'UTF-8'),
            MB_CASE_TITLE,
            'UTF-8'
        );
    }

    return ucwords(strtolower($value), " \t\r\n\f\v-' ");
}


function normalizePhilippineMobile(string $mobile): string
{
    $mobile = preg_replace('/[\s\-()]/', '', $mobile) ?? $mobile;

    if (str_starts_with($mobile, '+63')) {
        $mobile = '0' . substr($mobile, 3);
    }

    if (str_starts_with($mobile, '63')) {
        $mobile = '0' . substr($mobile, 2);
    }

    return $mobile;
}

$systemName = 'FloodGuard';
$systemLocation = 'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal';
$logoUrl = 'assets/images/floodguard-logo.png';

try {
    $settingsStmt = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'system_name',
            'location',
            'logo_path'
         )"
    );

    $systemSettings = $settingsStmt->fetchAll(PDO::FETCH_KEY_PAIR);

    if (!empty($systemSettings['system_name'])) {
        $systemName = $systemSettings['system_name'];
    }

    if (!empty($systemSettings['location'])) {
        $systemLocation = $systemSettings['location'];
    }

    $databaseLogoPath = $systemSettings['logo_path'] ?? null;

    if (
        is_string($databaseLogoPath) &&
        preg_match('#^assets/[A-Za-z0-9._/-]+$#', $databaseLogoPath)
    ) {
        $logoUrl = ltrim($databaseLogoPath, '/');
    }
} catch (PDOException $exception) {
    // Keep the default system identity if settings cannot be loaded.
}

if (empty($_SESSION['public_registration_csrf'])) {
    $_SESSION['public_registration_csrf'] = bin2hex(random_bytes(32));
}

$csrfToken = $_SESSION['public_registration_csrf'];
$successData = null;

if (
    isset($_GET['submitted']) &&
    $_GET['submitted'] === '1' &&
    isset($_SESSION['registration_success'])
) {
    $successData = $_SESSION['registration_success'];
    unset($_SESSION['registration_success']);
}

$formData = [
    'applicant_type' => 'resident',
    'full_name' => '',
    'mobile_number' => '',
    'complete_address' => '',
    'purok_sitio' => '',
    'barangay' => 'San Isidro',
    'municipality' => 'Rodriguez',
    'province' => 'Rizal',
    'bridge_connection' => '',
    'bridge_connection_other' => '',
    'bridge_use_frequency' => ''
];

$errors = [];
$existingRegistration = null;
$isResubmission = false;
$smsConsentChecked = false;
$privacyConsentChecked = false;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    foreach ($formData as $field => $defaultValue) {
        if (isset($_POST[$field])) {
            $formData[$field] = trim((string) $_POST[$field]);
        }
    }

    $formData['full_name'] = normalizePersonName($formData['full_name']);
    $formData['mobile_number'] = normalizePhilippineMobile($formData['mobile_number']);

    $smsConsentChecked = isset($_POST['sms_consent']);
    $privacyConsentChecked = isset($_POST['privacy_consent']);

    $allowedApplicantTypes = ['resident', 'non_resident'];
    $allowedConnections = [
        'resident_near_bridge',
        'work',
        'school',
        'business',
        'delivery_transportation',
        'visiting_relatives',
        'regular_commute',
        'other'
    ];
    $allowedFrequencies = [
        'daily',
        'several_times_week',
        'weekly',
        'occasionally'
    ];

    $submittedToken = $_POST['csrf_token'] ?? '';

    if (
        !is_string($submittedToken) ||
        !hash_equals($_SESSION['public_registration_csrf'], $submittedToken)
    ) {
        $errors[] = 'The registration form expired. Please refresh the page and try again.';
    }

    if (!in_array($formData['applicant_type'], $allowedApplicantTypes, true)) {
        $errors[] = 'Please select a valid applicant type.';
    }

    $isResident = $formData['applicant_type'] === 'resident';
    $notificationScope = $isResident
        ? 'full_community_alerts'
        : 'bridge_alerts_only';

    if ($isResident) {
        $formData['barangay'] = 'San Isidro';
        $formData['municipality'] = 'Rodriguez';
        $formData['province'] = 'Rizal';
    }

    if ($formData['full_name'] === '') {
        $errors[] = 'Please enter your complete name.';
    } elseif (
        publicTextLength($formData['full_name']) < 2 ||
        publicTextLength($formData['full_name']) > 150
    ) {
        $errors[] = 'The complete name must contain 2 to 150 characters.';
    } elseif (
        !preg_match("/^[\p{L}\p{M}\s.'-]+$/u", $formData['full_name'])
    ) {
        $errors[] = 'The complete name may only contain letters, spaces, periods, apostrophes, and hyphens.';
    }

    if (!preg_match('/^09\d{9}$/', $formData['mobile_number'])) {
        $errors[] = 'Enter a valid Philippine mobile number using the format 09XXXXXXXXX.';
    }

    if (
        $formData['complete_address'] === '' ||
        publicTextLength($formData['complete_address']) > 255
    ) {
        $errors[] = 'Please enter a valid complete address.';
    }

    if (publicTextLength($formData['purok_sitio']) > 100) {
        $errors[] = 'The purok or sitio must not exceed 100 characters.';
    }

    if (
        $formData['barangay'] === '' ||
        publicTextLength($formData['barangay']) > 100
    ) {
        $errors[] = 'Please enter a valid barangay.';
    }

    if (
        $formData['municipality'] === '' ||
        publicTextLength($formData['municipality']) > 100
    ) {
        $errors[] = 'Please enter a valid municipality.';
    }

    if (
        $formData['province'] === '' ||
        publicTextLength($formData['province']) > 100
    ) {
        $errors[] = 'Please enter a valid province.';
    }

    if (!$isResident) {
        if (!in_array($formData['bridge_connection'], $allowedConnections, true)) {
            $errors[] = 'Please select your connection to the spillway bridge.';
        }

        if (
            $formData['bridge_connection'] === 'other' &&
            $formData['bridge_connection_other'] === ''
        ) {
            $errors[] = 'Please describe your connection to the bridge.';
        }

        if (publicTextLength($formData['bridge_connection_other']) > 150) {
            $errors[] = 'The bridge connection description must not exceed 150 characters.';
        }

        if (!in_array($formData['bridge_use_frequency'], $allowedFrequencies, true)) {
            $errors[] = 'Please select how often you use the bridge.';
        }
    } else {
        $formData['bridge_connection'] = '';
        $formData['bridge_connection_other'] = '';
        $formData['bridge_use_frequency'] = '';
    }

    if (!$smsConsentChecked) {
        $errors[] = 'You must agree to receive emergency SMS notifications.';
    }

    if (!$privacyConsentChecked) {
        $errors[] = 'You must agree to the collection and processing of your registration information.';
    }

    if (!$errors) {
        $duplicateStmt = $pdo->prepare(
            'SELECT
                id,
                reference_no,
                applicant_type,
                full_name,
                mobile_number,
                proof_stored_name,
                registration_status
             FROM residents
             WHERE mobile_number = :mobile_number
             LIMIT 1'
        );

        $duplicateStmt->execute([
            ':mobile_number' => $formData['mobile_number']
        ]);

        $existingRegistration = $duplicateStmt->fetch(PDO::FETCH_ASSOC) ?: null;

        if ($existingRegistration) {
            $existingStatus = (string) $existingRegistration['registration_status'];

            if ($existingStatus === 'rejected') {
                if (
                    $existingRegistration['applicant_type'] !==
                    $formData['applicant_type']
                ) {
                    $previousType = $existingRegistration['applicant_type'] === 'resident'
                        ? 'Resident'
                        : 'Non-Resident';

                    $errors[] =
                        'This mobile number was previously registered as ' .
                        $previousType .
                        ' under reference number ' .
                        $existingRegistration['reference_no'] .
                        '. Select the same applicant type to submit corrected information.';
                } else {
                    $isResubmission = true;
                }
            } elseif ($existingStatus === 'pending') {
                $errors[] =
                    'This mobile number already has a pending registration under reference number ' .
                    $existingRegistration['reference_no'] .
                    '.';
            } elseif ($existingStatus === 'approved') {
                $errors[] =
                    'This mobile number is already approved under reference number ' .
                    $existingRegistration['reference_no'] .
                    '.';
            } else {
                $errors[] =
                    'This mobile number already belongs to registration ' .
                    $existingRegistration['reference_no'] .
                    '. Please contact the FloodGuard administrator for assistance.';
            }
        }
    }

    $proofOriginalName = null;
    $proofStoredName = null;
    $proofMimeType = null;
    $proofFileSize = null;
    $storedProofPath = null;
    $proofUpload = $_FILES['verification_proof'] ?? null;

    if ($isResident) {
        $uploadError = is_array($proofUpload)
            ? (int) ($proofUpload['error'] ?? UPLOAD_ERR_NO_FILE)
            : UPLOAD_ERR_NO_FILE;

        if ($uploadError === UPLOAD_ERR_NO_FILE) {
            $errors[] = 'Residents must upload a proof of residency or a valid ID showing an address in Barangay San Isidro.';
        } elseif ($uploadError !== UPLOAD_ERR_OK) {
            $errors[] = 'The proof of residency could not be uploaded.';
        } else {
            $maximumFileSize = 5 * 1024 * 1024;
            $proofFileSize = (int) $proofUpload['size'];

            if ($proofFileSize <= 0 || $proofFileSize > $maximumFileSize) {
                $errors[] = 'The proof of residency must not exceed 5 MB.';
            }

            $temporaryFile = (string) $proofUpload['tmp_name'];
            $allowedMimeTypes = [
                'image/jpeg' => 'jpg',
                'image/png' => 'png',
                'application/pdf' => 'pdf'
            ];

            if (!function_exists('finfo_open')) {
                $errors[] = 'Server file validation is unavailable. Enable the PHP fileinfo extension.';
            } else {
                $fileInfo = finfo_open(FILEINFO_MIME_TYPE);
                $detectedMimeType = $fileInfo
                    ? finfo_file($fileInfo, $temporaryFile)
                    : false;

                if ($fileInfo) {
                    finfo_close($fileInfo);
                }

                if (
                    !is_string($detectedMimeType) ||
                    !isset($allowedMimeTypes[$detectedMimeType])
                ) {
                    $errors[] = 'Only JPG, PNG, and PDF proof documents are accepted.';
                } else {
                    $proofMimeType = $detectedMimeType;
                    $extension = $allowedMimeTypes[$detectedMimeType];
                    $proofOriginalName = basename((string) $proofUpload['name']);
                    $proofStoredName =
                        date('YmdHis') .
                        '-' .
                        bin2hex(random_bytes(8)) .
                        '.' .
                        $extension;
                }
            }
        }
    }

    if (!$errors) {
        try {
            if ($isResident && $proofStoredName !== null) {
                $uploadDirectory = __DIR__ . '/assets/uploads/pending_proofs';

                if (
                    !is_dir($uploadDirectory) &&
                    !mkdir($uploadDirectory, 0775, true) &&
                    !is_dir($uploadDirectory)
                ) {
                    throw new RuntimeException(
                        'Unable to prepare the temporary proof folder.'
                    );
                }

                $storedProofPath =
                    $uploadDirectory . DIRECTORY_SEPARATOR . $proofStoredName;

                if (!move_uploaded_file(
                    (string) $proofUpload['tmp_name'],
                    $storedProofPath
                )) {
                    throw new RuntimeException(
                        'The proof of residency could not be saved temporarily.'
                    );
                }
            }

            $verificationToken = bin2hex(random_bytes(32));
            $otp = (string) random_int(100000, 999999);
            $expiredProofName = null;

            $pdo->beginTransaction();

            $pendingStmt = $pdo->prepare(
                'SELECT
                    id,
                    proof_stored_name,
                    expires_at,
                    CASE WHEN expires_at > NOW() THEN 1 ELSE 0 END AS is_active
                 FROM pending_phone_verifications
                 WHERE mobile_number = :mobile_number
                 FOR UPDATE'
            );
            $pendingStmt->execute([
                ':mobile_number' => $formData['mobile_number']
            ]);
            $previousPending = $pendingStmt->fetch(PDO::FETCH_ASSOC) ?: null;

            if ($previousPending) {
                if ((int) $previousPending['is_active'] === 1) {
                    throw new RuntimeException(
                        'A verification code was already requested for this mobile number. Use the previous verification page or wait 15 minutes before registering again.'
                    );
                }

                $expiredProofName = $previousPending['proof_stored_name'];
                $deleteExpiredStmt = $pdo->prepare(
                    'DELETE FROM pending_phone_verifications WHERE id = :id'
                );
                $deleteExpiredStmt->execute([
                    ':id' => (int) $previousPending['id']
                ]);
            }

            $insertPendingStmt = $pdo->prepare(
                'INSERT INTO pending_phone_verifications (
                    verification_token,
                    existing_resident_id,
                    applicant_type,
                    full_name,
                    mobile_number,
                    complete_address,
                    purok_sitio,
                    barangay,
                    municipality,
                    province,
                    bridge_connection,
                    bridge_connection_other,
                    bridge_use_frequency,
                    proof_original_name,
                    proof_stored_name,
                    proof_mime_type,
                    proof_file_size,
                    notification_scope,
                    sms_consent,
                    privacy_consent,
                    otp_hash,
                    otp_expires_at,
                    last_sent_at,
                    expires_at
                 ) VALUES (
                    :verification_token,
                    :existing_resident_id,
                    :applicant_type,
                    :full_name,
                    :mobile_number,
                    :complete_address,
                    :purok_sitio,
                    :barangay,
                    :municipality,
                    :province,
                    :bridge_connection,
                    :bridge_connection_other,
                    :bridge_use_frequency,
                    :proof_original_name,
                    :proof_stored_name,
                    :proof_mime_type,
                    :proof_file_size,
                    :notification_scope,
                    1,
                    1,
                    :otp_hash,
                    DATE_ADD(NOW(), INTERVAL 5 MINUTE),
                    NOW(),
                    DATE_ADD(NOW(), INTERVAL 15 MINUTE)
                 )'
            );

            $insertPendingStmt->execute([
                ':verification_token' => $verificationToken,
                ':existing_resident_id' => $isResubmission && $existingRegistration
                    ? (int) $existingRegistration['id']
                    : null,
                ':applicant_type' => $formData['applicant_type'],
                ':full_name' => $formData['full_name'],
                ':mobile_number' => $formData['mobile_number'],
                ':complete_address' => $formData['complete_address'],
                ':purok_sitio' => $formData['purok_sitio'] !== ''
                    ? $formData['purok_sitio']
                    : null,
                ':barangay' => $formData['barangay'],
                ':municipality' => $formData['municipality'],
                ':province' => $formData['province'],
                ':bridge_connection' => $formData['bridge_connection'] !== ''
                    ? $formData['bridge_connection']
                    : null,
                ':bridge_connection_other' => $formData['bridge_connection_other'] !== ''
                    ? $formData['bridge_connection_other']
                    : null,
                ':bridge_use_frequency' => $formData['bridge_use_frequency'] !== ''
                    ? $formData['bridge_use_frequency']
                    : null,
                ':proof_original_name' => $proofOriginalName,
                ':proof_stored_name' => $proofStoredName,
                ':proof_mime_type' => $proofMimeType,
                ':proof_file_size' => $proofFileSize,
                ':notification_scope' => $notificationScope,
                ':otp_hash' => password_hash($otp, PASSWORD_DEFAULT)
            ]);

            $verificationId = (int) $pdo->lastInsertId();
            $otpMessage = sprintf(
                'FloodGuard verification code: %s. This code expires in 5 minutes. Do not share this code.',
                $otp
            );

            $queueStmt = $pdo->prepare(
                'INSERT INTO sms_logs (
                    alert_id,
                    resident_id,
                    verification_id,
                    mobile_number,
                    recipient_type,
                    message_type,
                    message,
                    delivery_status
                 ) VALUES (
                    NULL,
                    NULL,
                    :verification_id,
                    :mobile_number,
                    :recipient_type,
                    "otp",
                    :message,
                    "pending"
                 )'
            );
            $queueStmt->execute([
                ':verification_id' => $verificationId,
                ':mobile_number' => $formData['mobile_number'],
                ':recipient_type' => $formData['applicant_type'],
                ':message' => $otpMessage
            ]);

            $pdo->commit();

            if (is_string($expiredProofName) && $expiredProofName !== '') {
                $expiredProofPath =
                    __DIR__ . '/assets/uploads/pending_proofs/' .
                    basename($expiredProofName);
                if (is_file($expiredProofPath)) {
                    @unlink($expiredProofPath);
                }
            }

            unset($_SESSION['public_registration_csrf']);
            header(
                'Location: verify_phone.php?token=' .
                rawurlencode($verificationToken)
            );
            exit;
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }

            if ($storedProofPath !== null && is_file($storedProofPath)) {
                @unlink($storedProofPath);
            }

            if ($exception instanceof PDOException) {
                error_log('[FloodGuard registration OTP] ' . $exception->getMessage());
                $errors[] = 'A verification request already exists for this mobile number.';
            } elseif ($exception instanceof RuntimeException) {
                $errors[] = $exception->getMessage();
            } else {
                error_log('[FloodGuard registration OTP] ' . $exception->getMessage());
                $errors[] = 'The verification request could not be created. Please try again.';
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>
        SMS Registration | <?= publicEscape($systemName) ?>
    </title>

    <link rel="stylesheet" href="assets/css/public-register.css">

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    >
</head>
<body>

<header class="public-header">
    <a href="index.php" class="public-brand">
        <div class="public-logo">
            <img
                src="<?= publicEscape($logoUrl) ?>"
                alt="<?= publicEscape($systemName) ?> Logo"
                onerror="this.onerror=null;this.src='assets/images/floodguard-logo.png';"
            >
        </div>

        <div>
            <strong><?= publicEscape($systemName) ?></strong>
            <span>Flood Monitoring and Warning System</span>
        </div>
    </a>

    <div class="public-header-status">
        <span class="status-indicator"></span>

        <div>
            <span>Public Service</span>
            <strong>SMS Registration</strong>
        </div>
    </div>
</header>

<main class="public-main">

    <?php if ($successData): ?>

        <section class="registration-success">
            <div class="success-icon">
                <i class="bi bi-check-lg"></i>
            </div>

            <span class="success-eyebrow">
                <?= !empty($successData['is_resubmission'])
                    ? 'Registration Resubmitted'
                    : 'Registration Submitted'
                ?>
            </span>

            <h1>
                Thank you,
                <?= publicEscape($successData['full_name'] ?? '') ?>
            </h1>

            <p>
                <?php if (!empty($successData['is_resubmission'])): ?>
                    Your corrected registration was submitted successfully. Your existing reference number was retained and the application is pending another administrator review.
                <?php else: ?>
                    Your SMS-alert registration was submitted successfully and is now waiting for administrator review.
                <?php endif; ?>
            </p>

            <div class="reference-card">
                <span>Your reference number</span>
                <strong><?= publicEscape($successData['reference_no'] ?? '') ?></strong>
                <small>Save this number for future reference.</small>
            </div>

            <div class="success-information">
                <i class="bi bi-info-circle-fill"></i>
                <p>
                    Emergency SMS notifications will only be sent after your registration has been reviewed and approved.
                </p>
            </div>

            <a href="register.php" class="register-another-button">
                Register Another Mobile Number
            </a>
        </section>

    <?php else: ?>

        <section class="registration-introduction">
            <div class="introduction-content">
                <span class="public-eyebrow">Community Early Warning Service</span>

                <h1>Register for FloodGuard SMS alerts</h1>

                <p>
                    Receive important flood warnings, bridge closure updates, and emergency notices from the FloodGuard monitoring system.
                </p>

                <div class="public-location">
                    <i class="bi bi-geo-alt-fill"></i>

                    <div>
                        <strong>Monitoring Location</strong>
                        <span><?= publicEscape($systemLocation) ?></span>
                    </div>
                </div>
            </div>

            <div class="information-grid">
                <article>
                    <i class="bi bi-phone-fill"></i>
                    <div>
                        <strong>SMS Notifications</strong>
                        <span>Receive warnings directly on your mobile phone.</span>
                    </div>
                </article>

                <article>
                    <i class="bi bi-shield-check"></i>
                    <div>
                        <strong>Administrator Review</strong>
                        <span>Registrations are checked before activation.</span>
                    </div>
                </article>

                <article>
                    <i class="bi bi-exclamation-triangle-fill"></i>
                    <div>
                        <strong>Emergency Information</strong>
                        <span>Stay informed about bridge and flood conditions.</span>
                    </div>
                </article>
            </div>
        </section>

        <section class="registration-form-card">
            <div class="form-card-header">
                <span>SMS Alert Registration</span>
                <h2>Registrant Information</h2>
                <p>Complete the form using accurate and current information.</p>
            </div>

            <?php if ($errors): ?>
                <div class="registration-alert" role="alert">
                    <i class="bi bi-exclamation-circle-fill"></i>

                    <div>
                        <strong>Please review the following:</strong>

                        <ul>
                            <?php foreach ($errors as $error): ?>
                                <li><?= publicEscape($error) ?></li>
                            <?php endforeach; ?>
                        </ul>
                    </div>
                </div>
            <?php endif; ?>

            <form
                method="POST"
                enctype="multipart/form-data"
                id="registrationForm"
            >
                <input
                    type="hidden"
                    name="csrf_token"
                    value="<?= publicEscape($csrfToken) ?>"
                >

                <div class="form-section">
                    <div class="form-section-heading">
                        <span>1</span>

                        <div>
                            <h3>Applicant Type</h3>
                            <p>Select the option that correctly describes your registration.</p>
                        </div>
                    </div>

                    <div class="applicant-type-options">
                        <label class="selection-card">
                            <input
                                type="radio"
                                name="applicant_type"
                                value="resident"
                                <?= $formData['applicant_type'] === 'resident' ? 'checked' : '' ?>
                            >

                            <span class="selection-card-content">
                                <i class="bi bi-house-door-fill"></i>

                                <span>
                                    <strong>Resident</strong>
                                    <small>Lives in Barangay San Isidro and can provide proof of address.</small>
                                </span>
                            </span>
                        </label>

                        <label class="selection-card">
                            <input
                                type="radio"
                                name="applicant_type"
                                value="non_resident"
                                <?= $formData['applicant_type'] === 'non_resident' ? 'checked' : '' ?>
                            >

                            <span class="selection-card-content">
                                <i class="bi bi-person-badge-fill"></i>

                                <span>
                                    <strong>Non-Resident</strong>
                                    <small>Regularly uses or has a valid connection to the spillway bridge.</small>
                                </span>
                            </span>
                        </label>
                    </div>
                </div>

                <div class="form-section">
                    <div class="form-section-heading">
                        <span>2</span>

                        <div>
                            <h3>Personal Information</h3>
                            <p>Provide the information of the mobile-phone owner.</p>
                        </div>
                    </div>

                    <div class="form-grid">
                        <div class="form-group full-width">
                            <label for="full_name">
                                Complete Name <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-person-fill"></i>

                                <input
                                    type="text"
                                    id="full_name"
                                    name="full_name"
                                    minlength="2"
                                    maxlength="150"
                                    value="<?= publicEscape($formData['full_name']) ?>"
                                    placeholder="Example: Juan Dela Cruz"
                                    autocomplete="name"
                                    required
                                >
                            </div>

                            <small class="field-note">
                                The system automatically formats the name using proper capitalization.
                            </small>
                        </div>

                        <div class="form-group">
                            <label for="mobile_number">
                                Mobile Number <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-phone-fill"></i>

                                <input
                                    type="tel"
                                    id="mobile_number"
                                    name="mobile_number"
                                    maxlength="13"
                                    value="<?= publicEscape($formData['mobile_number']) ?>"
                                    placeholder="09XXXXXXXXX"
                                    inputmode="numeric"
                                    autocomplete="tel"
                                    required
                                >
                            </div>

                            <small class="field-note">Use an active Philippine mobile number.</small>
                        </div>

                        <div class="form-group">
                            <label for="purok_sitio">Purok or Sitio</label>

                            <div class="input-wrapper">
                                <i class="bi bi-signpost-fill"></i>

                                <input
                                    type="text"
                                    id="purok_sitio"
                                    name="purok_sitio"
                                    maxlength="100"
                                    value="<?= publicEscape($formData['purok_sitio']) ?>"
                                    placeholder="Optional"
                                >
                            </div>
                        </div>

                        <div class="form-group full-width">
                            <label for="complete_address">
                                Complete Address <span>*</span>
                            </label>

                            <div class="input-wrapper textarea-wrapper">
                                <i class="bi bi-geo-alt-fill"></i>

                                <textarea
                                    id="complete_address"
                                    name="complete_address"
                                    maxlength="255"
                                    placeholder="House number, street, subdivision, or landmark"
                                    required
                                ><?= publicEscape($formData['complete_address']) ?></textarea>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="barangay">
                                Barangay <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-building-fill"></i>

                                <input
                                    type="text"
                                    id="barangay"
                                    name="barangay"
                                    maxlength="100"
                                    value="<?= publicEscape($formData['barangay']) ?>"
                                    required
                                >
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="municipality">
                                Municipality <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-map-fill"></i>

                                <input
                                    type="text"
                                    id="municipality"
                                    name="municipality"
                                    maxlength="100"
                                    value="<?= publicEscape($formData['municipality']) ?>"
                                    required
                                >
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="province">
                                Province <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-pin-map-fill"></i>

                                <input
                                    type="text"
                                    id="province"
                                    name="province"
                                    maxlength="100"
                                    value="<?= publicEscape($formData['province']) ?>"
                                    required
                                >
                            </div>
                        </div>

                        <div
                            class="form-group full-width resident-proof-group"
                            id="residentProofGroup"
                        >
                            <label for="verification_proof">
                                Proof of Residency or Valid ID <span>*</span>
                            </label>

                            <label class="file-upload" for="verification_proof">
                                <i class="bi bi-cloud-arrow-up-fill"></i>

                                <span>
                                    <strong id="fileUploadText">Choose JPG, PNG, or PDF</strong>
                                    <small>
                                        The document must clearly show an address in Barangay San Isidro. Maximum 5 MB.
                                    </small>
                                </span>
                            </label>

                            <input
                                type="file"
                                id="verification_proof"
                                name="verification_proof"
                                class="hidden-file-input"
                                accept=".jpg,.jpeg,.png,.pdf"
                            >
                        </div>
                    </div>
                </div>

                <div class="form-section" id="nonResidentSection">
                    <div class="form-section-heading">
                        <span>3</span>

                        <div>
                            <h3>Bridge Connection</h3>
                            <p>This information is required only for non-resident applicants.</p>
                        </div>
                    </div>

                    <div class="form-grid">
                        <div class="form-group">
                            <label for="bridge_connection">
                                Connection to the Bridge <span>*</span>
                            </label>

                            <div class="select-wrapper">
                                <i class="bi bi-diagram-3-fill"></i>

                                <select id="bridge_connection" name="bridge_connection">
                                    <option value="">Select connection</option>

                                    <?php
                                    $connectionOptions = [
                                        'resident_near_bridge' => 'Resident Near Bridge',
                                        'work' => 'Work',
                                        'school' => 'School',
                                        'business' => 'Business',
                                        'delivery_transportation' => 'Delivery or Transportation',
                                        'visiting_relatives' => 'Visiting Relatives',
                                        'regular_commute' => 'Regular Commute',
                                        'other' => 'Other'
                                    ];
                                    ?>

                                    <?php foreach ($connectionOptions as $value => $label): ?>
                                        <option
                                            value="<?= publicEscape($value) ?>"
                                            <?= $formData['bridge_connection'] === $value ? 'selected' : '' ?>
                                        >
                                            <?= publicEscape($label) ?>
                                        </option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="bridge_use_frequency">
                                Bridge Use Frequency <span>*</span>
                            </label>

                            <div class="select-wrapper">
                                <i class="bi bi-calendar-check-fill"></i>

                                <select id="bridge_use_frequency" name="bridge_use_frequency">
                                    <option value="">Select frequency</option>
                                    <option value="daily" <?= $formData['bridge_use_frequency'] === 'daily' ? 'selected' : '' ?>>Daily</option>
                                    <option value="several_times_week" <?= $formData['bridge_use_frequency'] === 'several_times_week' ? 'selected' : '' ?>>Several Times a Week</option>
                                    <option value="weekly" <?= $formData['bridge_use_frequency'] === 'weekly' ? 'selected' : '' ?>>Weekly</option>
                                    <option value="occasionally" <?= $formData['bridge_use_frequency'] === 'occasionally' ? 'selected' : '' ?>>Occasionally</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group full-width" id="otherConnectionGroup">
                            <label for="bridge_connection_other">
                                Describe Your Connection <span>*</span>
                            </label>

                            <div class="input-wrapper">
                                <i class="bi bi-pencil-fill"></i>

                                <input
                                    type="text"
                                    id="bridge_connection_other"
                                    name="bridge_connection_other"
                                    maxlength="150"
                                    value="<?= publicEscape($formData['bridge_connection_other']) ?>"
                                    placeholder="Please specify"
                                >
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-section">
                    <div class="form-section-heading">
                        <span>4</span>

                        <div>
                            <h3>Automatic Notification Coverage</h3>
                            <p>The system assigns the correct alert coverage based on the applicant type.</p>
                        </div>
                    </div>

                    <div class="automatic-notification-card" id="automaticNotificationCard">
                        <div class="automatic-notification-icon">
                            <i class="bi bi-broadcast" id="notificationIcon"></i>
                        </div>

                        <div class="automatic-notification-content">
                            <div class="automatic-notification-heading">
                                <strong id="notificationTitle">Full Community Alerts</strong>
                                <span>Automatically assigned</span>
                            </div>

                            <p id="notificationDescription">
                                Residents receive flood warnings, weather alerts, bridge closure and reopening notices, unsafe crossing alerts, and community emergency announcements.
                            </p>
                        </div>
                    </div>
                </div>

                <div class="form-section consent-section">
                    <label class="consent-option">
                        <input
                            type="checkbox"
                            name="sms_consent"
                            value="1"
                            <?= $smsConsentChecked ? 'checked' : '' ?>
                            required
                        >

                        <span>
                            I agree to receive FloodGuard emergency and safety notifications through SMS.
                        </span>
                    </label>

                    <label class="consent-option">
                        <input
                            type="checkbox"
                            name="privacy_consent"
                            value="1"
                            <?= $privacyConsentChecked ? 'checked' : '' ?>
                            required
                        >

                        <span>
                            I consent to the collection and processing of my information for registration review and emergency notification purposes.
                        </span>
                    </label>
                </div>

                <button
                    type="submit"
                    id="submitRegistration"
                    class="registration-submit"
                >
                    <span>Send Verification Code</span>
                    <i class="bi bi-send-fill"></i>
                </button>

                <p class="submission-note">
                    Your registration is saved only after your mobile number is verified. It will then remain pending until reviewed by an authorized FloodGuard administrator.
                </p>
            </form>
        </section>

    <?php endif; ?>

</main>

<footer class="public-footer">
    <p>
        © <?= date('Y') ?> <?= publicEscape($systemName) ?>.
        Barangay San Isidro Flood Monitoring and Warning System.
    </p>
</footer>

<script src="assets/js/public-register.js"></script>

</body>
</html>
