'use strict';

// FloodGuard SMS registration administration interactions.

const registrationModal = document.getElementById('registrationModal');
const registrationRows = document.querySelectorAll('.registration-row');
const viewRegistrationButtons = document.querySelectorAll(
    '.view-registration-button'
);
const modalCloseButtons = document.querySelectorAll('[data-modal-close]');

const actionForm = document.getElementById('registrationActionForm');
const registrationIdInput = document.getElementById('modalRegistrationId');
const approveButton = document.getElementById('modalApproveButton');
const rejectToggle = document.getElementById('modalRejectToggle');
const confirmRejectButton = document.getElementById('modalConfirmReject');
const cancelRejectButton = document.getElementById('modalCancelReject');
const rejectReasonPanel = document.getElementById('rejectReasonPanel');
const rejectionReasonInput = document.getElementById('rejectionReason');
const alreadyReviewedMessage = document.getElementById('alreadyReviewedMessage');

const actionConfirmationModal = document.getElementById('actionConfirmationModal');
const actionConfirmationCloseButtons = document.querySelectorAll(
    '[data-action-confirmation-close]'
);
const actionConfirmationIcon = document.getElementById('actionConfirmationIcon');
const actionConfirmationTitle = document.getElementById('actionConfirmationTitle');
const actionConfirmationMessage = document.getElementById('actionConfirmationMessage');
const actionConfirmationReference = document.getElementById(
    'actionConfirmationReference'
);
const actionConfirmationSubmit = document.getElementById('actionConfirmationSubmit');

let lastFocusedElement = null;
let confirmationLastFocusedElement = null;
let activeRegistration = null;
let pendingActionSubmitter = null;
let actionSubmissionConfirmed = false;

function setText(id, value, fallback = '—') {
    const element = document.getElementById(id);

    if (!element) {
        return;
    }

    const normalized = value === null || value === undefined || value === ''
        ? fallback
        : String(value);

    element.textContent = normalized;
}

function setVisible(element, visible) {
    if (!element) {
        return;
    }

    element.classList.toggle('is-hidden', !visible);
}

function resetRejectMode() {
    if (!actionForm || !rejectReasonPanel || !rejectionReasonInput) {
        return;
    }

    actionForm.classList.remove('rejecting');
    rejectReasonPanel.classList.remove('is-visible');
    rejectionReasonInput.value = '';
    rejectionReasonInput.required = false;
    rejectionReasonInput.setCustomValidity('');
}

function configureActionButtons(registration) {
    if (
        !approveButton ||
        !rejectToggle ||
        !alreadyReviewedMessage ||
        !actionForm
    ) {
        return;
    }

    resetRejectMode();

    const status = registration.registration_status;
    const canApprove = status !== 'approved' && status !== 'unsubscribed';
    const canReject = status !== 'rejected' && status !== 'unsubscribed';

    setVisible(approveButton, canApprove);
    setVisible(rejectToggle, canReject);
    setVisible(confirmRejectButton, canReject);
    setVisible(cancelRejectButton, canReject);

    alreadyReviewedMessage.classList.remove('is-visible');
    alreadyReviewedMessage.textContent = '';

    if (status === 'approved') {
        alreadyReviewedMessage.textContent =
            'This registration is approved. It may still be rejected later if the submitted information is found to be invalid.';
        alreadyReviewedMessage.classList.add('is-visible');
    } else if (status === 'rejected') {
        alreadyReviewedMessage.textContent =
            'This registration is rejected. Approving it will replace the previous rejection decision.';
        alreadyReviewedMessage.classList.add('is-visible');
    } else if (status === 'unsubscribed') {
        alreadyReviewedMessage.textContent =
            'This recipient has unsubscribed. Review actions are unavailable.';
        alreadyReviewedMessage.classList.add('is-visible');
    }
}

function populateModal(registration) {
    activeRegistration = registration;

    setText('modalReferenceNumber', registration.reference_no);
    setText('modalFullName', registration.full_name);
    setText('modalApplicantType', registration.applicant_type_label);
    setText('modalRegisteredAt', registration.created_at);
    setText('modalMobileNumber', registration.mobile_number);
    setText(
        'modalMobileVerified',
        registration.mobile_verified ? 'Verified' : 'Unverified'
    );
    setText('modalNotificationScope', registration.notification_scope);
    setText('modalCompleteAddress', registration.complete_address);
    setText('modalPurokSitio', registration.purok_sitio);
    setText('modalBarangay', registration.barangay);
    setText(
        'modalMunicipalityProvince',
        `${registration.municipality}, ${registration.province}`
    );
    setText('modalBridgeConnection', registration.bridge_connection);
    setText('modalBridgeConnectionOther', registration.bridge_connection_other);
    setText('modalBridgeFrequency', registration.bridge_use_frequency);
    setText('modalSmsConsent', registration.sms_consent ? 'Granted' : 'Not granted');
    setText(
        'modalPrivacyConsent',
        registration.privacy_consent ? 'Granted' : 'Not granted'
    );
    setText('modalReviewer', registration.reviewer_name);
    setText('modalReviewedAt', registration.reviewed_at);
    setText('modalRejectionReason', registration.rejection_reason);

    const avatar = document.getElementById('modalApplicantAvatar');
    if (avatar) {
        avatar.textContent = registration.full_name
            ? registration.full_name.charAt(0).toUpperCase()
            : 'A';
    }

    const statusBadge = document.getElementById('modalStatusBadge');
    if (statusBadge) {
        statusBadge.textContent = registration.registration_status_label;
        statusBadge.className =
            `modal-status-badge ${registration.registration_status}`;
    }

    const bridgeCard = document.getElementById('modalBridgeCard');
    setVisible(bridgeCard, registration.applicant_type === 'non_resident');

    const bridgeOtherRow = document.getElementById('modalBridgeOtherRow');
    setVisible(
        bridgeOtherRow,
        registration.applicant_type === 'non_resident' &&
        Boolean(registration.bridge_connection_other)
    );

    const proofAvailable = document.getElementById('modalProofAvailable');
    const proofEmpty = document.getElementById('modalProofEmpty');
    const proofLink = document.getElementById('modalProofLink');

    setVisible(proofAvailable, registration.proof_available);
    setVisible(proofEmpty, !registration.proof_available);

    if (registration.proof_available) {
        setText('modalProofName', registration.proof_name);
        setText(
            'modalProofMeta',
            `${registration.proof_type} • ${registration.proof_size}`
        );

        if (proofLink) {
            proofLink.href = registration.proof_url;
        }
    } else if (proofLink) {
        proofLink.removeAttribute('href');
    }

    const rejectionReasonRow = document.getElementById('modalRejectionReasonRow');
    setVisible(rejectionReasonRow, Boolean(registration.rejection_reason));

    if (registrationIdInput) {
        registrationIdInput.value = String(registration.id);
    }

    configureActionButtons(registration);
}

function openRegistrationModal(row) {
    if (!registrationModal) {
        return;
    }

    let registration;

    try {
        registration = JSON.parse(row.dataset.registration || '{}');
    } catch (error) {
        console.error('Unable to read registration details.', error);
        return;
    }

    lastFocusedElement = document.activeElement;
    populateModal(registration);

    registrationModal.classList.add('is-open');
    registrationModal.setAttribute('aria-hidden', 'false');
    document.body.classList.add('modal-open');

    const closeButton = registrationModal.querySelector('.registration-modal-close');
    if (closeButton) {
        closeButton.focus();
    }
}

function closeRegistrationModal() {
    if (!registrationModal) {
        return;
    }

    closeActionConfirmationModal(false);

    registrationModal.classList.remove('is-open');
    registrationModal.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('modal-open');
    resetRejectMode();
    activeRegistration = null;

    if (lastFocusedElement instanceof HTMLElement) {
        lastFocusedElement.focus();
    }
}

function openActionConfirmationModal(action, submitter) {
    if (
        !actionConfirmationModal ||
        !actionConfirmationIcon ||
        !actionConfirmationTitle ||
        !actionConfirmationMessage ||
        !actionConfirmationReference ||
        !actionConfirmationSubmit
    ) {
        return;
    }

    pendingActionSubmitter = submitter;
    confirmationLastFocusedElement = document.activeElement;

    const reference = activeRegistration?.reference_no || 'Selected registration';
    actionConfirmationReference.textContent = reference;

    const icon = actionConfirmationIcon.querySelector('i');
    const buttonLabel = actionConfirmationSubmit.querySelector('span');

    actionConfirmationIcon.className = `action-confirmation-icon ${action}`;
    actionConfirmationSubmit.className = `action-confirmation-submit ${action}`;

    if (action === 'approve') {
        if (icon) {
            icon.className = 'bi bi-check-circle-fill';
        }

        actionConfirmationTitle.textContent = 'Approve this registration?';
        actionConfirmationMessage.textContent =
            'The applicant will become an approved FloodGuard SMS recipient after this action is completed.';

        if (buttonLabel) {
            buttonLabel.textContent = 'Approve Registration';
        }
    } else {
        if (icon) {
            icon.className = 'bi bi-x-circle-fill';
        }

        actionConfirmationTitle.textContent = 'Reject this registration?';
        actionConfirmationMessage.textContent =
            'The registration will be marked as rejected. An SMS containing the reason and instructions to register again will be queued for the applicant.';

        if (buttonLabel) {
            buttonLabel.textContent = 'Reject Registration';
        }
    }

    actionConfirmationSubmit.disabled = false;
    actionConfirmationModal.classList.add('is-open');
    actionConfirmationModal.setAttribute('aria-hidden', 'false');

    window.requestAnimationFrame(() => {
        actionConfirmationSubmit.focus();
    });
}

function closeActionConfirmationModal(restoreFocus = true) {
    if (!actionConfirmationModal) {
        return;
    }

    actionConfirmationModal.classList.remove('is-open');
    actionConfirmationModal.setAttribute('aria-hidden', 'true');
    pendingActionSubmitter = null;

    if (
        restoreFocus &&
        confirmationLastFocusedElement instanceof HTMLElement
    ) {
        confirmationLastFocusedElement.focus();
    }

    confirmationLastFocusedElement = null;
}

registrationRows.forEach(row => {
    row.addEventListener('click', event => {
        if (event.target.closest('a, button, input, select, textarea')) {
            return;
        }

        openRegistrationModal(row);
    });

    row.addEventListener('keydown', event => {
        if (event.target.closest('a, button, input, select, textarea')) {
            return;
        }

        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            openRegistrationModal(row);
        }
    });
});

viewRegistrationButtons.forEach(button => {
    button.addEventListener('click', event => {
        event.preventDefault();
        event.stopPropagation();

        const row = button.closest('.registration-row');

        if (row) {
            openRegistrationModal(row);
        }
    });
});

modalCloseButtons.forEach(button => {
    button.addEventListener('click', closeRegistrationModal);
});

if (rejectToggle && rejectReasonPanel && rejectionReasonInput && actionForm) {
    rejectToggle.addEventListener('click', () => {
        actionForm.classList.add('rejecting');
        rejectReasonPanel.classList.add('is-visible');
        rejectionReasonInput.required = true;
        rejectionReasonInput.focus();
    });
}

if (cancelRejectButton) {
    cancelRejectButton.addEventListener('click', resetRejectMode);
}

if (actionForm) {
    actionForm.addEventListener('submit', event => {
        if (actionSubmissionConfirmed) {
            actionSubmissionConfirmed = false;
            return;
        }

        event.preventDefault();

        const submitter = event.submitter;
        const action = submitter instanceof HTMLButtonElement
            ? submitter.value
            : '';

        if (!['approve', 'reject'].includes(action)) {
            return;
        }

        if (action === 'reject' && rejectionReasonInput) {
            const reason = rejectionReasonInput.value.trim();

            if (reason.length < 5) {
                rejectionReasonInput.setCustomValidity(
                    'Enter a rejection reason containing at least 5 characters.'
                );
                rejectionReasonInput.reportValidity();
                return;
            }

            rejectionReasonInput.setCustomValidity('');
        }

        openActionConfirmationModal(action, submitter);
    });
}

if (actionConfirmationSubmit) {
    actionConfirmationSubmit.addEventListener('click', () => {
        if (
            !actionForm ||
            !(pendingActionSubmitter instanceof HTMLButtonElement)
        ) {
            return;
        }

        const submitter = pendingActionSubmitter;

        actionConfirmationSubmit.disabled = true;
        actionConfirmationSubmit.innerHTML =
            '<span>Processing…</span>';

        actionSubmissionConfirmed = true;
        actionForm.requestSubmit(submitter);
    });
}

actionConfirmationCloseButtons.forEach(button => {
    button.addEventListener('click', () => {
        closeActionConfirmationModal(true);
    });
});

if (rejectionReasonInput) {
    rejectionReasonInput.addEventListener('input', () => {
        rejectionReasonInput.setCustomValidity('');
    });
}

document.addEventListener('keydown', event => {
    if (event.key !== 'Escape') {
        return;
    }

    if (
        actionConfirmationModal &&
        actionConfirmationModal.classList.contains('is-open')
    ) {
        closeActionConfirmationModal(true);
        return;
    }

    if (
        registrationModal &&
        registrationModal.classList.contains('is-open')
    ) {
        closeRegistrationModal();
    }
});