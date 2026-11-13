<?php

declare(strict_types=1);

/**
 * Minimal environment loader for XAMPP/shared hosting.
 * Existing server environment variables always take precedence over .env.
 */
function floodguardLoadEnvironment(string $path): void
{
    if (!is_file($path) || !is_readable($path)) {
        return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) {
        return;
    }

    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }

        [$name, $value] = array_map('trim', explode('=', $line, 2));
        if (!preg_match('/^[A-Z][A-Z0-9_]*$/', $name) || getenv($name) !== false) {
            continue;
        }

        if (
            strlen($value) >= 2 &&
            (($value[0] === '"' && $value[-1] === '"') ||
             ($value[0] === "'" && $value[-1] === "'"))
        ) {
            $value = substr($value, 1, -1);
        }

        putenv($name . '=' . $value);
        $_ENV[$name] = $value;
    }
}

function floodguardEnv(string $name, ?string $default = null): ?string
{
    $value = getenv($name);
    return $value === false ? $default : $value;
}

function floodguardEnvBool(string $name, bool $default = false): bool
{
    $value = floodguardEnv($name);
    if ($value === null) {
        return $default;
    }

    $parsed = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    return $parsed ?? $default;
}

floodguardLoadEnvironment(dirname(__DIR__) . '/.env');

$applicationTimezone = floodguardEnv('APP_TIMEZONE', 'Asia/Manila');
if (is_string($applicationTimezone) && in_array($applicationTimezone, timezone_identifiers_list(), true)) {
    date_default_timezone_set($applicationTimezone);
}
