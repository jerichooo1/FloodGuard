<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Security/RateLimiter.php';
require_once __DIR__ . '/../../../../app/Support/Validation.php';

floodguardRequireMethod('POST');
$input = floodguardJsonInput();

try {
    $email = floodguardEmail($input);
    $code = trim((string) ($input['code'] ?? ''));
    if (preg_match('/^\d{6}$/', $code) !== 1) {
        floodguardJsonResponse(422, ['success' => false, 'message' => 'Enter the six-digit code from your email.']);
    }

    $subject = floodguardRateLimitSubject($email);
    $remaining = floodguardRateLimitRemaining($pdo, 'email_verification', $subject);
    if ($remaining > 0) {
        floodguardJsonResponse(429, ['success' => false, 'message' => 'Too many incorrect codes. Try again later.', 'retry_after_seconds' => $remaining]);
    }

    $pdo->beginTransaction();
    $statement = $pdo->prepare(
        'SELECT evt.id,evt.user_id,rp.approval_status
         FROM email_verification_tokens evt
         JOIN users u ON u.id=evt.user_id
         JOIN resident_profiles rp ON rp.user_id=evt.user_id
         WHERE u.email=:email AND evt.token_hash=:hash
           AND evt.used_at IS NULL AND evt.expires_at>NOW()
         ORDER BY evt.id DESC LIMIT 1 FOR UPDATE'
    );
    $statement->execute([':email' => $email, ':hash' => hash('sha256', $email . '|' . $code)]);
    $record = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$record) {
        $pdo->rollBack();
        floodguardRecordFailedAttempt($pdo, 'email_verification', $subject, 5, 15, 300);
        floodguardJsonResponse(410, ['success' => false, 'message' => 'The verification code is invalid or expired.']);
    }

    $newStatus = $record['approval_status'] === 'approved' ? 'active' : 'pending';
    $pdo->prepare('UPDATE users SET email_verified_at=NOW(),account_status=:status WHERE id=:id')
        ->execute([':status' => $newStatus, ':id' => $record['user_id']]);
    $pdo->prepare('UPDATE email_verification_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')
        ->execute([':id' => $record['user_id']]);
    $pdo->commit();
    floodguardClearRateLimit($pdo, 'email_verification', $subject);

    $message = $newStatus === 'active'
        ? 'Email verified. Your approved account is ready to sign in.'
        : 'Email verified. Your application is now waiting for administrator approval.';
    floodguardJsonResponse(200, ['success' => true, 'message' => $message, 'approval_status' => $record['approval_status']]);
} catch (InvalidArgumentException $exception) {
    floodguardJsonResponse(422, ['success' => false, 'message' => $exception->getMessage()]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[Verify email] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to verify the email.']);
}
