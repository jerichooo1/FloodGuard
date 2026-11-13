<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Security/RateLimiter.php';
require_once __DIR__ . '/../../../../app/Support/Validation.php';
require_once __DIR__ . '/../../../../app/Mail/Mailer.php';

floodguardRequireMethod('POST');
$input = floodguardJsonInput();

try {
    $email = floodguardEmail($input);
    $subject = floodguardRateLimitSubject($email);
    $remaining = floodguardRateLimitRemaining($pdo, 'email_verification_resend', $subject);
    if ($remaining > 0) {
        floodguardJsonResponse(429, ['success' => false, 'message' => 'Please wait before requesting another code.', 'retry_after_seconds' => $remaining]);
    }

    $statement = $pdo->prepare(
        'SELECT u.id,u.full_name,u.email_verified_at
         FROM users u
         JOIN user_roles ur ON ur.user_id=u.id
         JOIN roles r ON r.id=ur.role_id AND r.slug="resident"
         WHERE u.email=:email LIMIT 1'
    );
    $statement->execute([':email' => $email]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$user || $user['email_verified_at'] !== null) {
        floodguardJsonResponse(200, ['success' => true, 'message' => 'If verification is still required, a new code was sent.']);
    }

    $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    $minutes = (int) ($pdo->query("SELECT setting_value FROM system_settings WHERE setting_key='email_verification_minutes' LIMIT 1")->fetchColumn() ?: 30);
    $expires = date('Y-m-d H:i:s', time() + max(10, min(1440, $minutes)) * 60);
    $pdo->beginTransaction();
    $pdo->prepare('UPDATE email_verification_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')->execute([':id' => $user['id']]);
    $pdo->prepare('INSERT INTO email_verification_tokens (user_id,token_hash,expires_at) VALUES (:id,:hash,:expires)')
        ->execute([':id' => $user['id'], ':hash' => hash('sha256', $email . '|' . $code), ':expires' => $expires]);
    $pdo->commit();

    if (!floodguardSendVerificationEmail($email, (string) $user['full_name'], $code)) {
        $pdo->prepare('UPDATE email_verification_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')->execute([':id' => $user['id']]);
        error_log('[Resend verification delivery] ' . (floodguardMailError() ?? 'Unknown email delivery failure.'));
        floodguardJsonResponse(503, ['success' => false, 'message' => 'The verification email could not be sent. Please try again later.']);
    }

    floodguardRecordFailedAttempt($pdo, 'email_verification_resend', $subject, 1, 15, 60);
    floodguardJsonResponse(200, ['success' => true, 'message' => 'A new six-digit code was sent to your email.']);
} catch (InvalidArgumentException $exception) {
    floodguardJsonResponse(422, ['success' => false, 'message' => $exception->getMessage()]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[Resend verification] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to resend the verification code.']);
}
