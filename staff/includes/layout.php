<?php

declare(strict_types=1);

if (!isset($pdo) || !$pdo instanceof PDO || !isset($staffUser, $staffCsrf)) {
    throw new RuntimeException('Staff layout requires authentication and database context.');
}

$staffCurrentPage = basename($_SERVER['PHP_SELF'] ?? '');
$staffDeviceId = 'FG-STATION-001';
$staffDeviceOnline = false;

try {
    $settings = $pdo->query(
        "SELECT setting_key, setting_value FROM system_settings
         WHERE setting_key IN ('device_id', 'device_offline_timeout_seconds')"
    )->fetchAll(PDO::FETCH_KEY_PAIR);
    $staffDeviceId = (string) ($settings['device_id'] ?? $staffDeviceId);
    $timeout = max(30, (int) ($settings['device_offline_timeout_seconds'] ?? 180));
    $latest = $pdo->query('SELECT measured_at FROM device_latest_readings ORDER BY measured_at DESC LIMIT 1')->fetchColumn();
    $staffDeviceOnline = is_string($latest) && strtotime($latest) !== false && time() - (int) strtotime($latest) <= $timeout;
} catch (PDOException $exception) {
    $staffDeviceOnline = false;
}
?>
<div class="sidebar-overlay" id="sidebarOverlay"></div>
<aside class="admin-sidebar" id="adminSidebar">
    <div class="sidebar-brand">
        <img src="../assets/images/floodguard-logo.png" alt="FloodGuard" class="sidebar-logo">
        <div class="sidebar-brand-text"><strong>FloodGuard</strong><span>Barangay Operations</span></div>
        <button type="button" class="sidebar-close" id="sidebarClose" aria-label="Close navigation"><i class="bi bi-x-lg"></i></button>
    </div>
    <div class="sidebar-section-label">Operations</div>
    <nav class="sidebar-navigation" aria-label="Barangay personnel navigation">
        <?php if (isset($staffPermissions['posts.review'])): ?>
        <a href="posts.php" class="sidebar-link <?= $staffCurrentPage === 'posts.php' ? 'active' : '' ?>">
            <i class="bi bi-newspaper"></i><span>Post Review</span>
        </a>
        <?php endif; ?>
        <?php if (isset($staffPermissions['assignments.manage'])): ?>
            <a href="operations.php" class="sidebar-link <?= $staffCurrentPage === 'operations.php' ? 'active' : '' ?>">
                <i class="bi bi-truck-front-fill"></i><span>Response Operations</span>
            </a>
            <a href="teams.php" class="sidebar-link <?= $staffCurrentPage === 'teams.php' ? 'active' : '' ?>">
                <i class="bi bi-people-fill"></i><span>Team Management</span>
            </a>
        <?php endif; ?>
    </nav>
    <div class="sidebar-bottom">
        <div class="station-summary">
            <span class="station-dot <?= $staffDeviceOnline ? 'online' : 'offline' ?>"></span>
            <div><strong><?= $staffDeviceOnline ? 'Station Online' : 'Station Offline' ?></strong><span><?= floodguardEscape($staffDeviceId) ?></span></div>
        </div>
        <div class="sidebar-admin">
            <div class="admin-avatar"><?= floodguardEscape(strtoupper(substr((string) $staffUser['full_name'], 0, 1))) ?></div>
            <div class="sidebar-admin-details"><strong><?= floodguardEscape($staffUser['full_name']) ?></strong><span>Barangay Personnel</span></div>
            <form method="post" action="logout.php" class="sidebar-logout-form">
                <input type="hidden" name="csrf_token" value="<?= floodguardEscape($staffCsrf) ?>">
                <button type="submit" class="sidebar-logout" aria-label="Sign out" title="Sign out"><i class="bi bi-box-arrow-right"></i></button>
            </form>
        </div>
    </div>
</aside>
