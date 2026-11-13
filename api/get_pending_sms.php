<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'GET required.']);
    exit;
}

$deviceId = requireFloodguardDevice();

try {
    $pdo->beginTransaction();

    $pdo->exec(
        'UPDATE sms_logs AS sms
         LEFT JOIN pending_phone_verifications AS pending
            ON pending.id = sms.verification_id
         SET
            sms.delivery_status = "failed",
            sms.modem_response = "OTP expired or verification request removed."
         WHERE sms.delivery_status = "pending"
           AND sms.message_type = "otp"
           AND (
                pending.id IS NULL OR
                pending.otp_expires_at <= NOW()
           )'
    );

    $smsStmt = $pdo->query(
        'SELECT
            id,
            mobile_number,
            message,
            message_type
         FROM sms_logs
         WHERE delivery_status = "pending"
           AND (
                claimed_at IS NULL OR
                claimed_at < DATE_SUB(NOW(), INTERVAL 2 MINUTE)
           )
         ORDER BY created_at ASC, id ASC
         LIMIT 1
         FOR UPDATE'
    );

    $sms = $smsStmt->fetch(PDO::FETCH_ASSOC) ?: null;

    if ($sms === null) {
        $pdo->commit();

        echo json_encode([
            'success' => true,
            'sms' => null
        ], JSON_UNESCAPED_SLASHES);
        exit;
    }

    $claimStmt = $pdo->prepare(
        'UPDATE sms_logs
         SET
            claimed_by = :claimed_by,
            claimed_at = NOW(),
            attempt_count = attempt_count + 1,
            modem_response = NULL
         WHERE id = :id
           AND delivery_status = "pending"'
    );

    $claimStmt->execute([
        ':claimed_by' => $deviceId,
        ':id' => (int) $sms['id']
    ]);

    if ($claimStmt->rowCount() !== 1) {
        throw new RuntimeException('The queued SMS could not be claimed.');
    }

    $pdo->commit();

    $localNumber = (string) $sms['mobile_number'];
    $internationalNumber = preg_match('/^09\d{9}$/', $localNumber)
        ? '+63' . substr($localNumber, 1)
        : $localNumber;

    echo json_encode([
        'success' => true,
        'sms' => [
            'id' => (int) $sms['id'],
            'mobile_number' => $internationalNumber,
            'message' => (string) $sms['message'],
            'message_type' => (string) $sms['message_type']
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('[FloodGuard get_pending_sms] ' . $exception->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Unable to load the SMS queue.'
    ]);
}
