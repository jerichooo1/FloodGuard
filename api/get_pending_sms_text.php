<?php

declare(strict_types=1);

header('Content-Type: text/plain; charset=utf-8');
header('Cache-Control: no-store');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/device_api.php';

function plainResponse(string $body, int $statusCode = 200): never
{
    http_response_code($statusCode);
    header('Content-Length: ' . strlen($body));
    echo $body;
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    plainResponse('ERROR|GET_REQUIRED', 405);
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
        'SELECT id, mobile_number, message, message_type
         FROM sms_logs
         WHERE delivery_status = "pending"
           AND (
                claimed_at IS NULL OR
                claimed_at < DATE_SUB(NOW(), INTERVAL 2 MINUTE)
           )
         ORDER BY
            CASE WHEN message_type = "otp" THEN 0 ELSE 1 END,
            created_at ASC,
            id ASC
         LIMIT 1
         FOR UPDATE'
    );

    $sms = $smsStmt->fetch(PDO::FETCH_ASSOC) ?: null;

    if ($sms === null) {
        $pdo->commit();
        plainResponse('EMPTY');
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
        throw new RuntimeException('Unable to claim the queued SMS.');
    }

    $pdo->commit();

    $number = (string) $sms['mobile_number'];
    if (preg_match('/^09\d{9}$/', $number)) {
        $number = '+63' . substr($number, 1);
    }

    // Pipes and line breaks are protocol separators, so remove them from
    // administrator-written messages before sending the compact response.
    $message = preg_replace('/[|\r\n]+/', ' ', (string) $sms['message']);
    $message = trim((string) preg_replace('/\s+/', ' ', $message));

    $response =
        'FGSMS|' . (int) $sms['id'] . '|' . $number . '|' . $message;
    plainResponse($response);
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('[FloodGuard get_pending_sms_text] ' . $exception->getMessage());
    plainResponse('ERROR|QUEUE_FAILURE', 500);
}
