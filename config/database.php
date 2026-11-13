<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| FloodGuard Database Connection
|--------------------------------------------------------------------------
*/

require_once __DIR__ . '/environment.php';

$applicationTimezone = floodguardEnv('APP_TIMEZONE', 'Asia/Manila');
date_default_timezone_set($applicationTimezone);

$databaseHost = floodguardEnv('DB_HOST', '127.0.0.1');
$databasePort = floodguardEnv('DB_PORT', '3306');
$databaseName = floodguardEnv('DB_NAME', 'floodguard_db');
$databaseUser = floodguardEnv('DB_USER', 'root');
$databasePassword = floodguardEnv('DB_PASSWORD', '');
$databaseCharset = 'utf8mb4';

$dsn = sprintf(
    'mysql:host=%s;port=%s;dbname=%s;charset=%s',
    $databaseHost,
    $databasePort,
    $databaseName,
    $databaseCharset
);

$pdoOptions = [
    PDO::ATTR_ERRMODE =>
        PDO::ERRMODE_EXCEPTION,

    PDO::ATTR_DEFAULT_FETCH_MODE =>
        PDO::FETCH_ASSOC,

    PDO::ATTR_EMULATE_PREPARES =>
        false
];

try {
    $pdo = new PDO(
        $dsn,
        $databaseUser,
        $databasePassword,
        $pdoOptions
    );

    // Keep MySQL NOW(), CURRENT_TIMESTAMP, and PHP on the same timezone.
    $timezone = new DateTimeZone($applicationTimezone);
    $offsetSeconds = $timezone->getOffset(new DateTimeImmutable('now', $timezone));
    $offsetSign = $offsetSeconds < 0 ? '-' : '+';
    $offsetSeconds = abs($offsetSeconds);
    $mysqlOffset = sprintf(
        '%s%02d:%02d',
        $offsetSign,
        intdiv($offsetSeconds, 3600),
        intdiv($offsetSeconds % 3600, 60)
    );
    $pdo->exec('SET time_zone = '.$pdo->quote($mysqlOffset));
} catch (PDOException $exception) {
    http_response_code(500);

    exit(
        'Unable to connect to the FloodGuard database.'
    );
}
