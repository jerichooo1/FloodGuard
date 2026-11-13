<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Auth/Authorization.php';
require_once __DIR__ . '/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET');
$user = floodguardRequireApiUser($pdo);

try {
    $statement = $pdo->prepare(
        'SELECT pn.id, pn.event_type, pn.alert_level, pn.title, pn.body,
                pn.data_json, pn.created_at, pnr.delivery_status, pnr.read_at
         FROM push_notification_recipients pnr
         JOIN push_notifications pn ON pn.id=pnr.push_notification_id
         WHERE pnr.user_id=:user_id
         ORDER BY pn.created_at DESC, pn.id DESC LIMIT 100'
    );
    $statement->execute([':user_id' => (int) $user['id']]);
    $rows = $statement->fetchAll();
    foreach ($rows as &$row) {
        $row['data'] = $row['data_json'] ? json_decode((string) $row['data_json'], true) : null;
        $row['is_read'] = $row['read_at'] !== null;
        unset($row['data_json']);
    }
    unset($row);
    floodguardJsonResponse(200, ['success' => true, 'data' => $rows]);
} catch (Throwable $exception) {
    error_log('[FloodGuard push inbox] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to load notifications.']);
}
