<?php

declare(strict_types=1);

$GLOBALS['floodguard_mail_error'] = null;

function floodguardMailError(): ?string
{
    $error = $GLOBALS['floodguard_mail_error'] ?? null;
    return is_string($error) && $error !== '' ? $error : null;
}

function floodguardSetMailError(string $message): void
{
    $GLOBALS['floodguard_mail_error'] = $message;
}

function floodguardBuildMailer(string $recipientEmail, string $recipientName): ?PHPMailer\PHPMailer\PHPMailer
{
    $autoload = dirname(__DIR__, 2) . '/vendor/autoload.php';
    if (is_file($autoload)) require_once $autoload;
    if (!class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
        floodguardSetMailError('PHPMailer is not installed. Run composer install in the FloodGuard directory.');
        return null;
    }

    $host = (string) floodguardEnv('SMTP_HOST', '');
    $username = (string) floodguardEnv('SMTP_USERNAME', '');
    $password = (string) floodguardEnv('SMTP_PASSWORD', '');
    if ($host === '' || $username === '' || $password === '') {
        floodguardSetMailError('SMTP_HOST, SMTP_USERNAME, or SMTP_PASSWORD is missing from .env.');
        return null;
    }

    $mail = new PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->Host = $host;
    $mail->SMTPAuth = true;
    $mail->Username = $username;
    $mail->Password = $password;
    $mail->SMTPSecure = (string) floodguardEnv('SMTP_ENCRYPTION', 'tls');
    $mail->Port = (int) floodguardEnv('SMTP_PORT', '587');
    $mail->CharSet = 'UTF-8';
    $mail->setFrom((string) floodguardEnv('MAIL_FROM_ADDRESS', $username), (string) floodguardEnv('MAIL_FROM_NAME', 'FloodGuard'));
    $mail->addAddress($recipientEmail, $recipientName);
    $mail->isHTML(true);
    $GLOBALS['floodguard_mail_error'] = null;
    return $mail;
}

function floodguardSendVerificationEmail(string $recipientEmail, string $recipientName, string $code): bool
{
    try {
        $mail = floodguardBuildMailer($recipientEmail, $recipientName);
        if ($mail === null) return false;
        $safeName = htmlspecialchars($recipientName, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        $safeCode = htmlspecialchars($code, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        $mail->Subject = 'Verify your FloodGuard account';
        $mail->Body = "<p>Hello {$safeName},</p><p>Enter this verification code in the FloodGuard mobile app:</p><p style=\"font-size:28px;font-weight:700;letter-spacing:6px\">{$safeCode}</p><p>This one-time code expires in 30 minutes. Do not share it.</p>";
        $mail->AltBody = "Your FloodGuard email verification code is {$code}. It expires in 30 minutes.";
        $mail->send();
        return true;
    } catch (Throwable $exception) {
        floodguardSetMailError($exception->getMessage());
        error_log('[FloodGuard verification email] ' . $exception->getMessage());
        return false;
    }
}

function floodguardSendPasswordResetCodeEmail(string $recipientEmail, string $recipientName, string $code): bool
{
    try {
        $mail = floodguardBuildMailer($recipientEmail, $recipientName);
        if ($mail === null) return false;
        $safeName = htmlspecialchars($recipientName, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        $safeCode = htmlspecialchars($code, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        $mail->Subject = 'Your FloodGuard password reset code';
        $mail->Body = "<p>Hello {$safeName},</p><p>Use this verification code to reset your FloodGuard password:</p><p style=\"font-size:28px;font-weight:700;letter-spacing:6px\">{$safeCode}</p><p>This one-time code expires in 15 minutes. Do not share it. If you did not request a reset, ignore this email.</p>";
        $mail->AltBody = "Your FloodGuard password reset code is {$code}. It expires in 15 minutes.";
        $mail->send();
        return true;
    } catch (Throwable $exception) {
        floodguardSetMailError($exception->getMessage());
        error_log('[FloodGuard password reset email] ' . $exception->getMessage());
        return false;
    }
}

function floodguardSendResidentDecisionEmail(string $recipientEmail, string $recipientName, string $decision, ?string $reason = null, bool $emailVerified = true): bool
{
    try {
        $mail = floodguardBuildMailer($recipientEmail, $recipientName);
        if ($mail === null) return false;
        $safeName = htmlspecialchars($recipientName, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        if ($decision === 'approved') {
            $mail->Subject = 'Your FloodGuard resident account was approved';
            $nextStep = $emailVerified ? 'You may now sign in to the FloodGuard mobile application.' : 'Please verify your email address before signing in.';
            $mail->Body = "<p>Hello {$safeName},</p><p>Your proof of residency was reviewed and your FloodGuard resident account has been <strong>approved</strong>.</p><p>{$nextStep}</p>";
            $mail->AltBody = "Your FloodGuard resident account was approved. {$nextStep}";
        } else {
            $safeReason = htmlspecialchars((string) $reason, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
            $mail->Subject = 'Update about your FloodGuard resident application';
            $mail->Body = "<p>Hello {$safeName},</p><p>Your FloodGuard resident application was <strong>rejected</strong>.</p><p><strong>Reason:</strong> {$safeReason}</p><p>You may correct the information and register again using the FloodGuard mobile app. You may reuse the same email address and mobile number.</p>";
            $mail->AltBody = "Your FloodGuard resident application was rejected. Reason: {$reason}. Correct the information and register again in the FloodGuard mobile app; you may reuse the same email and mobile number.";
        }
        $mail->send();
        return true;
    } catch (Throwable $exception) {
        floodguardSetMailError($exception->getMessage());
        error_log('[FloodGuard resident decision email] ' . $exception->getMessage());
        return false;
    }
}
