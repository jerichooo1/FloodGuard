<?php

declare(strict_types=1);

require_once __DIR__ . '/../../app/Support/Security.php';
require_once __DIR__ . '/../../app/Security/Csrf.php';
require_once __DIR__ . '/../../app/Auth/Authorization.php';

floodguardApplySecurityHeaders();
floodguardStartSecureSession();

if (empty($_SESSION['user_id']) || empty($_SESSION['user_logged_in'])) {
    header('Location: login.php');
    exit;
}

$sessionTimeoutSeconds = 3600;
if (
    isset($_SESSION['user_last_activity']) &&
    time() - (int) $_SESSION['user_last_activity'] > $sessionTimeoutSeconds
) {
    $_SESSION = [];
    session_destroy();
    header('Location: login.php?notice=session_expired');
    exit;
}

if (!isset($pdo) || !$pdo instanceof PDO) {
    throw new RuntimeException('The database connection must be loaded before auth.php.');
}

$authUserStmt = $pdo->prepare(
    'SELECT u.id, u.full_name, u.email, u.account_status,
            a.id AS legacy_admin_id
     FROM users u
     INNER JOIN user_roles ur ON ur.user_id = u.id
     INNER JOIN roles r ON r.id = ur.role_id AND r.slug = "administrator"
     LEFT JOIN admins a
       ON CONVERT(LOWER(a.email) USING utf8mb4) COLLATE utf8mb4_unicode_ci = u.email
     WHERE u.id = :id
     LIMIT 1'
);
$authUserStmt->execute([':id' => (int) $_SESSION['user_id']]);
$currentUser = $authUserStmt->fetch(PDO::FETCH_ASSOC);

if (!$currentUser || $currentUser['account_status'] !== 'active') {
    $_SESSION = [];
    session_destroy();
    header('Location: login.php?notice=account_unavailable');
    exit;
}

$currentPermissions = floodguardUserPermissions($pdo, (int) $currentUser['id']);
if (!isset($currentPermissions['system_health.view'])) {
    http_response_code(403);
    exit('Administrator permission is required.');
}

$_SESSION['user_last_activity'] = time();
$_SESSION['user_name'] = $currentUser['full_name'];
$_SESSION['user_email'] = $currentUser['email'];
$_SESSION['user_permissions'] = array_keys($currentPermissions);

// Temporary aliases keep existing pages and legacy foreign keys working.
$_SESSION['admin_logged_in'] = true;
$_SESSION['admin_id'] = (int) ($currentUser['legacy_admin_id'] ?? 0);
$_SESSION['admin_name'] = $currentUser['full_name'];
$_SESSION['admin_email'] = $currentUser['email'];
$_SESSION['admin_last_activity'] = $_SESSION['user_last_activity'];
$currentAdmin = $currentUser;

$logoutCsrfToken = floodguardCsrfToken('logout');
