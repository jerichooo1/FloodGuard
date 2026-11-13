<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/database.php';

$minutes = (int) ($pdo->query(
    "SELECT setting_value FROM system_settings
     WHERE setting_key='sensor_summary_interval_minutes' LIMIT 1"
)->fetchColumn() ?: 15);
$minutes = in_array($minutes, [5, 10, 15, 30, 60], true) ? $minutes : 15;
$seconds = $minutes * 60;

$sql =
    'INSERT INTO sensor_summaries (
        monitoring_device_id, interval_start, interval_minutes,
        sample_count, valid_sample_count, min_water_level_cm,
        avg_water_level_cm, max_water_level_cm, avg_wind_speed_mps,
        max_wind_speed_mps, rain_detected_count, highest_alert_level
     )
     SELECT monitoring_device_id,
            FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(created_at) / ' . $seconds . ') * ' . $seconds . '),
            ' . $minutes . ', COUNT(*),
            SUM(sensor_health IN ("healthy","suspect") AND water_level_cm IS NOT NULL),
            MIN(CASE WHEN sensor_health IN ("healthy","suspect") THEN water_level_cm END),
            AVG(CASE WHEN sensor_health IN ("healthy","suspect") THEN water_level_cm END),
            MAX(CASE WHEN sensor_health IN ("healthy","suspect") THEN water_level_cm END),
            AVG(CASE WHEN sensor_health IN ("healthy","suspect") THEN wind_speed_mps END),
            MAX(CASE WHEN sensor_health IN ("healthy","suspect") THEN wind_speed_mps END),
            SUM(rain_detected=1),
            CASE MAX(FIELD(alert_level,"normal","warning","critical"))
                WHEN 3 THEN "critical" WHEN 2 THEN "warning" ELSE "normal" END
     FROM sensor_readings
     WHERE monitoring_device_id IS NOT NULL
       AND created_at < DATE_SUB(NOW(), INTERVAL ' . $minutes . ' MINUTE)
     GROUP BY monitoring_device_id,
              FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(created_at) / ' . $seconds . ') * ' . $seconds . ')
     ON DUPLICATE KEY UPDATE
        sample_count=VALUES(sample_count), valid_sample_count=VALUES(valid_sample_count),
        min_water_level_cm=VALUES(min_water_level_cm), avg_water_level_cm=VALUES(avg_water_level_cm),
        max_water_level_cm=VALUES(max_water_level_cm), avg_wind_speed_mps=VALUES(avg_wind_speed_mps),
        max_wind_speed_mps=VALUES(max_wind_speed_mps), rain_detected_count=VALUES(rain_detected_count),
        highest_alert_level=VALUES(highest_alert_level)';

$affected = $pdo->exec($sql);
fwrite(STDOUT, (int) $affected . " summary row operation(s) completed.\n");
