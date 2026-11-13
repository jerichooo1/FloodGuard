<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

// FloodGuard is installed in Rodriguez, Rizal, Philippines.
date_default_timezone_set('Asia/Manila');

// Use the same database session timezone for TIMESTAMP values and NOW().
try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // Continue with the database server's configured timezone.
}

/*
|--------------------------------------------------------------------------
| Helper functions
|--------------------------------------------------------------------------
*/

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

function dashboardNumber(
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

function dashboardStatusLabel(
    ?string $status
): string {
    if ($status === null || $status === '') {
        return 'No data';
    }

    return ucwords(
        str_replace('_', ' ', $status)
    );
}

function dashboardStatusClass(
    ?string $status
): string {
    return match (
        strtolower((string) $status)
    ) {
        'normal',
        'online',
        'open',
        'path_clear' =>
            'status-normal',

        'warning',
        'closing',
        'opening',
        'paused' =>
            'status-warning',

        'critical',
        'closed',
        'obstacle_detected' =>
            'status-critical',

        default =>
            'status-offline'
    };
}

function dashboardDateTime(?string $value): string
{
    if ($value === null || $value === '') {
        return 'Waiting for monitoring station';
    }

    try {
        return (new DateTimeImmutable(
            $value,
            new DateTimeZone('Asia/Manila')
        ))->format('F j, Y g:i:s A');
    } catch (Exception $exception) {
        return 'Invalid monitoring timestamp';
    }
}

/*
|--------------------------------------------------------------------------
| Load dashboard settings
|--------------------------------------------------------------------------
*/

$deviceId = 'FG-STATION-001';
$deviceTimeout = 180;
$systemLocation =
    'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal';

try {
    $dashboardSettingsStmt = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'device_id',
            'location',
            'device_offline_timeout_seconds'
         )"
    );

    $dashboardSettings =
        $dashboardSettingsStmt->fetchAll(
            PDO::FETCH_KEY_PAIR
        );

    if (!empty($dashboardSettings['device_id'])) {
        $deviceId =
            $dashboardSettings['device_id'];
    }

    if (!empty($dashboardSettings['location'])) {
        $systemLocation =
            $dashboardSettings['location'];
    }

    if (!empty($dashboardSettings['device_offline_timeout_seconds'])) {
        $deviceTimeout = max(30, (int) $dashboardSettings['device_offline_timeout_seconds']);
    }
} catch (PDOException $exception) {
    // Use defaults.
}

/*
|--------------------------------------------------------------------------
| Load real sensor readings
|--------------------------------------------------------------------------
*/

$latestReading = null;
$recentReadings = [];
$databaseError = '';

try {
    $latestReadingStmt = $pdo->prepare(
        'SELECT
            dl.*,
            md.device_uid AS device_id,
            dl.measured_at AS created_at,
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

    $latestReadingStmt->execute([
        ':device_id' => $deviceId
    ]);

    $latestReading =
        $latestReadingStmt->fetch(PDO::FETCH_ASSOC)
        ?: null;
$recentReadingsStmt = $pdo->prepare(
    'SELECT sr.*
     FROM sensor_readings sr
     WHERE sr.device_id = :device_id
       AND (
            sr.alert_level IN ("warning", "critical")
            OR sr.history_sample_reason = "significant_change"
            OR sr.id = (
                SELECT latest.id
                FROM sensor_readings latest
                WHERE latest.device_id = :latest_device_id
                ORDER BY latest.created_at DESC, latest.id DESC
                LIMIT 1
            )
       )
     ORDER BY sr.created_at DESC, sr.id DESC
     LIMIT 8'
);

$recentReadingsStmt->execute([
    ':device_id' => $deviceId,
    ':latest_device_id' => $deviceId
]);

    $recentReadings =
        $recentReadingsStmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $exception) {
    $databaseError =
        'Unable to load the latest monitoring records.';
}

/*
|--------------------------------------------------------------------------
| Device connectivity
|--------------------------------------------------------------------------
*/

$deviceIsOnline = false;
$lastUpdateText =
    'Waiting for monitoring station';

if ($latestReading) {
    $readingAgeSeconds = (int) (
        $latestReading['reading_age_seconds']
        ?? PHP_INT_MAX
    );

    $reportedOnline = strtolower(
        (string) ($latestReading['device_status'] ?? '')
    ) === 'online';

    $deviceIsOnline =
        $reportedOnline &&
        $readingAgeSeconds >= 0 &&
        $readingAgeSeconds <= $deviceTimeout;

    $lastUpdateText = dashboardDateTime(
        $latestReading['created_at'] ?? null
    );
}

/*
|--------------------------------------------------------------------------
| Resident mobile access summary
|--------------------------------------------------------------------------
*/

$residentAccounts = 0;
$pushEnabledResidents = 0;
$locationConsentResidents = 0;

try {
    $registrationStmt = $pdo->query(
        'SELECT
            COUNT(*) AS resident_count,
            SUM(rp.push_notifications_enabled = 1) AS push_enabled_count,
            SUM(rp.location_sharing_consent = 1) AS location_consent_count
         FROM resident_profiles rp
         JOIN users u ON u.id = rp.user_id
         WHERE u.account_status = "active"'
    );

    $registrationSummary =
        $registrationStmt->fetch(PDO::FETCH_ASSOC);

    $residentAccounts =
        (int) (
            $registrationSummary['resident_count']
            ?? 0
        );

    $pushEnabledResidents =
        (int) (
            $registrationSummary['push_enabled_count']
            ?? 0
        );

    $locationConsentResidents =
        (int) (
            $registrationSummary['location_consent_count']
            ?? 0
        );
} catch (PDOException $exception) {
    // Keep values at zero.
}

$alertLevel =
    $latestReading['alert_level'] ?? null;

$displayCondition = $deviceIsOnline
    ? $alertLevel
    : ($latestReading ? 'offline' : null);

$pageTitle = 'Monitoring Dashboard';
$pageSubtitle = $systemLocation;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <meta http-equiv="refresh" content="15">

    <title>Monitoring Dashboard | FloodGuard</title>

    <link
        rel="stylesheet"
        href="../assets/css/admin.css"
    >

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    >
</head>

<body>

<?php
require __DIR__ . '/includes/sidebar.php';
?>

<div class="admin-page">

    <?php
    require __DIR__ . '/includes/topbar.php';
    ?>

    <main class="admin-content">

        <?php if ($databaseError !== ''): ?>
            <div class="page-alert alert-error">
                <i class="bi bi-exclamation-circle-fill"></i>

                <span>
                    <?= fgEscape($databaseError) ?>
                </span>
            </div>
        <?php endif; ?>

        <section class="monitoring-cards">

            <article class="monitoring-card">
                <div class="monitoring-icon water">
                    <i class="bi bi-water"></i>
                </div>

                <div>
                    <span>Water Level</span>

                    <strong data-live-field="water_level_cm">
                        <?= dashboardNumber(
                            $latestReading[
                                'water_level_cm'
                            ] ?? null,
                            1,
                            ' cm'
                        ) ?>
                    </strong>

                    <small>
                        Sensor distance:
                        <span data-live-field="water_distance_cm"><?= dashboardNumber(
                            $latestReading[
                                'water_distance_cm'
                            ] ?? null,
                            1,
                            ' cm'
                        ) ?></span>
                    </small>
                </div>
            </article>

            <article class="monitoring-card">
                <div class="monitoring-icon rain">
                    <i class="bi bi-cloud-rain-heavy-fill"></i>
                </div>

                <div>
                    <span>Rain Status</span>

                    <strong data-live-field="rain_status">
                        <?php if (!$latestReading): ?>
                            No data
                        <?php else: ?>
                            <?= (int) $latestReading[
                                'rain_detected'
                            ] === 1
                                ? 'Rain Detected'
                                : 'No Rain'
                            ?>
                        <?php endif; ?>
                    </strong>

                    <small>
                        Analog reading:
                        <span data-live-field="rain_analog"><?= fgEscape(
                            isset(
                                $latestReading[
                                    'rain_analog'
                                ]
                            )
                                ? (string) $latestReading[
                                    'rain_analog'
                                ]
                                : '--'
                        ) ?></span>
                    </small>
                </div>
            </article>

            <article class="monitoring-card">
                <div class="monitoring-icon wind">
                    <i class="bi bi-wind"></i>
                </div>

                <div>
                    <span>Wind Speed</span>

                    <strong data-live-field="wind_speed_mps">
                        <?= dashboardNumber(
                            $latestReading[
                                'wind_speed_mps'
                            ] ?? null,
                            1,
                            ' m/s'
                        ) ?>
                    </strong>

                    <small>
                        Local bridge measurement
                    </small>
                </div>
            </article>

            <article class="monitoring-card">
                <div class="monitoring-icon battery">
                    <i class="bi bi-battery-half"></i>
                </div>

                <div>
                    <span>Estimated Battery</span>

                    <strong data-live-field="battery_percent">
                        <?= dashboardNumber(
                            $latestReading[
                                'battery_percent'
                            ] ?? null,
                            0,
                            '%'
                        ) ?>
                    </strong>

                    <small data-live-field="battery_voltage">
                        <?= dashboardNumber(
                            $latestReading[
                                'battery_voltage'
                            ] ?? null,
                            2,
                            ' V'
                        ) ?>
                    </small>
                </div>
            </article>

        </section>

        <section class="dashboard-main-grid">

            <article class="content-card alert-card">

                <div class="content-card-header">
                    <div>
                        <span class="section-label">
                            Current Condition
                        </span>

                        <h2>Flood Alert Level</h2>
                    </div>

                    <span data-live-field="alert_badge"
                        class="status-badge <?= dashboardStatusClass(
                            $displayCondition
                        ) ?>"
                    >
                        <?= dashboardStatusLabel(
                            $displayCondition
                        ) ?>
                    </span>
                </div>

                <div class="current-alert-display" data-live-field="condition_panel">

                    <?php if (!$latestReading): ?>
                        <i class="bi bi-hourglass-split"></i>

                        <div>
                            <strong>
                                No monitoring data received
                            </strong>

                            <p>
                                The dashboard is ready to receive
                                real sensor readings from the ESP32
                                and A7670E monitoring station.
                            </p>
                        </div>
                    <?php elseif (!$deviceIsOnline): ?>
                        <i class="bi bi-wifi-off"></i>

                        <div>
                            <strong>
                                Monitoring station offline
                            </strong>

                            <p>
                                No new sensor reading was received
                                during the last
                                <?= $deviceTimeout ?> seconds.
                                Last data received:
                                <?= fgEscape($lastUpdateText) ?>
                            </p>
                        </div>
                    <?php else: ?>
                        <i class="bi bi-broadcast-pin"></i>

                        <div>
                            <strong>
                                <?= dashboardStatusLabel(
                                    $alertLevel
                                ) ?>
                                condition detected
                            </strong>

                            <p>
                                Latest monitoring data received:
                                <?= fgEscape($lastUpdateText) ?>
                            </p>
                        </div>
                    <?php endif; ?>

                </div>

            </article>

            <article class="content-card">

                <div class="content-card-header">
                    <div>
                        <span class="section-label">
                            Mobile Application
                        </span>

                        <h2>Resident Mobile Access</h2>
                    </div>
                </div>

                <div class="summary-list">

                    <div class="summary-row">
                        <span>Active Resident Accounts</span>

                        <strong>
                            <?= $residentAccounts ?>
                        </strong>
                    </div>

                    <div class="summary-row">
                        <span>Push Notifications Enabled</span>

                        <strong>
                            <?= $pushEnabledResidents ?>
                        </strong>
                    </div>

                    <div class="summary-row">
                        <span>Location Sharing Consent</span>

                        <strong>
                            <?= $locationConsentResidents ?>
                        </strong>
                    </div>

                </div>

            </article>

        </section>

        <section class="content-card system-status-card">

            <div class="content-card-header">
                <div>
                    <span class="section-label">
                        Monitoring Station
                    </span>

                    <h2>Device and Bridge Status</h2>
                </div>

                <span data-live-field="connection_badge"
                    class="connection-pill <?= $deviceIsOnline
                        ? 'online'
                        : 'offline'
                    ?>"
                >
                    <?= $deviceIsOnline
                        ? 'Online'
                        : 'Offline'
                    ?>
                </span>
            </div>

            <div class="system-status-grid">

                <div>
                    <span>Device ID</span>
                    <strong><?= fgEscape($deviceId) ?></strong>
                </div>

                <div>
                    <span>North Barrier</span>

                    <strong data-live-field="north_barrier_status">
                        <?= dashboardStatusLabel(
                            $latestReading[
                                'north_barrier_status'
                            ] ?? null
                        ) ?>
                    </strong>
                </div>

                <div>
                    <span>South Barrier</span>

                    <strong data-live-field="south_barrier_status">
                        <?= dashboardStatusLabel(
                            $latestReading[
                                'south_barrier_status'
                            ] ?? null
                        ) ?>
                    </strong>
                </div>

                <div>
                    <span>North Obstacle</span>

                    <strong data-live-field="north_obstacle">
                        <?php if (!$latestReading): ?>
                            No data
                        <?php else: ?>
                            <?= (int) $latestReading[
                                'north_obstacle'
                            ] === 1
                                ? 'Detected'
                                : 'Path Clear'
                            ?>
                        <?php endif; ?>
                    </strong>
                </div>

                <div>
                    <span>South Obstacle</span>

                    <strong data-live-field="south_obstacle">
                        <?php if (!$latestReading): ?>
                            No data
                        <?php else: ?>
                            <?= (int) $latestReading[
                                'south_obstacle'
                            ] === 1
                                ? 'Detected'
                                : 'Path Clear'
                            ?>
                        <?php endif; ?>
                    </strong>
                </div>

                <div>
                    <span>Last Update</span>

                    <strong data-live-field="last_update">
                        <?= fgEscape($lastUpdateText) ?>
                    </strong>
                </div>

            </div>

        </section>

        <section class="content-card records-card">

            <div class="content-card-header">
                <div>
                    <span class="section-label">
                        Monitoring Records
                    </span>

                    <h2>Recent Monitoring Events</h2>
                </div>

                <a
                    href="sensor_history.php"
                    class="text-link"
                >
                    View History
                    <i class="bi bi-arrow-right"></i>
                </a>
            </div>

            <div class="table-container">
                <table class="admin-table">
                    <thead>
                    <tr>
                        <th>Date and Time</th>
                        <th>Water Level</th>
                        <th>Rain</th>
                        <th>Wind Speed</th>
                        <th>Battery</th>
                        <th>Alert Level</th>
                    </tr>
                    </thead>

                    <tbody>

                    <?php if (!$recentReadings): ?>
                        <tr>
                            <td
                                colspan="6"
                                class="empty-table"
                            >
                                <i class="bi bi-database-x"></i>

                                <strong>
                                    No sensor readings available
                                </strong>

                                <span>
                                    Real records will appear after
                                    the monitoring station submits
                                    data.
                                </span>
                            </td>
                        </tr>
                    <?php else: ?>

                        <?php foreach (
                            $recentReadings as $reading
                        ): ?>
                            <tr>
                                <td>
                                    <?= fgEscape(
                                        dashboardDateTime(
                                            $reading['created_at']
                                            ?? null
                                        )
                                    ) ?>
                                </td>

                                <td>
                                    <?= dashboardNumber(
                                        $reading[
                                            'water_level_cm'
                                        ],
                                        1,
                                        ' cm'
                                    ) ?>
                                </td>

                                <td>
                                    <?= (int) $reading[
                                        'rain_detected'
                                    ] === 1
                                        ? 'Rain Detected'
                                        : 'No Rain'
                                    ?>
                                </td>

                                <td>
                                    <?= dashboardNumber(
                                        $reading[
                                            'wind_speed_mps'
                                        ],
                                        1,
                                        ' m/s'
                                    ) ?>
                                </td>

                                <td>
                                    <?= dashboardNumber(
                                        $reading[
                                            'battery_percent'
                                        ],
                                        0,
                                        '%'
                                    ) ?>
                                </td>

                                <td>
                                    <span
                                        class="status-badge <?= dashboardStatusClass(
                                            $reading[
                                                'alert_level'
                                            ]
                                        ) ?>"
                                    >
                                        <?= dashboardStatusLabel(
                                            $reading[
                                                'alert_level'
                                            ]
                                        ) ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endforeach; ?>

                    <?php endif; ?>

                    </tbody>
                </table>
            </div>

        </section>

    </main>

</div>

<script src="../assets/js/admin.js"></script>

</body>
</html>
