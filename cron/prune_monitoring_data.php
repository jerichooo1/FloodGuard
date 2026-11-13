<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';

$settings = $pdo->query(
    "SELECT setting_key, setting_value FROM system_settings
     WHERE setting_key IN ('raw_telemetry_retention_days','sensor_reading_retention_days')"
)->fetchAll(PDO::FETCH_KEY_PAIR);
$rawDays = max(1, min(30, (int) ($settings['raw_telemetry_retention_days'] ?? 7)));
$readingDays = max(7, min(365, (int) ($settings['sensor_reading_retention_days'] ?? 90)));

$raw = $pdo->prepare(
    'UPDATE sensor_readings SET raw_payload=NULL
     WHERE raw_payload IS NOT NULL AND created_at < DATE_SUB(NOW(), INTERVAL :days DAY)'
);
$raw->bindValue(':days', $rawDays, PDO::PARAM_INT);
$raw->execute();

$old = $pdo->prepare(
    'DELETE sr FROM sensor_readings sr
     LEFT JOIN device_latest_readings dl ON dl.sensor_reading_id=sr.id
     WHERE dl.sensor_reading_id IS NULL
       AND sr.created_at < DATE_SUB(NOW(), INTERVAL :days DAY)'
);
$old->bindValue(':days', $readingDays, PDO::PARAM_INT);
$old->execute();

fwrite(STDOUT, $raw->rowCount() . " raw payload(s) cleared; " .
    $old->rowCount() . " old reading(s) removed.\n");
