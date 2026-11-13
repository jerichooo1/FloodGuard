<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/../app/Audit/AuditLogger.php';

if (!isset($staffPermissions['assignments.manage'])) {
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

        if ($action === 'create_team') {
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
    <title>Team Management | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css"><link rel="stylesheet" href="../assets/css/barangay.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/layout.php'; ?>
<div class="admin-page">
    <header class="admin-topbar staff-topbar">
        <div class="topbar-left"><button type="button" class="mobile-menu-button" id="mobileMenuButton" aria-label="Open navigation"><i class="bi bi-list"></i></button><div><h1>Team Management</h1><p>Create response teams and manage responder rosters</p></div></div>
        <div class="topbar-right"><div class="topbar-station-status"><span class="station-dot <?= $staffDeviceOnline ? 'online' : 'offline' ?>"></span><div><span>Monitoring Station</span><strong><?= $staffDeviceOnline ? 'Receiving Data' : 'Waiting for Data' ?></strong></div></div><div class="topbar-admin"><div class="admin-avatar"><?= floodguardEscape(strtoupper(substr((string) $staffUser['full_name'], 0, 1))) ?></div><div><strong><?= floodguardEscape($staffUser['full_name']) ?></strong><span>Barangay Personnel</span></div></div></div>
    </header>
    <main class="admin-content">
        <div class="page-intro"><div><span class="eyebrow">Responder organization</span><h2>Build and maintain response teams</h2><p>Create teams and add active responder accounts. Dispatch remains in Response Operations.</p></div><span class="role-pill"><i class="bi bi-people"></i> Team Management</span></div>
        <?php if ($flash): ?><div class="message <?= $flashType ?>" role="status"><i class="bi <?= $flashType === 'error' ? 'bi-exclamation-circle' : 'bi-check-circle' ?>"></i><?= floodguardEscape($flash) ?></div><?php endif; ?>
        <section class="operations-summary" aria-label="Operations summary">
            <article class="metric-card"><span>Response teams</span><strong><?= count($teams) ?></strong><small>Configured units</small></article>
            <article class="metric-card"><span>Available teams</span><strong><?= $availableTeamCount ?></strong><small>Ready for dispatch</small></article>
            <article class="metric-card"><span>Assigned teams</span><strong><?= count(array_filter($teams, fn(array $team): bool => $team['duty_status'] === 'assigned')) ?></strong><small>Currently responding</small></article>
            <article class="metric-card"><span>Active responders</span><strong><?= count($responders) ?></strong><small>Responder accounts</small></article>
        </section>
        <section class="quick-actions" style="grid-template-columns:repeat(2,minmax(0,1fr))" aria-label="Team workflow">
            <article class="panel action-card"><div class="action-heading"><span class="action-number">1</span><div><h3>Create team</h3><p>Name a response unit.</p></div></div><form method="post" class="compact-form"><input type="hidden" name="csrf_token" value="<?= floodguardEscape($staffCsrf) ?>"><label>Team name<input name="team_name" maxlength="120" required placeholder="Example: San Isidro Team A"></label><button class="primary-button" name="action" value="create_team"><i class="bi bi-plus-lg"></i>Create team</button></form></article>
            <article class="panel action-card"><div class="action-heading"><span class="action-number">2</span><div><h3>Add responder</h3><p>Build the team roster.</p></div></div><form method="post" class="compact-form"><input type="hidden" name="csrf_token" value="<?= floodguardEscape($staffCsrf) ?>"><label>Response team<select name="team_id" required><option value="">Select team</option><?php foreach ($teams as $team): ?><option value="<?= $team['id'] ?>"><?= floodguardEscape($team['team_name']) ?></option><?php endforeach; ?></select></label><label>Responder<select name="responder_id" required><option value="">Select responder</option><?php foreach ($responders as $responder): ?><option value="<?= $responder['id'] ?>"><?= floodguardEscape($responder['full_name'] . ' — ' . $responder['email']) ?></option><?php endforeach; ?></select></label><button class="primary-button" name="action" value="add_member"><i class="bi bi-person-plus"></i>Add responder</button></form></article>
        </section>
        <section class="data-grid" style="grid-template-columns:minmax(0,1fr)">
            <article class="panel"><div class="panel-header"><div><h3>Response teams</h3><p>Select a row to inspect its roster.</p></div><i class="bi bi-people"></i></div><div class="table-scroll"><table class="data-table"><thead><tr><th>Team</th><th>Status</th><th>Members</th></tr></thead><tbody>
            <?php if (!$teams): ?><tr><td colspan="3" class="empty-table">No response teams yet.</td></tr><?php endif; ?>
            <?php foreach ($teams as $team): $payload = ['type'=>'team','title'=>$team['team_name'],'details'=>[['label'=>'Duty status','value'=>ucwords(str_replace('_',' ',$team['duty_status']))],['label'=>'Team availability','value'=>(int)$team['is_active']?'Active':'Inactive'],['label'=>'Member count','value'=>(string)$team['member_count']],['label'=>'Created','value'=>$team['created_at']]],'members'=>$teamMembers[(int)$team['id']]??[]]; ?><tr class="clickable-row"><td><button type="button" class="row-button" data-details="<?= floodguardEscape(json_encode($payload, JSON_UNESCAPED_SLASHES) ?: '{}') ?>"><span><strong><?= floodguardEscape($team['team_name']) ?></strong><small>View team details</small></span><i class="bi bi-chevron-right"></i></button></td><td><span class="status-chip <?= floodguardEscape($team['duty_status']) ?>"><?= floodguardEscape(str_replace('_',' ',$team['duty_status'])) ?></span></td><td><?= (int) $team['member_count'] ?></td></tr><?php endforeach; ?>
            </tbody></table></div></article>
        </section>
    </main>
</div>
<div class="modal-shell" id="detailModal" hidden><div class="modal-backdrop" data-modal-close></div><section class="detail-modal" role="dialog" aria-modal="true" aria-labelledby="modalTitle"><header class="modal-head"><div><span class="kicker" id="modalEyebrow">Details</span><h2 id="modalTitle">Details</h2></div><button type="button" class="modal-close" data-modal-close aria-label="Close details"><i class="bi bi-x-lg"></i></button></header><div class="modal-body" id="modalBody"></div></section></div>
<script src="../assets/js/admin.js"></script><script src="../assets/js/staff-operations.js"></script>
</body></html>
