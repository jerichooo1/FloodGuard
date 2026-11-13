
'use strict';

const sensorModal = document.getElementById('sensorDetailsModal');
const sensorRows = document.querySelectorAll('.sensor-reading-row');
const closeSensorModalButtons = document.querySelectorAll('[data-close-sensor-modal]');

let lastSensorTrigger = null;

function decodeSensorRecord(encodedRecord) {
    try {
        const binaryString = window.atob(encodedRecord);
        const bytes = Uint8Array.from(
            binaryString,
            character => character.charCodeAt(0)
        );

        return JSON.parse(
            new TextDecoder('utf-8').decode(bytes)
        );
    } catch (error) {
        console.error('Unable to decode the sensor record.', error);
        return null;
    }
}

function setSensorText(elementId, value, fallback = 'No data') {
    const element = document.getElementById(elementId);

    if (!element) {
        return;
    }

    element.textContent =
        value === null || value === undefined || value === ''
            ? fallback
            : String(value);
}

function statusClass(status) {
    const normalized = String(status || '').toLowerCase();

    if (['normal', 'online', 'open', 'path_clear', 'safe', 'healthy'].includes(normalized)) {
        return 'status-normal';
    }

    if (['warning', 'maintenance', 'opening', 'closing', 'watch', 'warning_soon', 'suspect'].includes(normalized)) {
        return 'status-warning';
    }

    if (['critical', 'sensor_error', 'closed', 'obstacle_detected', 'fault'].includes(normalized)) {
        return 'status-critical';
    }

    return 'status-offline';
}

function updateStatusPill(elementId, label, rawStatus) {
    const element = document.getElementById(elementId);

    if (!element) {
        return;
    }

    element.textContent = label || 'No data';
    element.className = `sensor-modal-pill ${statusClass(rawStatus)}`;
}

function formatRawPayload(rawPayload) {
    if (!rawPayload || rawPayload.trim() === '') {
        return 'No raw payload stored.';
    }

    try {
        const parsedPayload = JSON.parse(rawPayload);
        return JSON.stringify(parsedPayload, null, 2);
    } catch (error) {
        return rawPayload;
    }
}

function populateSensorModal(record) {
    setSensorText('modalRecordId', record.id);
    setSensorText('modalDeviceId', record.device_id);
    setSensorText('modalRecordedAt', record.created_at);

    updateStatusPill(
        'modalAlertLevel',
        record.alert_level,
        record.alert_level_raw
    );

    updateStatusPill(
        'modalPredictionStatus',
        record.prediction_status,
        record.prediction_status_raw
    );

    updateStatusPill(
        'modalSensorHealth',
        record.sensor_health,
        record.sensor_health_raw
    );

    updateStatusPill(
        'modalDeviceStatus',
        record.device_status,
        record.device_status_raw
    );

    setSensorText('modalWaterLevel', record.water_level_cm);
    setSensorText('modalWaterDistance', record.water_distance_cm);
    setSensorText('modalRiseRate', record.rise_rate_cm_min);
    setSensorText('modalPredictionMinutes', record.predicted_minutes_to_warning);
    setSensorText('modalPredictionLabel', record.prediction_status);
    setSensorText('modalSensorHealthText', record.sensor_health);
    setSensorText('modalRainDetected', record.rain_detected);
    setSensorText('modalRainAnalog', record.rain_analog);
    setSensorText('modalWindSpeed', record.wind_speed_mps);
    setSensorText('modalNorthBarrier', record.north_barrier_status);
    setSensorText('modalSouthBarrier', record.south_barrier_status);
    setSensorText('modalNorthObstacle', record.north_obstacle);
    setSensorText('modalSouthObstacle', record.south_obstacle);
    setSensorText('modalBatteryVoltage', record.battery_voltage);
    setSensorText('modalBatteryPercent', record.battery_percent);
    setSensorText('modalRawPayload', formatRawPayload(record.raw_payload));
}

function openSensorModal(trigger) {
    if (!sensorModal || !trigger) {
        return;
    }

    const encodedRecord = trigger.dataset.sensorRecord;
    const record = decodeSensorRecord(encodedRecord);

    if (!record) {
        return;
    }

    lastSensorTrigger = trigger;
    populateSensorModal(record);

    sensorModal.classList.add('is-open');
    sensorModal.setAttribute('aria-hidden', 'false');
    document.body.classList.add('sensor-modal-open');

    const closeButton = sensorModal.querySelector('.sensor-modal-close');

    if (closeButton) {
        closeButton.focus();
    }
}

function closeSensorModal() {
    if (!sensorModal) {
        return;
    }

    sensorModal.classList.remove('is-open');
    sensorModal.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('sensor-modal-open');

    if (lastSensorTrigger) {
        lastSensorTrigger.focus();
    }
}

sensorRows.forEach(row => {
    row.addEventListener('click', event => {
        if (event.target.closest('.view-sensor-button')) {
            return;
        }

        openSensorModal(row);
    });

    row.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            openSensorModal(row);
        }
    });

    const eyeButton = row.querySelector('.view-sensor-button');

    if (eyeButton) {
        eyeButton.addEventListener('click', event => {
            event.preventDefault();
            event.stopPropagation();
            openSensorModal(row);
        });
    }
});

closeSensorModalButtons.forEach(button => {
    button.addEventListener('click', closeSensorModal);
});

document.addEventListener('keydown', event => {
    if (
        event.key === 'Escape' &&
        sensorModal &&
        sensorModal.classList.contains('is-open')
    ) {
        closeSensorModal();
    }
});
