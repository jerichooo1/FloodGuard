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

// Shared monitoring-station status used by the topbar and sidebar.
$deviceId = 'FG-STATION-001';
$deviceTimeout = 180;
$deviceIsOnline = false;

try {
    $deviceSettingStmt = $pdo->query(
        "SELECT setting_value
         FROM system_settings
         WHERE setting_key = 'device_id'
         LIMIT 1"
    );

    $configuredDeviceId = $deviceSettingStmt->fetchColumn();

    if (is_string($configuredDeviceId) && $configuredDeviceId !== '') {
        $deviceId = $configuredDeviceId;
    }

    $deviceStatusStmt = $pdo->prepare(
        'SELECT
            dl.device_status,
            TIMESTAMPDIFF(
                SECOND,
                dl.measured_at,
                CURRENT_TIMESTAMP
            ) AS reading_age_seconds
         FROM monitoring_devices md
         JOIN device_latest_readings dl ON dl.monitoring_device_id = md.id
         WHERE md.device_uid = :device_id
         LIMIT 1'
    );

    $deviceStatusStmt->execute([
        ':device_id' => $deviceId
    ]);

    $latestDeviceStatus = $deviceStatusStmt->fetch(PDO::FETCH_ASSOC);

    if ($latestDeviceStatus) {
        $readingAgeSeconds = (int) (
            $latestDeviceStatus['reading_age_seconds']
            ?? PHP_INT_MAX
        );

        $deviceIsOnline =
            strtolower((string) $latestDeviceStatus['device_status']) === 'online' &&
            $readingAgeSeconds >= 0 &&
            $readingAgeSeconds <= $deviceTimeout;
    }
} catch (PDOException $exception) {
    $deviceIsOnline = false;
}

if (!function_exists('fgEscape')) {
    function fgEscape(?string $value): string
    {
        return htmlspecialchars(
            $value ?? '',
            ENT_QUOTES,
            'UTF-8'
        );
    }
}

function sensorLabel(?string $value): string
{
    if ($value === null || trim($value) === '') {
        return 'No data';
    }

    return ucwords(
        str_replace('_', ' ', $value)
    );
}

function sensorStatusClass(?string $value): string
{
    return match (strtolower((string) $value)) {
        'normal', 'online', 'open', 'path_clear', 'healthy' => 'status-normal',
        'warning', 'maintenance', 'opening', 'closing', 'suspect' => 'status-warning',
        'critical', 'sensor_error', 'closed', 'obstacle_detected', 'fault' => 'status-critical',
        default => 'status-offline'
    };
}

function sensorNumber(
    mixed $value,
    int $decimals = 1,
    string $suffix = ''
): string {
    if ($value === null || $value === '') {
        return 'No data';
    }

    return number_format(
        (float) $value,
        $decimals
    ) . $suffix;
}

function sensorBooleanLabel(mixed $value): string
{
    if ($value === null || $value === '') {
        return 'No data';
    }

    return (int) $value === 1
        ? 'Detected'
        : 'Not detected';
}

function validDateInput(string $date): bool
{
    if ($date === '') {
        return true;
    }

    $parsed = DateTime::createFromFormat('Y-m-d', $date);

    return $parsed !== false &&
        $parsed->format('Y-m-d') === $date;
}

function sensorHistoryUrl(
    int $page,
    string $alertLevel,
    string $sensorHealth,
    string $deviceStatus,
    string $dateFrom,
    string $dateTo
): string {
    $parameters = ['page' => $page];

    if ($alertLevel !== '') {
        $parameters['alert_level'] = $alertLevel;
    }

    if ($sensorHealth !== '') {
        $parameters['sensor_health'] = $sensorHealth;
    }

    if ($deviceStatus !== '') {
        $parameters['device_status'] = $deviceStatus;
    }

    if ($dateFrom !== '') {
        $parameters['date_from'] = $dateFrom;
    }

    if ($dateTo !== '') {
        $parameters['date_to'] = $dateTo;
    }

    return 'sensor_history.php?' . http_build_query($parameters);
}

/*
|--------------------------------------------------------------------------
| Filter values
|--------------------------------------------------------------------------
*/

$alertLevelFilter = trim((string) ($_GET['alert_level'] ?? ''));
$sensorHealthFilter = trim((string) ($_GET['sensor_health'] ?? ''));
$deviceStatusFilter = trim((string) ($_GET['device_status'] ?? ''));
$dateFrom = trim((string) ($_GET['date_from'] ?? ''));
$dateTo = trim((string) ($_GET['date_to'] ?? ''));

$allowedAlertLevels = [
    'normal',
    'warning',
    'critical'
];

$allowedSensorHealthStatuses = [
    'healthy',
    'suspect',
    'fault',
    'unknown'
];

$allowedDeviceStatuses = [
    'online',
    'offline',
    'sensor_error',
    'maintenance'
];

if (!in_array($alertLevelFilter, $allowedAlertLevels, true)) {
    $alertLevelFilter = '';
}

if (!in_array($sensorHealthFilter, $allowedSensorHealthStatuses, true)) {
    $sensorHealthFilter = '';
}

if (!in_array($deviceStatusFilter, $allowedDeviceStatuses, true)) {
    $deviceStatusFilter = '';
}

$filterError = '';

if (!validDateInput($dateFrom) || !validDateInput($dateTo)) {
    $filterError = 'Please enter a valid date range.';
    $dateFrom = '';
    $dateTo = '';
}

if (
    $dateFrom !== '' &&
    $dateTo !== '' &&
    $dateFrom > $dateTo
) {
    $filterError = 'The starting date cannot be later than the ending date.';
    $dateFrom = '';
    $dateTo = '';
}

/* Sensor History intentionally stores a concise operational audit trail.
   Continuous values belong on the live dashboard; this page keeps the full
   reading only when a meaningful categorical state changes. */
$changeHistoryCte = 'WITH sequenced AS (
    SELECT sr.*,
        LAG(id) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_id,
        LAG(alert_level) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_alert_level,
        LAG(sensor_health) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_sensor_health,
        LAG(rain_detected) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_rain_detected,
        LAG(device_status) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_device_status,
        LAG(north_barrier_status) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_north_barrier_status,
        LAG(south_barrier_status) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_south_barrier_status,
        LAG(north_obstacle) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_north_obstacle,
        LAG(south_obstacle) OVER (PARTITION BY device_id ORDER BY created_at,id) AS previous_south_obstacle
    FROM sensor_readings sr
    WHERE sr.device_id=:sequence_device_id
), changes AS (
    SELECT * FROM sequenced WHERE previous_id IS NULL
       OR NOT (alert_level <=> previous_alert_level)
       OR NOT (sensor_health <=> previous_sensor_health)
       OR NOT (rain_detected <=> previous_rain_detected)
       OR NOT (device_status <=> previous_device_status)
       OR NOT (north_barrier_status <=> previous_north_barrier_status)
       OR NOT (south_barrier_status <=> previous_south_barrier_status)
       OR NOT (north_obstacle <=> previous_north_obstacle)
       OR NOT (south_obstacle <=> previous_south_obstacle)
)';

$summaryCounts = ['total' => 0, 'normal' => 0, 'warning' => 0, 'critical' => 0, 'sensor_fault' => 0];
$databaseError = '';

try {
    $summaryStmt = $pdo->prepare($changeHistoryCte . '
        SELECT COUNT(*) AS total_count,
            SUM(alert_level="normal") AS normal_count,
            SUM(alert_level="warning") AS warning_count,
            SUM(alert_level="critical") AS critical_count,
            SUM(sensor_health="fault") AS sensor_fault_count
        FROM changes');
    $summaryStmt->execute([':sequence_device_id' => $deviceId]);
    $summaryRow = $summaryStmt->fetch(PDO::FETCH_ASSOC) ?: [];
    $summaryCounts = [
        'total' => (int) ($summaryRow['total_count'] ?? 0),
        'normal' => (int) ($summaryRow['normal_count'] ?? 0),
        'warning' => (int) ($summaryRow['warning_count'] ?? 0),
        'critical' => (int) ($summaryRow['critical_count'] ?? 0),
        'sensor_fault' => (int) ($summaryRow['sensor_fault_count'] ?? 0)
    ];
} catch (PDOException $exception) {
    $databaseError = 'The sensor change summary could not be loaded.';
}

function sensorChangeSummary(array $reading): string
{
    if ($reading['previous_id'] === null) return 'Initial station state recorded';

    $changes = [];
    $pairs = [
        ['Alert level', 'previous_alert_level', 'alert_level'],
        ['Sensor health', 'previous_sensor_health', 'sensor_health'],
        ['Device status', 'previous_device_status', 'device_status'],
        ['North barrier', 'previous_north_barrier_status', 'north_barrier_status'],
        ['South barrier', 'previous_south_barrier_status', 'south_barrier_status'],
    ];
    foreach ($pairs as [$label, $before, $after]) {
        if ($reading[$before] !== $reading[$after]) $changes[] = $label . ': ' . sensorLabel((string) $reading[$after]);
    }
    if ($reading['previous_rain_detected'] !== $reading['rain_detected']) $changes[] = (int) $reading['rain_detected'] === 1 ? 'Rain detected' : 'Rain cleared';
    if ($reading['previous_north_obstacle'] !== $reading['north_obstacle']) $changes[] = (int) $reading['north_obstacle'] === 1 ? 'North obstacle detected' : 'North path cleared';
    if ($reading['previous_south_obstacle'] !== $reading['south_obstacle']) $changes[] = (int) $reading['south_obstacle'] === 1 ? 'South obstacle detected' : 'South path cleared';

    return $changes ? implode(' · ', $changes) : 'Operating state updated';
}

$whereConditions = [];
$queryParameters = [':sequence_device_id' => $deviceId];

if ($alertLevelFilter !== '') {
    $whereConditions[] = 'alert_level = :alert_level';
    $queryParameters[':alert_level'] = $alertLevelFilter;
}

if ($sensorHealthFilter !== '') {
    $whereConditions[] = 'sensor_health = :sensor_health';
    $queryParameters[':sensor_health'] = $sensorHealthFilter;
}

if ($deviceStatusFilter !== '') {
    $whereConditions[] = 'device_status = :device_status';
    $queryParameters[':device_status'] = $deviceStatusFilter;
}

if ($dateFrom !== '') {
    $whereConditions[] = 'created_at >= :date_from';
    $queryParameters[':date_from'] = $dateFrom . ' 00:00:00';
}

if ($dateTo !== '') {
    $whereConditions[] = 'created_at <= :date_to';
    $queryParameters[':date_to'] = $dateTo . ' 23:59:59';
}

$whereSql = $whereConditions ? 'WHERE ' . implode(' AND ', $whereConditions) : '';

/*
|--------------------------------------------------------------------------
| Pagination
|--------------------------------------------------------------------------
*/

$currentPage = max(1, (int) ($_GET['page'] ?? 1));
$recordsPerPage = 15;
$totalFilteredRecords = 0;
$totalPages = 1;
$offset = 0;
$sensorReadings = [];

try {
    $countStmt = $pdo->prepare(
        $changeHistoryCte . " SELECT COUNT(*) FROM changes {$whereSql}"
    );

    foreach ($queryParameters as $parameter => $value) {
        $countStmt->bindValue($parameter, $value, PDO::PARAM_STR);
    }

    $countStmt->execute();

    $totalFilteredRecords = (int) $countStmt->fetchColumn();
    $totalPages = max(
        1,
        (int) ceil($totalFilteredRecords / $recordsPerPage)
    );

    if ($currentPage > $totalPages) {
        $currentPage = $totalPages;
    }

    $offset = ($currentPage - 1) * $recordsPerPage;

    $readingsStmt = $pdo->prepare(
        $changeHistoryCte . " SELECT
            id,
            device_id,
            water_distance_cm,
            water_level_cm,
            sensor_health,
            rain_analog,
            rain_detected,
            wind_speed_mps,
            north_obstacle,
            south_obstacle,
            north_barrier_status,
            south_barrier_status,
            battery_voltage,
            battery_percent,
            alert_level,
            device_status,
            raw_payload,
            created_at,
            previous_id,previous_alert_level,previous_sensor_health,previous_rain_detected,
            previous_device_status,previous_north_barrier_status,previous_south_barrier_status,
            previous_north_obstacle,previous_south_obstacle
         FROM changes
         {$whereSql}
         ORDER BY created_at DESC, id DESC
         LIMIT :record_limit
         OFFSET :record_offset"
    );

    foreach ($queryParameters as $parameter => $value) {
        $readingsStmt->bindValue($parameter, $value, PDO::PARAM_STR);
    }

    $readingsStmt->bindValue(
        ':record_limit',
        $recordsPerPage,
        PDO::PARAM_INT
    );

    $readingsStmt->bindValue(
        ':record_offset',
        $offset,
        PDO::PARAM_INT
    );

    $readingsStmt->execute();

    $sensorReadings = $readingsStmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $exception) {
    $databaseError = 'The sensor-history records could not be loaded.';
}

$pageTitle = 'Sensor History';
$pageSubtitle = 'Review meaningful sensor and operating-state changes recorded by FloodGuard.';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Sensor History | FloodGuard</title>

    <link
        rel="stylesheet"
        href="../assets/css/admin.css"
    >

    <link
        rel="stylesheet"
        href="../assets/css/sensor-history.css"
    >
    <link rel="stylesheet" href="../assets/css/history-center.css">

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    >
</head>
<body>

<?php require __DIR__ . '/includes/sidebar.php'; ?>

<div class="admin-page">

    <?php require __DIR__ . '/includes/topbar.php'; ?>

    <main class="admin-content standard-admin-page sensor-history-page">
        <?php $historyActiveTab = 'sensor'; require __DIR__ . '/includes/history_tabs.php'; ?>

        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error">
                <i class="bi bi-exclamation-circle-fill"></i>
                <span><?= fgEscape($databaseError) ?></span>
            </div>
        <?php endif; ?>

        <?php if ($filterError !== ''): ?>
            <div class="page-alert alert-warning-page">
                <i class="bi bi-calendar-x-fill"></i>
                <span><?= fgEscape($filterError) ?></span>
            </div>
        <?php endif; ?>

        <section class="sensor-statistics">

            <article class="sensor-stat-card">
                <div class="sensor-stat-icon total">
                    <i class="bi bi-database-fill"></i>
                </div>

                <div>
                    <span>Recorded Changes</span>
                    <strong><?= number_format($summaryCounts['total']) ?></strong>
                    <small>Meaningful state changes only</small>
                </div>
            </article>

            <article class="sensor-stat-card">
                <div class="sensor-stat-icon normal">
                    <i class="bi bi-check-circle-fill"></i>
                </div>

                <div>
                    <span>Normal</span>
                    <strong><?= number_format($summaryCounts['normal']) ?></strong>
                    <small>Changes ending in Normal</small>
                </div>
            </article>

            <article class="sensor-stat-card">
                <div class="sensor-stat-icon warning">
                    <i class="bi bi-exclamation-triangle-fill"></i>
                </div>

                <div>
                    <span>Warning</span>
                    <strong><?= number_format($summaryCounts['warning']) ?></strong>
                    <small>Changes ending in Warning</small>
                </div>
            </article>

            <article class="sensor-stat-card">
                <div class="sensor-stat-icon critical">
                    <i class="bi bi-shield-fill-exclamation"></i>
                </div>

                <div>
                    <span>Critical</span>
                    <strong><?= number_format($summaryCounts['critical']) ?></strong>
                    <small>Changes ending in Critical</small>
                </div>
            </article>

            <article class="sensor-stat-card">
                <div class="sensor-stat-icon fault">
                    <i class="bi bi-cpu-fill"></i>
                </div>

                <div>
                    <span>Sensor Faults</span>
                    <strong><?= number_format($summaryCounts['sensor_fault']) ?></strong>
                    <small>Confirmed sensor-fault states</small>
                </div>
            </article>

        </section>

        <section class="content-card sensor-history-card">

            <div class="content-card-header sensor-history-header">
                <div>
                    <span class="section-label">Operational Audit Trail</span>
                    <h2>Sensor State Changes</h2>
                    <p class="sensor-section-description">
                        The live dashboard handles continuous readings. This page records a snapshot only when an important operating state changes.
                    </p>
                </div>

                <span class="sensor-record-count">
                    <?= number_format($totalFilteredRecords) ?>
                    change<?= $totalFilteredRecords === 1 ? '' : 's' ?>
                </span>
            </div>

            <form method="GET" class="sensor-filters">

                <select name="alert_level" aria-label="Alert level">
                    <option value="">All Alert Levels</option>

                    <?php foreach ($allowedAlertLevels as $alertLevel): ?>
                        <option
                            value="<?= fgEscape($alertLevel) ?>"
                            <?= $alertLevelFilter === $alertLevel ? 'selected' : '' ?>
                        >
                            <?= fgEscape(sensorLabel($alertLevel)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <select name="sensor_health" aria-label="Sensor health">
                    <option value="">All Sensor Health</option>

                    <?php foreach ($allowedSensorHealthStatuses as $sensorHealth): ?>
                        <option
                            value="<?= fgEscape($sensorHealth) ?>"
                            <?= $sensorHealthFilter === $sensorHealth ? 'selected' : '' ?>
                        >
                            <?= fgEscape(sensorLabel($sensorHealth)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <select name="device_status" aria-label="Device status">
                    <option value="">All Device Statuses</option>

                    <?php foreach ($allowedDeviceStatuses as $deviceStatus): ?>
                        <option
                            value="<?= fgEscape($deviceStatus) ?>"
                            <?= $deviceStatusFilter === $deviceStatus ? 'selected' : '' ?>
                        >
                            <?= fgEscape(sensorLabel($deviceStatus)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <div class="sensor-date-field">
                    <label for="date_from">From</label>
                    <input
                        type="date"
                        id="date_from"
                        name="date_from"
                        value="<?= fgEscape($dateFrom) ?>"
                    >
                </div>

                <div class="sensor-date-field">
                    <label for="date_to">To</label>
                    <input
                        type="date"
                        id="date_to"
                        name="date_to"
                        value="<?= fgEscape($dateTo) ?>"
                    >
                </div>

                <button type="submit" class="sensor-filter-button">
                    <i class="bi bi-funnel-fill"></i>
                    Apply Filters
                </button>

                <?php if (
                    $alertLevelFilter !== '' ||
                    $sensorHealthFilter !== '' ||
                    $deviceStatusFilter !== '' ||
                    $dateFrom !== '' ||
                    $dateTo !== ''
                ): ?>
                    <a href="sensor_history.php" class="sensor-clear-filter">
                        Clear
                    </a>
                <?php endif; ?>

            </form>

            <div class="table-container sensor-table-container">
                <table class="admin-table sensor-history-table">
                    <thead>
                    <tr>
                        <th>Recorded Change</th>
                        <th>Date and Time</th>
                        <th>Water Level</th>
                        <th>Rain</th>
                        <th>Alert Level</th>
                        <th>Sensor Health</th>
                        <th aria-label="Actions"></th>
                    </tr>
                    </thead>

                    <tbody>

                    <?php if (!$sensorReadings): ?>
                        <tr>
                            <td colspan="7" class="empty-table sensor-empty-table">
                                <i class="bi bi-database-x"></i>
                                <strong>No sensor state changes found</strong>
                                <span>
                                    A record will appear when an alert, sensor, rain, device, barrier, or obstacle state changes.
                                </span>
                            </td>
                        </tr>
                    <?php else: ?>

                        <?php foreach ($sensorReadings as $reading): ?>
                            <?php
                            $recordPayload = [
                                'id' => (int) $reading['id'],
                                'device_id' => (string) $reading['device_id'],
                                'water_distance_cm' => sensorNumber($reading['water_distance_cm'], 2, ' cm'),
                                'water_level_cm' => sensorNumber($reading['water_level_cm'], 2, ' cm'),
                                // Compatibility values keep the existing modal JavaScript safe.
                                // Prediction is intentionally not shown or queried by this page.
                                'rise_rate_cm_min' => 'Not included',
                                'predicted_minutes_to_warning' => 'Not included',
                                'prediction_status' => 'Not included',
                                'prediction_status_raw' => 'unavailable',
                                'sensor_health' => sensorLabel($reading['sensor_health']),
                                'sensor_health_raw' => (string) $reading['sensor_health'],
                                'rain_analog' => $reading['rain_analog'] !== null
                                    ? number_format((int) $reading['rain_analog'])
                                    : 'No data',
                                'rain_detected' => (int) $reading['rain_detected'] === 1
                                    ? 'Rain detected'
                                    : 'No rain detected',
                                'wind_speed_mps' => sensorNumber($reading['wind_speed_mps'], 2, ' m/s'),
                                'north_obstacle' => sensorBooleanLabel($reading['north_obstacle']),
                                'south_obstacle' => sensorBooleanLabel($reading['south_obstacle']),
                                'north_barrier_status' => sensorLabel($reading['north_barrier_status']),
                                'south_barrier_status' => sensorLabel($reading['south_barrier_status']),
                                'battery_voltage' => sensorNumber($reading['battery_voltage'], 2, ' V'),
                                'battery_percent' => sensorNumber($reading['battery_percent'], 0, '%'),
                                'alert_level' => sensorLabel($reading['alert_level']),
                                'alert_level_raw' => (string) $reading['alert_level'],
                                'device_status' => sensorLabel($reading['device_status']),
                                'device_status_raw' => (string) $reading['device_status'],
                                'raw_payload' => (string) ($reading['raw_payload'] ?? ''),
                                'created_at' => date(
                                    'F j, Y g:i:s A',
                                    strtotime((string) $reading['created_at'])
                                )
                            ];

                            $encodedPayload = base64_encode(
                                json_encode(
                                    $recordPayload,
                                    JSON_UNESCAPED_UNICODE |
                                    JSON_UNESCAPED_SLASHES |
                                    JSON_THROW_ON_ERROR
                                )
                            );
                            ?>

                            <tr
                                class="sensor-reading-row"
                                tabindex="0"
                                role="button"
                                aria-label="View sensor reading <?= (int) $reading['id'] ?>"
                                data-sensor-record="<?= fgEscape($encodedPayload) ?>"
                            >
                                <td class="sensor-change-cell">
                                    <strong><?= fgEscape(sensorChangeSummary($reading)) ?></strong>
                                    <span>Full readings were captured at this moment.</span>
                                </td>

                                <td>
                                    <div class="sensor-date-cell">
                                        <strong>
                                            <?= date(
                                                'M d, Y',
                                                strtotime((string) $reading['created_at'])
                                            ) ?>
                                        </strong>

                                        <span>
                                            <?= date(
                                                'h:i:s A',
                                                strtotime((string) $reading['created_at'])
                                            ) ?>
                                        </span>
                                    </div>
                                </td>

                                <td>
                                    <div class="sensor-value-cell">
                                        <strong>
                                            <?= fgEscape(sensorNumber($reading['water_level_cm'], 1, ' cm')) ?>
                                        </strong>
                                        <span>
                                            Distance:
                                            <?= fgEscape(sensorNumber($reading['water_distance_cm'], 1, ' cm')) ?>
                                        </span>
                                    </div>
                                </td>

                                <td>
                                    <span class="sensor-rain-label <?= (int) $reading['rain_detected'] === 1 ? 'detected' : 'clear' ?>">
                                        <i class="bi <?= (int) $reading['rain_detected'] === 1 ? 'bi-cloud-rain-heavy-fill' : 'bi-cloud-sun-fill' ?>"></i>
                                        <?= (int) $reading['rain_detected'] === 1 ? 'Detected' : 'No Rain' ?>
                                    </span>
                                </td>

                                <td>
                                    <span class="status-badge <?= sensorStatusClass($reading['alert_level']) ?>">
                                        <?= fgEscape(sensorLabel($reading['alert_level'])) ?>
                                    </span>
                                </td>

                                <td>
                                    <span class="status-badge <?= sensorStatusClass($reading['sensor_health']) ?>">
                                        <?= fgEscape(sensorLabel($reading['sensor_health'])) ?>
                                    </span>
                                </td>

                                <td class="sensor-action-cell">
                                    <button
                                        type="button"
                                        class="view-sensor-button"
                                        aria-label="View sensor reading details"
                                        title="View details"
                                    >
                                        <i class="bi bi-eye-fill"></i>
                                    </button>
                                </td>
                            </tr>
                        <?php endforeach; ?>

                    <?php endif; ?>

                    </tbody>
                </table>
            </div>

            <?php if ($totalPages > 1): ?>
                <div class="sensor-pagination">
                    <div class="sensor-pagination-summary">
                        Showing
                        <?= number_format($offset + 1) ?>
                        to
                        <?= number_format(min($offset + $recordsPerPage, $totalFilteredRecords)) ?>
                        of
                        <?= number_format($totalFilteredRecords) ?>
                    </div>

                    <div class="sensor-pagination-links">
                        <?php if ($currentPage > 1): ?>
                            <a
                                href="<?= fgEscape(sensorHistoryUrl(
                                    $currentPage - 1,
                                    $alertLevelFilter,
                                    $sensorHealthFilter,
                                    $deviceStatusFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="sensor-page-button"
                                aria-label="Previous page"
                            >
                                <i class="bi bi-chevron-left"></i>
                            </a>
                        <?php endif; ?>

                        <?php
                        $startPage = max(1, $currentPage - 2);
                        $endPage = min($totalPages, $currentPage + 2);
                        ?>

                        <?php for ($page = $startPage; $page <= $endPage; $page++): ?>
                            <a
                                href="<?= fgEscape(sensorHistoryUrl(
                                    $page,
                                    $alertLevelFilter,
                                    $sensorHealthFilter,
                                    $deviceStatusFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="sensor-page-button <?= $page === $currentPage ? 'active' : '' ?>"
                            >
                                <?= $page ?>
                            </a>
                        <?php endfor; ?>

                        <?php if ($currentPage < $totalPages): ?>
                            <a
                                href="<?= fgEscape(sensorHistoryUrl(
                                    $currentPage + 1,
                                    $alertLevelFilter,
                                    $sensorHealthFilter,
                                    $deviceStatusFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="sensor-page-button"
                                aria-label="Next page"
                            >
                                <i class="bi bi-chevron-right"></i>
                            </a>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endif; ?>

        </section>

    </main>

</div>

<div class="sensor-modal" id="sensorDetailsModal" aria-hidden="true">
    <div class="sensor-modal-backdrop" data-close-sensor-modal></div>

    <section
        class="sensor-modal-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="sensorModalTitle"
    >
        <header class="sensor-modal-header">
            <div>
                <span class="sensor-modal-eyebrow">Monitoring Record</span>
                <h2 id="sensorModalTitle">Sensor Reading Details</h2>
                <p id="modalRecordedAt">—</p>
            </div>

            <button
                type="button"
                class="sensor-modal-close"
                data-close-sensor-modal
                aria-label="Close sensor details"
            >
                <i class="bi bi-x-lg"></i>
            </button>
        </header>

        <div class="sensor-modal-body">

            <div class="sensor-modal-summary">
                <div class="sensor-modal-device">
                    <div class="sensor-modal-device-icon">
                        <i class="bi bi-cpu-fill"></i>
                    </div>

                    <div>
                        <span>Monitoring Device</span>
                        <strong id="modalDeviceId">—</strong>
                        <small>Record ID: <span id="modalRecordId">—</span></small>
                    </div>
                </div>

                <div class="sensor-modal-statuses">
                    <div>
                        <span>Alert Level</span>
                        <strong id="modalAlertLevel" class="sensor-modal-pill">—</strong>
                    </div>

                    <div>
                        <span>Sensor Health</span>
                        <strong id="modalSensorHealth" class="sensor-modal-pill">—</strong>
                    </div>

                    <div>
                        <span>Device Status</span>
                        <strong id="modalDeviceStatus" class="sensor-modal-pill">—</strong>
                    </div>
                </div>
            </div>

            <section class="sensor-detail-section">
                <div class="sensor-detail-heading">
                    <i class="bi bi-water"></i>
                    <div>
                        <h3>Water Monitoring</h3>
                        <p>Ultrasonic distance and calculated water level</p>
                    </div>
                </div>

                <div class="sensor-detail-grid">
                    <div class="sensor-detail-item">
                        <span>Water Level</span>
                        <strong id="modalWaterLevel">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>Water Distance</span>
                        <strong id="modalWaterDistance">—</strong>
                    </div>
                </div>
            </section>

            <!-- Compatibility targets for the existing modal script. -->
            <div hidden aria-hidden="true">
                <strong id="modalPredictionStatus"></strong>
                <strong id="modalRiseRate"></strong>
                <strong id="modalPredictionMinutes"></strong>
                <strong id="modalPredictionLabel"></strong>
                <strong id="modalSensorHealthText"></strong>
            </div>

            <section class="sensor-detail-section">
                <div class="sensor-detail-heading">
                    <i class="bi bi-cloud-rain-heavy-fill"></i>
                    <div>
                        <h3>Weather Conditions</h3>
                        <p>Rain detection and wind measurement</p>
                    </div>
                </div>

                <div class="sensor-detail-grid three-columns">
                    <div class="sensor-detail-item">
                        <span>Rain Condition</span>
                        <strong id="modalRainDetected">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>Rain Analog Value</span>
                        <strong id="modalRainAnalog">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>Wind Speed</span>
                        <strong id="modalWindSpeed">—</strong>
                    </div>
                </div>
            </section>

            <section class="sensor-detail-section">
                <div class="sensor-detail-heading">
                    <i class="bi bi-sign-stop-fill"></i>
                    <div>
                        <h3>Bridge Safety</h3>
                        <p>Barrier positions and obstacle detection</p>
                    </div>
                </div>

                <div class="sensor-detail-grid two-by-two">
                    <div class="sensor-detail-item">
                        <span>North Barrier</span>
                        <strong id="modalNorthBarrier">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>South Barrier</span>
                        <strong id="modalSouthBarrier">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>North Obstacle</span>
                        <strong id="modalNorthObstacle">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>South Obstacle</span>
                        <strong id="modalSouthObstacle">—</strong>
                    </div>
                </div>
            </section>

            <section class="sensor-detail-section">
                <div class="sensor-detail-heading">
                    <i class="bi bi-battery-charging"></i>
                    <div>
                        <h3>Power Status</h3>
                        <p>Estimated battery voltage and percentage</p>
                    </div>
                </div>

                <div class="sensor-detail-grid">
                    <div class="sensor-detail-item">
                        <span>Battery Voltage</span>
                        <strong id="modalBatteryVoltage">—</strong>
                    </div>

                    <div class="sensor-detail-item">
                        <span>Battery Percentage</span>
                        <strong id="modalBatteryPercent">—</strong>
                    </div>
                </div>
            </section>

            <section class="sensor-detail-section raw-payload-section">
                <div class="sensor-detail-heading">
                    <i class="bi bi-code-square"></i>
                    <div>
                        <h3>Raw Device Payload</h3>
                        <p>Original payload stored with this reading</p>
                    </div>
                </div>

                <pre id="modalRawPayload">No raw payload stored.</pre>
            </section>

        </div>

        <footer class="sensor-modal-footer">
            <button
                type="button"
                class="sensor-modal-secondary-button"
                data-close-sensor-modal
            >
                Close
            </button>
        </footer>
    </section>
</div>

<script src="../assets/js/admin.js"></script>
<script src="../assets/js/sensor-history.js"></script>

</body>
</html>
