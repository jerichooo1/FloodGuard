<?php

$pageTitle =
    $pageTitle ?? 'Administrator Dashboard';

$pageSubtitle =
    $pageSubtitle
    ?? 'FloodGuard monitoring and management system';

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
?>

<header class="admin-topbar">

    <div class="topbar-left">

        <button
            type="button"
            class="mobile-menu-button"
            id="mobileMenuButton"
            aria-label="Open navigation"
        >
            <i class="bi bi-list"></i>
        </button>

        <div>
            <h1><?= fgEscape($pageTitle) ?></h1>
            <p><?= fgEscape($pageSubtitle) ?></p>
        </div>

    </div>

    <div class="topbar-right">

        <div class="topbar-station-status" data-live-field="topbar_station">
            <span
                class="station-dot <?= $deviceIsOnline
                    ? 'online'
                    : 'offline'
                ?>"
            ></span>

            <div>
                <span>Monitoring Station</span>

                <strong>
                    <?= $deviceIsOnline
                        ? 'Receiving Data'
                        : 'Waiting for Data'
                    ?>
                </strong>
            </div>
        </div>

        <div class="topbar-admin">
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

            <div>
                <strong>
                    <?= fgEscape(
                        $_SESSION['admin_name']
                            ?? 'Administrator'
                    ) ?>
                </strong>

                <span>Administrator</span>
            </div>
        </div>

    </div>

</header>
