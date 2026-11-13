<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';
require_once __DIR__ . '/../app/Notifications/PushNotificationService.php';

function jsonResponse(int $status, array $payload): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function nullableNumber(array $data, string $key, float $minimum, float $maximum): ?float
{
    if (!array_key_exists($key, $data) || $data[$key] === null || $data[$key] === '') {
        return null;
    }
    if (!is_numeric($data[$key])) {
        throw new InvalidArgumentException("{$key} must be numeric.");
    }
    $value = (float) $data[$key];
    if ($value < $minimum || $value > $maximum) {
        throw new InvalidArgumentException("{$key} is outside the accepted range.");
    }
    return $value;
}

function nullableInteger(array $data, string $key, int $minimum, int $maximum): ?int
{
    if (!array_key_exists($key, $data) || $data[$key] === null || $data[$key] === '') {
        return null;
    }
    $value = filter_var($data[$key], FILTER_VALIDATE_INT);
    if ($value === false || $value < $minimum || $value > $maximum) {
        throw new InvalidArgumentException("{$key} is outside the accepted range.");
    }
    return (int) $value;
}

function booleanValue(mixed $value, bool $default = false): int
{
    if ($value === null || $value === '') {
        return $default ? 1 : 0;
    }
    if (is_bool($value)) {
        return $value ? 1 : 0;
    }
    $parsed = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    if ($parsed === null) {
        throw new InvalidArgumentException('A boolean field contains an invalid value.');
    }
    return $parsed ? 1 : 0;
}

function allowedValue(array $data, string $key, array $allowed, string $default): string
{
    $value = strtolower(trim((string) ($data[$key] ?? $default)));
    if (!in_array($value, $allowed, true)) {
        throw new InvalidArgumentException("{$key} contains an unsupported value.");
    }
    return $value;
}

function addDeviceEvent(
    PDO $pdo,
    int $deviceId,
    ?int $readingId,
    string $type,
    string $severity,
    string $title,
    array $details = []
): void {
    $statement = $pdo->prepare(
        'INSERT INTO device_events
            (monitoring_device_id, sensor_reading_id, event_type, severity,
             title, details_json, occurred_at)
         VALUES
            (:device_id, :reading_id, :event_type, :severity,
             :title, :details_json, NOW())'
    );
    $statement->execute([
        ':device_id' => $deviceId,
        ':reading_id' => $readingId,
        ':event_type' => $type,
        ':severity' => $severity,
        ':title' => $title,
        ':details_json' => $details
            ? json_encode($details, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
            : null
    ]);
}

function numericChanged(mixed $previous, ?float $current, float $threshold): bool
{
    if ($previous === null || $previous === '' || $current === null) {
        return ($previous === null || $previous === '') !== ($current === null);
    }

    return abs((float) $previous - $current) >= $threshold;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(405, ['success' => false, 'message' => 'Only POST requests are allowed.']);
}

$rawBody = file_get_contents('php://input') ?: '';
$contentType = strtolower((string) ($_SERVER['CONTENT_TYPE'] ?? ''));
try {
    $data = str_contains($contentType, 'application/json')
        ? json_decode($rawBody, true, 512, JSON_THROW_ON_ERROR)
        : $_POST;
} catch (JsonException $exception) {
    jsonResponse(400, ['success' => false, 'message' => 'Invalid JSON request body.']);
}

if (!is_array($data) || !$data) {
    jsonResponse(400, ['success' => false, 'message' => 'No sensor data was received.']);
}

try {
    $deviceUid = substr(trim((string) ($data['device_id'] ?? '')), 0, 50);
    if ($deviceUid === '') {
        throw new InvalidArgumentException('device_id is required.');
    }

    [$credentialDeviceId, $credentialKey, $credentialSource] = floodguardDeviceCredentials($data);
    if ($credentialSource !== 'headers' || $credentialDeviceId === '' || $credentialKey === '') {
        jsonResponse(401, [
            'success' => false,
            'message' => 'X-Device-ID and X-Device-Key headers are required.'
        ]);
    }
    $authenticatedDeviceId = requireFloodguardDevice($data, $pdo);
    if (!hash_equals($authenticatedDeviceId, $deviceUid)) {
        jsonResponse(403, ['success' => false, 'message' => 'Payload device_id does not match the authenticated device.']);
    }
    $authenticationMode = 'device_api_key';

    $deviceStmt = $pdo->prepare(
        'SELECT id, operational_status
         FROM monitoring_devices
         WHERE device_uid = :device_uid AND is_active = 1
         LIMIT 1'
    );
    $deviceStmt->execute([':device_uid' => $deviceUid]);
    $device = $deviceStmt->fetch(PDO::FETCH_ASSOC);
    if (!$device) {
        jsonResponse(403, ['success' => false, 'message' => 'Monitoring device is not registered or active.']);
    }
    $monitoringDeviceId = (int) $device['id'];

    $waterDistance = nullableNumber($data, 'water_distance_cm', 0, 1000);
    $waterLevel = nullableNumber($data, 'water_level_cm', 0, 1000);
    $riseRate = nullableNumber($data, 'rise_rate_cm_min', -100, 100);
    $rainAnalog = nullableInteger($data, 'rain_analog', 0, 4095);
    $rainDetected = booleanValue($data['rain_detected'] ?? null);
    $windSpeed = nullableNumber($data, 'wind_speed_mps', 0, 100);
    if ($windSpeed === null) {
        $windSpeed = nullableNumber($data, 'wind_speed_ms', 0, 100);
    }
    $northObstacle = booleanValue($data['north_obstacle'] ?? null);
    $southObstacle = booleanValue($data['south_obstacle'] ?? null);
    $barrierStates = ['open','closed','opening','closing','paused','blocked','fault','not_connected','unknown'];
    $northBarrier = allowedValue($data, 'north_barrier_status', $barrierStates, 'not_connected');
    $southBarrier = allowedValue($data, 'south_barrier_status', $barrierStates, 'not_connected');
    $batteryVoltage = nullableNumber($data, 'battery_voltage', 0, 30);
    $batteryPercent = nullableNumber($data, 'battery_percent', 0, 100);
    $alertLevel = allowedValue($data, 'alert_level', ['normal','warning','critical'], 'normal');
    $sensorHealth = allowedValue($data, 'sensor_health', ['healthy','suspect','fault','unknown'], 'unknown');
    $deviceStatus = allowedValue($data, 'device_status', ['online','offline','sensor_error','maintenance'], 'online');
    $predictionStatus = 'unavailable';

    $thresholdDefaults = [
        'warning_level_cm' => 20.0,
        'critical_level_cm' => 35.0,
        'rain_warning_threshold' => 1200.0,
        'rain_critical_threshold' => 600.0,
        'wind_warning_mps' => 10.0,
        'wind_critical_mps' => 20.0
    ];
    $thresholds = $thresholdDefaults;
    $thresholdStatement = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'warning_level_cm', 'critical_level_cm',
            'rain_warning_threshold', 'rain_critical_threshold',
            'wind_warning_mps', 'wind_critical_mps'
         )"
    );
    foreach ($thresholdStatement->fetchAll(PDO::FETCH_ASSOC) as $thresholdRow) {
        $thresholdKey = (string) ($thresholdRow['setting_key'] ?? '');
        $thresholdValue = $thresholdRow['setting_value'] ?? null;
        if (array_key_exists($thresholdKey, $thresholds) && is_numeric($thresholdValue)) {
            $thresholds[$thresholdKey] = (float) $thresholdValue;
        }
    }

    $serverAlertLevel = 'normal';
    if (
        ($waterLevel !== null && $waterLevel >= $thresholds['critical_level_cm']) ||
        ($rainAnalog !== null && $rainAnalog <= $thresholds['rain_critical_threshold']) ||
        ($windSpeed !== null && $windSpeed >= $thresholds['wind_critical_mps'])
    ) {
        $serverAlertLevel = 'critical';
    } elseif (
        ($waterLevel !== null && $waterLevel >= $thresholds['warning_level_cm']) ||
        ($rainAnalog !== null && $rainAnalog <= $thresholds['rain_warning_threshold']) ||
        ($windSpeed !== null && $windSpeed >= $thresholds['wind_warning_mps'])
    ) {
        $serverAlertLevel = 'warning';
    }

    $severityRank = ['normal' => 0, 'warning' => 1, 'critical' => 2];
    if ($severityRank[$serverAlertLevel] > $severityRank[$alertLevel]) {
        $alertLevel = $serverAlertLevel;
    }

    if ($sensorHealth === 'healthy' && ($waterDistance === null || $waterLevel === null)) {
        throw new InvalidArgumentException('Healthy water sensing requires distance and level values.');
    }

    $keepRaw = floodguardEnvBool('FG_STORE_RAW_TELEMETRY', false) ||
        in_array($sensorHealth, ['suspect', 'fault'], true) ||
        $deviceStatus === 'sensor_error';
    $rawPayload = $keepRaw ? ($rawBody !== '' ? $rawBody : json_encode($data)) : null;

    $pdo->beginTransaction();

    $latestStmt = $pdo->prepare(
        'SELECT * FROM device_latest_readings
         WHERE monitoring_device_id = :device_id LIMIT 1 FOR UPDATE'
    );
    $latestStmt->execute([':device_id' => $monitoringDeviceId]);
    $previous = $latestStmt->fetch(PDO::FETCH_ASSOC) ?: null;

    $historyIntervalSeconds = (int) ($pdo->query(
        "SELECT setting_value FROM system_settings
         WHERE setting_key='sensor_history_interval_seconds' LIMIT 1"
    )->fetchColumn() ?: 300);
    $historyIntervalSeconds = max(60, min(3600, $historyIntervalSeconds));
    $lastHistoryStmt = $pdo->prepare(
        'SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS age_seconds
         FROM sensor_readings
         WHERE monitoring_device_id = :device_id
         ORDER BY created_at DESC, id DESC LIMIT 1'
    );
    $lastHistoryStmt->execute([':device_id' => $monitoringDeviceId]);
    $lastHistoryAge = $lastHistoryStmt->fetchColumn();
    $historyIntervalElapsed = $lastHistoryAge === false ||
        (int) $lastHistoryAge >= $historyIntervalSeconds;

    $significantChange = !$previous ||
        (string) $previous['alert_level'] !== $alertLevel ||
        (string) $previous['sensor_health'] !== $sensorHealth ||
        (string) $previous['device_status'] !== $deviceStatus ||
        (int) $previous['rain_detected'] !== $rainDetected ||
        (string) $previous['north_barrier_status'] !== $northBarrier ||
        (string) $previous['south_barrier_status'] !== $southBarrier ||
        numericChanged($previous['water_level_cm'] ?? null, $waterLevel, 1.0) ||
        numericChanged($previous['battery_percent'] ?? null, $batteryPercent, 5.0);

    $historySaved = $historyIntervalElapsed || $significantChange;
    $historyReason = !$previous ? 'initial' : ($significantChange ? 'significant_change' : 'scheduled_sample');
    $readingId = null;

    $insert = $pdo->prepare(
        'INSERT INTO sensor_readings (
            monitoring_device_id, device_id, water_distance_cm, water_level_cm,
            rise_rate_cm_min, predicted_minutes_to_warning, prediction_status,
            sensor_health, rain_analog, rain_detected, wind_speed_mps,
            north_obstacle, south_obstacle, north_barrier_status,
            south_barrier_status, battery_voltage, battery_percent,
            alert_level, device_status, raw_payload, history_sample_reason
         ) VALUES (
            :monitoring_device_id, :device_uid, :water_distance, :water_level,
            :rise_rate, NULL, "unavailable", :sensor_health, :rain_analog,
            :rain_detected, :wind_speed, :north_obstacle, :south_obstacle,
            :north_barrier, :south_barrier, :battery_voltage, :battery_percent,
            :alert_level, :device_status, :raw_payload, :history_sample_reason
         )'
    );
    $values = [
        ':monitoring_device_id' => $monitoringDeviceId,
        ':device_uid' => $deviceUid,
        ':water_distance' => $waterDistance,
        ':water_level' => $waterLevel,
        ':rise_rate' => $riseRate,
        ':sensor_health' => $sensorHealth,
        ':rain_analog' => $rainAnalog,
        ':rain_detected' => $rainDetected,
        ':wind_speed' => $windSpeed,
        ':north_obstacle' => $northObstacle,
        ':south_obstacle' => $southObstacle,
        ':north_barrier' => $northBarrier,
        ':south_barrier' => $southBarrier,
        ':battery_voltage' => $batteryVoltage,
        ':battery_percent' => $batteryPercent,
        ':alert_level' => $alertLevel,
        ':device_status' => $deviceStatus,
        ':raw_payload' => $rawPayload,
        ':history_sample_reason' => $historyReason
    ];
    if ($historySaved) {
        $insert->execute($values);
        $readingId = (int) $pdo->lastInsertId();
    }

    $latestUpsert = $pdo->prepare(
        'INSERT INTO device_latest_readings (
            monitoring_device_id, sensor_reading_id, water_distance_cm,
            water_level_cm, sensor_health, rain_analog, rain_detected,
            wind_speed_mps, north_obstacle, south_obstacle,
            north_barrier_status, south_barrier_status, battery_voltage,
            battery_percent, alert_level, device_status, measured_at
         ) VALUES (
            :monitoring_device_id, :sensor_reading_id, :water_distance,
            :water_level, :sensor_health, :rain_analog, :rain_detected,
            :wind_speed, :north_obstacle, :south_obstacle,
            :north_barrier, :south_barrier, :battery_voltage,
            :battery_percent, :alert_level, :device_status, NOW()
         ) ON DUPLICATE KEY UPDATE
            sensor_reading_id=VALUES(sensor_reading_id),
            water_distance_cm=VALUES(water_distance_cm), water_level_cm=VALUES(water_level_cm),
            sensor_health=VALUES(sensor_health), rain_analog=VALUES(rain_analog),
            rain_detected=VALUES(rain_detected), wind_speed_mps=VALUES(wind_speed_mps),
            north_obstacle=VALUES(north_obstacle), south_obstacle=VALUES(south_obstacle),
            north_barrier_status=VALUES(north_barrier_status),
            south_barrier_status=VALUES(south_barrier_status),
            battery_voltage=VALUES(battery_voltage), battery_percent=VALUES(battery_percent),
            alert_level=VALUES(alert_level), device_status=VALUES(device_status),
            measured_at=VALUES(measured_at)'
    );
    $latestValues = $values;
    unset(
        $latestValues[':device_uid'],
        $latestValues[':rise_rate'],
        $latestValues[':raw_payload'],
        $latestValues[':history_sample_reason']
    );
    $latestValues[':sensor_reading_id'] = $readingId;
    $latestUpsert->execute($latestValues);

    $connectedStatus = $deviceStatus === 'maintenance' ? 'maintenance' : 'online';
    $firmwareVersion = isset($data['firmware_version'])
        ? substr(trim((string) $data['firmware_version']), 0, 50)
        : null;
    $pdo->prepare(
        'UPDATE monitoring_devices
         SET operational_status=:status, last_seen_at=NOW(),
             firmware_version=COALESCE(:firmware, firmware_version)
         WHERE id=:id'
    )->execute([':status' => $connectedStatus, ':firmware' => $firmwareVersion, ':id' => $monitoringDeviceId]);

    $queuedPushRecipients = 0;
    if (($previous && $previous['alert_level'] !== $alertLevel) || (!$previous && $alertLevel !== 'normal')) {
        addDeviceEvent($pdo, $monitoringDeviceId, $readingId, 'alert_transition',
            $alertLevel === 'critical' ? 'critical' : ($alertLevel === 'warning' ? 'warning' : 'info'),
            'Alert level changed to ' . ucfirst($alertLevel),
            ['from' => $previous['alert_level'] ?? null, 'to' => $alertLevel]);

        $pushTitle = match ($alertLevel) {
            'critical' => 'Critical Flood Alert',
            'warning' => 'Flood Warning',
            default => 'Flood Condition Cleared'
        };
        $pushBody = match ($alertLevel) {
            'critical' => 'Critical flooding has been detected near the Spillway Bridge. Avoid the area and follow official instructions.',
            'warning' => 'The Spillway Bridge monitoring station has detected a warning-level flood condition.',
            default => 'The monitored flood condition has returned to Normal.'
        };
        $queuedPushRecipients = floodguardQueueResidentPush(
            $pdo,
            'alert_transition',
            $alertLevel,
            $pushTitle,
            $pushBody,
            [
                'device_id' => $deviceUid,
                'alert_level' => $alertLevel,
                'water_level_cm' => $waterLevel,
                'measured_at' => date(DATE_ATOM)
            ]
        );
    }
    if (($previous && $previous['sensor_health'] !== $sensorHealth) ||
        (!$previous && in_array($sensorHealth, ['suspect', 'fault'], true))) {
        addDeviceEvent($pdo, $monitoringDeviceId, $readingId,
            $sensorHealth === 'fault' ? 'sensor_fault' : 'sensor_health_changed',
            $sensorHealth === 'fault' ? 'critical' : ($sensorHealth === 'suspect' ? 'warning' : 'info'),
            'Sensor health changed to ' . ucfirst($sensorHealth),
            ['from' => $previous['sensor_health'] ?? null, 'to' => $sensorHealth]);
    }
    if (in_array((string) $device['operational_status'], ['offline', 'never_connected'], true)) {
        addDeviceEvent($pdo, $monitoringDeviceId, $readingId, 'device_online', 'info', 'Monitoring station is online');
    }
    foreach (['north_barrier_status' => $northBarrier, 'south_barrier_status' => $southBarrier] as $field => $value) {
        if ($previous && $previous[$field] !== $value) {
            addDeviceEvent($pdo, $monitoringDeviceId, $readingId, 'barrier_state_changed',
                in_array($value, ['fault', 'blocked'], true) ? 'critical' : 'info',
                ucwords(str_replace('_', ' ', $field)) . ' changed',
                ['from' => $previous[$field], 'to' => $value]);
        }
    }

    $pdo->commit();

    jsonResponse(200, [
        'success' => true,
        'message' => 'Live sensor state updated successfully.',
        'reading_id' => $readingId,
        'history_saved' => $historySaved,
        'history_reason' => $historySaved ? $historyReason : null,
        'device_id' => $deviceUid,
        'alert_level' => $alertLevel,
        'previous_alert_level' => $previous['alert_level'] ?? null,
        'queued_push_recipients' => $queuedPushRecipients,
        'prediction_status' => $predictionStatus,
        'sensor_health' => $sensorHealth,
        'wind_speed_mps' => $windSpeed,
        'authentication_mode' => $authenticationMode
    ]);
} catch (InvalidArgumentException $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonResponse(422, ['success' => false, 'message' => $exception->getMessage()]);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('[FloodGuard submit_reading] ' . $exception->getMessage());
    jsonResponse(500, ['success' => false, 'message' => 'The sensor reading could not be stored.']);
}
