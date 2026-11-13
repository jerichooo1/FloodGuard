<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Auth/Authorization.php';
require_once __DIR__ . '/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET', 'POST', 'DELETE');
$user = floodguardRequireApiUser($pdo);
$userId = (int) $user['id'];

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $statement = $pdo->prepare(
            'SELECT id, platform, device_name, app_version, last_seen_at, created_at
             FROM resident_push_devices
             WHERE user_id=:user_id AND revoked_at IS NULL
             ORDER BY last_seen_at DESC'
        );
        $statement->execute([':user_id' => $userId]);
        floodguardJsonResponse(200, ['success' => true, 'data' => $statement->fetchAll()]);
    }

    $input = floodguardJsonInput();
    $token = trim((string) ($input['device_token'] ?? ''));
    if (strlen($token) < 20 || strlen($token) > 512) {
        floodguardJsonResponse(422, ['success' => false, 'message' => 'A valid push device token is required.']);
    }
    $hash = hash('sha256', $token);

    if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        $statement = $pdo->prepare(
            'UPDATE resident_push_devices SET revoked_at=NOW()
             WHERE user_id=:user_id AND token_hash=:hash AND revoked_at IS NULL'
        );
        $statement->execute([':user_id' => $userId, ':hash' => $hash]);
        floodguardJsonResponse(200, ['success' => true, 'message' => 'Push device signed out.']);
    }

    $platform = strtolower(trim((string) ($input['platform'] ?? '')));
    if (!in_array($platform, ['android', 'ios', 'web'], true)) {
        floodguardJsonResponse(422, ['success' => false, 'message' => 'Platform must be android, ios, or web.']);
    }

    $statement = $pdo->prepare(
        'INSERT INTO resident_push_devices
            (user_id, token_hash, device_token, platform, device_name, app_version, last_seen_at)
         VALUES (:user_id, :hash, :token, :platform, :device_name, :app_version, NOW())
         ON DUPLICATE KEY UPDATE
            user_id=VALUES(user_id), device_token=VALUES(device_token),
            platform=VALUES(platform), device_name=VALUES(device_name),
            app_version=VALUES(app_version), last_seen_at=NOW(), revoked_at=NULL'
    );
    $statement->execute([
        ':user_id' => $userId,
        ':hash' => $hash,
        ':token' => $token,
        ':platform' => $platform,
        ':device_name' => substr(trim((string) ($input['device_name'] ?? '')), 0, 150) ?: null,
        ':app_version' => substr(trim((string) ($input['app_version'] ?? '')), 0, 50) ?: null
    ]);
    floodguardJsonResponse(200, ['success' => true, 'message' => 'Push device registered.']);
} catch (Throwable $exception) {
    error_log('[FloodGuard push devices] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to update the push device.']);
}
