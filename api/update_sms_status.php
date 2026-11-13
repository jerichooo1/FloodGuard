<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'POST required.']);
    exit;
}

$deviceId = requireFloodguardDevice();
$payload = json_decode(file_get_contents('php://input') ?: '', true);

if (!is_array($payload)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON body.']);
    exit;
}

$smsId = filter_var($payload['sms_id'] ?? null, FILTER_VALIDATE_INT);
$status = strtolower(trim((string) ($payload['status'] ?? '')));
$modemResponse = trim((string) ($payload['modem_response'] ?? ''));

if (!$smsId || !in_array($status, ['sent', 'failed'], true)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Invalid SMS result.']);
    exit;
}

$modemResponse = substr($modemResponse, 0, 1000);

try {
    $updateStmt = $pdo->prepare(
        'UPDATE sms_logs
         SET
            delivery_status = :delivery_status,
            modem_response = :modem_response,
            sent_at = CASE
                WHEN :sent_status = "sent" THEN NOW()
                ELSE NULL
            END,
            message = CASE
                WHEN message_type = "otp" AND :redact_status = "sent"
                    THEN "FloodGuard phone verification code sent."
                ELSE message
            END
         WHERE id = :id
           AND delivery_status = "pending"
           AND claimed_by = :claimed_by'
    );

    $updateStmt->execute([
        ':delivery_status' => $status,
        ':modem_response' => $modemResponse !== '' ? $modemResponse : null,
        ':sent_status' => $status,
        ':redact_status' => $status,
        ':id' => (int) $smsId,
        ':claimed_by' => $deviceId
    ]);

    if ($updateStmt->rowCount() !== 1) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'The SMS is no longer assigned to this device.'
        ]);
        exit;
    }

    echo json_encode(['success' => true]);
} catch (PDOException $exception) {
    error_log('[FloodGuard update_sms_status] ' . $exception->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to update the SMS result.'
    ]);
}
