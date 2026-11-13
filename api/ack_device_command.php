<?php

declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

function finish(string $message, int $status = 200): never
{
    http_response_code($status);
    header('Content-Length: ' . strlen($message));
    echo $message;
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    finish('ERROR|POST_REQUIRED', 405);
}

$raw = file_get_contents('php://input') ?: '';
$data = str_contains(strtolower((string) ($_SERVER['CONTENT_TYPE'] ?? '')), 'application/json')
    ? (json_decode($raw, true) ?: [])
    : $_POST;

$deviceId = trim((string) ($data['device_id'] ?? $_SERVER['HTTP_X_DEVICE_ID'] ?? ''));
$commandId = filter_var($data['command_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
$resultStatus = strtolower(trim((string) ($data['status'] ?? '')));
$resultMessage = substr(trim((string) ($data['result'] ?? '')), 0, 500);

if ($deviceId === '' || $commandId === false || !in_array($resultStatus, ['completed', 'failed'], true)) {
    finish('ERROR|INVALID_REQUEST', 422);
}

try {
    $authenticatedDeviceId = requireFloodguardDevice($data);
    if (!hash_equals($authenticatedDeviceId, $deviceId)) {
        finish('ERROR|UNAUTHORIZED', 403);
    }

    $stmt = $pdo->prepare(
        'UPDATE device_commands
         SET command_status = :status, completed_at = NOW(), result_message = :result
         WHERE id = :id AND device_id = :device_id AND command_status = "claimed"'
    );
    $stmt->execute([
        ':status' => $resultStatus, ':result' => $resultMessage !== '' ? $resultMessage : controlLabel($resultStatus),
        ':id' => $commandId, ':device_id' => $deviceId
    ]);

    finish($stmt->rowCount() === 1 ? 'OK' : 'ERROR|NOT_CLAIMED', $stmt->rowCount() === 1 ? 200 : 409);
} catch (Throwable $exception) {
    error_log('[FloodGuard command acknowledgment] ' . $exception->getMessage());
    finish('ERROR|SERVER', 500);
}

function controlLabel(string $value): string
{
    return ucwords(str_replace('_', ' ', $value));
}
