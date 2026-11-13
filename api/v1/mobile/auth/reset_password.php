<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';

floodguardRequireMethod('POST');
$input = floodguardJsonInput();
$resetToken = trim((string) ($input['reset_token'] ?? ''));
$password = (string) ($input['password'] ?? '');

if (strlen($resetToken) !== 64 || !ctype_xdigit($resetToken)) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Your verified reset session is invalid. Request a new code.']);
}
if (strlen($password) < 10 || strlen($password) > 72 || !preg_match('/[A-Za-z]/', $password) || !preg_match('/\d/', $password)) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Password must be 10–72 characters and contain a letter and number.']);
}

try {
    $pdo->beginTransaction();
    $statement = $pdo->prepare(
        'SELECT id,user_id
         FROM password_reset_tokens
         WHERE token_hash=:hash AND used_at IS NULL AND expires_at>NOW()
         ORDER BY id DESC LIMIT 1 FOR UPDATE'
    );
    $statement->execute([':hash' => hash('sha256', $resetToken)]);
    $record = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$record) {
        $pdo->rollBack();
        floodguardJsonResponse(410, ['success' => false, 'message' => 'Your verified reset session expired. Request a new code.']);
    }

    $pdo->prepare('UPDATE users SET password_hash=:password,token_version=token_version+1 WHERE id=:id')
        ->execute([':password' => password_hash($password, PASSWORD_DEFAULT), ':id' => $record['user_id']]);
    $pdo->prepare('UPDATE password_reset_tokens SET used_at=NOW() WHERE user_id=:id AND used_at IS NULL')
        ->execute([':id' => $record['user_id']]);
    $pdo->prepare('UPDATE api_tokens SET revoked_at=NOW() WHERE user_id=:id AND revoked_at IS NULL')
        ->execute([':id' => $record['user_id']]);
    $pdo->commit();

    floodguardJsonResponse(200, [
        'success' => true,
        'message' => 'Password changed. Sign in again using your new password.',
    ]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[Reset password] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to reset the password.']);
}
