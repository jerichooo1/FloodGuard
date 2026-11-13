<?php

declare(strict_types=1);

function floodguardBase64UrlEncode(string $value): string
{
    return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
}

function floodguardFirebaseCredentials(): array
{
    $encoded = trim((string) floodguardEnv('FIREBASE_SERVICE_ACCOUNT_BASE64', ''));
    if ($encoded === '') {
        throw new RuntimeException('FIREBASE_SERVICE_ACCOUNT_BASE64 is not configured.');
    }

    $json = base64_decode($encoded, true);
    $credentials = $json === false ? null : json_decode($json, true);
    if (!is_array($credentials)) {
        throw new RuntimeException('The Firebase service-account credential is invalid.');
    }

    foreach (['project_id', 'client_email', 'private_key', 'token_uri'] as $field) {
        if (empty($credentials[$field]) || !is_string($credentials[$field])) {
            throw new RuntimeException('Firebase credential is missing ' . $field . '.');
        }
    }

    return $credentials;
}

function floodguardFirebaseAccessToken(array $credentials): string
{
    $now = time();
    $header = floodguardBase64UrlEncode(json_encode([
        'alg' => 'RS256',
        'typ' => 'JWT'
    ], JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
    $claims = floodguardBase64UrlEncode(json_encode([
        'iss' => $credentials['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => $credentials['token_uri'],
        'iat' => $now,
        'exp' => $now + 3600
    ], JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR));
    $unsigned = $header . '.' . $claims;

    $signature = '';
    if (!openssl_sign($unsigned, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
        throw new RuntimeException('Unable to sign the Firebase authentication request.');
    }

    $assertion = $unsigned . '.' . floodguardBase64UrlEncode($signature);
    [$status, $response] = floodguardFirebaseHttpRequest(
        $credentials['token_uri'],
        [
            'Content-Type: application/x-www-form-urlencoded',
            'Accept: application/json'
        ],
        http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $assertion
        ], '', '&', PHP_QUERY_RFC3986)
    );

    $decoded = json_decode($response, true);
    if ($status < 200 || $status >= 300 || !is_array($decoded) || empty($decoded['access_token'])) {
        throw new RuntimeException('Firebase authentication failed with HTTP ' . $status . '.');
    }

    return (string) $decoded['access_token'];
}

function floodguardFirebaseSend(
    array $credentials,
    string $accessToken,
    string $deviceToken,
    string $title,
    string $body,
    string $alertLevel,
    array $data = []
): array {
    $stringData = [];
    foreach ($data as $key => $value) {
        if ($value === null) {
            continue;
        }
        $stringData[(string) $key] = is_scalar($value)
            ? (string) $value
            : json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    $critical = $alertLevel === 'critical';
    $message = [
        'message' => [
            'token' => $deviceToken,
            'notification' => [
                'title' => $title,
                'body' => $body
            ],
            'data' => $stringData,
            'android' => [
                'priority' => 'HIGH',
                'ttl' => $critical ? '900s' : '1800s',
                'notification' => [
                    'channel_id' => $critical ? 'floodguard_critical' : 'floodguard_warning',
                    'sound' => 'default',
                    'default_vibrate_timings' => true,
                    'visibility' => 'PUBLIC',
                    'notification_priority' => $critical ? 'PRIORITY_MAX' : 'PRIORITY_HIGH'
                ]
            ]
        ]
    ];

    $url = 'https://fcm.googleapis.com/v1/projects/'
        . rawurlencode($credentials['project_id']) . '/messages:send';
    [$status, $response] = floodguardFirebaseHttpRequest(
        $url,
        [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json; charset=utf-8',
            'Accept: application/json'
        ],
        json_encode($message, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR)
    );

    $decoded = json_decode($response, true);
    return [
        'success' => $status >= 200 && $status < 300 && is_array($decoded) && !empty($decoded['name']),
        'http_status' => $status,
        'provider_message_id' => is_array($decoded) ? ($decoded['name'] ?? null) : null,
        'error' => floodguardFirebaseErrorMessage($status, $decoded, $response),
        'token_invalid' => floodguardFirebaseTokenIsInvalid($status, $decoded)
    ];
}

function floodguardFirebaseHttpRequest(string $url, array $headers, string $body): array
{
    $curl = curl_init($url);
    if ($curl === false) {
        throw new RuntimeException('Unable to initialize an HTTPS request.');
    }

    curl_setopt_array($curl, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $body,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2
    ]);
    $response = curl_exec($curl);
    $status = (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    $error = curl_error($curl);
    curl_close($curl);

    if ($response === false) {
        throw new RuntimeException('Firebase HTTPS request failed: ' . $error);
    }

    return [$status, (string) $response];
}

function floodguardFirebaseErrorMessage(int $status, mixed $decoded, string $raw): ?string
{
    if ($status >= 200 && $status < 300) {
        return null;
    }
    if (is_array($decoded) && isset($decoded['error']['message'])) {
        return substr((string) $decoded['error']['message'], 0, 500);
    }
    return substr(trim(strip_tags($raw)) ?: ('Firebase HTTP ' . $status), 0, 500);
}

function floodguardFirebaseTokenIsInvalid(int $status, mixed $decoded): bool
{
    if (!in_array($status, [400, 404], true) || !is_array($decoded)) {
        return false;
    }
    $text = json_encode($decoded, JSON_UNESCAPED_SLASHES);
    return is_string($text) && (
        str_contains($text, 'UNREGISTERED') ||
        str_contains($text, 'registration token is not a valid FCM')
    );
}
