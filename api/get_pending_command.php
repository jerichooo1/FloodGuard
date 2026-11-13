<?php

declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

function stop(string $message, int $status = 200): never
{
    http_response_code($status);
    header('Content-Length: ' . strlen($message));
    echo $message;
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    stop('ERROR|GET_REQUIRED', 405);
}

$deviceId = requireFloodguardDevice();

try {
    $pdo->beginTransaction();

    $pdo->prepare(
        'UPDATE device_commands
         SET command_status = "expired", completed_at = NOW(),
             result_message = "Command expired before device retrieval."
         WHERE device_id = :device_id
           AND command_status IN ("pending", "claimed")
           AND expires_at <= NOW()'
    )->execute([':device_id' => $deviceId]);

    $commandStmt = $pdo->prepare(
        'SELECT id, command_type, parameters_json
         FROM device_commands
         WHERE device_id = :device_id
           AND command_status = "pending"
           AND expires_at > NOW()
         ORDER BY id ASC
         LIMIT 1
         FOR UPDATE'
    );
    $commandStmt->execute([':device_id' => $deviceId]);
    $command = $commandStmt->fetch(PDO::FETCH_ASSOC);

    if (!$command) {
        $pdo->commit();
        stop('NONE');
    }

    $pdo->prepare(
        'UPDATE device_commands
         SET command_status = "claimed", claimed_at = NOW()
         WHERE id = :id'
    )->execute([':id' => $command['id']]);

    $pdo->commit();
    $parameters = json_decode((string) ($command['parameters_json'] ?? '{}'), true) ?: [];
    $duration = max(0, (int) ($parameters['duration_ms'] ?? 0));
    $audioFile = max(0, (int) ($parameters['audio_file'] ?? 0));
    stop('COMMAND|' . (int) $command['id'] . '|' . $command['command_type'] . '|' . $duration . '|' . $audioFile);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('[FloodGuard command queue] ' . $exception->getMessage());
    stop('ERROR|SERVER', 500);
}
