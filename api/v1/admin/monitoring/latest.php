<?php

declare(strict_types=1);

require_once __DIR__ . '/../../../../config/database.php';
require_once __DIR__ . '/../../../../app/Support/Security.php';
require_once __DIR__ . '/../../../../app/Auth/Authorization.php';
require_once __DIR__ . '/../../../../app/Http/JsonResponse.php';

floodguardStartSecureSession();
if (empty($_SESSION['user_id']) || empty($_SESSION['user_logged_in'])) {
    floodguardJsonResponse(401, ['success' => false, 'message' => 'Authentication required.']);
}
if (!floodguardUserCan($pdo, (int) $_SESSION['user_id'], 'system_health.view')) {
    floodguardJsonResponse(403, ['success' => false, 'message' => 'Permission denied.']);
}

try {
    $pollAfter = (int) ($pdo->query(
        "SELECT setting_value FROM system_settings
         WHERE setting_key='authenticated_poll_seconds' LIMIT 1"
    )->fetchColumn() ?: 5);
    $pollAfter = max(3, min(60, $pollAfter));
    $offlineTimeout = (int) ($pdo->query(
        "SELECT setting_value FROM system_settings
         WHERE setting_key='device_offline_timeout_seconds' LIMIT 1"
    )->fetchColumn() ?: 180);
    $offlineTimeout = max(30, min(3600, $offlineTimeout));

    $statement = $pdo->query(
        'SELECT md.device_uid, md.station_name, md.operational_status,
                md.is_active, md.firmware_version, md.last_seen_at,
                dl.*, TIMESTAMPDIFF(SECOND, md.last_seen_at, NOW()) AS age_seconds
         FROM monitoring_devices md
         LEFT JOIN device_latest_readings dl ON dl.monitoring_device_id=md.id
         ORDER BY md.station_name'
    );
    $devices = $statement->fetchAll(PDO::FETCH_ASSOC);
    foreach ($devices as &$device) {
        unset($device['monitoring_device_id']);
        $device['is_active'] = (bool) $device['is_active'];
        $device['age_seconds'] = $device['age_seconds'] === null ? null : (int) $device['age_seconds'];
    }
    unset($device);

    floodguardJsonResponse(200, [
        'success' => true,
        'data' => $devices,
        'poll_after_seconds' => $pollAfter,
        'offline_timeout_seconds' => $offlineTimeout,
        'server_time' => date(DATE_ATOM)
    ]);
} catch (Throwable $exception) {
    error_log('[FloodGuard admin latest monitoring] ' . $exception->getMessage());
    floodguardJsonResponse(500, ['success' => false, 'message' => 'Unable to load device monitoring information.']);
}
