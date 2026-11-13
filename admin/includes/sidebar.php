<?php

/*
|--------------------------------------------------------------------------
| FloodGuard Reusable Sidebar
|--------------------------------------------------------------------------
| The database and authentication must already be loaded by the page.
*/

if (!isset($pdo) || !$pdo instanceof PDO) {
    throw new RuntimeException(
        'Database connection must be loaded before sidebar.php.'
    );
}

if (!function_exists('fgEscape')) {
    function fgEscape(?string $value): string
    {
        return htmlspecialchars(
            $value ?? '',
            ENT_QUOTES,
            'UTF-8'
        );
    }
}

/*
|--------------------------------------------------------------------------
| System settings
|--------------------------------------------------------------------------
*/

$sidebarSystemName = 'FloodGuard';
$sidebarLogoPath = 'assets/images/floodguard-logo.png';
$sidebarDeviceId = $deviceId ?? 'FG-STATION-001';
$sidebarTimeout = 180;

try {
    $sidebarSettingsStmt = $pdo->query(
        "SELECT setting_key, setting_value
         FROM system_settings
         WHERE setting_key IN (
            'system_name',
            'logo_path',
            'device_id',
            'device_offline_timeout_seconds'
         )"
    );

    $sidebarSettings = $sidebarSettingsStmt->fetchAll(
        PDO::FETCH_KEY_PAIR
    );

    if (!empty($sidebarSettings['system_name'])) {
        $sidebarSystemName =
            $sidebarSettings['system_name'];
    }

    if (!empty($sidebarSettings['device_id'])) {
        $sidebarDeviceId =
            $sidebarSettings['device_id'];
    }

    if (
        !empty(
            $sidebarSettings[
                'device_offline_timeout_seconds'
            ]
        )
    ) {
        $sidebarTimeout = max(
            30,
            (int) $sidebarSettings[
                'device_offline_timeout_seconds'
            ]
        );
    }

    $databaseLogoPath =
        $sidebarSettings['logo_path'] ?? null;

    if (
        is_string($databaseLogoPath) &&
        preg_match(
            '#^assets/[A-Za-z0-9._/-]+$#',
            $databaseLogoPath
        )
    ) {
        $sidebarLogoPath =
            $databaseLogoPath;
    }
} catch (PDOException $exception) {
    // Keep default settings.
}

/*
|--------------------------------------------------------------------------
| Device status
|--------------------------------------------------------------------------
*/

if (!isset($deviceIsOnline)) {
    $deviceIsOnline = false;

    try {
        $deviceStatusStmt = $pdo->query(
            'SELECT measured_at AS created_at
             FROM device_latest_readings
             ORDER BY measured_at DESC
             LIMIT 1'
        );

        $latestDeviceRecord =
            $deviceStatusStmt->fetch(PDO::FETCH_ASSOC);

        if ($latestDeviceRecord) {
            $latestDeviceTime = strtotime(
                (string) $latestDeviceRecord['created_at']
            );

            if ($latestDeviceTime !== false) {
                $deviceIsOnline =
                    time() - $latestDeviceTime
                    <= $sidebarTimeout;
            }
        }
    } catch (PDOException $exception) {
        $deviceIsOnline = false;
    }
}

/*
|--------------------------------------------------------------------------
| Current page
|--------------------------------------------------------------------------
*/

$currentAdminPage = basename(
    $_SERVER['PHP_SELF'] ?? ''
);

$sidebarLogoUrl =
    '../' . ltrim($sidebarLogoPath, '/');

$sidebarLinks = [
    [
        'file' => 'dashboard.php',
        'label' => 'Dashboard',
        'icon' => 'bi-grid-1x2-fill'
    ],
    [
        'file' => 'accounts.php',
        'label' => 'Account Management',
        'icon' => 'bi-person-gear'
    ],
    [
        'file' => 'resident_accounts.php',
        'label' => 'Resident Applications',
        'icon' => 'bi-person-vcard-fill'
    ],
    [
        'file' => 'sensor_history.php',
        'files' => ['sensor_history.php', 'alert_history.php', 'history.php'],
        'label' => 'History',
        'icon' => 'bi-clock-history'
    ],
    [
        'file' => 'controls.php',
        'label' => 'Device Controls',
        'icon' => 'bi-sliders'
    ],
    [
        'file' => 'settings.php',
        'label' => 'System Settings',
        'icon' => 'bi-gear-fill'
    ]
];
?>

<div class="sidebar-overlay" id="sidebarOverlay"></div>

<aside class="admin-sidebar" id="adminSidebar">

    <div class="sidebar-brand">
        <img
            src="<?= fgEscape($sidebarLogoUrl) ?>"
            alt="<?= fgEscape($sidebarSystemName) ?> Logo"
            class="sidebar-logo"
            onerror="
                this.onerror = null;
                this.src = '../assets/images/floodguard-logo.png';
            "
        >

        <div class="sidebar-brand-text">
            <strong>
                <?= fgEscape($sidebarSystemName) ?>
            </strong>

            <span>Monitoring System</span>
        </div>

        <button
            type="button"
            class="sidebar-close"
            id="sidebarClose"
            aria-label="Close navigation"
        >
            <i class="bi bi-x-lg"></i>
        </button>
    </div>

    <div class="sidebar-section-label">
        Main Navigation
    </div>

    <nav class="sidebar-navigation">

        <?php foreach ($sidebarLinks as $link): ?>
            <?php
            $isActive = in_array(
                $currentAdminPage,
                $link['files'] ?? [$link['file']],
                true
            );
            ?>

            <a
                href="<?= fgEscape($link['file']) ?>"
                class="sidebar-link <?= $isActive
                    ? 'active'
                    : ''
                ?>"
            >
                <i class="bi <?= fgEscape($link['icon']) ?>"></i>

                <span>
                    <?= fgEscape($link['label']) ?>
                </span>
            </a>
        <?php endforeach; ?>

    </nav>

    <div class="sidebar-bottom">

        <div class="station-summary" data-live-field="sidebar_station">
            <span
                class="station-dot <?= $deviceIsOnline
                    ? 'online'
                    : 'offline'
                ?>"
            ></span>

            <div>
                <strong>
                    <?= $deviceIsOnline
                        ? 'Station Online'
                        : 'Station Offline'
                    ?>
                </strong>

                <span>
                    <?= fgEscape($sidebarDeviceId) ?>
                </span>
            </div>
        </div>

        <div class="sidebar-admin">
            <div class="admin-avatar">
                <?= fgEscape(
                    strtoupper(
                        substr(
                            $_SESSION['admin_name']
                                ?? 'A',
                            0,
                            1
                        )
                    )
                ) ?>
            </div>

            <div class="sidebar-admin-details">
                <strong>
                    <?= fgEscape(
                        $_SESSION['admin_name']
                            ?? 'Administrator'
                    ) ?>
                </strong>

                <span>
                    <?= fgEscape(
                        $_SESSION['admin_email']
                            ?? ''
                    ) ?>
                </span>
            </div>

            <form method="POST" action="logout.php" class="sidebar-logout-form">
                <input type="hidden" name="csrf_token" value="<?= fgEscape($logoutCsrfToken ?? '') ?>">
                <button
                    type="submit"
                    class="sidebar-logout"
                    title="Logout"
                    aria-label="Logout"
                >
                    <i class="bi bi-box-arrow-right"></i>
                </button>
            </form>
        </div>

    </div>

</aside>
