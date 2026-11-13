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

function settingsEscape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function settingsBool(array $settings, string $key, bool $default = false): bool
{
    if (!array_key_exists($key, $settings)) {
        return $default;
    }

    return in_array(strtolower((string) $settings[$key]), ['1', 'true', 'yes', 'on'], true);
}

function saveSetting(PDO $pdo, string $key, string $value): void
{
    $existsStatement = $pdo->prepare(
        'SELECT 1 FROM system_settings WHERE setting_key = :setting_key LIMIT 1'
    );
    $existsStatement->execute([':setting_key' => $key]);

    if ($existsStatement->fetchColumn()) {
        $statement = $pdo->prepare(
            'UPDATE system_settings
             SET setting_value = :setting_value
             WHERE setting_key = :setting_key'
        );
    } else {
        $statement = $pdo->prepare(
            'INSERT INTO system_settings (setting_key, setting_value)
             VALUES (:setting_key, :setting_value)'
        );
    }

    $statement->execute([
        ':setting_key' => $key,
        ':setting_value' => $value
    ]);
}

function settingsInteger(
    array $input,
    string $key,
    int $minimum,
    int $maximum,
    string $label
): int {
    $value = filter_var($input[$key] ?? null, FILTER_VALIDATE_INT);

    if ($value === false || $value < $minimum || $value > $maximum) {
        throw new InvalidArgumentException(
            "{$label} must be between {$minimum} and {$maximum}."
        );
    }

    return (int) $value;
}

function settingsDecimal(
    array $input,
    string $key,
    float $minimum,
    float $maximum,
    string $label
): float {
    $value = $input[$key] ?? null;

    if (!is_numeric($value)) {
        throw new InvalidArgumentException("{$label} must be numeric.");
    }

    $number = (float) $value;

    if ($number < $minimum || $number > $maximum) {
        throw new InvalidArgumentException(
            "{$label} must be between {$minimum} and {$maximum}."
        );
    }

    return $number;
}

$defaults = [
    'device_id' => 'FG-STATION-001',
    'offline_timeout_seconds' => '90',
    'dashboard_refresh_seconds' => '30',
    'sensor_height_cm' => '43.18',
    'warning_level_cm' => '15',
    'critical_level_cm' => '25',
    'rain_warning_threshold' => '1200',
    'rain_critical_threshold' => '600',
    'wind_warning_mps' => '10',
    'wind_critical_mps' => '20',
    'push_delivery_enabled' => '1',
    'push_provider' => 'firebase',
    'push_max_attempts' => '3'
];

$settings = $defaults;
$databaseReady = true;
$databaseError = '';
$flashMessage = $_SESSION['settings_flash'] ?? null;
unset($_SESSION['settings_flash']);

try {
    $statement = $pdo->query('SELECT setting_key, setting_value FROM system_settings');

    foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $key = (string) ($row['setting_key'] ?? '');

        if ($key !== '') {
            $settings[$key] = (string) ($row['setting_value'] ?? '');
        }
    }
} catch (PDOException $exception) {
    $databaseReady = false;
    $databaseError = 'Run system_settings.sql before using the System Settings page.';
}

if (empty($_SESSION['settings_csrf'])) {
    $_SESSION['settings_csrf'] = bin2hex(random_bytes(32));
}

$csrfToken = (string) $_SESSION['settings_csrf'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!$databaseReady) {
            throw new RuntimeException('The settings database is not ready.');
        }

        $submittedToken = (string) ($_POST['csrf_token'] ?? '');

        if (!hash_equals($csrfToken, $submittedToken)) {
            throw new RuntimeException('The form expired. Refresh the page and try again.');
        }

        $section = (string) ($_POST['settings_section'] ?? '');
        $updates = [];

        if ($section === 'general') {
            $systemName = trim((string) ($_POST['system_name'] ?? ''));
            $stationName = trim((string) ($_POST['station_name'] ?? ''));
            $stationLocation = trim((string) ($_POST['station_location'] ?? ''));
            $deviceId = strtoupper(trim((string) ($_POST['device_id'] ?? '')));

            if ($systemName === '' || mb_strlen($systemName) > 100) {
                throw new InvalidArgumentException('System name is required and must not exceed 100 characters.');
            }

            if ($stationName === '' || mb_strlen($stationName) > 120) {
                throw new InvalidArgumentException('Station name is required and must not exceed 120 characters.');
            }

            if ($stationLocation === '' || mb_strlen($stationLocation) > 255) {
                throw new InvalidArgumentException('Station location is required and must not exceed 255 characters.');
            }

            if (!preg_match('/^[A-Z0-9][A-Z0-9-]{2,49}$/', $deviceId)) {
                throw new InvalidArgumentException('Device ID may contain only uppercase letters, numbers, and hyphens.');
            }

            $updates = [
                'system_name' => $systemName,
                'station_name' => $stationName,
                'station_location' => $stationLocation,
                'device_id' => $deviceId
            ];
        } elseif ($section === 'monitoring') {
            $offlineTimeout = settingsInteger($_POST, 'offline_timeout_seconds', 30, 600, 'Offline timeout');
            $refreshSeconds = settingsInteger($_POST, 'dashboard_refresh_seconds', 5, 300, 'Dashboard refresh interval');
            $sensorHeight = settingsDecimal($_POST, 'sensor_height_cm', 10, 500, 'Sensor height');
            $warningLevel = settingsDecimal($_POST, 'warning_level_cm', 0, $sensorHeight, 'Warning level');
            $criticalLevel = settingsDecimal($_POST, 'critical_level_cm', 0, $sensorHeight, 'Critical level');
            $rainWarning = settingsInteger($_POST, 'rain_warning_threshold', 0, 4095, 'Rain warning threshold');
            $rainCritical = settingsInteger($_POST, 'rain_critical_threshold', 0, 4095, 'Rain critical threshold');
            $windWarning = settingsDecimal($_POST, 'wind_warning_mps', 0, 100, 'Wind warning threshold');
            $windCritical = settingsDecimal($_POST, 'wind_critical_mps', 0, 100, 'Wind critical threshold');

            if ($criticalLevel <= $warningLevel) {
                throw new InvalidArgumentException('Critical level must be greater than the Warning level.');
            }

            if ($rainCritical >= $rainWarning) {
                throw new InvalidArgumentException('Critical rain value must be lower than the Warning rain value.');
            }

            if ($windCritical <= $windWarning) {
                throw new InvalidArgumentException('Critical wind speed must be greater than the Warning wind speed.');
            }

            $updates = [
                'offline_timeout_seconds' => (string) $offlineTimeout,
                'device_offline_timeout_seconds' => (string) $offlineTimeout,
                'dashboard_refresh_seconds' => (string) $refreshSeconds,
                'sensor_height_cm' => number_format($sensorHeight, 2, '.', ''),
                'warning_level_cm' => number_format($warningLevel, 1, '.', ''),
                'critical_level_cm' => number_format($criticalLevel, 1, '.', ''),
                'rain_warning_threshold' => (string) $rainWarning,
                'rain_critical_threshold' => (string) $rainCritical,
                'wind_warning_mps' => number_format($windWarning, 1, '.', ''),
                'wind_critical_mps' => number_format($windCritical, 1, '.', '')
            ];
        } elseif ($section === 'notifications') {
            $maxAttempts = settingsInteger(
                $_POST,
                'push_max_attempts',
                1,
                10,
                'Maximum delivery attempts'
            );

            $updates = [
                'push_delivery_enabled' => isset($_POST['push_delivery_enabled']) ? '1' : '0',
                'push_provider' => 'firebase',
                'push_max_attempts' => (string) $maxAttempts
            ];
        } else {
            throw new InvalidArgumentException('Invalid settings section.');
        }

        $pdo->beginTransaction();

        foreach ($updates as $key => $value) {
            saveSetting($pdo, $key, $value);
        }

        $pdo->commit();

        $_SESSION['settings_flash'] = [
            'type' => 'success',
            'message' => 'Settings saved successfully.'
        ];
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        $_SESSION['settings_flash'] = [
            'type' => 'error',
            'message' => $exception->getMessage()
        ];
    }

    header('Location: settings.php');
    exit;
}

$deviceIsOnline = false;
$latestReadingAt = null;

if ($databaseReady) {
    try {
        $latestStatement = $pdo->prepare(
            'SELECT dl.measured_at AS created_at,
                    TIMESTAMPDIFF(SECOND, dl.measured_at, CURRENT_TIMESTAMP) AS reading_age_seconds,
                    dl.device_status
             FROM monitoring_devices md
             JOIN device_latest_readings dl ON dl.monitoring_device_id = md.id
             WHERE md.device_uid = :device_id
             LIMIT 1'
        );
        $latestStatement->execute([':device_id' => $settings['device_id']]);
        $latest = $latestStatement->fetch(PDO::FETCH_ASSOC) ?: null;

        if ($latest) {
            $age = (int) ($latest['reading_age_seconds'] ?? PHP_INT_MAX);
            $timeout = (int) $settings['offline_timeout_seconds'];
            $deviceIsOnline =
                strtolower((string) $latest['device_status']) === 'online' &&
                $age >= 0 &&
                $age <= $timeout;
            $latestReadingAt = (string) $latest['created_at'];
        }
    } catch (PDOException $exception) {
        // The settings form remains available even if no sensor reading exists.
    }
}

$pageTitle = 'System Settings';
$pageSubtitle = 'Configure FloodGuard monitoring, push alerts, and station information.';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Settings | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="../assets/css/system-settings.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/sidebar.php'; ?>

<div class="admin-page">
    <?php require __DIR__ . '/includes/topbar.php'; ?>

    <main class="admin-content standard-admin-page system-settings-page">
        <?php if (is_array($flashMessage)): ?>
            <div class="page-alert <?= ($flashMessage['type'] ?? '') === 'success' ? 'alert-success' : 'alert-error' ?>">
                <i class="bi <?= ($flashMessage['type'] ?? '') === 'success' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill' ?>"></i>
                <span><?= settingsEscape((string) ($flashMessage['message'] ?? '')) ?></span>
            </div>
        <?php endif; ?>

        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error">
                <i class="bi bi-database-exclamation"></i>
                <span><?= settingsEscape($databaseError) ?></span>
            </div>
        <?php endif; ?>

        <section class="settings-overview" aria-label="System summary">
            <article class="settings-overview-card">
                <span class="settings-overview-icon blue"><i class="bi bi-broadcast-pin"></i></span>
                <div><small>Monitoring Station</small><strong><?= $deviceIsOnline ? 'Online' : 'Offline' ?></strong><span><?= settingsEscape($settings['device_id']) ?></span></div>
                <span class="settings-state-dot <?= $deviceIsOnline ? 'online' : 'offline' ?>"></span>
            </article>
            <article class="settings-overview-card">
                <span class="settings-overview-icon purple"><i class="bi bi-water"></i></span>
                <div><small>Water Thresholds</small><strong><?= settingsEscape($settings['warning_level_cm']) ?> / <?= settingsEscape($settings['critical_level_cm']) ?> cm</strong><span>Warning / Critical</span></div>
            </article>
            <article class="settings-overview-card">
                <span class="settings-overview-icon green"><i class="bi bi-cloud-rain-heavy-fill"></i></span>
                <div><small>Rain Thresholds</small><strong><?= settingsEscape($settings['rain_warning_threshold']) ?> / <?= settingsEscape($settings['rain_critical_threshold']) ?></strong><span>Warning / Critical raw values</span></div>
            </article>
            <article class="settings-overview-card">
                <span class="settings-overview-icon amber"><i class="bi bi-wind"></i></span>
                <div><small>Wind Thresholds</small><strong><?= settingsEscape($settings['wind_warning_mps']) ?> / <?= settingsEscape($settings['wind_critical_mps']) ?> m/s</strong><span>Warning / Critical</span></div>
            </article>
        </section>

        <div class="settings-layout">
            <nav class="settings-navigation" aria-label="Settings sections">
                <button type="button" class="settings-nav-button is-active" data-settings-target="monitoring-settings"><i class="bi bi-activity"></i><span><strong>Monitoring</strong><small>Timing and sensor thresholds</small></span></button>
                <button type="button" class="settings-nav-button" data-settings-target="notification-settings"><i class="bi bi-bell-fill"></i><span><strong>Push Notifications</strong><small>Mobile alert delivery</small></span></button>
                <button type="button" class="settings-nav-button" data-settings-target="hardware-settings"><i class="bi bi-cpu-fill"></i><span><strong>Hardware</strong><small>Prototype configuration</small></span></button>
            </nav>

            <div class="settings-content">
                <section class="content-card settings-panel" id="monitoring-settings">
                    <div class="settings-panel-header"><div><span class="section-label">Sensor Configuration</span><h2>Monitoring Settings</h2><p>Configure dashboard timing and Warning/Critical thresholds for water, rain, and wind.</p></div><span class="settings-panel-icon purple"><i class="bi bi-activity"></i></span></div>
                    <form method="POST" class="settings-form" data-settings-form>
                        <input type="hidden" name="csrf_token" value="<?= settingsEscape($csrfToken) ?>">
                        <input type="hidden" name="settings_section" value="monitoring">
                        <div class="settings-field-grid">
                            <label class="settings-field"><span>Offline Timeout</span><div class="settings-input-suffix"><input type="number" name="offline_timeout_seconds" min="30" max="600" required value="<?= settingsEscape($settings['offline_timeout_seconds']) ?>"><em>seconds</em></div><small>No upload within this period means Offline.</small></label>
                            <label class="settings-field"><span>Dashboard Refresh</span><div class="settings-input-suffix"><input type="number" name="dashboard_refresh_seconds" min="5" max="300" required value="<?= settingsEscape($settings['dashboard_refresh_seconds']) ?>"><em>seconds</em></div><small>How often the dashboard requests current data.</small></label>
                            <label class="settings-field"><span>Sensor Height</span><div class="settings-input-suffix"><input type="number" name="sensor_height_cm" min="10" max="500" step="0.01" required value="<?= settingsEscape($settings['sensor_height_cm']) ?>"><em>cm</em></div><small>Ultrasonic sensor height above the reference point.</small></label>
                            <label class="settings-field"><span>Warning Water Level</span><div class="settings-input-suffix"><input type="number" name="warning_level_cm" min="0" max="500" step="0.1" required value="<?= settingsEscape($settings['warning_level_cm']) ?>"><em>cm</em></div><small>Level that starts Warning status.</small></label>
                            <label class="settings-field"><span>Critical Water Level</span><div class="settings-input-suffix"><input type="number" name="critical_level_cm" min="0" max="500" step="0.1" required value="<?= settingsEscape($settings['critical_level_cm']) ?>"><em>cm</em></div><small>Must be higher than the Warning level.</small></label>
                            <label class="settings-field"><span>Rain Warning Threshold</span><div class="settings-input-suffix"><input type="number" name="rain_warning_threshold" min="0" max="4095" required value="<?= settingsEscape($settings['rain_warning_threshold']) ?>"><em>raw</em></div><small>Warning when the analog reading is at or below this value.</small></label>
                            <label class="settings-field"><span>Rain Critical Threshold</span><div class="settings-input-suffix"><input type="number" name="rain_critical_threshold" min="0" max="4095" required value="<?= settingsEscape($settings['rain_critical_threshold']) ?>"><em>raw</em></div><small>Must be lower than the Warning value.</small></label>
                            <label class="settings-field"><span>Wind Warning Threshold</span><div class="settings-input-suffix"><input type="number" name="wind_warning_mps" min="0" max="100" step="0.1" required value="<?= settingsEscape($settings['wind_warning_mps']) ?>"><em>m/s</em></div><small>Wind speed that starts Warning status.</small></label>
                            <label class="settings-field"><span>Wind Critical Threshold</span><div class="settings-input-suffix"><input type="number" name="wind_critical_mps" min="0" max="100" step="0.1" required value="<?= settingsEscape($settings['wind_critical_mps']) ?>"><em>m/s</em></div><small>Must be higher than the Warning speed.</small></label>
                        </div>
                        
                        <div class="settings-form-actions"><button type="reset" class="settings-reset-button">Reset</button><button type="submit" class="settings-save-button" <?= !$databaseReady ? 'disabled' : '' ?>><i class="bi bi-check2-circle"></i> Save Monitoring Settings</button></div>
                    </form>
                </section>

                <section class="content-card settings-panel" id="notification-settings">
                    <div class="settings-panel-header"><div><span class="section-label">Resident Mobile Alerts</span><h2>Push Notifications</h2><p>Manage Firebase delivery of warning and critical alerts to registered resident devices.</p></div><span class="settings-panel-icon green"><i class="bi bi-bell-fill"></i></span></div>
                    <form method="POST" class="settings-form" data-settings-form>
                        <input type="hidden" name="csrf_token" value="<?= settingsEscape($csrfToken) ?>">
                        <input type="hidden" name="settings_section" value="notifications">
                        <div class="settings-toggle-list">
                            <label class="settings-toggle-row"><span><strong>Firebase Push Delivery</strong><small>Send automatic warning, critical, and recovery alerts to eligible resident devices.</small></span><input type="checkbox" name="push_delivery_enabled" value="1" <?= settingsBool($settings, 'push_delivery_enabled', true) ? 'checked' : '' ?>><i aria-hidden="true"></i></label>
                        </div>
                        <div class="settings-field-grid settings-timing-grid">
                            <label class="settings-field"><span>Provider</span><input type="text" value="Firebase Cloud Messaging" readonly><small>The configured Android push provider.</small></label>
                            <label class="settings-field"><span>Maximum Delivery Attempts</span><div class="settings-input-suffix"><input type="number" name="push_max_attempts" min="1" max="10" required value="<?= settingsEscape($settings['push_max_attempts']) ?>"><em>attempts</em></div><small>Failed deliveries remain eligible for this many scheduled attempts.</small></label>
                        </div>
                        <div class="settings-info"><i class="bi bi-info-circle-fill"></i><p>Only active residents who enabled notifications and registered a valid device token receive push alerts. Delivery results appear in Notification History.</p></div>
                        <div class="settings-form-actions"><button type="reset" class="settings-reset-button">Reset</button><button type="submit" class="settings-save-button" <?= !$databaseReady ? 'disabled' : '' ?>><i class="bi bi-check2-circle"></i> Save Push Settings</button></div>
                    </form>
                </section>

                <section class="content-card settings-panel" id="hardware-settings">
                    <div class="settings-panel-header"><div><span class="section-label">Prototype Hardware</span><h2>Connected Components</h2><p>Read-only summary of the FloodGuard station configuration.</p></div><span class="settings-panel-icon amber"><i class="bi bi-cpu-fill"></i></span></div>
                    <div class="hardware-settings-grid">
                        <article><span class="hardware-icon"><i class="bi bi-router-fill"></i></span><div><strong>A7670E LTE Modem</strong><small>Cellular telemetry and website uploads</small></div><em class="hardware-ready">Configured</em></article>
                        <article><span class="hardware-icon"><i class="bi bi-megaphone-fill"></i></span><div><strong>DFPlayer Mini</strong><small>Single 0001.mp3 voice recording</small></div><em class="hardware-ready">Configured</em></article>
                        <article><span class="hardware-icon"><i class="bi bi-volume-up-fill"></i></span><div><strong>12 V Emergency Siren</strong><small>Relay-controlled warning output</small></div><em class="hardware-ready">Configured</em></article>
                        <article><span class="hardware-icon"><i class="bi bi-sign-stop-fill"></i></span><div><strong>Bridge Barriers</strong><small>North and south servos with obstacle protection</small></div><em class="hardware-ready">Configured</em></article>
                    </div>
                    <div class="hardware-footer"><span><i class="bi bi-clock-history"></i> Latest reading</span><strong><?= $latestReadingAt ? date('M d, Y h:i:s A', strtotime($latestReadingAt)) : 'No reading available' ?></strong></div>
                </section>
            </div>
        </div>
    </main>
</div>

<div class="settings-unsaved" id="settingsUnsaved" aria-hidden="true">
    <i class="bi bi-pencil-square"></i><span>You have unsaved changes.</span>
</div>

<script src="../assets/js/admin.js"></script>
<script src="../assets/js/system-settings.js"></script>
</body>
</html>
