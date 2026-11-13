<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../app/Support/Security.php';
require_once __DIR__ . '/../app/Security/Csrf.php';
require_once __DIR__ . '/../app/Security/RateLimiter.php';

floodguardApplySecurityHeaders();
floodguardStartSecureSession();
if (!empty($_SESSION['staff_user_id'])) { header('Location: posts.php'); exit; }

$csrf = floodguardCsrfToken('staff_login');
$error = '';
$notice = $_GET['notice'] ?? '';
$email = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = strtolower(trim((string) ($_POST['email'] ?? '')));
    $password = (string) ($_POST['password'] ?? '');
    try {
        if (!floodguardVerifyCsrf((string) ($_POST['csrf_token'] ?? ''), 'staff_login')) throw new RuntimeException('The form expired. Please refresh and try again.');
        $subject = floodguardRateLimitSubject($email);
        $remaining = floodguardRateLimitRemaining($pdo, 'staff_login', $subject);
        if ($remaining > 0) throw new RuntimeException("Too many attempts. Wait {$remaining} seconds.");
        $stmt = $pdo->prepare('SELECT u.id,u.password_hash,u.account_status,u.email_verified_at FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id AND r.slug="barangay_personnel" WHERE u.email=:email LIMIT 1');
        $stmt->execute([':email' => $email]);
        $user = $stmt->fetch();
        if (!$user || !password_verify($password, $user['password_hash'])) {
            floodguardRecordFailedAttempt($pdo, 'staff_login', $subject, 5, 15, 60);
            throw new RuntimeException('Invalid barangay personnel email or password.');
        }
        if ($user['account_status'] !== 'active' || $user['email_verified_at'] === null) throw new RuntimeException('This barangay personnel account is unavailable.');
        floodguardClearRateLimit($pdo, 'staff_login', $subject);
        session_regenerate_id(true);
        $_SESSION['staff_user_id'] = (int) $user['id'];
        $_SESSION['staff_last_activity'] = time();
        header('Location: posts.php');
        exit;
    } catch (Throwable $e) { $error = $e->getMessage(); }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Barangay Personnel Sign In | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/auth.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<main class="login-page">
    <section class="login-information" aria-label="FloodGuard Barangay Operations">
        <div class="login-brand"><div class="login-logo"><img src="../assets/images/floodguard-logo.png" alt="FloodGuard"></div><div><strong>FloodGuard</strong><span>Barangay Operations Portal</span></div></div>
        <div class="login-information-content">
            <span class="login-eyebrow">Authorized personnel</span>
            <h1>From verified report to coordinated response.</h1>
            <p>A focused workspace for Barangay Personnel to review resident reports, approve verified incidents, prepare response teams, and dispatch responders.</p>
            <div class="login-features">
                <article class="login-feature"><span class="feature-icon"><i class="bi bi-file-earmark-check"></i></span><div><strong>Review reports</strong><span>Verify resident-submitted conditions.</span></div></article>
                <article class="login-feature"><span class="feature-icon"><i class="bi bi-truck-front"></i></span><div><strong>Coordinate response</strong><span>Assign teams to approved incidents.</span></div></article>
            </div>
            <div class="location-box"><i class="bi bi-geo-alt"></i><div><strong>Spillway Bridge Monitoring Area</strong><span>Barangay San Isidro, Rodriguez, Rizal</span></div></div>
        </div>
        <div class="login-security"><i class="bi bi-shield-lock"></i><span>Access is limited to active Barangay Personnel accounts. Actions are recorded in the system audit trail.</span></div>
    </section>
    <section class="login-form-section">
        <div class="login-form-wrapper">
            <header class="login-form-header"><span>Secure access</span><h2>Welcome back</h2><p>Sign in with your Barangay Personnel account to continue.</p></header>
            <?php if ($error !== ''): ?><div class="login-alert error-alert" role="alert"><i class="bi bi-exclamation-circle"></i><span><?= floodguardEscape($error) ?></span></div><?php elseif ($notice === 'logged_out'): ?><div class="login-alert notice-alert" role="status"><i class="bi bi-check-circle"></i><span>You have been signed out safely.</span></div><?php elseif ($notice === 'session_expired'): ?><div class="login-alert notice-alert" role="status"><i class="bi bi-clock-history"></i><span>Your session expired for security. Please sign in again.</span></div><?php elseif ($notice === 'account_unavailable'): ?><div class="login-alert error-alert" role="alert"><i class="bi bi-person-x"></i><span>This account is no longer available. Contact an administrator.</span></div><?php endif; ?>
            <form method="post" id="staffLoginForm">
                <input type="hidden" name="csrf_token" value="<?= floodguardEscape($csrf) ?>">
                <div class="login-field"><label for="email">Email address</label><div class="login-input"><i class="bi bi-envelope"></i><input id="email" type="email" name="email" value="<?= floodguardEscape($email) ?>" required autocomplete="username" placeholder="name@example.com"></div></div>
                <div class="login-field"><label for="password">Password</label><div class="login-input"><i class="bi bi-lock"></i><input id="password" type="password" name="password" required autocomplete="current-password" placeholder="Enter your password"><button type="button" class="password-toggle" id="passwordToggle" aria-label="Show password"><i class="bi bi-eye"></i></button></div></div>
                <button type="submit" class="login-button" id="loginButton"><span>Sign in to operations</span><i class="bi bi-arrow-right"></i></button>
            </form>
            <p class="login-footer-text"><a href="../index.php">Return to public monitoring</a></p>
        </div>
    </section>
</main>
<script>
(() => {
    const password = document.getElementById('password');
    const toggle = document.getElementById('passwordToggle');
    const form = document.getElementById('staffLoginForm');
    const submit = document.getElementById('loginButton');
    toggle.addEventListener('click', () => {
        const visible = password.type === 'text';
        password.type = visible ? 'password' : 'text';
        toggle.setAttribute('aria-label', visible ? 'Show password' : 'Hide password');
        toggle.querySelector('i').className = visible ? 'bi bi-eye' : 'bi bi-eye-slash';
    });
    form.addEventListener('submit', () => { submit.disabled = true; submit.querySelector('span').textContent = 'Signing in…'; });
})();
</script>
</body>
</html>
