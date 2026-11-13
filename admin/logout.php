<?php

declare(strict_types=1);

require_once __DIR__ . '/../app/Support/Security.php';
require_once __DIR__ . '/../app/Security/Csrf.php';

floodguardStartSecureSession();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit('Logout requires a POST request.');
}

$submittedToken = (string) ($_POST['csrf_token'] ?? '');
if (!floodguardVerifyCsrf($submittedToken, 'logout')) {
    http_response_code(419);
    exit('The logout request expired. Please return to the dashboard and try again.');
}

$_SESSION = [];
if (ini_get('session.use_cookies')) {
    $cookie = session_get_cookie_params();
    setcookie(
        session_name(),
        '',
        time() - 42000,
        $cookie['path'],
        $cookie['domain'],
        $cookie['secure'],
        $cookie['httponly']
    );
}

session_destroy();
header('Location: login.php?notice=logged_out');
exit;
