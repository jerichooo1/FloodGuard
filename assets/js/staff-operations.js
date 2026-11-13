(() => {
    const incidentSelect = document.getElementById('incidentSelect');
    const incidentLocation = document.getElementById('incidentLocation');
    if (incidentSelect && incidentLocation) {
        const updateIncidentLocation = () => {
            const selected = incidentSelect.options[incidentSelect.selectedIndex];
            incidentLocation.textContent = selected?.dataset.location || 'Select an incident to view its location.';
            incidentLocation.title = selected?.dataset.location || '';
        };
        incidentSelect.addEventListener('change', updateIncidentLocation);
        updateIncidentLocation();
    }

    const shell = document.getElementById('detailModal');
    if (!shell) return;
    const title = document.getElementById('modalTitle');
    const eyebrow = document.getElementById('modalEyebrow');
    const body = document.getElementById('modalBody');
    const closeButton = shell.querySelector('.modal-close');
    let returnFocus = null;

    const escape = (value) => String(value ?? '').replace(/[&<>"]/g, (char) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[char]));
    const item = (label, value, wide = false) => `<div class="modal-item${wide ? ' wide' : ''}"><span>${escape(label)}</span><strong>${escape(value || 'Not recorded')}</strong></div>`;

    const openModal = (button) => {
        const data = JSON.parse(button.dataset.details || '{}');
        returnFocus = button;
        eyebrow.textContent = data.type === 'team' ? 'Response team' : 'Response assignment';
        title.textContent = data.title || 'Details';
        let html = '<div class="modal-summary">';
        for (const detail of data.details || []) html += item(detail.label, detail.value, detail.wide);
        html += '</div>';
        if (data.members) {
            html += '<h3 class="modal-section-title">Team members</h3>';
            html += data.members.length ? data.members.map((member) => `<div class="modal-member"><i class="bi bi-person-badge"></i><div><strong>${escape(member.name)}</strong><small>${escape(member.email)}${member.lead ? ' · Team lead' : ''}</small></div></div>`).join('') : '<p class="empty-table">No responders have been added.</p>';
        }
        body.innerHTML = html;
        shell.hidden = false;
        document.body.classList.add('modal-open');
        closeButton.focus();
    };
    const closeModal = () => {
        shell.hidden = true;
        document.body.classList.remove('modal-open');
        if (returnFocus) returnFocus.focus();
    };
    document.querySelectorAll('[data-details]').forEach((button) => button.addEventListener('click', () => openModal(button)));
    shell.querySelectorAll('[data-modal-close]').forEach((element) => element.addEventListener('click', closeModal));
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && !shell.hidden) closeModal();
        if (event.key === 'Tab' && !shell.hidden) {
            const focusable = [...shell.querySelectorAll('button:not([disabled]),a[href],input:not([disabled]),select:not([disabled]),textarea:not([disabled])')];
            if (!focusable.length) return;
            const first = focusable[0];
            const last = focusable[focusable.length - 1];
            if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
            if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
        }
    });
})();

(() => {
    let activeModal = null;
    let returnFocus = null;

    const closeReportModal = () => {
        if (!activeModal) return;
        activeModal.hidden = true;
        activeModal = null;
        document.body.classList.remove('modal-open');
        if (returnFocus) returnFocus.focus();
    };

    document.querySelectorAll('[data-report-open]').forEach((button) => {
        button.addEventListener('click', () => {
            const modal = document.getElementById(button.dataset.reportOpen);
            if (!modal) return;
            returnFocus = button;
            activeModal = modal;
            modal.hidden = false;
            document.body.classList.add('modal-open');
            modal.querySelector('.modal-close')?.focus();
        });
    });

    document.querySelectorAll('[data-report-close]').forEach((element) => element.addEventListener('click', closeReportModal));
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && activeModal) closeReportModal();
        if (event.key !== 'Tab' || !activeModal) return;
        const focusable = [...activeModal.querySelectorAll('button:not([disabled]),a[href],input:not([disabled]),select:not([disabled]),textarea:not([disabled])')];
        if (!focusable.length) return;
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
        if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    });
})();
