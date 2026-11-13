<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../app/Notifications/FirebaseMessagingService.php';

try {
    $enabled = $pdo->prepare(
        'SELECT setting_value FROM system_settings WHERE setting_key=:key LIMIT 1'
    );
    $enabled->execute([':key' => 'push_delivery_enabled']);
    if ((string) $enabled->fetchColumn() !== '1') {
        fwrite(STDOUT, "Push delivery is disabled.\n");
        exit(0);
    }

    $maxAttemptsStatement = $pdo->prepare(
        'SELECT setting_value FROM system_settings WHERE setting_key=:key LIMIT 1'
    );
    $maxAttemptsStatement->execute([':key' => 'push_max_attempts']);
    $maxAttempts = max(1, min(10, (int) ($maxAttemptsStatement->fetchColumn() ?: 3)));

    $credentials = floodguardFirebaseCredentials();
    $accessToken = floodguardFirebaseAccessToken($credentials);
    $queue = $pdo->prepare(
        'SELECT pnr.id AS recipient_id, pnr.user_id, pnr.attempt_count,
                pn.id AS notification_id, pn.event_type, pn.alert_level,
                pn.title, pn.body, pn.data_json
         FROM push_notification_recipients pnr
         JOIN push_notifications pn ON pn.id=pnr.push_notification_id
         WHERE pnr.delivery_status="queued" AND pnr.attempt_count < :max_attempts
         ORDER BY pnr.created_at ASC, pnr.id ASC
         LIMIT 100'
    );
    $queue->bindValue(':max_attempts', $maxAttempts, PDO::PARAM_INT);
    $queue->execute();
    $items = $queue->fetchAll();

    $deviceStatement = $pdo->prepare(
        'SELECT id, device_token
         FROM resident_push_devices
         WHERE user_id=:user_id AND revoked_at IS NULL
         ORDER BY last_seen_at DESC'
    );
    $markSent = $pdo->prepare(
        'UPDATE push_notification_recipients
         SET delivery_status="sent", attempt_count=attempt_count+1,
             provider_message_id=:provider, last_error=NULL, sent_at=NOW()
         WHERE id=:id'
    );
    $markFailed = $pdo->prepare(
        'UPDATE push_notification_recipients
         SET delivery_status=:status, attempt_count=attempt_count+1,
             last_error=:error
         WHERE id=:id'
    );
    $revokeDevice = $pdo->prepare(
        'UPDATE resident_push_devices SET revoked_at=NOW() WHERE id=:id'
    );

    $sent = 0;
    $failed = 0;
    $skipped = 0;
    foreach ($items as $item) {
        $deviceStatement->execute([':user_id' => (int) $item['user_id']]);
        $devices = $deviceStatement->fetchAll();
        if (!$devices) {
            $markFailed->execute([
                ':status' => 'skipped',
                ':error' => 'No active push device.',
                ':id' => (int) $item['recipient_id']
            ]);
            $skipped++;
            continue;
        }

        $data = $item['data_json']
            ? json_decode((string) $item['data_json'], true)
            : [];
        if (!is_array($data)) {
            $data = [];
        }
        $data += [
            'notification_id' => (string) $item['notification_id'],
            'event_type' => (string) $item['event_type'],
            'alert_level' => (string) $item['alert_level']
        ];

        $delivered = false;
        $providerId = null;
        $errors = [];
        foreach ($devices as $device) {
            $result = floodguardFirebaseSend(
                $credentials,
                $accessToken,
                (string) $device['device_token'],
                (string) $item['title'],
                (string) $item['body'],
                (string) $item['alert_level'],
                $data
            );
            if ($result['success']) {
                $delivered = true;
                $providerId ??= $result['provider_message_id'];
            } else {
                $errors[] = (string) ($result['error'] ?? 'Firebase delivery failed.');
                if ($result['token_invalid']) {
                    $revokeDevice->execute([':id' => (int) $device['id']]);
                }
            }
        }

        if ($delivered) {
            $markSent->execute([
                ':provider' => $providerId,
                ':id' => (int) $item['recipient_id']
            ]);
            $sent++;
        } else {
            $nextAttempt = (int) $item['attempt_count'] + 1;
            $markFailed->execute([
                ':status' => $nextAttempt >= $maxAttempts ? 'failed' : 'queued',
                ':error' => substr(implode(' | ', array_unique($errors)), 0, 500),
                ':id' => (int) $item['recipient_id']
            ]);
            $failed++;
        }
    }

    fwrite(STDOUT, sprintf(
        "Push delivery complete: %d sent, %d failed/retry, %d skipped.\n",
        $sent,
        $failed,
        $skipped
    ));
} catch (Throwable $exception) {
    error_log('[FloodGuard push delivery] ' . $exception->getMessage());
    fwrite(STDERR, 'Push delivery failed: ' . $exception->getMessage() . PHP_EOL);
    exit(1);
}
