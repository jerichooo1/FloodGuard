'use strict';

const confirmation = document.getElementById('controlConfirmation');
const commandForm = document.getElementById('deviceCommandForm');
const commandTypeInput = document.getElementById('deviceCommandType');
const confirmTitle = document.getElementById('controlConfirmTitle');
const confirmDescription = document.getElementById('controlConfirmDescription');
const confirmSubmit = document.getElementById('controlConfirmSubmit');
let selectedCommand = '';

function closeConfirmation() {
    confirmation?.classList.remove('is-open');
    confirmation?.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('control-modal-open');
    selectedCommand = '';
}

document.querySelectorAll('.control-command-button').forEach(button => {
    button.addEventListener('click', () => {
        if (button.disabled || !confirmation) return;
        selectedCommand = button.dataset.command || '';
        confirmTitle.textContent = button.dataset.title || 'Confirm command';
        confirmDescription.textContent = button.dataset.description || 'Review the command before sending it.';
        confirmation.classList.add('is-open');
        confirmation.setAttribute('aria-hidden', 'false');
        document.body.classList.add('control-modal-open');
        confirmSubmit.focus();
    });
});

document.querySelectorAll('[data-control-close]').forEach(button => button.addEventListener('click', closeConfirmation));

confirmSubmit?.addEventListener('click', async () => {
    if (!selectedCommand || !commandForm || !commandTypeInput) return;
    commandTypeInput.value = selectedCommand;
    confirmSubmit.disabled = true;
    confirmSubmit.innerHTML = '<i class="bi bi-hourglass-split"></i> Sending…';

    try {
        const response = await fetch('controls.php', {
            method: 'POST',
            headers: {'X-Requested-With': 'XMLHttpRequest'},
            body: new FormData(commandForm)
        });
        const result = await response.json();
        if (!response.ok || !result.success) throw new Error(result.message || 'The command could not be queued.');
        window.location.reload();
    } catch (error) {
        confirmDescription.textContent = error.message;
        confirmSubmit.disabled = false;
        confirmSubmit.innerHTML = '<i class="bi bi-send-fill"></i> Try Again';
    }
});

const detailsDialog = document.getElementById('commandDetailsDialog');
const detailFields = {
    command: document.getElementById('detailsCommand'), id: document.getElementById('detailsId'),
    status: document.getElementById('detailsStatus'), requested_by: document.getElementById('detailsRequestedBy'),
    requested_at: document.getElementById('detailsRequestedAt'), claimed_at: document.getElementById('detailsClaimedAt'),
    completed_at: document.getElementById('detailsCompletedAt'), expires_at: document.getElementById('detailsExpiresAt'),
    result: document.getElementById('detailsResult')
};

function openDetails(row) {
    if (!detailsDialog) return;
    let details;
    try { details = JSON.parse(row.dataset.commandDetails || '{}'); } catch { return; }
    Object.entries(detailFields).forEach(([key, element]) => { if (element) element.textContent = details[key] ?? '—'; });
    detailsDialog.showModal();
}

document.querySelectorAll('.command-row').forEach(row => {
    row.addEventListener('click', () => openDetails(row));
    row.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); openDetails(row); }
    });
    row.querySelector('.view-command-button')?.addEventListener('click', event => { event.stopPropagation(); openDetails(row); });
});

detailsDialog?.querySelector('[data-details-close]')?.addEventListener('click', () => detailsDialog.close());
detailsDialog?.addEventListener('click', event => { if (event.target === detailsDialog) detailsDialog.close(); });
