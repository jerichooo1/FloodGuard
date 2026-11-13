<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';

$timeout = (int) ($pdo->query(
    "SELECT setting_value FROM system_settings
     WHERE setting_key='device_offline_timeout_seconds' LIMIT 1"
)->fetchColumn() ?: 90);
$timeout = max(30, min(3600, $timeout));

$pdo->beginTransaction();
try {
    $statement = $pdo->prepare(
        'SELECT id, device_uid FROM monitoring_devices
         WHERE is_active=1
           AND operational_status IN ("online", "maintenance")
           AND last_seen_at < DATE_SUB(NOW(), INTERVAL :timeout SECOND)
         FOR UPDATE'
    );
    $statement->bindValue(':timeout', $timeout, PDO::PARAM_INT);
    $statement->execute();
    $devices = $statement->fetchAll(PDO::FETCH_ASSOC);

    $event = $pdo->prepare(
        'INSERT INTO device_events
            (monitoring_device_id, sensor_reading_id, event_type, severity,
             title, details_json, occurred_at)
         VALUES (:id, NULL, "device_offline", "critical",
                 "Monitoring station is offline", :details, NOW())'
    );
    $update = $pdo->prepare(
        'UPDATE monitoring_devices SET operational_status="offline" WHERE id=:id'
    );
    foreach ($devices as $device) {
        $event->execute([
            ':id' => $device['id'],
            ':details' => json_encode(['timeout_seconds' => $timeout])
        ]);
        $update->execute([':id' => $device['id']]);
    }

    $pdo->commit();
    fwrite(STDOUT, count($devices) . " device(s) marked offline.\n");
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    fwrite(STDERR, "Offline check failed.\n");
    error_log('[FloodGuard offline check] ' . $exception->getMessage());
    exit(1);
}
