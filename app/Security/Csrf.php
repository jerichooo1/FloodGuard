<?php

declare(strict_types=1);

function floodguardCsrfToken(string $purpose = 'default'): string
{
    if (session_status() !== PHP_SESSION_ACTIVE) {
        throw new RuntimeException('A session is required before creating a CSRF token.');
    }

    $_SESSION['csrf_tokens'] ??= [];
    if (empty($_SESSION['csrf_tokens'][$purpose])) {
        $_SESSION['csrf_tokens'][$purpose] = bin2hex(random_bytes(32));
    }

    return (string) $_SESSION['csrf_tokens'][$purpose];
}

function floodguardVerifyCsrf(string $submitted, string $purpose = 'default'): bool
{
    $expected = $_SESSION['csrf_tokens'][$purpose] ?? '';
    return is_string($expected) && $expected !== '' && hash_equals($expected, $submitted);
}

function floodguardRotateCsrf(string $purpose = 'default'): string
{
    unset($_SESSION['csrf_tokens'][$purpose]);
    return floodguardCsrfToken($purpose);
}
