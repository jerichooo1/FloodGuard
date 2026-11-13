(() => {
    const search = document.getElementById('accountSearch');
    const filter = document.getElementById('accountRoleFilter');
    const rows = [...document.querySelectorAll('[data-account-row]')];
    const applyFilters = () => {
        const query = (search?.value || '').trim().toLowerCase();
        const role = filter?.value || 'all';
        rows.forEach((row) => {
            const matchesText = !query || row.dataset.search.includes(query);
            const matchesRole = role === 'all' || row.dataset.role === role;
            row.hidden = !(matchesText && matchesRole);
        });
    };
    search?.addEventListener('input', applyFilters);
    filter?.addEventListener('change', applyFilters);

    let returnFocus = null;
    const openModal = (id, trigger) => {
        const modal = document.getElementById(id);
        if (!modal) return;
        returnFocus = trigger || document.activeElement;
        modal.hidden = false;
        document.body.classList.add('account-modal-open');
        modal.querySelector('input:not([type="hidden"]),select,button')?.focus();
    };
    const closeModal = (modal) => {
        modal.hidden = true;
        document.body.classList.remove('account-modal-open');
        returnFocus?.focus();
    };
    document.querySelectorAll('[data-open-modal]').forEach((button) => button.addEventListener('click', () => openModal(button.dataset.openModal, button)));
    document.querySelectorAll('[data-close-modal]').forEach((element) => element.addEventListener('click', () => closeModal(element.closest('.account-modal'))));

    document.querySelectorAll('[data-edit-account]').forEach((button) => button.addEventListener('click', () => {
        const data = JSON.parse(button.dataset.editAccount || '{}');
        document.getElementById('editUserId').value = data.id;
        document.getElementById('editName').value = data.name;
        document.getElementById('editEmail').value = data.email;
        document.getElementById('editRole').value = data.role;
        document.getElementById('editStatus').value = data.status;
        document.getElementById('editAccountTitle').textContent = data.name;
        openModal('editAccountModal', button);
    }));
    document.querySelectorAll('[data-reset-account]').forEach((button) => button.addEventListener('click', () => {
        const data = JSON.parse(button.dataset.resetAccount || '{}');
        document.getElementById('resetUserId').value = data.id;
        document.getElementById('resetAccountName').textContent = data.name;
        document.getElementById('resetAccountEmail').textContent = data.email;
        openModal('resetPasswordModal', button);
    }));
    document.querySelectorAll('[data-delete-account]').forEach((button) => button.addEventListener('click', () => {
        const data = JSON.parse(button.dataset.deleteAccount || '{}');
        document.getElementById('deleteUserId').value = data.id;
        document.getElementById('deleteAccountName').textContent = data.name;
        document.getElementById('deleteAccountEmail').textContent = data.email;
        document.getElementById('deleteWarning').textContent = data.safe ? 'This unused account can be permanently deleted.' : 'This account has operational history and will be deactivated to preserve audit records.';
        document.getElementById('deleteButtonText').textContent = data.safe ? 'Delete account' : 'Deactivate account';
        openModal('deleteAccountModal', button);
    }));
    document.addEventListener('keydown', (event) => {
        const modal = document.querySelector('.account-modal:not([hidden])');
        if (!modal) return;
        if (event.key === 'Escape') closeModal(modal);
        if (event.key === 'Tab') {
            const focusable = [...modal.querySelectorAll('button:not([disabled]),input:not([disabled]),select:not([disabled])')];
            if (!focusable.length) return;
            const first = focusable[0], last = focusable[focusable.length - 1];
            if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
            if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
        }
    });
    document.querySelectorAll('[data-submit-lock]').forEach((form) => form.addEventListener('submit', () => {
        const button = form.querySelector('button[type="submit"]');
        if (button) { button.disabled = true; button.dataset.originalText = button.textContent; button.textContent = 'Saving…'; }
    }));
})();
