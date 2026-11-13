<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/../app/Audit/AuditLogger.php';

if (!isset($staffPermissions['assignments.manage']) || !isset($staffPermissions['reports.review'])) {
    http_response_code(403);
    exit('Barangay personnel assignment access required.');
}

$flash = '';
$flashType = 'success';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!floodguardVerifyCsrf((string) ($_POST['csrf_token'] ?? ''), 'staff_operations')) {
            throw new RuntimeException('The form expired. Please try again.');
        }
        $action = (string) ($_POST['action'] ?? '');
        $pdo->beginTransaction();

        if (in_array($action, ['approved', 'correction_requested', 'rejected'], true)) {
            if (!isset($staffPermissions['reports.decide'])) throw new RuntimeException('Report-decision permission required.');
            $reportId = filter_var($_POST['report_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            if ($reportId === false) throw new InvalidArgumentException('Select a valid report.');
            $stmt = $pdo->prepare('SELECT * FROM flood_reports WHERE id=:id FOR UPDATE');
            $stmt->execute([':id' => $reportId]);
            $report = $stmt->fetch();
            if (!$report) throw new RuntimeException('Report not found.');
            $from = (string) $report['status'];
            if (!in_array($from, ['submitted', 'resubmitted', 'under_review'], true)) throw new DomainException('This report already has a final decision.');
            $reason = null;
            if ($action === 'approved') {
                $priority = (string) ($_POST['priority'] ?? 'medium');
                if (!in_array($priority, ['low', 'medium', 'high', 'urgent'], true)) throw new InvalidArgumentException('Select a valid priority.');
                $existing = $pdo->prepare('SELECT id FROM flood_incidents WHERE source_report_id=:report LIMIT 1');
                $existing->execute([':report' => $reportId]);
                if ($existing->fetchColumn()) throw new DomainException('An incident already exists for this report.');
                $pdo->prepare('UPDATE flood_reports SET status="approved",reviewed_by=:user,reviewed_at=NOW(),decision_reason=NULL WHERE id=:id')->execute([':user' => $staffUser['id'], ':id' => $reportId]);
                $incidentNumber = 'FG-INC-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(4)));
                $stmt = $pdo->prepare('INSERT INTO flood_incidents (incident_number,source_report_id,priority,status,public_approved,created_by) VALUES (:number,:report,:priority,"awaiting_assignment",0,:creator)');
                $stmt->execute([':number' => $incidentNumber, ':report' => $reportId, ':priority' => $priority, ':creator' => $staffUser['id']]);
                $incidentId = (int) $pdo->lastInsertId();
                $pdo->prepare('INSERT INTO incident_status_history (flood_incident_id,from_status,to_status,notes,changed_by,changed_at) VALUES (:id,NULL,"awaiting_assignment","Created from verified resident report",:user,NOW())')->execute([':id' => $incidentId, ':user' => $staffUser['id']]);
                floodguardAudit($pdo, (int) $staffUser['id'], 'incident.created', 'flood_incident', $incidentId, null, ['incident_number' => $incidentNumber, 'priority' => $priority]);
                $flash = 'Report verified. The incident is ready for dispatch.';
            } else {
                $reason = trim((string) ($_POST['decision_reason'] ?? ''));
                if ($reason === '' || mb_strlen($reason) > 1000) throw new InvalidArgumentException('A clear reason is required and must not exceed 1000 characters.');
                $pdo->prepare('UPDATE flood_reports SET status=:status,reviewed_by=:user,reviewed_at=NOW(),decision_reason=:reason WHERE id=:id')->execute([':status' => $action, ':user' => $staffUser['id'], ':reason' => $reason, ':id' => $reportId]);
                $flash = $action === 'rejected' ? 'Report rejected.' : 'Correction requested from the resident.';
            }
            $pdo->prepare('INSERT INTO flood_report_status_history (flood_report_id,from_status,to_status,reason,changed_by,changed_at) VALUES (:id,:from,:to,:reason,:user,NOW())')->execute([':id' => $reportId, ':from' => $from, ':to' => $action, ':reason' => $reason, ':user' => $staffUser['id']]);
            floodguardAudit($pdo, (int) $staffUser['id'], 'flood_report.' . $action, 'flood_report', (int) $reportId, ['status' => $from], ['status' => $action, 'reason' => $reason]);
        } elseif ($action === 'create_team') {
            $name = trim((string) ($_POST['team_name'] ?? ''));
            if ($name === '' || mb_strlen($name) > 120) {
                throw new InvalidArgumentException('Team name is required and must not exceed 120 characters.');
            }
            $stmt = $pdo->prepare('INSERT INTO response_teams (team_name,duty_status,is_active,created_by) VALUES (:name,"available",1,:user)');
            $stmt->execute([':name' => $name, ':user' => $staffUser['id']]);
            $entityId = (int) $pdo->lastInsertId();
            floodguardAudit($pdo, (int) $staffUser['id'], 'response_team.created', 'response_team', $entityId, null, ['team_name' => $name]);
            $flash = 'Response team created and ready for responders.';
        } elseif ($action === 'add_member') {
            $teamId = filter_var($_POST['team_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            $responderId = filter_var($_POST['responder_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            if ($teamId === false || $responderId === false) throw new InvalidArgumentException('Select a valid team and responder.');
            $check = $pdo->prepare('SELECT COUNT(*) FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE u.id=:id AND u.account_status="active" AND r.slug="responder"');
            $check->execute([':id' => $responderId]);
            if (!(int) $check->fetchColumn()) throw new InvalidArgumentException('Selected account is not an active responder.');
            $pdo->prepare('INSERT IGNORE INTO response_team_members (response_team_id,responder_user_id,is_team_lead) VALUES (:team,:responder,0)')->execute([':team' => $teamId, ':responder' => $responderId]);
            floodguardAudit($pdo, (int) $staffUser['id'], 'response_team.member_added', 'response_team', (int) $teamId, null, ['responder_user_id' => (int) $responderId]);
            $flash = 'Responder added to the selected team.';
        } elseif ($action === 'assign_incident') {
            $incidentId = filter_var($_POST['incident_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            $teamId = filter_var($_POST['team_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            $notes = trim((string) ($_POST['notes'] ?? ''));
            if ($incidentId === false || $teamId === false || mb_strlen($notes) > 1000) throw new InvalidArgumentException('Select a valid incident and available team.');
            $incident = $pdo->prepare('SELECT status FROM flood_incidents WHERE id=:id FOR UPDATE');
            $incident->execute([':id' => $incidentId]);
            if ($incident->fetchColumn() !== 'awaiting_assignment') throw new DomainException('Incident is not awaiting assignment.');
            $team = $pdo->prepare('SELECT duty_status,is_active,(SELECT COUNT(*) FROM response_team_members WHERE response_team_id=response_teams.id) AS members FROM response_teams WHERE id=:id FOR UPDATE');
            $team->execute([':id' => $teamId]);
            $teamRow = $team->fetch();
            if (!$teamRow || !(int) $teamRow['is_active'] || $teamRow['duty_status'] !== 'available' || !(int) $teamRow['members']) throw new DomainException('Team must be active, available, and have at least one responder.');
            $stmt = $pdo->prepare('INSERT INTO incident_assignments (flood_incident_id,response_team_id,status,assigned_by,assigned_at,notes) VALUES (:incident,:team,"assigned",:user,NOW(),:notes)');
            $stmt->execute([':incident' => $incidentId, ':team' => $teamId, ':user' => $staffUser['id'], ':notes' => $notes ?: null]);
            $assignmentId = (int) $pdo->lastInsertId();
            $pdo->prepare('UPDATE flood_incidents SET status="assigned" WHERE id=:id')->execute([':id' => $incidentId]);
            $pdo->prepare('UPDATE response_teams SET duty_status="assigned" WHERE id=:id')->execute([':id' => $teamId]);
            $pdo->prepare('INSERT INTO incident_status_history (flood_incident_id,assignment_id,from_status,to_status,notes,changed_by,changed_at) VALUES (:incident,:assignment,"awaiting_assignment","assigned",:notes,:user,NOW())')->execute([':incident' => $incidentId, ':assignment' => $assignmentId, ':notes' => $notes ?: null, ':user' => $staffUser['id']]);
            floodguardAudit($pdo, (int) $staffUser['id'], 'assignment.created', 'incident_assignment', $assignmentId, null, ['incident_id' => (int) $incidentId, 'team_id' => (int) $teamId]);
            $flash = 'Incident assigned. The response team can now view the dispatch.';
        } else {
            throw new InvalidArgumentException('Invalid operation.');
        }
        $pdo->commit();
        floodguardRotateCsrf('staff_operations');
        $staffCsrf = floodguardCsrfToken('staff_operations');
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $flash = $e->getMessage();
        $flashType = 'error';
    }
}

$pendingReports = $pdo->query('SELECT fr.id,fr.report_number,fr.reporter_name_snapshot,fr.reporter_phone_snapshot,u.email AS reporter_email,fr.location_description,fr.latitude,fr.longitude,fr.flood_description,fr.immediate_danger,fr.status,fr.submitted_at,(SELECT id FROM flood_report_photos p WHERE p.flood_report_id=fr.id ORDER BY p.id DESC LIMIT 1) photo_id FROM flood_reports fr JOIN users u ON u.id=fr.reporter_user_id WHERE fr.status IN ("submitted","resubmitted","under_review") ORDER BY fr.immediate_danger DESC,fr.submitted_at')->fetchAll();
$teams = $pdo->query('SELECT rt.id,rt.team_name,rt.duty_status,rt.is_active,rt.created_at,COUNT(rtm.responder_user_id) AS member_count FROM response_teams rt LEFT JOIN response_team_members rtm ON rtm.response_team_id=rt.id GROUP BY rt.id ORDER BY rt.team_name')->fetchAll();
$teamMembers = [];
foreach ($pdo->query('SELECT rtm.response_team_id,u.full_name,u.email,rtm.is_team_lead FROM response_team_members rtm JOIN users u ON u.id=rtm.responder_user_id ORDER BY rtm.is_team_lead DESC,u.full_name')->fetchAll() as $member) {
    $teamMembers[(int) $member['response_team_id']][] = ['name' => $member['full_name'], 'email' => $member['email'], 'lead' => (bool) $member['is_team_lead']];
}
$responders = $pdo->query('SELECT DISTINCT u.id,u.full_name,u.email FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE r.slug="responder" AND u.account_status="active" ORDER BY u.full_name')->fetchAll();
$incidents = $pdo->query('SELECT fi.id,fi.incident_number,fi.priority,fr.location_description FROM flood_incidents fi JOIN flood_reports fr ON fr.id=fi.source_report_id WHERE fi.status="awaiting_assignment" ORDER BY FIELD(fi.priority,"urgent","high","medium","low"),fi.created_at')->fetchAll();
$assignments = $pdo->query('SELECT ia.id,fi.incident_number,fi.priority,fi.status AS incident_status,ia.status,rt.team_name,ia.assigned_at,ia.accepted_at,ia.completed_at,ia.notes,fr.location_description,fr.flood_description,fr.immediate_danger,assigner.full_name AS assigned_by_name,acceptor.full_name AS accepted_by_name FROM incident_assignments ia JOIN flood_incidents fi ON fi.id=ia.flood_incident_id JOIN flood_reports fr ON fr.id=fi.source_report_id JOIN response_teams rt ON rt.id=ia.response_team_id JOIN users assigner ON assigner.id=ia.assigned_by LEFT JOIN users acceptor ON acceptor.id=ia.accepted_by ORDER BY ia.id DESC LIMIT 50')->fetchAll();
$availableTeamCount = count(array_filter($teams, fn(array $team): bool => $team['duty_status'] === 'available' && (int) $team['is_active'] === 1));
$activeAssignmentCount = count(array_filter($assignments, fn(array $assignment): bool => !in_array($assignment['status'], ['completed', 'declined', 'cancelled'], true)));
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Response Operations | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css"><link rel="stylesheet" href="../assets/css/barangay.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/layout.php'; ?>
<div class="admin-page">
    <header class="admin-topbar staff-topbar">
        <div class="topbar-left"><button type="button" class="mobile-menu-button" id="mobileMenuButton" aria-label="Open navigation"><i class="bi bi-list"></i></button><div><h1>Response Operations</h1><p>Teams, dispatch, and active assignments</p></div></div>
        <div class="topbar-right"><div class="topbar-station-status"><span class="station-dot <?= $staffDeviceOnline ? 'online' : 'offline' ?>"></span><div><span>Monitoring Station</span><strong><?= $staffDeviceOnline ? 'Receiving Data' : 'Waiting for Data' ?></strong></div></div><div class="topbar-admin"><div class="admin-avatar"><?= floodguardEscape(strtoupper(substr((string) $staffUser['full_name'], 0, 1))) ?></div><div><strong><?= floodguardEscape($staffUser['full_name']) ?></strong><span>Barangay Personnel</span></div></div></div>
    </header>
    <main class="admin-content">
        <div class="page-intro"><div><span class="eyebrow">Emergency response</span><h2>Review, verify, and dispatch</h2><p>Review resident incident reports, then dispatch verified incidents. Manage rosters from Team Management.</p></div><span class="role-pill"><i class="bi bi-shield-check"></i> Barangay Personnel</span></div>
        <?php if ($flash): ?><div class="message <?= $flashType ?>" role="status"><i class="bi <?= $flashType === 'error' ? 'bi-exclamation-circle' : 'bi-check-circle' ?>"></i><?= floodguardEscape($flash) ?></div><?php endif; ?>
        <section class="operations-summary" aria-label="Operations summary">
            <article class="metric-card"><span>Reports awaiting decision</span><strong><?= count($pendingReports) ?></strong><small>Resident emergency reports</small></article>
            <article class="metric-card"><span>Available teams</span><strong><?= $availableTeamCount ?></strong><small>Ready for dispatch</small></article>
            <article class="metric-card"><span>Active assignments</span><strong><?= $activeAssignmentCount ?></strong><small>Currently responding</small></article>
            <article class="metric-card"><span>Awaiting assignment</span><strong><?= count($incidents) ?></strong><small>Verified incidents</small></article>
        </section>
        <section class="panel" style="margin-bottom:18px"><div class="panel-header"><div><h3>Incident report review</h3><p>Select a report to view its full details and make a decision.</p></div><i class="bi bi-clipboard2-check"></i></div>
            <div class="report-list"><?php if (!$pendingReports): ?><div class="empty-table">No incident reports are awaiting a decision.</div><?php endif; ?>
            <?php foreach ($pendingReports as $report): ?><button type="button" class="report-row report-modal-trigger" data-report-open="reportModal<?= (int) $report['id'] ?>"><div><strong><?= floodguardEscape($report['report_number']) ?></strong><span><?= floodguardEscape($report['reporter_name_snapshot']) ?> · <?= floodguardEscape($report['location_description']) ?></span></div><div class="report-row-meta"><span class="status status-<?= floodguardEscape($report['status']) ?>"><?= floodguardEscape(str_replace('_',' ',$report['status'])) ?></span><small><?= $report['immediate_danger'] ? 'Immediate danger' : floodguardEscape($report['submitted_at']) ?></small><i class="bi bi-chevron-right"></i></div></button><?php endforeach; ?></div>
        </section>
        <section class="quick-actions" style="grid-template-columns:minmax(0,1fr)" aria-label="Dispatch workflow">
            <article class="panel action-card"><div class="action-heading"><span class="action-number">2</span><div><h3>Dispatch verified incident</h3><p>Send an available team.</p></div></div><form method="post" class="compact-form"><input type="hidden" name="csrf_token" value="<?= floodguardEscape($staffCsrf) ?>"><label>Verified incident<select name="incident_id" id="incidentSelect" required><option value="">Select incident</option><?php foreach ($incidents as $incident): ?><option value="<?= $incident['id'] ?>" data-location="<?= floodguardEscape($incident['location_description']) ?>"><?= floodguardEscape($incident['incident_number'] . ' — ' . strtoupper($incident['priority'])) ?></option><?php endforeach; ?></select><small class="field-hint" id="incidentLocation">Select an incident to view its location.</small></label><label>Available team<select name="team_id" required><option value="">Select team</option><?php foreach ($teams as $team): if ($team['duty_status'] === 'available' && (int) $team['is_active'] && (int) $team['member_count']): ?><option value="<?= $team['id'] ?>"><?= floodguardEscape($team['team_name'] . ' (' . $team['member_count'] . ' member/s)') ?></option><?php endif; endforeach; ?></select></label><label>Dispatch notes<textarea name="notes" maxlength="1000" placeholder="Optional safety or route instructions"></textarea></label><button class="primary-button" name="action" value="assign_incident"><i class="bi bi-send-check"></i>Assign incident</button></form></article>
        </section>
        <section class="data-grid" style="grid-template-columns:minmax(0,1fr)">
            <article class="panel"><div class="panel-header"><div><h3>Response assignments</h3><p>Select an assignment to see all dispatch details.</p></div><i class="bi bi-clipboard2-pulse"></i></div><div class="table-scroll"><table class="data-table"><thead><tr><th>Incident</th><th>Team</th><th>Status</th><th>Assigned</th></tr></thead><tbody>
            <?php if (!$assignments): ?><tr><td colspan="4" class="empty-table">No assignments have been created.</td></tr><?php endif; ?>
            <?php foreach ($assignments as $row): $payload=['type'=>'assignment','title'=>$row['incident_number'],'details'=>[['label'=>'Priority','value'=>strtoupper($row['priority'])],['label'=>'Assignment status','value'=>ucwords(str_replace('_',' ',$row['status']))],['label'=>'Incident status','value'=>ucwords(str_replace('_',' ',$row['incident_status']))],['label'=>'Response team','value'=>$row['team_name']],['label'=>'Assigned by','value'=>$row['assigned_by_name']],['label'=>'Assigned at','value'=>$row['assigned_at']],['label'=>'Accepted by','value'=>$row['accepted_by_name']],['label'=>'Accepted at','value'=>$row['accepted_at']],['label'=>'Completed at','value'=>$row['completed_at']],['label'=>'Immediate danger','value'=>$row['immediate_danger']?'Yes':'No'],['label'=>'Location','value'=>$row['location_description'],'wide'=>true],['label'=>'Reported condition','value'=>$row['flood_description'],'wide'=>true],['label'=>'Dispatch notes','value'=>$row['notes'],'wide'=>true]]]; ?><tr class="clickable-row"><td><button type="button" class="row-button" data-details="<?= floodguardEscape(json_encode($payload, JSON_UNESCAPED_SLASHES) ?: '{}') ?>"><span><strong><?= floodguardEscape($row['incident_number']) ?></strong><small><?= floodguardEscape(strtoupper($row['priority'])) ?> priority</small></span><i class="bi bi-chevron-right"></i></button></td><td><?= floodguardEscape($row['team_name']) ?></td><td><span class="status-chip <?= floodguardEscape($row['status']) ?>"><?= floodguardEscape(str_replace('_',' ',$row['status'])) ?></span></td><td><?= floodguardEscape($row['assigned_at']) ?></td></tr><?php endforeach; ?>
            </tbody></table></div></article>
        </section>
    </main>
</div>
<?php foreach ($pendingReports as $report): ?>
<div class="modal-shell report-review-modal" id="reportModal<?= (int) $report['id'] ?>" hidden><div class="modal-backdrop" data-report-close></div><section class="detail-modal" role="dialog" aria-modal="true" aria-labelledby="reportModalTitle<?= (int) $report['id'] ?>"><header class="modal-head"><div><span class="kicker"><?= $report['immediate_danger'] ? 'Immediate danger · Resident report' : 'Resident report' ?></span><h2 id="reportModalTitle<?= (int) $report['id'] ?>"><?= floodguardEscape($report['report_number']) ?></h2></div><button type="button" class="modal-close" data-report-close aria-label="Close report"><i class="bi bi-x-lg"></i></button></header><div class="modal-body"><span class="status status-<?= floodguardEscape($report['status']) ?>"><?= floodguardEscape(str_replace('_',' ',$report['status'])) ?></span><dl class="report-details"><div><dt>Resident</dt><dd><?= floodguardEscape($report['reporter_name_snapshot']) ?></dd></div><div><dt>Contact</dt><dd><?= floodguardEscape($report['reporter_phone_snapshot']) ?><br><small><?= floodguardEscape($report['reporter_email']) ?></small></dd></div><div><dt>Location</dt><dd><?= floodguardEscape($report['location_description']) ?><br><small><?= floodguardEscape($report['latitude']) ?>, <?= floodguardEscape($report['longitude']) ?></small></dd></div><div><dt>Description</dt><dd><?= nl2br(floodguardEscape($report['flood_description'])) ?></dd></div><div><dt>Submitted</dt><dd><?= floodguardEscape($report['submitted_at']) ?></dd></div><div><dt>Immediate danger</dt><dd><?= $report['immediate_danger'] ? 'Yes' : 'No' ?></dd></div></dl><?php if ($report['photo_id']): ?><a class="photo-link" href="report_photo.php?id=<?= (int) $report['photo_id'] ?>" target="_blank"><i class="bi bi-image"></i> View private photograph</a><?php endif; ?><form method="post" class="decision-form"><input type="hidden" name="csrf_token" value="<?= floodguardEscape($staffCsrf) ?>"><input type="hidden" name="report_id" value="<?= (int) $report['id'] ?>"><label>Reason for correction or rejection<textarea name="decision_reason" maxlength="1000" placeholder="Required for correction or rejection"></textarea></label><div class="button-row"><button class="warning" name="action" value="correction_requested">Request correction</button><button class="danger" name="action" value="rejected">Reject</button></div><fieldset><legend>Verify report and create incident</legend><label>Priority<select name="priority"><option>low</option><option selected>medium</option><option>high</option><option>urgent</option></select></label><button class="success" name="action" value="approved">Verify report</button></fieldset></form></div></section></div>
<?php endforeach; ?>
<div class="modal-shell" id="detailModal" hidden><div class="modal-backdrop" data-modal-close></div><section class="detail-modal" role="dialog" aria-modal="true" aria-labelledby="modalTitle"><header class="modal-head"><div><span class="kicker" id="modalEyebrow">Details</span><h2 id="modalTitle">Details</h2></div><button type="button" class="modal-close" data-modal-close aria-label="Close details"><i class="bi bi-x-lg"></i></button></header><div class="modal-body" id="modalBody"></div></section></div>
<script src="../assets/js/admin.js"></script><script src="../assets/js/staff-operations.js"></script>
</body></html>
