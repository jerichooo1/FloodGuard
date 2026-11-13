<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';

$email = trim((string) ($argv[1] ?? ''));
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Usage: php tools/queue_test_push.php resident@example.com\n");
    exit(1);
}

try {
    $user = $pdo->prepare(
        'SELECT u.id
         FROM users u
         JOIN user_roles ur ON ur.user_id=u.id
         JOIN roles r ON r.id=ur.role_id AND r.slug="resident"
         WHERE u.email=:email AND u.account_status="active"
         LIMIT 1'
    );
    $user->execute([':email' => $email]);
    $userId = (int) $user->fetchColumn();
    if ($userId < 1) {
        throw new RuntimeException('An active resident with that email was not found.');
    }

    $device = $pdo->prepare(
        'SELECT COUNT(*) FROM resident_push_devices
         WHERE user_id=:user_id AND revoked_at IS NULL'
    );
    $device->execute([':user_id' => $userId]);
    if ((int) $device->fetchColumn() < 1) {
        throw new RuntimeException('That resident has no active push device.');
    }

    $pdo->beginTransaction();
    $notification = $pdo->prepare(
        'INSERT INTO push_notifications
            (event_type, alert_level, title, body, data_json, created_at)
         VALUES ("manual_test", "warning", :title, :body, :data, NOW())'
    );
    $notification->execute([
        ':title' => 'FloodGuard Warning Test',
        ':body' => 'This is a test of FloodGuard automatic push delivery.',
        ':data' => json_encode([
            'test' => true,
            'alert_level' => 'warning'
        ], JSON_UNESCAPED_SLASHES)
    ]);
    $notificationId = (int) $pdo->lastInsertId();
    $recipient = $pdo->prepare(
        'INSERT INTO push_notification_recipients
            (push_notification_id, user_id, delivery_status, created_at)
         VALUES (:notification_id, :user_id, "queued", NOW())'
    );
    $recipient->execute([
        ':notification_id' => $notificationId,
        ':user_id' => $userId
    ]);
    $pdo->commit();

    fwrite(STDOUT, sprintf(
        "Test notification %d queued for resident user %d.\n",
        $notificationId,
        $userId
    ));
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    fwrite(STDERR, 'Unable to queue test notification: ' . $exception->getMessage() . PHP_EOL);
    exit(1);
}
