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

date_default_timezone_set('Asia/Manila');

try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // Continue with the database server's configured timezone.
}

function verifyEscape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function verifyPublicError(Throwable $exception): string
{
    if ($exception instanceof RuntimeException) {
        return $exception->getMessage();
    }

    error_log('[FloodGuard phone verification] ' . $exception->getMessage());
    return 'The verification request could not be completed. Please try again.';
}

function verifyGenerateReference(PDO $pdo, string $applicantType): string
{
    if (!$pdo->inTransaction()) {
        throw new RuntimeException('A transaction is required.');
    }

    $ensureStmt = $pdo->prepare(
        'INSERT INTO registration_counters (applicant_type, last_number)
         VALUES (:applicant_type, 0)
         ON DUPLICATE KEY UPDATE applicant_type = VALUES(applicant_type)'
    );
    $ensureStmt->execute([':applicant_type' => $applicantType]);

    $counterStmt = $pdo->prepare(
        'SELECT last_number
         FROM registration_counters
         WHERE applicant_type = :applicant_type
         FOR UPDATE'
    );
    $counterStmt->execute([':applicant_type' => $applicantType]);
    $nextNumber = (int) $counterStmt->fetchColumn() + 1;

    $updateStmt = $pdo->prepare(
        'UPDATE registration_counters
         SET last_number = :last_number
         WHERE applicant_type = :applicant_type'
    );
    $updateStmt->execute([
        ':last_number' => $nextNumber,
        ':applicant_type' => $applicantType
    ]);

    return ($applicantType === 'resident' ? 'R' : 'NR') .
        str_pad((string) $nextNumber, 4, '0', STR_PAD_LEFT);
}

function verifyQueueOtp(PDO $pdo, array $pending, string $otp): void
{
    $message = sprintf(
        'FloodGuard verification code: %s. This code expires in 5 minutes. Do not share this code.',
        $otp
    );

    $smsStmt = $pdo->prepare(
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

    $smsStmt->execute([
        ':verification_id' => (int) $pending['id'],
        ':mobile_number' => (string) $pending['mobile_number'],
        ':recipient_type' => (string) $pending['applicant_type'],
        ':message' => $message
    ]);
}

function verifyCommonParameters(array $pending, ?string $finalProofName): array
{
    return [
        ':applicant_type' => $pending['applicant_type'],
        ':full_name' => $pending['full_name'],
        ':mobile_number' => $pending['mobile_number'],
        ':complete_address' => $pending['complete_address'],
        ':purok_sitio' => $pending['purok_sitio'],
        ':barangay' => $pending['barangay'],
        ':municipality' => $pending['municipality'],
        ':province' => $pending['province'],
        ':bridge_connection' => $pending['bridge_connection'],
        ':bridge_connection_other' => $pending['bridge_connection_other'],
        ':bridge_use_frequency' => $pending['bridge_use_frequency'],
        ':proof_original_name' => $pending['proof_original_name'],
        ':proof_stored_name' => $finalProofName,
        ':proof_mime_type' => $pending['proof_mime_type'],
        ':proof_file_size' => $pending['proof_file_size'],
        ':notification_scope' => $pending['notification_scope'],
        ':sms_consent' => (int) $pending['sms_consent'],
        ':privacy_consent' => (int) $pending['privacy_consent']
    ];
}

if (empty($_SESSION['phone_verification_csrf'])) {
    $_SESSION['phone_verification_csrf'] = bin2hex(random_bytes(32));
}

$csrfToken = (string) $_SESSION['phone_verification_csrf'];
$token = trim((string) ($_GET['token'] ?? $_POST['verification_token'] ?? ''));
$errors = [];
$notice = '';
$pending = null;

if (!preg_match('/^[a-f0-9]{64}$/', $token)) {
    $errors[] = 'The verification link is invalid. Please submit the registration form again.';
} else {
    $pendingStmt = $pdo->prepare(
        'SELECT *
         FROM pending_phone_verifications
         WHERE verification_token = :verification_token
         LIMIT 1'
    );
    $pendingStmt->execute([':verification_token' => $token]);
    $pending = $pendingStmt->fetch(PDO::FETCH_ASSOC) ?: null;

    if (!$pending) {
        $errors[] = 'This verification request does not exist or has already been completed.';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $pending) {
    $submittedCsrf = (string) ($_POST['csrf_token'] ?? '');

    if (!hash_equals($csrfToken, $submittedCsrf)) {
        $errors[] = 'The verification form expired. Refresh the page and try again.';
    } else {
        $action = (string) ($_POST['action'] ?? 'verify');

        if ($action === 'resend') {
            try {
                $pdo->beginTransaction();

                $lockStmt = $pdo->prepare(
                    'SELECT *
                     FROM pending_phone_verifications
                     WHERE verification_token = :verification_token
                     FOR UPDATE'
                );
                $lockStmt->execute([':verification_token' => $token]);
                $locked = $lockStmt->fetch(PDO::FETCH_ASSOC);

                if (!$locked) {
                    throw new RuntimeException('The verification request no longer exists.');
                }

                if (strtotime((string) $locked['expires_at']) < time()) {
                    throw new RuntimeException('The registration request expired. Please register again.');
                }

                if ((int) $locked['resend_count'] >= 3) {
                    throw new RuntimeException('The maximum number of OTP resends has been reached.');
                }

                $secondsSinceLastSend = time() - strtotime((string) $locked['last_sent_at']);
                if ($secondsSinceLastSend < 60) {
                    throw new RuntimeException(
                        'Please wait ' . (60 - $secondsSinceLastSend) .
                        ' seconds before requesting another code.'
                    );
                }

                $newOtp = (string) random_int(100000, 999999);

                $updateOtpStmt = $pdo->prepare(
                    'UPDATE pending_phone_verifications
                     SET
                        otp_hash = :otp_hash,
                        otp_expires_at = DATE_ADD(NOW(), INTERVAL 5 MINUTE),
                        otp_attempt_count = 0,
                        resend_count = resend_count + 1,
                        last_sent_at = NOW(),
                        expires_at = DATE_ADD(NOW(), INTERVAL 15 MINUTE)
                     WHERE id = :id'
                );
                $updateOtpStmt->execute([
                    ':otp_hash' => password_hash($newOtp, PASSWORD_DEFAULT),
                    ':id' => (int) $locked['id']
                ]);

                $cancelOldOtpStmt = $pdo->prepare(
                    'UPDATE sms_logs
                     SET
                        delivery_status = "failed",
                        modem_response = "Replaced by a newer OTP."
                     WHERE verification_id = :verification_id
                       AND message_type = "otp"
                       AND delivery_status = "pending"'
                );
                $cancelOldOtpStmt->execute([
                    ':verification_id' => (int) $locked['id']
                ]);

                verifyQueueOtp($pdo, $locked, $newOtp);
                $pdo->commit();

                $notice = 'A new verification code was queued for SMS delivery.';
                $pending['otp_attempt_count'] = 0;
                $pending['resend_count'] = (int) $locked['resend_count'] + 1;
            } catch (Throwable $exception) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                $errors[] = verifyPublicError($exception);
            }
        } elseif ($action === 'verify') {
            $otp = preg_replace('/\D/', '', (string) ($_POST['otp'] ?? '')) ?? '';

            if (!preg_match('/^\d{6}$/', $otp)) {
                $errors[] = 'Enter the six-digit verification code.';
            } else {
                $movedFrom = null;
                $movedTo = null;
                $oldProofPathToDelete = null;

                try {
                    $pdo->beginTransaction();

                    $lockStmt = $pdo->prepare(
                        'SELECT *
                         FROM pending_phone_verifications
                         WHERE verification_token = :verification_token
                         FOR UPDATE'
                    );
                    $lockStmt->execute([':verification_token' => $token]);
                    $locked = $lockStmt->fetch(PDO::FETCH_ASSOC);

                    if (!$locked) {
                        throw new RuntimeException('The verification request no longer exists.');
                    }

                    if (strtotime((string) $locked['expires_at']) < time()) {
                        throw new RuntimeException('The registration request expired. Please register again.');
                    }

                    if (strtotime((string) $locked['otp_expires_at']) < time()) {
                        throw new RuntimeException('The verification code expired. Request a new code.');
                    }

                    if ((int) $locked['otp_attempt_count'] >= 5) {
                        throw new RuntimeException('Too many incorrect attempts. Request a new code.');
                    }

                    if (!password_verify($otp, (string) $locked['otp_hash'])) {
                        $attemptStmt = $pdo->prepare(
                            'UPDATE pending_phone_verifications
                             SET otp_attempt_count = otp_attempt_count + 1
                             WHERE id = :id'
                        );
                        $attemptStmt->execute([':id' => (int) $locked['id']]);
                        $pdo->commit();
                        $errors[] = 'The verification code is incorrect.';
                    } else {
                        $finalProofName = $locked['proof_stored_name'];

                        if (
                            $locked['applicant_type'] === 'resident' &&
                            is_string($finalProofName) &&
                            $finalProofName !== ''
                        ) {
                            $pendingDirectory = __DIR__ . '/assets/uploads/pending_proofs';
                            $finalDirectory = __DIR__ . '/assets/uploads/residency_proofs';

                            if (!is_dir($finalDirectory) && !mkdir($finalDirectory, 0775, true) && !is_dir($finalDirectory)) {
                                throw new RuntimeException('The proof storage folder could not be prepared.');
                            }

                            $movedFrom = $pendingDirectory . '/' . basename($finalProofName);
                            $movedTo = $finalDirectory . '/' . basename($finalProofName);

                            if (!is_file($movedFrom) || !rename($movedFrom, $movedTo)) {
                                throw new RuntimeException('The proof of residency could not be finalized.');
                            }
                        }

                        $common = verifyCommonParameters($locked, $finalProofName);
                        $isResubmission = $locked['existing_resident_id'] !== null;

                        if ($isResubmission) {
                            $residentStmt = $pdo->prepare(
                                'SELECT id, reference_no, registration_status, proof_stored_name
                                 FROM residents
                                 WHERE id = :id
                                 FOR UPDATE'
                            );
                            $residentStmt->execute([':id' => (int) $locked['existing_resident_id']]);
                            $existing = $residentStmt->fetch(PDO::FETCH_ASSOC);

                            if (!$existing || $existing['registration_status'] !== 'rejected') {
                                throw new RuntimeException('The rejected registration can no longer be resubmitted.');
                            }

                            $referenceNumber = (string) $existing['reference_no'];

                            if (
                                is_string($existing['proof_stored_name']) &&
                                $existing['proof_stored_name'] !== '' &&
                                $existing['proof_stored_name'] !== $finalProofName
                            ) {
                                $oldProofPathToDelete =
                                    __DIR__ . '/assets/uploads/residency_proofs/' .
                                    basename($existing['proof_stored_name']);
                            }

                            $updateResidentStmt = $pdo->prepare(
                                'UPDATE residents SET
                                    applicant_type = :applicant_type,
                                    full_name = :full_name,
                                    mobile_number = :mobile_number,
                                    complete_address = :complete_address,
                                    purok_sitio = :purok_sitio,
                                    barangay = :barangay,
                                    municipality = :municipality,
                                    province = :province,
                                    bridge_connection = :bridge_connection,
                                    bridge_connection_other = :bridge_connection_other,
                                    bridge_use_frequency = :bridge_use_frequency,
                                    proof_original_name = :proof_original_name,
                                    proof_stored_name = :proof_stored_name,
                                    proof_mime_type = :proof_mime_type,
                                    proof_file_size = :proof_file_size,
                                    notification_scope = :notification_scope,
                                    sms_consent = :sms_consent,
                                    privacy_consent = :privacy_consent,
                                    mobile_verified = 1,
                                    registration_status = "pending",
                                    rejection_reason = NULL,
                                    reviewed_by = NULL,
                                    reviewed_at = NULL
                                 WHERE id = :id'
                            );
                            $updateResidentStmt->execute($common + [':id' => (int) $existing['id']]);
                        } else {
                            $referenceNumber = verifyGenerateReference(
                                $pdo,
                                (string) $locked['applicant_type']
                            );

                            $insertResidentStmt = $pdo->prepare(
                                'INSERT INTO residents (
                                    reference_no, applicant_type, full_name, mobile_number,
                                    complete_address, purok_sitio, barangay, municipality,
                                    province, bridge_connection, bridge_connection_other,
                                    bridge_use_frequency, proof_original_name, proof_stored_name,
                                    proof_mime_type, proof_file_size, notification_scope,
                                    sms_consent, privacy_consent, mobile_verified,
                                    registration_status
                                 ) VALUES (
                                    :reference_no, :applicant_type, :full_name, :mobile_number,
                                    :complete_address, :purok_sitio, :barangay, :municipality,
                                    :province, :bridge_connection, :bridge_connection_other,
                                    :bridge_use_frequency, :proof_original_name, :proof_stored_name,
                                    :proof_mime_type, :proof_file_size, :notification_scope,
                                    :sms_consent, :privacy_consent, 1, "pending"
                                 )'
                            );
                            $insertResidentStmt->execute(
                                [':reference_no' => $referenceNumber] + $common
                            );
                        }

                        $cancelOtpStmt = $pdo->prepare(
                            'UPDATE sms_logs
                             SET
                                delivery_status = "failed",
                                modem_response = "Phone number already verified."
                             WHERE verification_id = :verification_id
                               AND message_type = "otp"
                               AND delivery_status = "pending"'
                        );
                        $cancelOtpStmt->execute([
                            ':verification_id' => (int) $locked['id']
                        ]);

                        $deleteStmt = $pdo->prepare(
                            'DELETE FROM pending_phone_verifications WHERE id = :id'
                        );
                        $deleteStmt->execute([':id' => (int) $locked['id']]);

                        $pdo->commit();

                        if (
                            is_string($oldProofPathToDelete) &&
                            is_file($oldProofPathToDelete)
                        ) {
                            @unlink($oldProofPathToDelete);
                        }

                        $_SESSION['registration_success'] = [
                            'reference_no' => $referenceNumber,
                            'full_name' => (string) $locked['full_name'],
                            'is_resubmission' => $isResubmission
                        ];

                        unset($_SESSION['phone_verification_csrf']);
                        header('Location: register.php?submitted=1');
                        exit;
                    }
                } catch (Throwable $exception) {
                    if ($pdo->inTransaction()) {
                        $pdo->rollBack();
                    }

                    if ($movedFrom && $movedTo && is_file($movedTo) && !is_file($movedFrom)) {
                        @rename($movedTo, $movedFrom);
                    }

                    $errors[] = verifyPublicError($exception);
                }
            }
        }
    }
}

$maskedNumber = $pending
    ? '09*****' . substr((string) $pending['mobile_number'], -4)
    : 'your mobile number';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Mobile Number | FloodGuard</title>
    <link rel="stylesheet" href="assets/css/public-register.css">
    <link rel="stylesheet" href="assets/css/verify-phone.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<main class="verification-page">
    <section class="verification-card">
        <div class="verification-icon"><i class="bi bi-phone-fill"></i></div>
        <span class="public-eyebrow">Mobile Verification</span>
        <h1>Enter your verification code</h1>
        <p>
            FloodGuard queued a six-digit SMS code for
            <strong><?= verifyEscape($maskedNumber) ?></strong>.
        </p>

        <?php if ($notice !== ''): ?>
            <div class="verification-alert success">
                <i class="bi bi-check-circle-fill"></i>
                <span><?= verifyEscape($notice) ?></span>
            </div>
        <?php endif; ?>

        <?php if ($errors): ?>
            <div class="verification-alert error" role="alert">
                <i class="bi bi-exclamation-circle-fill"></i>
                <div>
                    <?php foreach ($errors as $error): ?>
                        <span><?= verifyEscape($error) ?></span>
                    <?php endforeach; ?>
                </div>
            </div>
        <?php endif; ?>

        <?php if ($pending): ?>
            <form method="POST" class="verification-form">
                <input type="hidden" name="csrf_token" value="<?= verifyEscape($csrfToken) ?>">
                <input type="hidden" name="verification_token" value="<?= verifyEscape($token) ?>">
                <input type="hidden" name="action" value="verify">

                <label for="otp">Six-digit code</label>
                <input
                    type="text"
                    inputmode="numeric"
                    autocomplete="one-time-code"
                    pattern="[0-9]{6}"
                    maxlength="6"
                    id="otp"
                    name="otp"
                    placeholder="000000"
                    required
                    autofocus
                >

                <button type="submit" class="verify-button">
                    <i class="bi bi-shield-check"></i>
                    Verify Mobile Number
                </button>
            </form>

            <form method="POST" class="resend-form">
                <input type="hidden" name="csrf_token" value="<?= verifyEscape($csrfToken) ?>">
                <input type="hidden" name="verification_token" value="<?= verifyEscape($token) ?>">
                <input type="hidden" name="action" value="resend">
                <button type="submit" class="resend-button">Resend verification code</button>
            </form>
        <?php else: ?>
            <a href="register.php" class="verify-button">Return to registration</a>
        <?php endif; ?>

        <small class="verification-note">
            Delivery requires the FloodGuard monitoring station and A7670E modem to be online.
        </small>
    </section>
</main>
</body>
</html>
