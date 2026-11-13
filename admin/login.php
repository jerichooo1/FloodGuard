<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Secure session
|--------------------------------------------------------------------------
*/

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../app/Support/Security.php';
require_once __DIR__ . '/../app/Security/RateLimiter.php';

floodguardApplySecurityHeaders();
floodguardStartSecureSession();

/*
|--------------------------------------------------------------------------
| Redirect logged-in administrators
|--------------------------------------------------------------------------
*/

if (
    !empty($_SESSION['user_id']) &&
    !empty($_SESSION['user_logged_in'])
) {
    header('Location: dashboard.php');
    exit;
}

/*
|--------------------------------------------------------------------------
| Helpers
|--------------------------------------------------------------------------
*/

function escape(?string $value): string
{
    return htmlspecialchars(
        $value ?? '',
        ENT_QUOTES,
        'UTF-8'
    );
}

/*
|--------------------------------------------------------------------------
| Load system identity
|--------------------------------------------------------------------------
*/

$systemName = 'FloodGuard';
$systemLocation =
    'Spillway Bridge, Barangay San Isidro, Rodriguez, Rizal';

try {
    $settingsStmt = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'system_name',
            'location'
         )"
    );

    $settings = $settingsStmt->fetchAll(
        PDO::FETCH_KEY_PAIR
    );

    if (!empty($settings['system_name'])) {
        $systemName =
            $settings['system_name'];
    }

    if (!empty($settings['location'])) {
        $systemLocation =
            $settings['location'];
    }
} catch (PDOException $exception) {
    // Use default system information.
}

/*
|--------------------------------------------------------------------------
| CSRF token
|--------------------------------------------------------------------------
*/

if (empty($_SESSION['login_csrf_token'])) {
    $_SESSION['login_csrf_token'] =
        bin2hex(random_bytes(32));
}

$csrfToken =
    $_SESSION['login_csrf_token'];

$errorMessage = '';
$noticeMessage = '';
$emailValue = '';

/*
|--------------------------------------------------------------------------
| Login notices
|--------------------------------------------------------------------------
*/

$notice = $_GET['notice'] ?? '';

if ($notice === 'session_expired') {
    $noticeMessage =
        'Your session expired. Please sign in again.';
}

if ($notice === 'account_unavailable') {
    $noticeMessage =
        'Your administrator account is currently unavailable.';
}

if ($notice === 'logged_out') {
    $noticeMessage =
        'You have been signed out successfully.';
}

/*
|--------------------------------------------------------------------------
| Temporary login-attempt protection
|--------------------------------------------------------------------------
*/

/*
|--------------------------------------------------------------------------
| Process login
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $emailValue = strtolower(
        trim($_POST['email'] ?? '')
    );

    $password =
        $_POST['password'] ?? '';

    $rateLimitSubject = floodguardRateLimitSubject($emailValue);

    try {
        $remainingSeconds = floodguardRateLimitRemaining(
            $pdo,
            'admin_login',
            $rateLimitSubject
        );
        if ($remainingSeconds > 0) {
            throw new RuntimeException(
                'Too many unsuccessful login attempts. Please wait ' .
                $remainingSeconds . ' seconds before trying again.'
            );
        }

        $submittedToken =
            $_POST['csrf_token'] ?? '';

        if (
            !is_string($submittedToken) ||
            !hash_equals(
                $_SESSION['login_csrf_token'],
                $submittedToken
            )
        ) {
            throw new RuntimeException(
                'The login form expired. Please refresh the page.'
            );
        }

        if (
            $emailValue === '' ||
            !filter_var(
                $emailValue,
                FILTER_VALIDATE_EMAIL
            )
        ) {
            throw new RuntimeException(
                'Please enter a valid email address.'
            );
        }

        if ($password === '') {
            throw new RuntimeException(
                'Please enter your password.'
            );
        }

        $adminStmt = $pdo->prepare(
            'SELECT
                u.id,
                u.full_name,
                u.email,
                u.password_hash,
                u.account_status,
                a.id AS legacy_admin_id,
                COUNT(CASE WHEN r.slug = "administrator" THEN 1 END) AS is_administrator
             FROM users u
             LEFT JOIN user_roles ur ON ur.user_id = u.id
             LEFT JOIN roles r ON r.id = ur.role_id
             LEFT JOIN admins a
               ON CONVERT(LOWER(a.email) USING utf8mb4) COLLATE utf8mb4_unicode_ci = u.email
             WHERE u.email = :email
             GROUP BY u.id, u.full_name, u.email, u.password_hash,
                      u.account_status, a.id
             LIMIT 1'
        );

        $adminStmt->execute([
            ':email' => $emailValue
        ]);

        $admin = $adminStmt->fetch(
            PDO::FETCH_ASSOC
        );

        $credentialsAreValid =
            $admin &&
            $admin['account_status'] === 'active' &&
            (int) $admin['is_administrator'] > 0 &&
            password_verify(
                $password,
                $admin['password_hash']
            );

        if (!$credentialsAreValid) {
            $blockSeconds = floodguardRecordFailedAttempt(
                $pdo,
                'admin_login',
                $rateLimitSubject
            );
            if ($blockSeconds > 0) {
                throw new RuntimeException(
                    'Too many unsuccessful login attempts. Login has been temporarily locked for 60 seconds.'
                );
            }

            throw new RuntimeException(
                'The email address or password is incorrect.'
            );
        }

        /*
        |--------------------------------------------------------------------------
        | Successful login
        |--------------------------------------------------------------------------
        */

        session_regenerate_id(true);

        $_SESSION['user_logged_in'] = true;
        $_SESSION['user_id'] = (int) $admin['id'];
        $_SESSION['user_name'] = $admin['full_name'];
        $_SESSION['user_email'] = $admin['email'];
        $_SESSION['user_last_activity'] = time();

        $_SESSION['admin_logged_in'] = true;
        $_SESSION['admin_id'] = (int) ($admin['legacy_admin_id'] ?? 0);

        $_SESSION['admin_name'] =
            $admin['full_name'];

        $_SESSION['admin_email'] =
            $admin['email'];

        $_SESSION['admin_last_activity'] =
            time();

        unset(
            $_SESSION['login_csrf_token']
        );

        floodguardClearRateLimit($pdo, 'admin_login', $rateLimitSubject);

        $lastLoginStmt = $pdo->prepare(
            'UPDATE users
             SET last_login_at = NOW()
             WHERE id = :id'
        );

        $lastLoginStmt->execute([
            ':id' => $admin['id']
        ]);

        if (!empty($admin['legacy_admin_id'])) {
            $legacyLoginStmt = $pdo->prepare(
                'UPDATE admins SET last_login_at = NOW() WHERE id = :id'
            );
            $legacyLoginStmt->execute([':id' => (int) $admin['legacy_admin_id']]);
        }

        header('Location: dashboard.php');
        exit;
    } catch (Throwable $exception) {
        $errorMessage =
            $exception->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <meta
        name="robots"
        content="noindex, nofollow"
    >

    <title>
        Administrator Login |
        <?= escape($systemName) ?>
    </title>

    <link
        rel="stylesheet"
        href="../assets/css/auth.css"
    >

    <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"
    >
</head>

<body>

<main class="login-page">

    <section class="login-information">

        <div class="login-brand">
            <div class="login-logo">
                <img
                    src="../assets/images/floodguard-logo.png"
                    alt="FloodGuard Logo"
                    onerror="
                        this.style.display = 'none';
                    "
                >
            </div>

            <div>
                <strong>
                    <?= escape($systemName) ?>
                </strong>

                <span>
                    Monitoring System
                </span>
            </div>
        </div>

        <div class="login-information-content">
            <span class="login-eyebrow">
                Administrator Access
            </span>

            <h1>
                Flood monitoring and emergency management
            </h1>

            <p>
                Sign in to view water-level readings, rainfall
                conditions, wind speed, bridge-barrier status,
                resident accounts, monitoring alerts, and operational access.
            </p>
<div class="login-features">

    <div class="login-feature">
        <div class="feature-icon">
            <i class="bi bi-broadcast-pin"></i>
        </div>

        <div>
            <strong>Real-Time Monitoring</strong>
            <span>Live sensor and bridge data</span>
        </div>
    </div>

    <div class="login-feature">
        <div class="feature-icon">
            <i class="bi bi-bell-fill"></i>
        </div>

        <div>
            <strong>Early Warning Alerts</strong>
            <span>Automatic flood notifications</span>
        </div>
    </div>

</div>
            <div class="location-box">
                <i class="bi bi-geo-alt-fill"></i>

                <div>
                    <strong>Monitoring Location</strong>

                    <span>
                        <?= escape($systemLocation) ?>
                    </span>
                </div>
            </div>
        </div>

        <div class="login-security">
            <i class="bi bi-shield-lock-fill"></i>

            <span>
                Access is limited to authorized Barangay
                San Isidro personnel.
            </span>
        </div>

    </section>

    <section class="login-form-section">

        <div class="login-form-wrapper">

            <header class="login-form-header">
                <span>Welcome Back</span>

                <h2>Administrator Login</h2>

                <p>
                    Enter your authorized FloodGuard credentials.
                </p>
            </header>

            <?php if ($noticeMessage !== ''): ?>
                <div class="login-alert notice-alert">
                    <i class="bi bi-info-circle-fill"></i>

                    <span>
                        <?= escape($noticeMessage) ?>
                    </span>
                </div>
            <?php endif; ?>

            <?php if ($errorMessage !== ''): ?>
                <div
                    class="login-alert error-alert"
                    role="alert"
                >
                    <i class="bi bi-exclamation-circle-fill"></i>

                    <span>
                        <?= escape($errorMessage) ?>
                    </span>
                </div>
            <?php endif; ?>

            <form method="POST" autocomplete="on">

                <input
                    type="hidden"
                    name="csrf_token"
                    value="<?= escape($csrfToken) ?>"
                >

                <div class="login-field">
                    <label for="email">
                        Email Address
                    </label>

                    <div class="login-input">
                        <i class="bi bi-envelope-fill"></i>

                        <input
                            type="email"
                            id="email"
                            name="email"
                            maxlength="150"
                            value="<?= escape($emailValue) ?>"
                            placeholder="admin@floodguard.local"
                            autocomplete="username"
                            required
                        >
                    </div>
                </div>

                <div class="login-field">
                    <label for="password">
                        Password
                    </label>

                    <div class="login-input">
                        <i class="bi bi-lock-fill"></i>

                        <input
                            type="password"
                            id="password"
                            name="password"
                            maxlength="72"
                            placeholder="Enter your password"
                            autocomplete="current-password"
                            required
                        >

                        <button
                            type="button"
                            id="togglePassword"
                            class="password-toggle"
                            aria-label="Show password"
                        >
                            <i class="bi bi-eye-fill"></i>
                        </button>
                    </div>
                </div>

                <button
                    type="submit"
                    class="login-button"
                >
                    <span>Sign In</span>
                    <i class="bi bi-arrow-right"></i>
                </button>

            </form>

            <p class="login-footer-text">
                FloodGuard administrator portal
            </p>

        </div>

    </section>

</main>

<script>
'use strict';

const passwordInput =
    document.getElementById('password');

const togglePassword =
    document.getElementById('togglePassword');

togglePassword.addEventListener(
    'click',
    function () {
        const passwordIsHidden =
            passwordInput.type === 'password';

        passwordInput.type =
            passwordIsHidden
                ? 'text'
                : 'password';

        const icon =
            this.querySelector('i');

        icon.className =
            passwordIsHidden
                ? 'bi bi-eye-slash-fill'
                : 'bi bi-eye-fill';

        this.setAttribute(
            'aria-label',
            passwordIsHidden
                ? 'Hide password'
                : 'Show password'
        );
    }
);
</script>

</body>
</html>
