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
    $remaining = floodguardRateLimitRemaining($pdo, 'password_reset', $subject);
    if ($remaining > 0) floodguardJsonResponse(429, ['success' => false, 'message' => 'Please wait before requesting another reset code.', 'retry_after_seconds' => $remaining]);

    $statement = $pdo->prepare('SELECT u.id,u.full_name FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE u.email=:email AND r.slug="resident" LIMIT 1');
    $statement->execute([':email' => $email]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);
    $sent = false;
    if ($user) {
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $pdo->beginTransaction();
        $pdo->prepare('UPDATE password_reset_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')->execute([':id' => $user['id']]);
        $pdo->prepare('INSERT INTO password_reset_tokens (user_id,token_hash,expires_at) VALUES (:id,:hash,DATE_ADD(NOW(),INTERVAL 15 MINUTE))')->execute([':id' => $user['id'], ':hash' => hash('sha256', $email . '|' . $code)]);
        $pdo->commit();
        $sent = floodguardSendPasswordResetCodeEmail($email, (string) $user['full_name'], $code);
        if (!$sent) {
            $pdo->prepare('UPDATE password_reset_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')
                ->execute([':id' => $user['id']]);
            error_log('[Forgot password delivery] ' . (floodguardMailError() ?? 'Unknown email delivery failure.'));
            floodguardJsonResponse(503, [
                'success' => false,
                'message' => 'The verification email could not be sent. Please try again later or contact the administrator.',
            ]);
        }
    }
    floodguardRecordFailedAttempt($pdo, 'password_reset', $subject, 1, 15, 60);
    $response = ['success' => true, 'message' => 'If the account exists, a six-digit verification code was sent to its email address.', 'email_sent' => $sent];
    floodguardJsonResponse(200, $response);
} catch (InvalidArgumentException $exception) {
    floodguardJsonResponse(422, ['success' => false, 'message' => $exception->getMessage()]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[Forgot password] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to process the password-reset request.']);
}
