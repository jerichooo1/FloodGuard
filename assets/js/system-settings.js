'use strict';

const settingsForms = document.querySelectorAll('[data-settings-form]');
const unsavedNotice = document.getElementById('settingsUnsaved');
const navigationButtons = document.querySelectorAll('[data-settings-target]');
let dirtyForms = new Set();

function updateUnsavedNotice() {
    unsavedNotice?.classList.toggle('is-visible', dirtyForms.size > 0);
    unsavedNotice?.setAttribute('aria-hidden', dirtyForms.size > 0 ? 'false' : 'true');
}

settingsForms.forEach(form => {
    form.addEventListener('input', () => {
        dirtyForms.add(form);
        updateUnsavedNotice();
    });

    form.addEventListener('change', () => {
        dirtyForms.add(form);
        updateUnsavedNotice();
    });

    form.addEventListener('reset', () => {
        window.setTimeout(() => {
            dirtyForms.delete(form);
            updateUnsavedNotice();
        }, 0);
    });

    form.addEventListener('submit', event => {
        const section = form.querySelector('[name="settings_section"]')?.value;

        if (section === 'monitoring') {
            const sensorHeight = Number(form.elements.sensor_height_cm.value);
            const warningLevel = Number(form.elements.warning_level_cm.value);
            const criticalLevel = Number(form.elements.critical_level_cm.value);
            const rainWarning = Number(form.elements.rain_warning_threshold.value);
            const rainCritical = Number(form.elements.rain_critical_threshold.value);
            const windWarning = Number(form.elements.wind_warning_mps.value);
            const windCritical = Number(form.elements.wind_critical_mps.value);

            if (warningLevel > sensorHeight || criticalLevel > sensorHeight) {
                event.preventDefault();
                window.fgMessage('Invalid water-level settings', 'Warning and Critical water levels cannot be higher than the sensor height.');
                return;
            }

            if (criticalLevel <= warningLevel) {
                event.preventDefault();
                window.fgMessage('Invalid threshold order', 'Critical water level must be higher than the Warning water level.');
                return;
            }

            if (rainCritical >= rainWarning) {
                event.preventDefault();
                window.fgMessage('Invalid rain thresholds', 'Critical rain must use a lower raw analog value than Warning.');
                return;
            }

            if (windCritical <= windWarning) {
                event.preventDefault();
                window.fgMessage('Invalid wind thresholds', 'Critical wind speed must be higher than Warning wind speed.');
                return;
            }
        }

        dirtyForms.delete(form);
        updateUnsavedNotice();
        const submitButton = form.querySelector('.settings-save-button');

        if (submitButton) {
            submitButton.disabled = true;
            submitButton.innerHTML = '<i class="bi bi-hourglass-split"></i> Saving…';
        }
    });
});

navigationButtons.forEach(button => {
    button.addEventListener('click', () => {
        const target = document.getElementById(button.dataset.settingsTarget || '');
        if (!target) return;

        navigationButtons.forEach(item => item.classList.toggle('is-active', item === button));
        target.scrollIntoView({behavior: 'smooth', block: 'start'});
    });
});

document.addEventListener('click', async event => {
    const link = event.target.closest('a[href]');
    if (!link || dirtyForms.size === 0 || link.target === '_blank') return;
    event.preventDefault();
    const leave = await window.fgConfirm(
        'Discard unsaved changes?',
        'You changed one or more settings. Leaving this page will discard those changes.',
        'Discard and leave',
        true
    );
    if (leave) window.location.href = link.href;
});

const observedSections = [...document.querySelectorAll('.settings-panel')];

if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
        const visible = entries
            .filter(entry => entry.isIntersecting)
            .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

        if (!visible) return;

        navigationButtons.forEach(button => {
            button.classList.toggle('is-active', button.dataset.settingsTarget === visible.target.id);
        });
    }, {rootMargin: '-20% 0px -65% 0px', threshold: [0, .2, .5]});

    observedSections.forEach(section => observer.observe(section));
}
