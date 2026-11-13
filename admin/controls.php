<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

date_default_timezone_set('Asia/Manila');

try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // Continue with the database server's configured timezone.
}

if (!function_exists('fgEscape')) {
    function fgEscape(?string $value): string
    {
        return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
    }
}

function controlLabel(string $value): string
{
    return ucwords(str_replace('_', ' ', $value));
}

function controlStatusClass(string $status): string
{
    return match ($status) {
        'completed' => 'status-normal',
        'pending', 'claimed' => 'status-warning',
        'failed' => 'status-critical',
        default => 'status-offline'
    };
}

function jsonReply(int $status, array $payload): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

$deviceId = 'FG-STATION-001';
$deviceTimeout = 180;
$deviceIsOnline = false;
$latestDeviceStatus = 'offline';
$latestReading = null;
$databaseError = '';

try {
    $settingStmt = $pdo->query(
        "SELECT setting_value FROM system_settings WHERE setting_key = 'device_id' LIMIT 1"
    );
    $configuredDeviceId = $settingStmt->fetchColumn();

    if (is_string($configuredDeviceId) && trim($configuredDeviceId) !== '') {
        $deviceId = trim($configuredDeviceId);
    }

    $readingStmt = $pdo->prepare(
        'SELECT dl.sensor_reading_id AS id, dl.device_status, dl.sensor_health,
                dl.alert_level, dl.water_level_cm, dl.battery_voltage,
                dl.battery_percent, dl.measured_at AS created_at,
                TIMESTAMPDIFF(SECOND, dl.measured_at, CURRENT_TIMESTAMP) AS reading_age_seconds
         FROM monitoring_devices md
         JOIN device_latest_readings dl ON dl.monitoring_device_id = md.id
         WHERE md.device_uid = :device_id
         LIMIT 1'
    );
    $readingStmt->execute([':device_id' => $deviceId]);
    $latestReading = $readingStmt->fetch(PDO::FETCH_ASSOC) ?: null;

    if ($latestReading) {
        $age = (int) ($latestReading['reading_age_seconds'] ?? PHP_INT_MAX);
        $latestDeviceStatus = strtolower(
            trim((string) ($latestReading['device_status'] ?? 'offline'))
        );
        $deviceIsOnline =
            in_array($latestDeviceStatus, ['online', 'maintenance'], true) &&
            $age >= 0 &&
            $age <= $deviceTimeout;
    }
} catch (PDOException $exception) {
    $databaseError = 'The monitoring-station status could not be loaded.';
}

if (empty($_SESSION['device_control_csrf'])) {
    $_SESSION['device_control_csrf'] = bin2hex(random_bytes(32));
}

$csrfToken = (string) $_SESSION['device_control_csrf'];

$commands = [
    'siren_on' => [
        'label' => 'Turn Siren On',
        'description' => 'Activates the siren with a 60-second firmware safety limit.',
        'icon' => 'bi-volume-up-fill',
        'duration_ms' => 60000,
        'expires_seconds' => 120
    ],
    'siren_off' => [
        'label' => 'Turn Siren Off',
        'description' => 'Stops the siren immediately.',
        'icon' => 'bi-volume-mute-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'siren_test' => [
        'label' => 'Test Siren for 3 Seconds',
        'description' => 'Runs a short siren test without changing the flood alert level.',
        'icon' => 'bi-soundwave',
        'duration_ms' => 3000,
        'expires_seconds' => 120
    ],
    'play_voice' => [
        'label' => 'Play Voice Alert',
        'description' => 'Plays 0001.mp3 through the DFPlayer Mini.',
        'icon' => 'bi-megaphone-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'stop_audio' => [
        'label' => 'Stop Voice Alert',
        'description' => 'Stops DFPlayer playback.',
        'icon' => 'bi-stop-circle-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'maintenance_on' => [
        'label' => 'Enable Maintenance Mode',
        'description' => 'Marks the station as under maintenance while hardware is tested.',
        'icon' => 'bi-tools',
        'duration_ms' => 0,
        'expires_seconds' => 180
    ],
    'maintenance_off' => [
        'label' => 'Disable Maintenance Mode',
        'description' => 'Returns the station to normal automatic monitoring.',
        'icon' => 'bi-check-circle-fill',
        'duration_ms' => 0,
        'expires_seconds' => 180
    ],
    'request_reading' => [
        'label' => 'Request Sensor Reading',
        'description' => 'Requests an immediate sensor upload from the ESP32.',
        'icon' => 'bi-arrow-repeat',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'barrier_open' => [
        'label' => 'Open Both Barriers',
        'description' => 'Opens the North and South barriers when both obstacle paths are clear.',
        'icon' => 'bi-unlock-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'barrier_close' => [
        'label' => 'Close Both Barriers',
        'description' => 'Closes the North and South barriers when both obstacle paths are clear.',
        'icon' => 'bi-lock-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ],
    'barrier_stop' => [
        'label' => 'Stop Both Barriers',
        'description' => 'Stops barrier movement and holds the current servo positions.',
        'icon' => 'bi-stop-circle-fill',
        'duration_ms' => 0,
        'expires_seconds' => 120
    ]
];

$canIssueDeviceCommands = isset($currentPermissions['device_commands.issue']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $isAjax = strtolower((string) ($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '')) === 'xmlhttprequest';

    if (!$canIssueDeviceCommands) {
        $message = 'Your administrator role can inspect command history but cannot issue operational device commands.';
        if ($isAjax) {
            jsonReply(403, ['success' => false, 'message' => $message]);
        }
        $_SESSION['device_control_flash'] = ['type' => 'error', 'message' => $message];
        header('Location: controls.php');
        exit;
    }

    try {
        $submittedToken = (string) ($_POST['csrf_token'] ?? '');

        if (!hash_equals($csrfToken, $submittedToken)) {
            throw new RuntimeException('The control request expired. Refresh the page and try again.');
        }

        $commandType = trim((string) ($_POST['command_type'] ?? ''));

        if (!array_key_exists($commandType, $commands)) {
            throw new RuntimeException('Invalid device command.');
        }

        if (!$deviceIsOnline) {
            throw new RuntimeException('The station is offline. Commands cannot be queued safely.');
        }

        if (
            $latestDeviceStatus === 'maintenance' &&
            !in_array($commandType, ['maintenance_off', 'request_reading'], true)
        ) {
            throw new RuntimeException(
                'Maintenance Mode is enabled. Disable it before using hardware controls.'
            );
        }

        if (
            $commandType === 'maintenance_on' &&
            $latestDeviceStatus === 'maintenance'
        ) {
            throw new RuntimeException('Maintenance Mode is already enabled.');
        }

        $definition = $commands[$commandType];
        $expiresAt = (new DateTimeImmutable('now'))
            ->modify('+' . (int) $definition['expires_seconds'] . ' seconds')
            ->format('Y-m-d H:i:s');
        $parameters = json_encode([
            'duration_ms' => $definition['duration_ms'],
            'audio_file' => $commandType === 'play_voice' ? 1 : null
        ], JSON_UNESCAPED_SLASHES);

        $pdo->beginTransaction();

        $pdo->prepare(
            'UPDATE device_commands
             SET command_status = "expired", completed_at = NOW(),
                 result_message = "Command expired before device retrieval."
             WHERE device_id = :device_id
               AND command_status IN ("pending", "claimed")
               AND expires_at <= NOW()'
        )->execute([':device_id' => $deviceId]);

        $insertStmt = $pdo->prepare(
            'INSERT INTO device_commands (
                device_id, command_type, parameters_json, command_status,
                requested_by, expires_at
             ) VALUES (
                :device_id, :command_type, :parameters_json, "pending",
                :requested_by, :expires_at
             )'
        );
        $insertStmt->bindValue(':device_id', $deviceId);
        $insertStmt->bindValue(':command_type', $commandType);
        $insertStmt->bindValue(':parameters_json', $parameters);
        $insertStmt->bindValue(':requested_by', (int) $_SESSION['admin_id'], PDO::PARAM_INT);
        $insertStmt->bindValue(':expires_at', $expiresAt);
        $insertStmt->execute();

        $commandId = (int) $pdo->lastInsertId();
        $pdo->commit();

        $message = $definition['label'] . ' was queued for the monitoring station.';
        $_SESSION['device_control_flash'] = ['type' => 'success', 'message' => $message];

        if ($isAjax) {
            jsonReply(201, ['success' => true, 'message' => $message, 'command_id' => $commandId]);
        }
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        $_SESSION['device_control_flash'] = ['type' => 'error', 'message' => $exception->getMessage()];

        if ($isAjax) {
            jsonReply(422, ['success' => false, 'message' => $exception->getMessage()]);
        }
    }

    header('Location: controls.php');
    exit;
}

$flashMessage = $_SESSION['device_control_flash'] ?? null;
unset($_SESSION['device_control_flash']);

$commandCounts = ['pending' => 0, 'completed' => 0, 'failed' => 0];
$commandHistory = [];
$maintenanceEnabled = false;

try {
    $countStmt = $pdo->prepare(
        'SELECT
            SUM(command_status IN ("pending", "claimed")) AS pending_count,
            SUM(command_status = "completed") AS completed_count,
            SUM(command_status = "failed") AS failed_count
         FROM device_commands
         WHERE device_id = :device_id'
    );
    $countStmt->execute([':device_id' => $deviceId]);
    $countRow = $countStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $commandCounts = [
        'pending' => (int) ($countRow['pending_count'] ?? 0),
        'completed' => (int) ($countRow['completed_count'] ?? 0),
        'failed' => (int) ($countRow['failed_count'] ?? 0)
    ];

    $historyStmt = $pdo->prepare(
        'SELECT dc.*, COALESCE(a.full_name, "Administrator") AS requested_by_name
         FROM device_commands dc
         LEFT JOIN admins a ON a.id = dc.requested_by
         WHERE dc.device_id = :device_id
         ORDER BY dc.id DESC
         LIMIT 20'
    );
    $historyStmt->execute([':device_id' => $deviceId]);
    $commandHistory = $historyStmt->fetchAll(PDO::FETCH_ASSOC);

    $maintenanceStmt = $pdo->prepare(
        'SELECT command_type
         FROM device_commands
         WHERE device_id = :device_id
           AND command_status = "completed"
           AND command_type IN ("maintenance_on", "maintenance_off")
         ORDER BY completed_at DESC, id DESC
         LIMIT 1'
    );
    $maintenanceStmt->execute([':device_id' => $deviceId]);
    $latestMaintenanceCommand = $maintenanceStmt->fetchColumn();
    $maintenanceEnabled = $latestMaintenanceCommand !== false
        ? $latestMaintenanceCommand === 'maintenance_on'
        : $latestDeviceStatus === 'maintenance';
} catch (PDOException $exception) {
    $databaseError = 'Run device_commands.sql before using the Device Controls page.';
}

$pageTitle = 'Device Controls';
$pageSubtitle = 'Safely manage connected FloodGuard warning hardware.';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Device Controls | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="../assets/css/device-controls.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/sidebar.php'; ?>

<div class="admin-page">
    <?php require __DIR__ . '/includes/topbar.php'; ?>

    <main class="admin-content standard-admin-page device-controls-page">
        <?php if (is_array($flashMessage)): ?>
            <div class="page-alert <?= ($flashMessage['type'] ?? '') === 'success' ? 'alert-success' : 'alert-error' ?>">
                <i class="bi <?= ($flashMessage['type'] ?? '') === 'success' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill' ?>"></i>
                <span><?= fgEscape((string) ($flashMessage['message'] ?? '')) ?></span>
            </div>
        <?php endif; ?>

        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error"><i class="bi bi-database-exclamation"></i><span><?= fgEscape($databaseError) ?></span></div>
        <?php endif; ?>

        <?php if (!$canIssueDeviceCommands): ?>
            <div class="page-alert alert-error"><i class="bi bi-shield-lock-fill"></i><span>Administrator access is read-only on this page. Operational commands are restricted to authorized Barangay Personnel.</span></div>
        <?php endif; ?>

        <section class="control-overview">
            <article class="control-overview-card station">
                <span class="control-overview-icon"><i class="bi bi-broadcast-pin"></i></span>
                <div><small>Monitoring Station</small><strong><?= $deviceIsOnline ? 'Online' : 'Offline' ?></strong><span><?= fgEscape($deviceId) ?></span></div>
                <span class="control-state-dot <?= $deviceIsOnline ? 'online' : 'offline' ?>"></span>
            </article>
            <article class="control-overview-card">
                <span class="control-overview-icon maintenance"><i class="bi bi-tools"></i></span>
                <div><small>Maintenance Mode</small><strong><?= $maintenanceEnabled ? 'Enabled' : 'Disabled' ?></strong><span>Administrative testing state</span></div>
            </article>
            <article class="control-overview-card">
                <span class="control-overview-icon pending"><i class="bi bi-hourglass-split"></i></span>
                <div><small>Queued Commands</small><strong><?= number_format($commandCounts['pending']) ?></strong><span>Waiting or being processed</span></div>
            </article>
            <article class="control-overview-card">
                <span class="control-overview-icon completed"><i class="bi bi-check-circle-fill"></i></span>
                <div><small>Completed Commands</small><strong><?= number_format($commandCounts['completed']) ?></strong><span><?= number_format($commandCounts['failed']) ?> failed</span></div>
            </article>
        </section>

        <section class="content-card control-panel-card">
            <div class="content-card-header control-panel-header">
                <div><span class="section-label">Manual Hardware Control</span><h2>Connected Devices</h2><p>Commands expire quickly and are accepted only while the station is online.</p></div>
                <span class="control-online-badge <?= $deviceIsOnline && $canIssueDeviceCommands ? 'online' : 'offline' ?>"><?= !$canIssueDeviceCommands ? 'Read-only access' : ($deviceIsOnline ? 'Controls Available' : 'Station Offline') ?></span>
            </div>

            <div class="control-groups">
                <article class="control-device-card danger">
                    <div class="control-device-heading"><span><i class="bi bi-volume-up-fill"></i></span><div><h3>Emergency Siren</h3><p>12 V siren connected through the relay module.</p></div></div>
                    <div class="control-actions">
                        <?php foreach (['siren_on', 'siren_off', 'siren_test'] as $type): $command = $commands[$type]; ?>
                            <button type="button" class="control-command-button <?= $type === 'siren_on' ? 'danger' : ($type === 'siren_off' ? 'secondary' : 'warning') ?>" data-command="<?= fgEscape($type) ?>" data-title="<?= fgEscape($command['label']) ?>" data-description="<?= fgEscape($command['description']) ?>" <?= !$canIssueDeviceCommands || !$deviceIsOnline || $maintenanceEnabled || $databaseError !== '' ? 'disabled' : '' ?>><i class="bi <?= fgEscape($command['icon']) ?>"></i><span><?= fgEscape($command['label']) ?></span></button>
                        <?php endforeach; ?>
                    </div>
                    <p class="control-safety-note"><i class="bi bi-shield-exclamation"></i> Siren On automatically stops after 60 seconds in the firmware.</p>
                </article>

                <article class="control-device-card audio">
                    <div class="control-device-heading"><span><i class="bi bi-megaphone-fill"></i></span><div><h3>Voice Alert</h3><p>DFPlayer Mini using the single 0001.mp3 recording.</p></div></div>
                    <div class="control-actions">
                        <?php foreach (['play_voice', 'stop_audio'] as $type): $command = $commands[$type]; ?>
                            <button type="button" class="control-command-button <?= $type === 'stop_audio' ? 'secondary' : 'primary' ?>" data-command="<?= fgEscape($type) ?>" data-title="<?= fgEscape($command['label']) ?>" data-description="<?= fgEscape($command['description']) ?>" <?= !$canIssueDeviceCommands || !$deviceIsOnline || $maintenanceEnabled || $databaseError !== '' ? 'disabled' : '' ?>><i class="bi <?= fgEscape($command['icon']) ?>"></i><span><?= fgEscape($command['label']) ?></span></button>
                        <?php endforeach; ?>
                    </div>
                </article>

                <article class="control-device-card system">
                    <div class="control-device-heading"><span><i class="bi bi-sliders"></i></span><div><h3>Station Operations</h3><p>Maintenance state and immediate sensor upload.</p></div></div>
                    <div class="control-actions">
                        <?php foreach (['maintenance_on', 'maintenance_off', 'request_reading'] as $type):
                            $command = $commands[$type];
                            $operationDisabled =
                                !$canIssueDeviceCommands ||
                                !$deviceIsOnline ||
                                $databaseError !== '' ||
                                ($type === 'maintenance_on' && $maintenanceEnabled) ||
                                ($type === 'maintenance_off' && !$maintenanceEnabled);
                        ?>
                            <button type="button" class="control-command-button <?= str_contains($type, '_off') ? 'secondary' : 'primary' ?>" data-command="<?= fgEscape($type) ?>" data-title="<?= fgEscape($command['label']) ?>" data-description="<?= fgEscape($command['description']) ?>" <?= $operationDisabled ? 'disabled' : '' ?>><i class="bi <?= fgEscape($command['icon']) ?>"></i><span><?= fgEscape($command['label']) ?></span></button>
                        <?php endforeach; ?>
                    </div>
                </article>

                <article class="control-device-card system">
                    <div class="control-device-heading"><span><i class="bi bi-sign-stop-fill"></i></span><div><h3>Bridge Barriers</h3><p>North and South servos with obstacle-protected movement.</p></div></div>
                    <div class="control-actions">
                        <?php foreach (['barrier_open', 'barrier_close', 'barrier_stop'] as $type):
                            $command = $commands[$type];
                            $barrierDisabled = !$canIssueDeviceCommands || !$deviceIsOnline || $databaseError !== '';
                        ?>
                            <button type="button" class="control-command-button <?= $type === 'barrier_stop' ? 'secondary' : ($type === 'barrier_close' ? 'danger' : 'primary') ?>" data-command="<?= fgEscape($type) ?>" data-title="<?= fgEscape($command['label']) ?>" data-description="<?= fgEscape($command['description']) ?>" <?= $barrierDisabled ? 'disabled' : '' ?>><i class="bi <?= fgEscape($command['icon']) ?>"></i><span><?= fgEscape($command['label']) ?></span></button>
                        <?php endforeach; ?>
                    </div>
                    <p class="control-safety-note"><i class="bi bi-shield-exclamation"></i> Movement is rejected or stopped when either obstacle sensor is blocked or has no valid echo.</p>
                </article>
            </div>
        </section>

        <section class="content-card command-history-card">
            <div class="content-card-header command-history-header"><div><span class="section-label">Administrative Audit Trail</span><h2>Recent Commands</h2><p>Latest commands requested by FloodGuard administrators.</p></div><span class="command-count"><?= count($commandHistory) ?> shown</span></div>
            <div class="command-table-container">
                <table class="admin-table command-history-table">
                    <thead><tr><th>Requested</th><th>Command</th><th>Administrator</th><th>Status</th><th>Completed</th><th aria-label="View details"></th></tr></thead>
                    <tbody>
                    <?php if (!$commandHistory): ?>
                        <tr><td colspan="6" class="command-empty"><i class="bi bi-terminal"></i><strong>No commands recorded</strong><span>Device-control activity will appear here.</span></td></tr>
                    <?php else: foreach ($commandHistory as $item):
                        $details = json_encode([
                            'id' => (int) $item['id'], 'command' => controlLabel((string) $item['command_type']),
                            'status' => controlLabel((string) $item['command_status']),
                            'requested_by' => (string) $item['requested_by_name'],
                            'requested_at' => date('M d, Y h:i:s A', strtotime((string) $item['requested_at'])),
                            'claimed_at' => $item['claimed_at'] ? date('M d, Y h:i:s A', strtotime((string) $item['claimed_at'])) : 'Not claimed',
                            'completed_at' => $item['completed_at'] ? date('M d, Y h:i:s A', strtotime((string) $item['completed_at'])) : 'Not completed',
                            'expires_at' => date('M d, Y h:i:s A', strtotime((string) $item['expires_at'])),
                            'result' => (string) ($item['result_message'] ?: 'No device response recorded.')
                        ], JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?: '{}';
                    ?>
                        <tr class="command-row" tabindex="0" data-command-details="<?= fgEscape($details) ?>">
                            <td><strong><?= date('M d, Y', strtotime((string) $item['requested_at'])) ?></strong><span><?= date('h:i:s A', strtotime((string) $item['requested_at'])) ?></span></td>
                            <td><?= fgEscape(controlLabel((string) $item['command_type'])) ?></td>
                            <td><?= fgEscape((string) $item['requested_by_name']) ?></td>
                            <td><span class="status-badge <?= controlStatusClass((string) $item['command_status']) ?>"><?= fgEscape(controlLabel((string) $item['command_status'])) ?></span></td>
                            <td><?= $item['completed_at'] ? date('M d, h:i A', strtotime((string) $item['completed_at'])) : '—' ?></td>
                            <td><button type="button" class="view-command-button" aria-label="View command details"><i class="bi bi-eye-fill"></i></button></td>
                        </tr>
                    <?php endforeach; endif; ?>
                    </tbody>
                </table>
            </div>
        </section>
    </main>
</div>

<div class="control-confirmation" id="controlConfirmation" aria-hidden="true">
    <div class="control-confirmation-backdrop" data-control-close></div>
    <section class="control-confirmation-dialog" role="alertdialog" aria-modal="true" aria-labelledby="controlConfirmTitle">
        <span class="control-confirmation-icon"><i class="bi bi-sliders"></i></span><h2 id="controlConfirmTitle">Confirm command</h2><p id="controlConfirmDescription">Review the command before sending it.</p>
        <div class="control-confirmation-station"><span>Target station</span><strong><?= fgEscape($deviceId) ?></strong></div>
        <div class="control-confirmation-actions"><button type="button" class="control-cancel-button" data-control-close>Cancel</button><button type="button" class="control-submit-button" id="controlConfirmSubmit"><i class="bi bi-send-fill"></i> Send Command</button></div>
    </section>
</div>

<dialog class="command-details-dialog" id="commandDetailsDialog">
    <header><div><span class="section-label">Command Details</span><h2 id="detailsCommand">Device Command</h2></div><button type="button" data-details-close aria-label="Close"><i class="bi bi-x-lg"></i></button></header>
    <dl><div><dt>Command ID</dt><dd id="detailsId">—</dd></div><div><dt>Status</dt><dd id="detailsStatus">—</dd></div><div><dt>Requested By</dt><dd id="detailsRequestedBy">—</dd></div><div><dt>Requested At</dt><dd id="detailsRequestedAt">—</dd></div><div><dt>Claimed At</dt><dd id="detailsClaimedAt">—</dd></div><div><dt>Completed At</dt><dd id="detailsCompletedAt">—</dd></div><div><dt>Expires At</dt><dd id="detailsExpiresAt">—</dd></div></dl>
    <div class="command-result"><span>Device Result</span><p id="detailsResult">—</p></div>
</dialog>

<form method="POST" id="deviceCommandForm" hidden><input type="hidden" name="csrf_token" value="<?= fgEscape($csrfToken) ?>"><input type="hidden" name="command_type" id="deviceCommandType"></form>
<script src="../assets/js/admin.js"></script>
<script src="../assets/js/device-controls.js"></script>
</body>
</html>
