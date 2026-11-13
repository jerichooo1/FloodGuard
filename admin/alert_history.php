<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

date_default_timezone_set('Asia/Manila');

try {
    $pdo->exec("SET time_zone = '+08:00'");
} catch (PDOException $exception) {
    // Continue using the database server's configured timezone.
}

if (!function_exists('fgEscape')) {
    function fgEscape(?string $value): string
    {
        return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
    }
}

function alertHistoryLabel(string $value): string
{
    return ucwords(str_replace('_', ' ', $value));
}

function alertHistoryStatusClass(string $severity): string
{
    return match ($severity) {
        'normal' => 'status-normal',
        'warning' => 'status-warning',
        'critical' => 'status-critical',
        default => 'status-offline'
    };
}

function alertHistoryIcon(string $eventType): string
{
    return match ($eventType) {
        'warning' => 'bi-exclamation-triangle-fill',
        'critical' => 'bi-shield-fill-exclamation',
        'recovery' => 'bi-check-circle-fill',
        'sensor_fault' => 'bi-cpu-fill',
        'sensor_restored' => 'bi-tools',
        'station_offline' => 'bi-wifi-off',
        'station_online' => 'bi-broadcast-pin',
        default => 'bi-bell-fill'
    };
}

function alertHistoryNumber(mixed $value, int $decimals = 1, string $suffix = ''): string
{
    if ($value === null || $value === '') {
        return 'No data';
    }

    return number_format((float) $value, $decimals) . $suffix;
}

function alertHistoryValidDate(string $date): bool
{
    if ($date === '') {
        return true;
    }

    $parsed = DateTimeImmutable::createFromFormat('!Y-m-d', $date);

    return $parsed !== false && $parsed->format('Y-m-d') === $date;
}

function alertHistoryUrl(
    int $page,
    string $search,
    string $eventType,
    string $severity,
    string $dateFrom,
    string $dateTo
): string {
    $parameters = ['page' => $page];

    foreach ([
        'search' => $search,
        'event_type' => $eventType,
        'severity' => $severity,
        'date_from' => $dateFrom,
        'date_to' => $dateTo
    ] as $key => $value) {
        if ($value !== '') {
            $parameters[$key] = $value;
        }
    }

    return 'alert_history.php?' . http_build_query($parameters);
}

function alertHistoryAddEvent(
    array &$events,
    array $reading,
    string $eventType,
    string $severity,
    string $title,
    string $description,
    ?DateTimeImmutable $occurredAt = null
): void {
    $recordedAt = $occurredAt ?? new DateTimeImmutable(
        (string) $reading['created_at'],
        new DateTimeZone('Asia/Manila')
    );

    $events[] = [
        'event_key' => $eventType . '-' . (string) $reading['id'] . '-' . $recordedAt->getTimestamp(),
        'reading_id' => (int) $reading['id'],
        'device_id' => (string) $reading['device_id'],
        'event_type' => $eventType,
        'severity' => $severity,
        'title' => $title,
        'description' => $description,
        'water_level_cm' => $reading['water_level_cm'],
        'sensor_health' => (string) ($reading['sensor_health'] ?? 'unknown'),
        'device_status' => (string) ($reading['device_status'] ?? 'offline'),
        'created_at' => $recordedAt->format('Y-m-d H:i:s'),
        'timestamp' => $recordedAt->getTimestamp()
    ];
}

/*
|--------------------------------------------------------------------------
| Recorded transition events
|--------------------------------------------------------------------------
*/

$deviceId = 'FG-STATION-001';
$databaseError = '';
$allEvents = [];

try {
    $deviceSettingStmt = $pdo->query(
        "SELECT setting_value
         FROM system_settings
         WHERE setting_key = 'device_id'
         LIMIT 1"
    );

    $configuredDeviceId = $deviceSettingStmt->fetchColumn();

    if (is_string($configuredDeviceId) && trim($configuredDeviceId) !== '') {
        $deviceId = trim($configuredDeviceId);
    }
} catch (PDOException $exception) {
    // Use the default device ID when settings are not available.
}

try {
    $eventsStmt = $pdo->prepare(
        'SELECT
            de.id,
            de.sensor_reading_id,
            de.event_type,
            de.severity,
            de.title,
            de.details_json,
            de.occurred_at,
            md.device_uid,
            COALESCE(sr.water_level_cm, dl.water_level_cm) AS water_level_cm,
            COALESCE(sr.wind_speed_mps, dl.wind_speed_mps) AS wind_speed_mps,
            COALESCE(sr.rain_analog, dl.rain_analog) AS rain_analog,
            COALESCE(sr.rain_detected, dl.rain_detected, 0) AS rain_detected,
            COALESCE(sr.sensor_health, dl.sensor_health, "unknown") AS sensor_health,
            COALESCE(sr.device_status, dl.device_status, "offline") AS device_status
         FROM device_events de
         JOIN monitoring_devices md ON md.id = de.monitoring_device_id
         LEFT JOIN sensor_readings sr ON sr.id = de.sensor_reading_id
         LEFT JOIN device_latest_readings dl ON dl.monitoring_device_id = md.id
         WHERE md.device_uid = :device_id
           AND de.event_type IN (
               "alert_transition", "sensor_fault", "sensor_health_changed",
               "device_offline", "device_online"
           )
         ORDER BY de.occurred_at DESC, de.id DESC'
    );

    $eventsStmt->execute([':device_id' => $deviceId]);

    foreach ($eventsStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $details = json_decode((string) ($row['details_json'] ?? ''), true);
        $details = is_array($details) ? $details : [];
        $storedType = (string) $row['event_type'];
        $eventType = $storedType;
        $severity = (string) $row['severity'];
        $description = 'A confirmed FloodGuard monitoring state change was recorded.';

        if ($storedType === 'alert_transition') {
            $to = strtolower((string) ($details['to'] ?? 'normal'));
            $eventType = $to === 'normal' ? 'recovery' : $to;
            $severity = $to === 'critical' ? 'critical' : ($to === 'warning' ? 'warning' : 'normal');
            $description = 'Alert level changed from ' .
                alertHistoryLabel((string) ($details['from'] ?? 'not recorded')) . ' to ' .
                alertHistoryLabel($to) . '.';
        } elseif ($storedType === 'sensor_health_changed') {
            $eventType = 'sensor_restored';
            $severity = 'normal';
            $description = 'Sensor health changed to ' .
                alertHistoryLabel((string) ($details['to'] ?? 'healthy')) . '.';
        } elseif ($storedType === 'device_offline') {
            $eventType = 'station_offline';
            $severity = 'critical';
            $description = 'The station exceeded the confirmed offline timeout.';
        } elseif ($storedType === 'device_online') {
            $eventType = 'station_online';
            $severity = 'normal';
            $description = 'The monitoring station resumed transmitting live data.';
        } elseif ($storedType === 'sensor_fault') {
            $description = 'The monitoring station reported a confirmed sensor fault.';
        }

        $timestamp = strtotime((string) $row['occurred_at']) ?: time();
        $allEvents[] = [
            'event_key' => 'device-event-' . (int) $row['id'],
            'reading_id' => (int) ($row['sensor_reading_id'] ?? 0),
            'device_id' => (string) $row['device_uid'],
            'event_type' => $eventType,
            'severity' => $severity,
            'title' => (string) $row['title'],
            'description' => $description,
            'water_level_cm' => $row['water_level_cm'],
            'wind_speed_mps' => $row['wind_speed_mps'],
            'rain_analog' => $row['rain_analog'],
            'rain_detected' => (int) $row['rain_detected'],
            'sensor_health' => (string) $row['sensor_health'],
            'device_status' => (string) $row['device_status'],
            'created_at' => (string) $row['occurred_at'],
            'timestamp' => $timestamp
        ];
    }
} catch (PDOException $exception) {
    $databaseError = 'The alert-history records could not be loaded.';
}

/*
|--------------------------------------------------------------------------
| Summary and filters
|--------------------------------------------------------------------------
*/

$summaryCounts = [
    'total' => count($allEvents),
    'warning' => 0,
    'critical' => 0,
    'sensor_fault' => 0,
    'recovery' => 0
];

foreach ($allEvents as $event) {
    if ($event['event_type'] === 'warning') {
        $summaryCounts['warning']++;
    }
    if ($event['event_type'] === 'critical') {
        $summaryCounts['critical']++;
    }
    if ($event['event_type'] === 'sensor_fault') {
        $summaryCounts['sensor_fault']++;
    }
    if (in_array($event['event_type'], ['recovery', 'sensor_restored', 'station_online'], true)) {
        $summaryCounts['recovery']++;
    }
}

$search = trim((string) ($_GET['search'] ?? ''));
$eventTypeFilter = trim((string) ($_GET['event_type'] ?? ''));
$severityFilter = trim((string) ($_GET['severity'] ?? ''));
$dateFrom = trim((string) ($_GET['date_from'] ?? ''));
$dateTo = trim((string) ($_GET['date_to'] ?? ''));
$filterError = '';

$allowedEventTypes = [
    'warning',
    'critical',
    'recovery',
    'sensor_fault',
    'sensor_restored',
    'station_offline',
    'station_online'
];
$allowedSeverities = ['normal', 'warning', 'critical'];

if (!in_array($eventTypeFilter, $allowedEventTypes, true)) {
    $eventTypeFilter = '';
}

if (!in_array($severityFilter, $allowedSeverities, true)) {
    $severityFilter = '';
}

if (!alertHistoryValidDate($dateFrom) || !alertHistoryValidDate($dateTo)) {
    $filterError = 'Please enter a valid date range.';
    $dateFrom = '';
    $dateTo = '';
} elseif ($dateFrom !== '' && $dateTo !== '' && $dateFrom > $dateTo) {
    $filterError = 'The starting date cannot be later than the ending date.';
    $dateFrom = '';
    $dateTo = '';
}

$filteredEvents = array_values(array_filter(
    $allEvents,
    static function (array $event) use (
        $search,
        $eventTypeFilter,
        $severityFilter,
        $dateFrom,
        $dateTo
    ): bool {
        if ($eventTypeFilter !== '' && $event['event_type'] !== $eventTypeFilter) {
            return false;
        }

        if ($severityFilter !== '' && $event['severity'] !== $severityFilter) {
            return false;
        }

        $eventDate = substr((string) $event['created_at'], 0, 10);

        if ($dateFrom !== '' && $eventDate < $dateFrom) {
            return false;
        }

        if ($dateTo !== '' && $eventDate > $dateTo) {
            return false;
        }

        if ($search !== '') {
            $haystack = strtolower(implode(' ', [
                $event['title'],
                $event['description'],
                $event['event_type'],
                $event['severity'],
                $event['sensor_health']
            ]));

            if (!str_contains($haystack, strtolower($search))) {
                return false;
            }
        }

        return true;
    }
));

$recordsPerPage = 12;
$totalFilteredRecords = count($filteredEvents);
$totalPages = max(1, (int) ceil($totalFilteredRecords / $recordsPerPage));
$currentPage = min(max(1, (int) ($_GET['page'] ?? 1)), $totalPages);
$offset = ($currentPage - 1) * $recordsPerPage;
$pageEvents = array_slice($filteredEvents, $offset, $recordsPerPage);

$pageTitle = 'Alert History';
$pageSubtitle = 'Review flood alerts, sensor faults, recoveries, and station interruptions.';

// Prefer the normal FloodGuard assets folder, but also support placing the
// page-specific stylesheet beside alert_history.php during local testing.
$alertHistoryCssFile = __DIR__ . '/../assets/css/alert-history.css';
$alertHistoryCssUrl = '../assets/css/alert-history.css';

if (!is_file($alertHistoryCssFile) && is_file(__DIR__ . '/alert-history.css')) {
    $alertHistoryCssFile = __DIR__ . '/alert-history.css';
    $alertHistoryCssUrl = 'alert-history.css';
}

$alertHistoryCssVersion = is_file($alertHistoryCssFile)
    ? (string) filemtime($alertHistoryCssFile)
    : '1';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alert History | FloodGuard</title>

    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="../assets/css/sensor-history.css">
    <link
        rel="stylesheet"
        href="<?= fgEscape($alertHistoryCssUrl) ?>?v=<?= fgEscape($alertHistoryCssVersion) ?>"
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

    <main class="admin-content standard-admin-page alert-history-page sensor-history-page">
        <?php $historyActiveTab = 'alerts'; require __DIR__ . '/includes/history_tabs.php'; ?>
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

        <section class="alert-statistics sensor-statistics">
            <?php
            $statCards = [
                ['total', 'All Events', 'bi-bell-fill', 'Recorded alert transitions', 'total'],
                ['warning', 'Warnings', 'bi-exclamation-triangle-fill', 'Warning conditions', 'warning'],
                ['critical', 'Critical Alerts', 'bi-shield-fill-exclamation', 'Critical flood conditions', 'critical'],
                ['sensor_fault', 'Sensor Faults', 'bi-cpu-fill', 'Maintenance required', 'fault'],
                ['recovery', 'Recoveries', 'bi-check-circle-fill', 'Restored conditions', 'normal']
            ];
            ?>

            <?php foreach ($statCards as [$key, $label, $icon, $description, $iconClass]): ?>
                <article class="alert-stat-card sensor-stat-card <?= fgEscape($key) ?>">
                    <div class="alert-stat-icon sensor-stat-icon <?= fgEscape($iconClass) ?>">
                        <i class="bi <?= fgEscape($icon) ?>"></i>
                    </div>
                    <div>
                        <span><?= fgEscape($label) ?></span>
                        <strong><?= number_format($summaryCounts[$key]) ?></strong>
                        <small><?= fgEscape($description) ?></small>
                    </div>
                </article>
            <?php endforeach; ?>
        </section>

        <section class="content-card alert-history-card sensor-history-card">
            <div class="content-card-header alert-history-header sensor-history-header">
                <div>
                    <span class="section-label">System Events</span>
                    <h2>FloodGuard Alert History</h2>
                    <p class="sensor-section-description">Repeated sensor uploads are grouped into meaningful status changes.</p>
                </div>

                <span class="alert-record-count sensor-record-count">
                    <?= number_format($totalFilteredRecords) ?>
                    event<?= $totalFilteredRecords === 1 ? '' : 's' ?>
                </span>
            </div>

            <form method="GET" class="alert-filters sensor-filters">
                <div class="alert-filter-search sensor-filter-search">
                    <i class="bi bi-search" aria-hidden="true"></i>
                    <input
                        type="search"
                        name="search"
                        value="<?= fgEscape($search) ?>"
                        placeholder="Search alerts..."
                        aria-label="Search alert history"
                    >
                </div>

                <select name="event_type" aria-label="Event type">
                    <option value="">All Event Types</option>
                    <?php foreach ($allowedEventTypes as $eventType): ?>
                        <option
                            value="<?= fgEscape($eventType) ?>"
                            <?= $eventTypeFilter === $eventType ? 'selected' : '' ?>
                        >
                            <?= fgEscape(alertHistoryLabel($eventType)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <select name="severity" aria-label="Severity">
                    <option value="">All Severities</option>
                    <?php foreach ($allowedSeverities as $severity): ?>
                        <option
                            value="<?= fgEscape($severity) ?>"
                            <?= $severityFilter === $severity ? 'selected' : '' ?>
                        >
                            <?= fgEscape(alertHistoryLabel($severity)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <div class="alert-date-field sensor-date-field">
                    <label for="date_from">From</label>
                    <input type="date" id="date_from" name="date_from" value="<?= fgEscape($dateFrom) ?>">
                </div>

                <div class="alert-date-field sensor-date-field">
                    <label for="date_to">To</label>
                    <input type="date" id="date_to" name="date_to" value="<?= fgEscape($dateTo) ?>">
                </div>

                <button type="submit" class="alert-filter-button sensor-filter-button">
                    <i class="bi bi-funnel-fill"></i>
                    Apply Filters
                </button>

                <?php if (
                    $search !== '' ||
                    $eventTypeFilter !== '' ||
                    $severityFilter !== '' ||
                    $dateFrom !== '' ||
                    $dateTo !== ''
                ): ?>
                    <a href="alert_history.php" class="alert-clear-filter sensor-clear-filter">Clear</a>
                <?php endif; ?>
            </form>

            <div class="table-container alert-table-container sensor-table-container">
                <table class="admin-table alert-history-table sensor-history-table">
                    <thead>
                    <tr>
                        <th>Date and Time</th>
                        <th>Event</th>
                        <th class="alert-readings-heading">Readings</th>
                        <th>Severity</th>
                        <th>Sensor Health</th>
                        <th class="alert-action-heading"><span class="visually-hidden">View</span></th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php if (!$pageEvents): ?>
                        <tr>
                            <td colspan="6" class="empty-table alert-empty-table sensor-empty-table">
                                <i class="bi bi-bell-slash-fill"></i>
                                <strong>No alert events found</strong>
                                <span>Warning, Critical, recovery, fault, and connectivity events will appear here.</span>
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($pageEvents as $event): ?>
                            <?php
                            $modalRecord = [
                                'event_key' => (string) $event['event_key'],
                                'reading_id' => (int) $event['reading_id'],
                                'device_id' => (string) $event['device_id'],
                                'event_type' => alertHistoryLabel((string) $event['event_type']),
                                'severity' => (string) $event['severity'],
                                'severity_label' => alertHistoryLabel((string) $event['severity']),
                                'title' => (string) $event['title'],
                                'description' => (string) $event['description'],
                                'water_level' => alertHistoryNumber($event['water_level_cm'], 1, ' cm'),
                                'wind_speed' => alertHistoryNumber($event['wind_speed_mps'], 1, ' m/s'),
                                'rain_status' => (int) $event['rain_detected'] === 1
                                    ? 'Rain detected'
                                    : 'No rain',
                                'rain_analog' => $event['rain_analog'] !== null
                                    ? number_format((int) $event['rain_analog'])
                                    : 'No data',
                                'sensor_health' => alertHistoryLabel((string) $event['sensor_health']),
                                'device_status' => alertHistoryLabel((string) $event['device_status']),
                                'date_time' => date('M d, Y h:i:s A', (int) $event['timestamp'])
                            ];

                            $modalRecordJson = json_encode(
                                $modalRecord,
                                JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
                            ) ?: '{}';
                            ?>
                            <tr
                                class="alert-record-row"
                                tabindex="0"
                                data-alert-record="<?= fgEscape($modalRecordJson) ?>"
                                aria-label="View details for <?= fgEscape($event['title']) ?>"
                            >
                                <td>
                                    <div class="alert-date-cell sensor-date-cell">
                                        <strong><?= date('M d, Y', (int) $event['timestamp']) ?></strong>
                                        <span><?= date('h:i:s A', (int) $event['timestamp']) ?></span>
                                    </div>
                                </td>
                                <td>
                                    <div class="alert-event-cell <?= fgEscape($event['severity']) ?>">
                                        <div class="sensor-value-cell">
                                            <strong><?= fgEscape($event['title']) ?></strong>
                                            <span><?= fgEscape(alertHistoryLabel($event['event_type'])) ?></span>
                                        </div>
                                    </div>
                                </td>
                                <td class="alert-readings-cell">
                                    <strong><?= fgEscape(alertHistoryNumber($event['water_level_cm'], 1, ' cm')) ?></strong>
                                    <span>Wind: <?= fgEscape(alertHistoryNumber($event['wind_speed_mps'], 1, ' m/s')) ?></span>
                                    <span><?= (int) $event['rain_detected'] === 1 ? 'Rain detected' : 'No rain' ?></span>
                                </td>
                                <td>
                                    <span class="status-badge <?= alertHistoryStatusClass($event['severity']) ?>">
                                        <?= fgEscape(alertHistoryLabel($event['severity'])) ?>
                                    </span>
                                </td>
                                <td><?= fgEscape(alertHistoryLabel($event['sensor_health'])) ?></td>
                                <td class="alert-action-cell">
                                    <button
                                        type="button"
                                        class="alert-view-button"
                                        aria-label="View full event details"
                                        title="View details"
                                    >
                                        <i class="bi bi-eye-fill" aria-hidden="true"></i>
                                    </button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                    </tbody>
                </table>
            </div>

            <?php if ($totalPages > 1): ?>
                <div class="alert-pagination sensor-pagination">
                    <div class="alert-pagination-summary sensor-pagination-summary">
                        Showing <?= number_format($offset + 1) ?> to
                        <?= number_format(min($offset + $recordsPerPage, $totalFilteredRecords)) ?> of
                        <?= number_format($totalFilteredRecords) ?>
                    </div>

                    <div class="alert-pagination-links sensor-pagination-links">
                        <?php if ($currentPage > 1): ?>
                            <a
                                href="<?= fgEscape(alertHistoryUrl(
                                    $currentPage - 1,
                                    $search,
                                    $eventTypeFilter,
                                    $severityFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="alert-page-button sensor-page-button"
                                aria-label="Previous page"
                            ><i class="bi bi-chevron-left"></i></a>
                        <?php endif; ?>

                        <?php
                        $startPage = max(1, $currentPage - 2);
                        $endPage = min($totalPages, $currentPage + 2);
                        ?>

                        <?php for ($page = $startPage; $page <= $endPage; $page++): ?>
                            <a
                                href="<?= fgEscape(alertHistoryUrl(
                                    $page,
                                    $search,
                                    $eventTypeFilter,
                                    $severityFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="alert-page-button sensor-page-button <?= $page === $currentPage ? 'active' : '' ?>"
                            ><?= $page ?></a>
                        <?php endfor; ?>

                        <?php if ($currentPage < $totalPages): ?>
                            <a
                                href="<?= fgEscape(alertHistoryUrl(
                                    $currentPage + 1,
                                    $search,
                                    $eventTypeFilter,
                                    $severityFilter,
                                    $dateFrom,
                                    $dateTo
                                )) ?>"
                                class="alert-page-button sensor-page-button"
                                aria-label="Next page"
                            ><i class="bi bi-chevron-right"></i></a>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>

<dialog id="alertDetailsModal" class="alert-details-modal" aria-labelledby="alertModalTitle">
    <div class="alert-modal-header">
        <div>
            <span class="section-label">Event Details</span>
            <h2 id="alertModalTitle">FloodGuard Alert</h2>
        </div>
        <button type="button" class="alert-modal-close" aria-label="Close details">
            <i class="bi bi-x-lg" aria-hidden="true"></i>
        </button>
    </div>

    <div class="alert-modal-body">
        <div class="alert-modal-summary">
            <span id="alertModalEventIcon" class="alert-modal-event-icon">
                <i class="bi bi-bell-fill" aria-hidden="true"></i>
            </span>
            <div>
                <strong id="alertModalEventTitle">—</strong>
                <span id="alertModalEventType">—</span>
            </div>
            <span id="alertModalSeverity" class="status-badge">—</span>
        </div>

        <dl class="alert-modal-grid">
            <div><dt>Date and Time</dt><dd id="alertModalDateTime">—</dd></div>
            <div><dt>Device ID</dt><dd id="alertModalDeviceId">—</dd></div>
            <div><dt>Water Level</dt><dd id="alertModalWaterLevel">—</dd></div>
            <div><dt>Wind Speed</dt><dd id="alertModalWindSpeed">—</dd></div>
            <div><dt>Rain Condition</dt><dd id="alertModalRainStatus">—</dd></div>
            <div><dt>Rain Analog</dt><dd id="alertModalRainAnalog">—</dd></div>
            <div><dt>Sensor Health</dt><dd id="alertModalSensorHealth">—</dd></div>
            <div><dt>Device Status</dt><dd id="alertModalDeviceStatus">—</dd></div>
            <div><dt>Source Reading ID</dt><dd id="alertModalReadingId">—</dd></div>
        </dl>

        <div class="alert-modal-description">
            <span>Full Details</span>
            <p id="alertModalDescription">—</p>
        </div>
    </div>
</dialog>

<script src="../assets/js/admin.js"></script>
<script>
(() => {
    'use strict';

    const modal = document.getElementById('alertDetailsModal');

    if (!modal) {
        return;
    }

    const fields = {
        title: document.getElementById('alertModalTitle'),
        eventTitle: document.getElementById('alertModalEventTitle'),
        eventType: document.getElementById('alertModalEventType'),
        severity: document.getElementById('alertModalSeverity'),
        eventIcon: document.getElementById('alertModalEventIcon'),
        dateTime: document.getElementById('alertModalDateTime'),
        deviceId: document.getElementById('alertModalDeviceId'),
        waterLevel: document.getElementById('alertModalWaterLevel'),
        windSpeed: document.getElementById('alertModalWindSpeed'),
        rainStatus: document.getElementById('alertModalRainStatus'),
        rainAnalog: document.getElementById('alertModalRainAnalog'),
        sensorHealth: document.getElementById('alertModalSensorHealth'),
        deviceStatus: document.getElementById('alertModalDeviceStatus'),
        readingId: document.getElementById('alertModalReadingId'),
        description: document.getElementById('alertModalDescription')
    };

    const iconBySeverity = {
        normal: 'bi-check-circle-fill',
        warning: 'bi-exclamation-triangle-fill',
        critical: 'bi-shield-fill-exclamation'
    };

    function openAlertDetails(row) {
        let record;

        try {
            record = JSON.parse(row.dataset.alertRecord || '{}');
        } catch (error) {
            return;
        }

        fields.title.textContent = record.title || 'FloodGuard Alert';
        fields.eventTitle.textContent = record.title || '—';
        fields.eventType.textContent = record.event_type || '—';
        fields.dateTime.textContent = record.date_time || '—';
        fields.deviceId.textContent = record.device_id || '—';
        fields.waterLevel.textContent = record.water_level || 'No data';
        fields.windSpeed.textContent = record.wind_speed || 'No data';
        fields.rainStatus.textContent = record.rain_status || 'No data';
        fields.rainAnalog.textContent = record.rain_analog || 'No data';
        fields.sensorHealth.textContent = record.sensor_health || 'Unknown';
        fields.deviceStatus.textContent = record.device_status || 'Unknown';
        fields.readingId.textContent = record.reading_id || '—';
        fields.description.textContent = record.description || 'No additional details.';

        const severity = ['normal', 'warning', 'critical'].includes(record.severity)
            ? record.severity
            : 'offline';

        fields.severity.className = `status-badge status-${severity}`;
        fields.severity.textContent = record.severity_label || 'Unknown';
        fields.eventIcon.className = `alert-modal-event-icon ${severity}`;
        fields.eventIcon.innerHTML = `<i class="bi ${iconBySeverity[severity] || 'bi-bell-fill'}" aria-hidden="true"></i>`;

        modal.showModal();
    }

    document.querySelectorAll('.alert-record-row').forEach(row => {
        row.addEventListener('click', () => openAlertDetails(row));
        row.addEventListener('keydown', event => {
            if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                openAlertDetails(row);
            }
        });

        const viewButton = row.querySelector('.alert-view-button');
        viewButton?.addEventListener('click', event => {
            event.stopPropagation();
            openAlertDetails(row);
        });
    });

    modal.querySelector('.alert-modal-close')?.addEventListener('click', () => modal.close());
    modal.addEventListener('click', event => {
        if (event.target === modal) {
            modal.close();
        }
    });
})();
</script>
</body>
</html>
