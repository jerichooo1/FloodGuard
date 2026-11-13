<?php

declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    exit('ERROR|GET required');
}

$deviceId = requireFloodguardDevice(null, $pdo);

$defaults = [
    'sensor_height_cm' => '43.18',
    'warning_level_cm' => '15.0',
    'critical_level_cm' => '25.0',
    'rain_warning_threshold' => '1200',
    'rain_critical_threshold' => '600',
    'wind_warning_mps' => '10.0',
    'wind_critical_mps' => '20.0'
];

try {
    $statement = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'sensor_height_cm',
            'warning_level_cm', 'critical_level_cm',
            'rain_warning_threshold', 'rain_critical_threshold',
            'wind_warning_mps', 'wind_critical_mps'
         )"
    );

    foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $key = (string) ($row['setting_key'] ?? '');
        $value = $row['setting_value'] ?? null;
        if (array_key_exists($key, $defaults) && is_numeric($value)) {
            $defaults[$key] = (string) $value;
        }
    }

    $sensorHeight = max(10.0, min(500.0, (float) $defaults['sensor_height_cm']));
    $waterWarning = max(0.0, min($sensorHeight, (float) $defaults['warning_level_cm']));
    $waterCritical = max(0.0, min($sensorHeight, (float) $defaults['critical_level_cm']));
    $rainWarning = max(0, min(4095, (int) $defaults['rain_warning_threshold']));
    $rainCritical = max(0, min(4095, (int) $defaults['rain_critical_threshold']));
    $windWarning = max(0.0, min(100.0, (float) $defaults['wind_warning_mps']));
    $windCritical = max(0.0, min(100.0, (float) $defaults['wind_critical_mps']));

    if ($waterCritical <= $waterWarning ||
        $rainCritical >= $rainWarning ||
        $windCritical <= $windWarning) {
        http_response_code(422);
        exit('ERROR|Invalid threshold order in System Settings');
    }

    echo 'CONFIG|',
        number_format($sensorHeight, 2, '.', ''), '|',
        number_format($waterWarning, 1, '.', ''), '|',
        number_format($waterCritical, 1, '.', ''), '|',
        $rainWarning, '|',
        $rainCritical, '|',
        number_format($windWarning, 1, '.', ''), '|',
        number_format($windCritical, 1, '.', '');
} catch (Throwable $exception) {
    error_log('[FloodGuard device configuration] ' . $exception->getMessage());
    http_response_code(500);
    echo 'ERROR|Unable to load device configuration';
}
