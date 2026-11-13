<?php
$historyActiveTab = $historyActiveTab ?? match (basename($_SERVER['PHP_SELF'] ?? '')) {
    'sensor_history.php' => 'sensor',
    'alert_history.php' => 'alerts',
    default => trim((string) ($_GET['tab'] ?? 'incidents'))
};
$historyTabs = [
    'sensor' => ['sensor_history.php', 'Sensor Data', 'bi-activity'],
    'alerts' => ['alert_history.php', 'Alerts', 'bi-exclamation-triangle-fill'],
    'incidents' => ['history.php?tab=incidents', 'Incidents', 'bi-shield-check'],
    'notifications' => ['history.php?tab=notifications', 'Notifications', 'bi-bell-fill'],
    'activity' => ['history.php?tab=activity', 'Activity', 'bi-journal-check']
];
?>
<nav class="history-tabs" aria-label="History sections">
    <?php foreach ($historyTabs as $key => [$url, $label, $icon]): ?>
        <a href="<?= fgEscape($url) ?>" class="history-tab <?= $historyActiveTab === $key ? 'active' : '' ?>">
            <i class="bi <?= fgEscape($icon) ?>" aria-hidden="true"></i>
            <span><?= fgEscape($label) ?></span>
        </a>
    <?php endforeach; ?>
</nav>
