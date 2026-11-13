<?php

declare(strict_types=1);

require_once __DIR__ . '/environment.php';

if (!defined('FLOODGUARD_DEVICE_ID')) {
    define('FLOODGUARD_DEVICE_ID', floodguardEnv('FLOODGUARD_DEVICE_ID', 'FG-STATION-001'));
}

if (!defined('FLOODGUARD_DEVICE_API_KEY')) {
    define('FLOODGUARD_DEVICE_API_KEY', floodguardEnv('FLOODGUARD_DEVICE_API_KEY', ''));
}

function floodguardDeviceCredentials(?array $body = null): array
{
    $headerDeviceId = (string) ($_SERVER['HTTP_X_DEVICE_ID'] ?? '');
    $headerDeviceKey = (string) ($_SERVER['HTTP_X_DEVICE_KEY'] ?? '');

    if ($headerDeviceId !== '' || $headerDeviceKey !== '') {
        return [$headerDeviceId, $headerDeviceKey, 'headers'];
    }

    if (!floodguardEnvBool('FG_DEVICE_LEGACY_CREDENTIALS', true)) {
        return ['', '', 'missing'];
    }

    return [
        (string) ($body['device_id'] ?? $_GET['device_id'] ?? ''),
        (string) ($body['device_key'] ?? $_GET['device_key'] ?? ''),
        'legacy'
    ];
}

function requireFloodguardDevice(?array $body = null, ?PDO $pdo = null): string
{
    [$deviceId, $deviceKey] = floodguardDeviceCredentials($body);

    $connection = $pdo ?? ($GLOBALS['pdo'] ?? null);
    if ($connection instanceof PDO && $deviceId !== '' && $deviceKey !== '') {
        try {
            $statement = $connection->prepare(
                'SELECT api_key_hash
                 FROM monitoring_devices
                 WHERE device_uid = :device_uid AND is_active = 1
                   AND operational_status <> "disabled"
                 LIMIT 1'
            );
            $statement->execute([':device_uid' => $deviceId]);
            $storedHash = $statement->fetchColumn();

            if (is_string($storedHash) && $storedHash !== '') {
                if (!hash_equals($storedHash, hash('sha256', $deviceKey))) {
                    floodguardRejectDevice();
                }
                return $deviceId;
            }
        } catch (PDOException $exception) {
            // Migration compatibility: use the environment credential until
            // the device registry table is installed and configured.
            if ((string) $exception->getCode() !== '42S02') {
                error_log('[FloodGuard device authentication] Registry lookup failed.');
                floodguardRejectDevice();
            }
        }
    }

    if (
        FLOODGUARD_DEVICE_API_KEY === '' ||
        !hash_equals(FLOODGUARD_DEVICE_ID, $deviceId) ||
        !hash_equals(FLOODGUARD_DEVICE_API_KEY, $deviceKey)
    ) {
        floodguardRejectDevice();
    }

    return $deviceId;
}

function floodguardRejectDevice(): never
{
    http_response_code(401);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode(['success' => false, 'message' => 'Invalid device credentials.']);
    exit;
}

