<?php

declare(strict_types=1);

function floodguardQueueResidentPush(
    PDO $pdo,
    string $eventType,
    string $alertLevel,
    string $title,
    string $body,
    array $data = []
): int {
    $notification = $pdo->prepare(
        'INSERT INTO push_notifications
            (event_type, alert_level, title, body, data_json, created_at)
         VALUES (:event_type, :alert_level, :title, :body, :data_json, NOW())'
    );
    $notification->execute([
        ':event_type' => $eventType,
        ':alert_level' => $alertLevel,
        ':title' => substr($title, 0, 150),
        ':body' => substr($body, 0, 1000),
        ':data_json' => $data
            ? json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
            : null
    ]);
    $notificationId = (int) $pdo->lastInsertId();

    $recipients = $pdo->prepare(
        'INSERT INTO push_notification_recipients
            (push_notification_id, user_id, delivery_status, created_at)
         SELECT :notification_id, u.id, "queued", NOW()
         FROM users u
         JOIN user_roles ur ON ur.user_id = u.id
         JOIN roles r ON r.id = ur.role_id AND r.slug = "resident"
         JOIN resident_profiles rp ON rp.user_id = u.id
         WHERE u.account_status = "active"
           AND u.email_verified_at IS NOT NULL
           AND rp.push_notifications_enabled = 1
           AND EXISTS (
               SELECT 1 FROM resident_push_devices pd
               WHERE pd.user_id = u.id AND pd.revoked_at IS NULL
           )'
    );
    $recipients->execute([':notification_id' => $notificationId]);
    return $recipients->rowCount();
}
