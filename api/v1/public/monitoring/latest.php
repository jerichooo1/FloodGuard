<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    floodguardJsonResponse(405, ['success' => false, 'message' => 'GET required.']);
}

try {
    $publicDeviceId = floodguardEnv('FLOODGUARD_DEVICE_ID', 'FG-STATION-001');
    $timeout = (int) ($pdo->query(
        "SELECT setting_value FROM system_settings
         WHERE setting_key='device_offline_timeout_seconds' LIMIT 1"
    )->fetchColumn() ?: 90);
    $pollSeconds = (int) ($pdo->query(
        "SELECT setting_value FROM system_settings
         WHERE setting_key='public_poll_seconds' LIMIT 1"
    )->fetchColumn() ?: 5);
    $pollSeconds = max(3, min(60, $pollSeconds));

    $statement = $pdo->prepare(
        'SELECT md.device_uid, md.station_name, md.location_description,
                md.operational_status, md.last_seen_at,
                dl.water_distance_cm, dl.water_level_cm, dl.sensor_health,
                dl.rain_detected, dl.wind_speed_mps,
                dl.north_barrier_status, dl.south_barrier_status,
                dl.battery_voltage, dl.battery_percent, dl.alert_level,
                dl.device_status, dl.measured_at,
                TIMESTAMPDIFF(SECOND, md.last_seen_at, NOW()) AS age_seconds
         FROM monitoring_devices md
         LEFT JOIN device_latest_readings dl ON dl.monitoring_device_id=md.id
         WHERE md.device_uid=:device_uid AND md.is_active=1
         LIMIT 1'
    );
    $statement->execute([':device_uid' => $publicDeviceId]);
    $row = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        floodguardJsonResponse(404, ['success' => false, 'message' => 'Monitoring station is unavailable.']);
    }

    $age = $row['age_seconds'] === null ? null : (int) $row['age_seconds'];
    $online = $age !== null && $age >= 0 && $age <= max(30, $timeout) &&
        in_array($row['operational_status'], ['online', 'maintenance'], true);
    $valid = $online && in_array($row['sensor_health'], ['healthy', 'suspect'], true) &&
        $row['water_level_cm'] !== null;

    floodguardJsonResponse(200, [
        'success' => true,
        'data' => [
            'device_id' => $row['device_uid'],
            'station_name' => $row['station_name'],
            'location' => $row['location_description'],
            'online' => $online,
            'measurement_valid' => $valid,
            'water_distance_cm' => $valid ? (float) $row['water_distance_cm'] : null,
            'water_level_cm' => $valid ? (float) $row['water_level_cm'] : null,
            'sensor_health' => $row['sensor_health'] ?? 'unknown',
            'rain_detected' => $valid ? (bool) $row['rain_detected'] : null,
            'wind_speed_mps' => $valid && $row['wind_speed_mps'] !== null ? (float) $row['wind_speed_mps'] : null,
            'bridge_status' => [
                'north' => $row['north_barrier_status'] ?? 'unknown',
                'south' => $row['south_barrier_status'] ?? 'unknown'
            ],
            'battery_voltage' => $online && $row['battery_voltage'] !== null ? (float) $row['battery_voltage'] : null,
            'battery_percent' => $online && $row['battery_percent'] !== null ? (float) $row['battery_percent'] : null,
            'alert_level' => $valid ? $row['alert_level'] : 'unavailable',
            'last_update' => $row['measured_at'],
            'age_seconds' => $age
        ],
        'poll_after_seconds' => $pollSeconds
    ]);
} catch (Throwable $exception) {
    error_log('[FloodGuard public latest monitoring] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Monitoring information is temporarily unavailable.']);
}
