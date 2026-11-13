'use strict';

const body = document.body;

function ensureFloodGuardDialog() {
    let modal = document.getElementById('floodguardDialog');
    if (modal) return modal;

    modal = document.createElement('div');
    modal.id = 'floodguardDialog';
    modal.className = 'fg-dialog';
    modal.hidden = true;
    modal.innerHTML = `
        <div class="fg-dialog-backdrop" data-fg-dialog-cancel></div>
        <section class="fg-dialog-panel" role="dialog" aria-modal="true" aria-labelledby="fgDialogTitle">
            <div class="fg-dialog-icon"><i class="bi bi-question-circle-fill"></i></div>
            <h2 id="fgDialogTitle">Confirm action</h2>
            <p id="fgDialogMessage"></p>
            <div class="fg-dialog-actions">
                <button type="button" class="fg-dialog-secondary" data-fg-dialog-cancel>Cancel</button>
                <button type="button" class="fg-dialog-primary" data-fg-dialog-confirm>Confirm</button>
            </div>
        </section>`;
    document.body.appendChild(modal);
    return modal;
}

window.fgDialog = function ({title = 'Please confirm', message = '', confirmText = 'Confirm', type = 'confirm'} = {}) {
    const modal = ensureFloodGuardDialog();
    const panel = modal.querySelector('.fg-dialog-panel');
    const icon = modal.querySelector('.fg-dialog-icon i');
    const confirmButton = modal.querySelector('[data-fg-dialog-confirm]');
    const cancelButtons = modal.querySelectorAll('[data-fg-dialog-cancel]');

    modal.querySelector('#fgDialogTitle').textContent = title;
    modal.querySelector('#fgDialogMessage').textContent = message;
    confirmButton.textContent = type === 'message' ? 'Close' : confirmText;
    confirmButton.className = `fg-dialog-primary ${type === 'danger' ? 'danger' : ''}`;
    icon.className = `bi ${type === 'danger' ? 'bi-exclamation-triangle-fill' : type === 'message' ? 'bi-info-circle-fill' : 'bi-question-circle-fill'}`;
    panel.classList.toggle('danger', type === 'danger');
    modal.querySelector('.fg-dialog-secondary').hidden = type === 'message';
    modal.hidden = false;
    document.body.classList.add('fg-dialog-open');

    return new Promise(resolve => {
        const finish = result => {
            modal.hidden = true;
            document.body.classList.remove('fg-dialog-open');
            confirmButton.onclick = null;
            cancelButtons.forEach(button => { button.onclick = null; });
            resolve(result);
        };
        confirmButton.onclick = () => finish(true);
        cancelButtons.forEach(button => { button.onclick = () => finish(false); });
        confirmButton.focus();
    });
};

window.fgConfirm = (title, message, confirmText = 'Confirm', danger = false) => window.fgDialog({
    title, message, confirmText, type: danger ? 'danger' : 'confirm'
});
window.fgMessage = (title, message) => window.fgDialog({title, message, type: 'message'});

const mobileMenuButton =
    document.getElementById('mobileMenuButton');

const sidebarClose =
    document.getElementById('sidebarClose');

const sidebarOverlay =
    document.getElementById('sidebarOverlay');

function openSidebar() {
    body.classList.add('sidebar-open');
}

function closeSidebar() {
    body.classList.remove('sidebar-open');
}

if (mobileMenuButton) {
    mobileMenuButton.addEventListener(
        'click',
        openSidebar
    );
}

if (sidebarClose) {
    sidebarClose.addEventListener(
        'click',
        closeSidebar
    );
}

if (sidebarOverlay) {
    sidebarOverlay.addEventListener(
        'click',
        closeSidebar
    );
}

window.addEventListener('resize', () => {
    if (window.innerWidth > 850) {
        closeSidebar();
    }
});

document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
        closeSidebar();
    }
});

const liveWaterLevel = document.querySelector('[data-live-field="water_level_cm"]');

if (liveWaterLevel) {
    const liveEndpoint = '../api/v1/admin/monitoring/latest.php';
    let livePollTimer = null;

    const liveField = name => document.querySelector(`[data-live-field="${name}"]`);
    const numberText = (value, decimals, suffix) => {
        if (value === null || value === undefined || value === '') return 'No data';
        return `${Number(value).toFixed(decimals)}${suffix}`;
    };
    const labelText = value => {
        if (!value) return 'No data';
        return String(value).replaceAll('_', ' ').replace(/\b\w/g, letter => letter.toUpperCase());
    };
    const setText = (name, value) => {
        const element = liveField(name);
        if (element) element.textContent = value;
    };

    async function refreshLiveMonitoring() {
        let nextPollSeconds = 5;

        try {
            const response = await fetch(liveEndpoint, {
                headers: {'Accept': 'application/json'},
                cache: 'no-store'
            });
            if (!response.ok) throw new Error('Live monitoring request failed.');

            const payload = await response.json();
            nextPollSeconds = Number(payload.poll_after_seconds) || 5;
            const reading = Array.isArray(payload.data) ? payload.data[0] : null;
            if (!reading) return;

            const timeoutSeconds = Number(payload.offline_timeout_seconds) || 180;
            const isOnline = reading.is_active &&
                ['online', 'maintenance'].includes(String(reading.operational_status)) &&
                Number(reading.age_seconds) <= timeoutSeconds;

            setText('water_level_cm', numberText(reading.water_level_cm, 1, ' cm'));
            setText('water_distance_cm', numberText(reading.water_distance_cm, 1, ' cm'));
            setText('rain_status', Number(reading.rain_detected) === 1 ? 'Rain Detected' : 'No Rain');
            setText('rain_analog', reading.rain_analog ?? '--');
            setText('wind_speed_mps', numberText(reading.wind_speed_mps, 1, ' m/s'));
            setText('battery_percent', numberText(reading.battery_percent, 0, '%'));
            setText('battery_voltage', numberText(reading.battery_voltage, 2, ' V'));
            setText('north_barrier_status', labelText(reading.north_barrier_status));
            setText('south_barrier_status', labelText(reading.south_barrier_status));
            setText('north_obstacle', Number(reading.north_obstacle) === 1 ? 'Detected' : 'Path Clear');
            setText('south_obstacle', Number(reading.south_obstacle) === 1 ? 'Detected' : 'Path Clear');
            setText('last_update', reading.measured_at ? new Date(reading.measured_at.replace(' ', 'T')).toLocaleString() : 'No data');

            const alertBadge = liveField('alert_badge');
            if (alertBadge) {
                const condition = isOnline ? String(reading.alert_level || 'normal') : 'offline';
                alertBadge.textContent = labelText(condition);
                alertBadge.className = `status-badge status-${condition}`;
            }

            const connectionBadge = liveField('connection_badge');
            if (connectionBadge) {
                connectionBadge.textContent = isOnline ? 'Online' : 'Offline';
                connectionBadge.className = `connection-pill ${isOnline ? 'online' : 'offline'}`;
            }

            const conditionPanel = liveField('condition_panel');
            if (conditionPanel) {
                const condition = labelText(reading.alert_level || 'normal');
                const updatedAt = reading.measured_at
                    ? new Date(reading.measured_at.replace(' ', 'T')).toLocaleString()
                    : 'not recorded';
                conditionPanel.innerHTML = isOnline
                    ? `<i class="bi bi-broadcast-pin"></i><div><strong>${condition} condition detected</strong><p>Latest monitoring data received: ${updatedAt}</p></div>`
                    : `<i class="bi bi-wifi-off"></i><div><strong>Monitoring station offline</strong><p>No live reading was received within ${timeoutSeconds} seconds. Last data received: ${updatedAt}</p></div>`;
            }

            const topbar = liveField('topbar_station');
            if (topbar) {
                topbar.querySelector('.station-dot')?.classList.toggle('online', isOnline);
                topbar.querySelector('.station-dot')?.classList.toggle('offline', !isOnline);
                const status = topbar.querySelector('strong');
                if (status) status.textContent = isOnline ? 'Receiving Data' : 'Waiting for Data';
            }

            const sidebarStation = liveField('sidebar_station');
            if (sidebarStation) {
                sidebarStation.querySelector('.station-dot')?.classList.toggle('online', isOnline);
                sidebarStation.querySelector('.station-dot')?.classList.toggle('offline', !isOnline);
                const status = sidebarStation.querySelector('strong');
                if (status) status.textContent = isOnline ? 'Station Online' : 'Station Offline';
            }
        } catch (error) {
            // Preserve the last known values and retry without interrupting the operator.
        } finally {
            window.clearTimeout(livePollTimer);
            livePollTimer = window.setTimeout(refreshLiveMonitoring, Math.max(3, nextPollSeconds) * 1000);
        }
    }

    refreshLiveMonitoring();
}
