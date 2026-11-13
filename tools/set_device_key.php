<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/environment.php';

$deviceId = floodguardEnv('FLOODGUARD_DEVICE_ID', 'FG-STATION-001');
$deviceKey = floodguardEnv('FLOODGUARD_DEVICE_API_KEY', '');

if (!is_string($deviceKey) || strlen($deviceKey) < 32) {
    fwrite(STDERR, "FLOODGUARD_DEVICE_API_KEY must contain at least 32 characters in .env.\n");
    exit(1);
}

$statement = $pdo->prepare(
    'UPDATE monitoring_devices
     SET api_key_hash = :api_key_hash
     WHERE device_uid = :device_uid AND is_active = 1'
);
$statement->execute([
    ':api_key_hash' => hash('sha256', $deviceKey),
    ':device_uid' => $deviceId
]);

if ($statement->rowCount() !== 1) {
    $check = $pdo->prepare(
        'SELECT api_key_hash FROM monitoring_devices
         WHERE device_uid=:device_uid AND is_active=1 LIMIT 1'
    );
    $check->execute([':device_uid' => $deviceId]);
    $currentHash = $check->fetchColumn();
    if (!is_string($currentHash) || !hash_equals($currentHash, hash('sha256', $deviceKey))) {
        fwrite(STDERR, "The active monitoring device was not found.\n");
        exit(1);
    }
}

fwrite(STDOUT, "Device credential hash updated for {$deviceId}.\n");
