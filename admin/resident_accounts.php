<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/../app/Audit/AuditLogger.php';
require_once __DIR__ . '/../app/Mail/Mailer.php';

date_default_timezone_set('Asia/Manila');
try { $pdo->exec("SET time_zone = '+08:00'"); } catch (PDOException $exception) { /* Use server timezone. */ }

if (!isset($currentPermissions['users.manage'])) {
    http_response_code(403);
    exit('Resident account management permission is required.');
}

function residentAccountEscape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

$flash = $_SESSION['resident_account_flash'] ?? null;
unset($_SESSION['resident_account_flash']);
$csrf = floodguardCsrfToken('resident_accounts');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!floodguardVerifyCsrf((string) ($_POST['csrf_token'] ?? ''), 'resident_accounts')) {
            throw new RuntimeException('The form expired. Refresh the page and try again.');
        }
        $userId = filter_var($_POST['user_id'] ?? null, FILTER_VALIDATE_INT, [
            'options' => ['min_range' => 1],
        ]);
        $action = (string) ($_POST['action'] ?? '');
        if (!$userId || !in_array($action, ['approve', 'reject'], true)) {
            throw new InvalidArgumentException('Select a valid resident application action.');
        }
        $reason = trim((string) ($_POST['rejection_reason'] ?? ''));
        if ($action === 'reject' && (mb_strlen($reason) < 5 || mb_strlen($reason) > 500)) {
            throw new InvalidArgumentException('Enter a rejection reason containing 5–500 characters.');
        }

        $pdo->beginTransaction();
        $statement = $pdo->prepare(
            'SELECT u.id,u.full_name,u.email,u.email_verified_at,u.account_status,
                    rp.approval_status,rp.verification_proof_path
             FROM users u
             JOIN resident_profiles rp ON rp.user_id=u.id
             JOIN user_roles ur ON ur.user_id=u.id
             JOIN roles r ON r.id=ur.role_id AND r.slug="resident"
             WHERE u.id=:id
             LIMIT 1 FOR UPDATE'
        );
        $statement->execute([':id' => $userId]);
        $resident = $statement->fetch(PDO::FETCH_ASSOC);
        if (!$resident) throw new RuntimeException('The resident application was not found.');
        if ($resident['email_verified_at'] === null) {
            throw new RuntimeException('The resident must verify their email before this application can be reviewed.');
        }
        if ($resident['approval_status'] !== 'pending') {
            throw new RuntimeException('This application already has a final decision and cannot be changed.');
        }

        if ($action === 'approve') {
            if (empty($resident['verification_proof_path'])) {
                throw new RuntimeException('This application has no proof image to review.');
            }
            $accountStatus = $resident['email_verified_at'] === null ? 'pending' : 'active';
            $pdo->prepare(
                'UPDATE resident_profiles
                 SET approval_status="approved",reviewed_by=:reviewer,reviewed_at=NOW(),rejection_reason=NULL
                 WHERE user_id=:id'
            )->execute([':reviewer' => $currentUser['id'], ':id' => $userId]);
            $pdo->prepare(
                'UPDATE users SET account_status=:status,token_version=token_version+1 WHERE id=:id'
            )->execute([':status' => $accountStatus, ':id' => $userId]);
            $message = $accountStatus === 'active'
                ? 'Resident application approved. The account can now sign in.'
                : 'Resident application approved. The account will activate after email verification.';
        } else {
            $pdo->prepare(
                'UPDATE resident_profiles
                 SET approval_status="rejected",reviewed_by=:reviewer,reviewed_at=NOW(),rejection_reason=:reason
                 WHERE user_id=:id'
            )->execute([':reviewer' => $currentUser['id'], ':reason' => $reason, ':id' => $userId]);
            $pdo->prepare(
                'UPDATE users SET account_status="inactive",token_version=token_version+1 WHERE id=:id'
            )->execute([':id' => $userId]);
            $pdo->prepare(
                'UPDATE api_tokens SET revoked_at=COALESCE(revoked_at,NOW()) WHERE user_id=:id'
            )->execute([':id' => $userId]);
            $message = 'Resident application rejected.';
        }

        floodguardAudit(
            $pdo,
            (int) $currentUser['id'],
            'resident_account.' . $action,
            'user',
            (int) $userId,
            ['approval_status' => $resident['approval_status'], 'account_status' => $resident['account_status']],
            ['approval_status' => $action === 'approve' ? 'approved' : 'rejected', 'reason' => $reason ?: null]
        );
        $pdo->commit();
        $emailSent = floodguardSendResidentDecisionEmail(
            (string) $resident['email'],
            (string) $resident['full_name'],
            $action === 'approve' ? 'approved' : 'rejected',
            $action === 'reject' ? $reason : null,
            $resident['email_verified_at'] !== null
        );
        $message .= $emailSent
            ? ' A notification email was sent to the resident.'
            : ' The decision was saved, but the notification email could not be sent. Check the SMTP configuration.';
        floodguardRotateCsrf('resident_accounts');
        $_SESSION['resident_account_flash'] = ['type' => 'success', 'message' => $message];
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $_SESSION['resident_account_flash'] = ['type' => 'error', 'message' => $exception->getMessage()];
    }
    header('Location: resident_accounts.php');
    exit;
}

$status = (string) ($_GET['status'] ?? 'pending');
if (!in_array($status, ['all', 'pending', 'approved', 'rejected'], true)) $status = 'pending';
$where = $status === 'all' ? '' : ' AND rp.approval_status=:status';
$statement = $pdo->prepare(
    'SELECT u.id,u.full_name,u.email,u.email_verified_at,u.account_status,u.created_at,
            rp.mobile_number,rp.address_line,rp.approval_status,rp.reviewed_at,
            rp.rejection_reason,rp.verification_proof_path,rp.notification_consented_at,
            reviewer.full_name AS reviewer_name
     FROM users u
     JOIN resident_profiles rp ON rp.user_id=u.id
     JOIN user_roles ur ON ur.user_id=u.id
     JOIN roles r ON r.id=ur.role_id AND r.slug="resident"
     LEFT JOIN users reviewer ON reviewer.id=rp.reviewed_by
     WHERE u.email_verified_at IS NOT NULL' . $where . '
     ORDER BY FIELD(rp.approval_status,"pending","rejected","approved"),u.created_at DESC'
);
$statement->execute($status === 'all' ? [] : [':status' => $status]);
$applications = $statement->fetchAll(PDO::FETCH_ASSOC);

$counts = ['pending' => 0, 'approved' => 0, 'rejected' => 0];
foreach ($pdo->query('SELECT rp.approval_status,COUNT(*) AS total FROM resident_profiles rp JOIN users u ON u.id=rp.user_id WHERE u.email_verified_at IS NOT NULL GROUP BY rp.approval_status')->fetchAll(PDO::FETCH_ASSOC) as $row) {
    if (isset($counts[$row['approval_status']])) $counts[$row['approval_status']] = (int) $row['total'];
}
$awaitingEmailVerification = (int) $pdo->query('SELECT COUNT(*) FROM resident_profiles rp JOIN users u ON u.id=rp.user_id WHERE u.email_verified_at IS NULL')->fetchColumn();

$pageTitle = 'Resident Applications';
$pageSubtitle = 'Review proof of residency before activating mobile accounts.';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Resident Applications | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <style>
        .resident-review{display:grid;gap:20px}.review-summary{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px}.review-summary a,.review-summary div,.application-table{background:#fff;border:1px solid #dce7f1;border-radius:18px}.review-summary a,.review-summary div{padding:18px;text-decoration:none;color:#082f55}.review-summary strong{display:block;font-size:28px;margin-top:5px}.review-summary small{display:block;color:#64748b;margin-top:4px}.review-filters{display:flex;gap:8px;flex-wrap:wrap}.review-filters a{padding:9px 14px;border:1px solid #cbdbea;border-radius:999px;background:#fff;color:#31506f;text-decoration:none;font-weight:700}.review-filters a.active{background:#0b5cab;border-color:#0b5cab;color:#fff}.application-table{overflow:hidden}.application-row{display:grid;grid-template-columns:minmax(220px,1.5fr) minmax(150px,.8fr) 130px 132px;gap:16px;align-items:center;padding:16px 20px;border-bottom:1px solid #e7eef5}.application-row:last-child{border-bottom:0}.application-row:hover{background:#f8fbfe}.resident-name{font-weight:800;color:#082f55}.resident-email,.submitted-label{display:block;margin-top:3px;color:#64748b;font-size:14px}.status-pill{display:inline-flex;justify-content:center;border-radius:999px;padding:7px 11px;font-size:12px;font-weight:800;text-transform:uppercase;background:#fff0c7;color:#9a5a00}.status-pill.approved{background:#d8f8e8;color:#08764d}.status-pill.rejected{background:#ffe0e0;color:#b42318}.view-application{border:1px solid #aed2f4;border-radius:10px;padding:9px 12px;background:#edf7ff;color:#07559d;font-weight:800;cursor:pointer}.review-alert{padding:14px 16px;border-radius:12px}.review-alert.success{background:#dcfce7;color:#166534}.review-alert.error{background:#fee2e2;color:#991b1b}.empty-review{padding:50px;text-align:center;color:#64748b}.review-modal[hidden]{display:none}.review-modal{position:fixed;inset:0;z-index:2000;display:grid;place-items:center;padding:24px}.modal-backdrop{position:absolute;inset:0;background:rgba(3,22,39,.62)}.modal-panel{position:relative;width:min(920px,100%);max-height:90vh;overflow:auto;background:#fff;border-radius:20px;box-shadow:0 24px 70px rgba(0,20,40,.3)}.modal-head{position:sticky;top:0;z-index:2;display:flex;justify-content:space-between;gap:16px;align-items:flex-start;padding:20px 24px;background:#fff;border-bottom:1px solid #e1eaf2}.modal-head h2{margin:3px 0 0;color:#082f55}.modal-close{border:0;background:#edf3f8;border-radius:50%;width:38px;height:38px;font-size:22px;cursor:pointer}.modal-body{display:grid;grid-template-columns:minmax(0,1fr) minmax(260px,.7fr);gap:24px;padding:24px}.details{display:grid;grid-template-columns:145px 1fr;gap:12px}.details dt{color:#64748b}.details dd{margin:0;font-weight:650;color:#12263f;overflow-wrap:anywhere}.proof{width:100%;max-height:340px;object-fit:contain;background:#f3f7fb;border-radius:14px;border:1px solid #dce7f1}.decision,.final-decision{margin:0 24px 24px;padding:18px;border-radius:14px}.decision{display:grid;gap:12px;background:#f5f9fd;border:1px solid #dce7f1}.decision textarea{width:100%;min-height:88px;box-sizing:border-box;border:1px solid #b9cada;border-radius:11px;padding:12px;resize:vertical}.decision-actions{display:flex;justify-content:flex-end;gap:10px;flex-wrap:wrap}.approve,.reject{border:0;border-radius:11px;padding:11px 16px;color:#fff;font-weight:800;cursor:pointer}.approve{background:#07845b}.reject{background:#d23131}.final-decision{background:#f3f7fb;color:#31506f}.final-decision.rejected{background:#fff1f1;color:#8f1d1d}.final-decision strong{display:block;margin-bottom:5px}.no-proof{color:#64748b}.modal-open{overflow:hidden}@media(max-width:1000px){.review-summary{grid-template-columns:repeat(2,1fr)}}@media(max-width:760px){.review-summary{grid-template-columns:1fr}.application-row{grid-template-columns:1fr auto}.application-row .submitted{display:none}.application-row .view-application{grid-column:1/-1}.modal-body{grid-template-columns:1fr}.details{grid-template-columns:1fr}.details dt{margin-top:6px}.review-modal{padding:10px}.modal-panel{max-height:96vh}.modal-head,.modal-body{padding:18px}.decision,.final-decision{margin:0 18px 18px}}
        .decision[hidden],.final-decision[hidden]{display:none}
    </style>
</head>
<body>
<?php require __DIR__ . '/includes/sidebar.php'; ?>
<div class="admin-page">
<?php require __DIR__ . '/includes/topbar.php'; ?>
<main class="admin-content standard-admin-page resident-review">
    <?php if (is_array($flash)): ?><div class="review-alert <?= residentAccountEscape($flash['type'] ?? 'error') ?>"><?= residentAccountEscape($flash['message'] ?? '') ?></div><?php endif; ?>
    <section class="review-summary">
        <div><span>Awaiting email verification</span><strong><?= $awaitingEmailVerification ?></strong><small>Not available for review yet</small></div>
        <a href="?status=pending"><span>Pending review</span><strong><?= $counts['pending'] ?></strong></a>
        <a href="?status=approved"><span>Approved residents</span><strong><?= $counts['approved'] ?></strong></a>
        <a href="?status=rejected"><span>Rejected applications</span><strong><?= $counts['rejected'] ?></strong></a>
    </section>
    <nav class="review-filters" aria-label="Application status">
        <?php foreach (['all' => 'All', 'pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $filter => $label): ?>
            <a class="<?= $status === $filter ? 'active' : '' ?>" href="?status=<?= $filter ?>"><?= $label ?></a>
        <?php endforeach; ?>
    </nav>
    <section class="application-table">
    <?php if (!$applications): ?><div class="empty-review"><i class="bi bi-person-check" style="font-size:34px"></i><p>No <?= residentAccountEscape($status) ?> resident applications.</p></div><?php endif; ?>
    <?php foreach ($applications as $application): ?>
        <?php
        $modalData = [
            'id' => (int) $application['id'], 'name' => $application['full_name'], 'email' => $application['email'],
            'mobile' => $application['mobile_number'], 'address' => $application['address_line'],
            'status' => $application['approval_status'], 'submitted' => $application['created_at'],
            'consent' => $application['notification_consented_at'] ? 'Accepted ' . $application['notification_consented_at'] : 'Not recorded',
            'reviewer' => $application['reviewer_name'], 'reviewed_at' => $application['reviewed_at'],
            'rejection_reason' => $application['rejection_reason'],
            'proof_url' => $application['verification_proof_path'] ? 'resident_proof.php?user_id=' . (int) $application['id'] : '',
        ];
        $modalJson = json_encode($modalData, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT) ?: '{}';
        ?>
        <article class="application-row">
            <div><span class="resident-name"><?= residentAccountEscape($application['full_name']) ?></span><span class="resident-email"><?= residentAccountEscape($application['email']) ?></span></div>
            <div class="submitted"><strong>Submitted</strong><span class="submitted-label"><?= residentAccountEscape($application['created_at']) ?></span></div>
            <span class="status-pill <?= residentAccountEscape($application['approval_status']) ?>"><?= residentAccountEscape($application['approval_status']) ?></span>
            <button class="view-application" type="button" data-open-application data-application="<?= residentAccountEscape($modalJson) ?>">View details</button>
        </article>
    <?php endforeach; ?>
    </section>
</main></div>

<div class="review-modal" id="applicationModal" hidden aria-hidden="true">
    <div class="modal-backdrop" data-close-modal></div>
    <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="modalResidentName">
        <header class="modal-head"><div><span id="modalStatus" class="status-pill">Pending</span><h2 id="modalResidentName">Resident application</h2></div><button class="modal-close" type="button" data-close-modal aria-label="Close">&times;</button></header>
        <div class="modal-body">
            <dl class="details">
                <dt>Email</dt><dd id="modalEmail"></dd><dt>Mobile number</dt><dd id="modalMobile"></dd><dt>Address</dt><dd id="modalAddress"></dd>
                <dt>Email verification</dt><dd>Verified</dd><dt>Notification consent</dt><dd id="modalConsent"></dd><dt>Submitted</dt><dd id="modalSubmitted"></dd>
                <dt id="reviewerLabel" hidden>Reviewed by</dt><dd id="modalReviewer" hidden></dd>
            </dl>
            <div><strong>Submitted proof</strong><a id="modalProofLink" target="_blank" rel="noopener"><img id="modalProof" class="proof" alt="Submitted proof of residency"></a><p id="modalNoProof" class="no-proof" hidden>No proof image attached.</p></div>
        </div>
        <div id="finalDecision" class="final-decision" hidden><strong id="finalDecisionTitle"></strong><span id="finalDecisionText"></span></div>
        <form method="post" class="decision" id="decisionForm" hidden>
            <input type="hidden" name="csrf_token" value="<?= residentAccountEscape($csrf) ?>"><input type="hidden" name="user_id" id="modalUserId">
            <label for="rejectionReason"><strong>Reason for rejection</strong> <span style="color:#64748b">(required only when rejecting)</span></label>
            <textarea id="rejectionReason" name="rejection_reason" maxlength="500" placeholder="Explain what is invalid or missing so the resident can correct it."></textarea>
            <div class="decision-actions"><button class="reject" name="action" value="reject" type="submit">Reject application</button><button class="approve" name="action" value="approve" type="submit">Approve resident</button></div>
        </form>
    </section>
</div>
<script src="../assets/js/admin.js"></script>
<script>
(() => {
    const modal = document.getElementById('applicationModal');
    const form = document.getElementById('decisionForm');
    const finalDecision = document.getElementById('finalDecision');
    const setText = (id, value) => { document.getElementById(id).textContent = value || 'Not recorded'; };
    const closeModal = () => { modal.hidden = true; modal.setAttribute('aria-hidden', 'true'); document.body.classList.remove('modal-open'); };
    document.querySelectorAll('[data-open-application]').forEach(button => button.addEventListener('click', () => {
        const data = JSON.parse(button.dataset.application || '{}');
        setText('modalResidentName', data.name); setText('modalEmail', data.email); setText('modalMobile', data.mobile); setText('modalAddress', data.address);
        setText('modalConsent', data.consent); setText('modalSubmitted', data.submitted); document.getElementById('modalUserId').value = data.id || '';
        const status = document.getElementById('modalStatus'); status.textContent = data.status || ''; status.className = 'status-pill ' + (data.status || '');
        const reviewerVisible = Boolean(data.reviewer); document.getElementById('reviewerLabel').hidden = !reviewerVisible; document.getElementById('modalReviewer').hidden = !reviewerVisible;
        if (reviewerVisible) setText('modalReviewer', data.reviewer + (data.reviewed_at ? ' · ' + data.reviewed_at : ''));
        const hasProof = Boolean(data.proof_url); document.getElementById('modalProofLink').hidden = !hasProof; document.getElementById('modalNoProof').hidden = hasProof;
        if (hasProof) { document.getElementById('modalProofLink').href = data.proof_url; document.getElementById('modalProof').src = data.proof_url; }
        const pending = data.status === 'pending'; form.hidden = !pending; finalDecision.hidden = pending; document.getElementById('rejectionReason').value = '';
        if (!pending) {
            finalDecision.className = 'final-decision ' + data.status;
            setText('finalDecisionTitle', data.status === 'rejected' ? 'Application rejected — decision is final' : 'Application approved — decision is final');
            setText('finalDecisionText', data.status === 'rejected' ? 'Reason: ' + (data.rejection_reason || 'No reason recorded.') + ' The resident may correct the details and register again.' : 'This resident account has already been approved.');
        }
        modal.hidden = false; modal.setAttribute('aria-hidden', 'false'); document.body.classList.add('modal-open'); document.querySelector('.modal-close').focus();
    }));
    document.querySelectorAll('[data-close-modal]').forEach(button => button.addEventListener('click', closeModal));
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && !modal.hidden) closeModal(); });
    form.addEventListener('submit', async event => {
        if (form.dataset.confirmed === 'true') { delete form.dataset.confirmed; return; }
        event.preventDefault();
        const action = event.submitter ? event.submitter.value : '';
        const reason = document.getElementById('rejectionReason').value.trim();
        if (action === 'reject' && reason.length < 5) { await window.fgMessage('Rejection reason required', 'Enter a clear rejection reason containing at least 5 characters.'); return; }
        const approved = await window.fgConfirm(
            action === 'approve' ? 'Approve resident?' : 'Reject application?',
            action === 'approve' ? 'The resident will be allowed to sign in after approval.' : 'This application decision is final. The resident may correct the details and register again.',
            action === 'approve' ? 'Approve resident' : 'Reject application',
            action === 'reject'
        );
        if (approved) { form.dataset.confirmed = 'true'; form.requestSubmit(event.submitter); }
    });
})();
</script>
</body></html>
