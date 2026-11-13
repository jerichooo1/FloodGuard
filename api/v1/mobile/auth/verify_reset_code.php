<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Support/Validation.php';
require_once __DIR__ . '/../../../../app/Security/RateLimiter.php';

floodguardRequireMethod('POST');
$input = floodguardJsonInput();

try {
    $email = floodguardEmail($input);
    $code = trim((string) ($input['code'] ?? ''));
    if (!preg_match('/^\d{6}$/', $code)) {
        floodguardJsonResponse(422, ['success' => false, 'message' => 'Enter the six-digit verification code.']);
    }

    $subject = floodguardRateLimitSubject($email);
    $remaining = floodguardRateLimitRemaining($pdo, 'password_reset_verify', $subject);
    if ($remaining > 0) {
        floodguardJsonResponse(429, [
            'success' => false,
            'message' => 'Too many incorrect codes. Try again later.',
            'retry_after_seconds' => $remaining,
        ]);
    }

    $pdo->beginTransaction();
    $statement = $pdo->prepare(
        'SELECT prt.id,prt.user_id
         FROM password_reset_tokens prt
         JOIN users u ON u.id=prt.user_id
         JOIN user_roles ur ON ur.user_id=u.id
         JOIN roles r ON r.id=ur.role_id AND r.slug="resident"
         WHERE u.email=:email AND prt.token_hash=:hash
           AND prt.used_at IS NULL AND prt.expires_at>NOW()
         ORDER BY prt.id DESC LIMIT 1 FOR UPDATE'
    );
    $statement->execute([
        ':email' => $email,
        ':hash' => hash('sha256', $email . '|' . $code),
    ]);
    $record = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$record) {
        $pdo->rollBack();
        floodguardRecordFailedAttempt($pdo, 'password_reset_verify', $subject, 5, 15, 300);
        floodguardJsonResponse(410, ['success' => false, 'message' => 'The verification code is invalid or expired.']);
    }

    $resetToken = bin2hex(random_bytes(32));
    $pdo->prepare('UPDATE password_reset_tokens SET used_at=NOW() WHERE id=:id')->execute([':id' => $record['id']]);
    $pdo->prepare(
        'INSERT INTO password_reset_tokens (user_id,token_hash,expires_at)
         VALUES (:user_id,:hash,DATE_ADD(NOW(),INTERVAL 10 MINUTE))'
    )->execute([
        ':user_id' => $record['user_id'],
        ':hash' => hash('sha256', $resetToken),
    ]);
    $pdo->commit();
    floodguardClearRateLimit($pdo, 'password_reset_verify', $subject);

    floodguardJsonResponse(200, [
        'success' => true,
        'message' => 'Code verified. You may now create a new password.',
        'reset_token' => $resetToken,
        'expires_in_seconds' => 600,
    ]);
} catch (InvalidArgumentException $exception) {
    floodguardJsonResponse(422, ['success' => false, 'message' => $exception->getMessage()]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[Verify reset code] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to verify the reset code.']);
}
