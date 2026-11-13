<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';
require_once __DIR__ . '/../../../../app/Http/Request.php';
require_once __DIR__ . '/../../../../app/Auth/Authorization.php';
require_once __DIR__ . '/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('POST');
$user = floodguardRequireApiUser($pdo);
$input = floodguardJsonInput();
$notificationId = filter_var($input['notification_id'] ?? null, FILTER_VALIDATE_INT);
if (!$notificationId || $notificationId < 1) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'A valid notification_id is required.']);
}

$statement = $pdo->prepare(
    'UPDATE push_notification_recipients
     SET read_at=COALESCE(read_at, NOW())
     WHERE push_notification_id=:notification_id AND user_id=:user_id'
);
$statement->execute([':notification_id' => $notificationId, ':user_id' => (int) $user['id']]);
if ($statement->rowCount() === 0) {
    $check = $pdo->prepare(
        'SELECT 1 FROM push_notification_recipients
         WHERE push_notification_id=:notification_id AND user_id=:user_id'
    );
    $check->execute([':notification_id' => $notificationId, ':user_id' => (int) $user['id']]);
    if (!$check->fetchColumn()) {
        floodguardJsonResponse(404, ['success' => false, 'message' => 'Notification not found.']);
    }
}
floodguardJsonResponse(200, ['success' => true, 'message' => 'Notification marked as read.']);
