'use strict';

const applicantTypeInputs = document.querySelectorAll(
    'input[name="applicant_type"]'
);
const nonResidentSection = document.getElementById('nonResidentSection');
const residentProofGroup = document.getElementById('residentProofGroup');
const bridgeConnection = document.getElementById('bridge_connection');
const bridgeUseFrequency = document.getElementById('bridge_use_frequency');
const otherConnectionGroup = document.getElementById('otherConnectionGroup');
const otherConnectionInput = document.getElementById('bridge_connection_other');
const proofInput = document.getElementById('verification_proof');
const fileUploadText = document.getElementById('fileUploadText');
const fullNameInput = document.getElementById('full_name');
const barangayInput = document.getElementById('barangay');
const municipalityInput = document.getElementById('municipality');
const provinceInput = document.getElementById('province');
const notificationTitle = document.getElementById('notificationTitle');
const notificationDescription = document.getElementById('notificationDescription');
const notificationIcon = document.getElementById('notificationIcon');
const registrationForm = document.getElementById('registrationForm');
const submitButton = document.getElementById('submitRegistration');

function selectedApplicantType() {
    const checkedInput = document.querySelector(
        'input[name="applicant_type"]:checked'
    );
    return checkedInput ? checkedInput.value : 'resident';
}

function toProperCase(value) {
    return value
        .trim()
        .replace(/\s+/g, ' ')
        .toLocaleLowerCase()
        .replace(
            /(^|[\s'-])\p{L}/gu,
            character => character.toLocaleUpperCase()
        );
}

function setLocationReadonly(isReadonly) {
    [barangayInput, municipalityInput, provinceInput].forEach(input => {
        if (!input) return;
        input.readOnly = isReadonly;
        input.classList.toggle('is-readonly', isReadonly);
    });
}

function updateNotificationInformation(isResident) {
    if (!notificationTitle || !notificationDescription || !notificationIcon) {
        return;
    }

    if (isResident) {
        notificationTitle.textContent = 'Full Community Alerts';
        notificationDescription.textContent =
            'Residents receive flood warnings, weather alerts, bridge closure and reopening notices, unsafe crossing alerts, and community emergency announcements.';
        notificationIcon.className = 'bi bi-broadcast';
        return;
    }

    notificationTitle.textContent = 'Bridge Safety Alerts Only';
    notificationDescription.textContent =
        'Non-residents receive bridge closure, reopening, and unsafe crossing notifications related to the Spillway Bridge.';
    notificationIcon.className = 'bi bi-sign-stop-fill';
}

function updateOtherConnectionField() {
    if (!bridgeConnection || !otherConnectionGroup || !otherConnectionInput) {
        return;
    }

    const shouldShow =
        selectedApplicantType() === 'non_resident' &&
        bridgeConnection.value === 'other';

    otherConnectionGroup.classList.toggle('is-visible', shouldShow);
    otherConnectionInput.required = shouldShow;
    if (!shouldShow) otherConnectionInput.value = '';
}

function updateApplicantFields() {
    const isResident = selectedApplicantType() === 'resident';

    if (nonResidentSection) {
        nonResidentSection.classList.toggle('is-visible', !isResident);
    }
    if (residentProofGroup) {
        residentProofGroup.classList.toggle('is-visible', isResident);
    }
    if (proofInput) {
        proofInput.required = isResident;
        if (!isResident) {
            proofInput.value = '';
            if (fileUploadText) fileUploadText.textContent = 'Choose JPG, PNG, or PDF';
        }
    }
    if (bridgeConnection) bridgeConnection.required = !isResident;
    if (bridgeUseFrequency) bridgeUseFrequency.required = !isResident;

    if (isResident) {
        if (barangayInput) barangayInput.value = 'San Isidro';
        if (municipalityInput) municipalityInput.value = 'Rodriguez';
        if (provinceInput) provinceInput.value = 'Rizal';
        if (bridgeConnection) bridgeConnection.value = '';
        if (bridgeUseFrequency) bridgeUseFrequency.value = '';
        if (otherConnectionInput) otherConnectionInput.value = '';
    }

    setLocationReadonly(isResident);
    updateOtherConnectionField();
    updateNotificationInformation(isResident);
}

applicantTypeInputs.forEach(input => {
    input.addEventListener('change', updateApplicantFields);
});

if (bridgeConnection) {
    bridgeConnection.addEventListener('change', updateOtherConnectionField);
}

if (fullNameInput) {
    fullNameInput.addEventListener('blur', () => {
        fullNameInput.value = toProperCase(fullNameInput.value);
    });
}

if (proofInput && fileUploadText) {
    proofInput.addEventListener('change', () => {
        const file = proofInput.files && proofInput.files[0];
        fileUploadText.textContent = file
            ? file.name
            : 'Choose JPG, PNG, or PDF';
    });
}

if (registrationForm && submitButton) {
    registrationForm.addEventListener('submit', () => {
        if (fullNameInput) {
            fullNameInput.value = toProperCase(fullNameInput.value);
        }
        if (!registrationForm.checkValidity()) return;

        submitButton.disabled = true;
        submitButton.innerHTML =
            '<span>Sending Verification Code…</span>' +
            '<i class="bi bi-send-fill"></i>';
    });
}

updateApplicantFields();
