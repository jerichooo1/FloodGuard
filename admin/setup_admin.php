<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../app/Support/Security.php';
require_once __DIR__ . '/../app/Security/Csrf.php';

floodguardApplySecurityHeaders();
floodguardStartSecureSession();

$errorMessage = '';
$successMessage = '';

function escape(string $value): string
{
    return htmlspecialchars(
        $value,
        ENT_QUOTES,
        'UTF-8'
    );
}

/*
|--------------------------------------------------------------------------
| Disable setup after an administrator already exists
|--------------------------------------------------------------------------
*/

$adminCount = (int) $pdo->query(
    'SELECT COUNT(*) FROM admins'
)->fetchColumn();

$setupLocked = $adminCount > 0;
$setupCsrfToken = floodguardCsrfToken('admin_setup');

/*
|--------------------------------------------------------------------------
| Create the first administrator
|--------------------------------------------------------------------------
*/

if (
    $_SERVER['REQUEST_METHOD'] === 'POST' &&
    !$setupLocked
) {
    $fullName = trim($_POST['full_name'] ?? '');
    $email = strtolower(trim($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';

    try {
        if (!floodguardVerifyCsrf((string) ($_POST['csrf_token'] ?? ''), 'admin_setup')) {
            throw new RuntimeException('The setup form expired. Refresh the page and try again.');
        }

        if ($fullName === '') {
            throw new RuntimeException(
                'Please enter the administrator name.'
            );
        }

        if (mb_strlen($fullName) > 150) {
            throw new RuntimeException(
                'The administrator name is too long.'
            );
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new RuntimeException(
                'Please enter a valid email address.'
            );
        }

        if (strlen($password) < 8) {
            throw new RuntimeException(
                'The password must contain at least 8 characters.'
            );
        }

        if ($password !== $confirmPassword) {
            throw new RuntimeException(
                'The passwords do not match.'
            );
        }

        $duplicateStmt = $pdo->prepare(
            'SELECT id
             FROM admins
             WHERE email = ?
             LIMIT 1'
        );

        $duplicateStmt->execute([$email]);

        if ($duplicateStmt->fetch()) {
            throw new RuntimeException(
                'This email address is already registered.'
            );
        }

        $passwordHash = password_hash(
            $password,
            PASSWORD_DEFAULT
        );

        if ($passwordHash === false) {
            throw new RuntimeException(
                'Unable to secure the password.'
            );
        }

        $pdo->beginTransaction();

        $insertStmt = $pdo->prepare(
            'INSERT INTO admins (
                full_name,
                email,
                password,
                status
             ) VALUES (
                :full_name,
                :email,
                :password,
                "active"
             )'
        );

        $insertStmt->execute([
            ':full_name' => $fullName,
            ':email' => $email,
            ':password' => $passwordHash
        ]);

        $userStmt = $pdo->prepare(
            'INSERT INTO users
                (full_name, email, password_hash, email_verified_at, account_status)
             VALUES (:full_name, :email, :password_hash, NOW(), "active")'
        );
        $userStmt->execute([
            ':full_name' => $fullName,
            ':email' => $email,
            ':password_hash' => $passwordHash
        ]);

        $roleStmt = $pdo->prepare(
            'INSERT INTO user_roles (user_id, role_id)
             SELECT :user_id, id FROM roles WHERE slug = "administrator" LIMIT 1'
        );
        $roleStmt->execute([':user_id' => (int) $pdo->lastInsertId()]);

        if ($roleStmt->rowCount() !== 1) {
            throw new RuntimeException('The administrator role is unavailable. Run Migration 001 first.');
        }

        $pdo->commit();
        floodguardRotateCsrf('admin_setup');

        $successMessage =
            'The first FloodGuard administrator account was created successfully.';

        $setupLocked = true;
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $errorMessage = $exception->getMessage();
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

    <title>FloodGuard Administrator Setup</title>

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

<main class="auth-page">

    <section class="auth-information">

        <div class="auth-brand">
            <div class="auth-brand-icon">
                <i class="bi bi-water"></i>
            </div>

            <div>
                <strong>FloodGuard</strong>
                <span>Monitoring System</span>
            </div>
        </div>

        <div class="auth-information-content">
            <span class="auth-eyebrow">
                Initial System Setup
            </span>

            <h1>
                Create the first administrator account
            </h1>

            <p>
                This account will manage monitoring records,
                resident registrations, flood alerts, SMS
                notifications, device controls, and system
                settings.
            </p>
        </div>

        <div class="auth-security-note">
            <i class="bi bi-shield-lock-fill"></i>

            <span>
                Passwords are securely hashed before being
                stored in the database.
            </span>
        </div>

    </section>

    <section class="auth-form-panel">

        <?php if ($successMessage !== ''): ?>

            <div class="auth-result success-result">
                <i class="bi bi-check-circle-fill"></i>

                <h2>Administrator Created</h2>

                <p>
                    <?= escape($successMessage) ?>
                </p>

                <a href="login.php" class="auth-primary-link">
                    Continue to Administrator Login
                </a>
            </div>

        <?php elseif ($setupLocked): ?>

            <div class="auth-result locked-result">
                <i class="bi bi-shield-check"></i>

                <h2>Setup Already Completed</h2>

                <p>
                    An administrator account already exists.
                    The setup page can no longer create another
                    initial account.
                </p>

                <a href="login.php" class="auth-primary-link">
                    Go to Administrator Login
                </a>
            </div>

        <?php else: ?>

            <div class="auth-form-heading">
                <span>Administrator Setup</span>
                <h2>Create Account</h2>

                <p>
                    Enter the credentials for the authorized
                    FloodGuard administrator.
                </p>
            </div>

            <?php if ($errorMessage !== ''): ?>
                <div class="auth-alert error-alert">
                    <i class="bi bi-exclamation-circle-fill"></i>

                    <span>
                        <?= escape($errorMessage) ?>
                    </span>
                </div>
            <?php endif; ?>

            <form method="POST" autocomplete="off">
                <input type="hidden" name="csrf_token" value="<?= escape($setupCsrfToken) ?>">

                <div class="auth-form-group">
                    <label for="full_name">
                        Administrator Name
                    </label>

                    <div class="auth-input-wrapper">
                        <i class="bi bi-person-fill"></i>

                        <input
                            type="text"
                            id="full_name"
                            name="full_name"
                            maxlength="150"
                            value="<?= escape(
                                $_POST['full_name'] ?? ''
                            ) ?>"
                            placeholder="Enter complete name"
                            required
                        >
                    </div>
                </div>

                <div class="auth-form-group">
                    <label for="email">
                        Email Address
                    </label>

                    <div class="auth-input-wrapper">
                        <i class="bi bi-envelope-fill"></i>

                        <input
                            type="email"
                            id="email"
                            name="email"
                            maxlength="150"
                            value="<?= escape(
                                $_POST['email'] ?? ''
                            ) ?>"
                            placeholder="administrator@example.com"
                            required
                        >
                    </div>
                </div>

                <div class="auth-form-group">
                    <label for="password">
                        Password
                    </label>

                    <div class="auth-input-wrapper">
                        <i class="bi bi-lock-fill"></i>

                        <input
                            type="password"
                            id="password"
                            name="password"
                            minlength="8"
                            placeholder="At least 8 characters"
                            required
                        >

                        <button
                            type="button"
                            class="password-toggle"
                            data-target="password"
                            aria-label="Show password"
                        >
                            <i class="bi bi-eye-fill"></i>
                        </button>
                    </div>
                </div>

                <div class="auth-form-group">
                    <label for="confirm_password">
                        Confirm Password
                    </label>

                    <div class="auth-input-wrapper">
                        <i class="bi bi-lock-fill"></i>

                        <input
                            type="password"
                            id="confirm_password"
                            name="confirm_password"
                            minlength="8"
                            placeholder="Repeat password"
                            required
                        >

                        <button
                            type="button"
                            class="password-toggle"
                            data-target="confirm_password"
                            aria-label="Show password"
                        >
                            <i class="bi bi-eye-fill"></i>
                        </button>
                    </div>
                </div>

                <button type="submit" class="auth-submit-button">
                    <i class="bi bi-person-check-fill"></i>
                    Create Administrator
                </button>

            </form>

        <?php endif; ?>

    </section>

</main>

<script>
document.querySelectorAll('.password-toggle').forEach(button => {
    button.addEventListener('click', function () {
        const targetId = this.dataset.target;
        const input = document.getElementById(targetId);
        const icon = this.querySelector('i');

        const passwordIsHidden =
            input.type === 'password';

        input.type = passwordIsHidden
            ? 'text'
            : 'password';

        icon.className = passwordIsHidden
            ? 'bi bi-eye-slash-fill'
            : 'bi bi-eye-fill';

        this.setAttribute(
            'aria-label',
            passwordIsHidden
                ? 'Hide password'
                : 'Show password'
        );
    });
});
</script>

</body>
</html>
