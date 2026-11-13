<?php

declare(strict_types=1);

function floodguardRequireMethod(string ...$allowed): void
{
    $method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
    if (!in_array($method, $allowed, true)) {
        header('Allow: ' . implode(', ', $allowed));
        floodguardJsonResponse(405, ['success' => false, 'message' => 'Method not allowed.']);
    }
}

function floodguardJsonInput(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    try {
        $data = json_decode($raw, true, 64, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        floodguardJsonResponse(400, ['success' => false, 'message' => 'Invalid JSON request body.']);
    }
    if (!is_array($data)) {
        floodguardJsonResponse(400, ['success' => false, 'message' => 'A JSON object is required.']);
    }
    return $data;
}

function floodguardBearerToken(): ?string
{
    $header = (string) ($_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
    if ($header === '' && function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $name => $value) {
            if (strcasecmp((string) $name, 'Authorization') === 0) {
                $header = (string) $value;
                break;
            }
        }
    }
    return preg_match('/^Bearer\s+(.+)$/i', trim($header), $matches) === 1 ? trim($matches[1]) : null;
}
