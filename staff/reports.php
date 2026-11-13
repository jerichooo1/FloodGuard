<?php

declare(strict_types=1);


require_once __DIR__.'/../config/database.php';
require_once __DIR__.'/includes/auth.php';
require_once __DIR__.'/../app/Incident/Workflow.php';
require_once __DIR__.'/../app/Audit/AuditLogger.php';

function staffCan(string $permission):bool{global $staffPermissions;
return isset($staffPermissions[$permission]);
}
$flash=isset($_GET['updated'])?'Report updated successfully.':'';
$flashType='success';

if($_SERVER['REQUEST_METHOD']==='POST'){
 try{if(!floodguardVerifyCsrf((string)($_POST['csrf_token']??''),'staff_operations'))throw new RuntimeException('The form expired. Please try again.');
$reportId=filter_var($_POST['report_id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
$action=(string)($_POST['action']??'');
if($reportId===false)throw new InvalidArgumentException('Valid report required.');

  $pdo->beginTransaction();
$stmt=$pdo->prepare('SELECT * FROM flood_reports WHERE id=:id FOR UPDATE');
$stmt->execute([':id'=>$reportId]);
$report=$stmt->fetch();
if(!$report)throw new RuntimeException('Report not found.');
$from=$report['status'];

  if($action==='start_review'){if(!staffCan('reports.review'))throw new RuntimeException('Permission denied.');
FloodGuardIncidentWorkflow::requireReportTransition($from,'under_review');
$to='under_review';
$reason=null;
$pdo->prepare('UPDATE flood_reports SET status=:status WHERE id=:id')->execute([':status'=>$to,':id'=>$reportId]);
}
  elseif(in_array($action,['correction_requested','rejected'],true)){if(!staffCan('reports.decide'))throw new RuntimeException('Permission denied.');
FloodGuardIncidentWorkflow::requireReportTransition($from,$action);
$reason=trim((string)($_POST['decision_reason']??''));
if($reason===''||mb_strlen($reason)>1000)throw new InvalidArgumentException('A clear reason is required and must not exceed 1000 characters.');
$to=$action;
$pdo->prepare('UPDATE flood_reports SET status=:status,reviewed_by=:user,reviewed_at=NOW(),decision_reason=:reason WHERE id=:id')->execute([':status'=>$to,':user'=>$staffUser['id'],':reason'=>$reason,':id'=>$reportId]);
}
  elseif($action==='approved'){if(!staffCan('reports.decide'))throw new RuntimeException('Permission denied.');
FloodGuardIncidentWorkflow::requireReportTransition($from,'approved');
$priority=(string)($_POST['priority']??'medium');
if(!in_array($priority,['low','medium','high','urgent'],true))throw new InvalidArgumentException('Invalid incident priority.');
$to='approved';
$reason=null;
$pdo->prepare('UPDATE flood_reports SET status="approved",reviewed_by=:user,reviewed_at=NOW(),decision_reason=NULL WHERE id=:id')->execute([':user'=>$staffUser['id'],':id'=>$reportId]);
$incidentNumber='FG-INC-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));
$visibility=(string)($_POST['incident_visibility']??'private');
if(!in_array($visibility,['private','public'],true))throw new InvalidArgumentException('Invalid incident visibility selection.');
$public=$visibility==='public'&&staffCan('incidents.publish');
$publicLocation=$public?trim((string)($_POST['public_location']??'')):null;
$publicCondition=$public?trim((string)($_POST['public_condition']??'')):null;
if($public&&($publicLocation===''||mb_strlen($publicLocation)>255||$publicCondition===''||mb_strlen($publicCondition)>1000))throw new InvalidArgumentException('Approved public location and condition are required.');
$water=trim((string)($_POST['public_water_level_cm']??''));
$water=$water===''?null:filter_var($water,FILTER_VALIDATE_FLOAT);
if($water===false||($water!==null&&($water<0||$water>1000)))throw new InvalidArgumentException('Public water level must be between 0 and 1000 cm.');
$insert=$pdo->prepare('INSERT INTO flood_incidents (incident_number,source_report_id,priority,status,public_approved,public_location,public_condition,public_water_level_cm,public_approved_by,public_approved_at,created_by) VALUES (:number,:report,:priority,"awaiting_assignment",:public,:location,:condition,:water,:approver,IF(:public_time=1,NOW(),NULL),:creator)');
$insert->execute([':number'=>$incidentNumber,':report'=>$reportId,':priority'=>$priority,':public'=>(int)$public,':location'=>$publicLocation,':condition'=>$publicCondition,':water'=>$water,':approver'=>$public?$staffUser['id']:null,':public_time'=>(int)$public,':creator'=>$staffUser['id']]);
$incidentId=(int)$pdo->lastInsertId();
$pdo->prepare('INSERT INTO incident_status_history (flood_incident_id,from_status,to_status,notes,changed_by,changed_at) VALUES (:id,NULL,"awaiting_assignment","Created from approved resident report",:user,NOW())')->execute([':id'=>$incidentId,':user'=>$staffUser['id']]);
floodguardAudit($pdo,(int)$staffUser['id'],'incident.created','flood_incident',$incidentId,null,['incident_number'=>$incidentNumber,'priority'=>$priority,'public_approved'=>$public]);
}
  else throw new InvalidArgumentException('Invalid review action.');

  $pdo->prepare('INSERT INTO flood_report_status_history (flood_report_id,from_status,to_status,reason,changed_by,changed_at) VALUES (:id,:from,:to,:reason,:user,NOW())')->execute([':id'=>$reportId,':from'=>$from,':to'=>$to,':reason'=>$reason,':user'=>$staffUser['id']]);
floodguardAudit($pdo,(int)$staffUser['id'],'flood_report.'.$to,'flood_report',(int)$reportId,['status'=>$from],['status'=>$to,'reason'=>$reason]);
$pdo->commit();
floodguardRotateCsrf('staff_operations');
header('Location: reports.php?id='.(int)$reportId.'&updated=1');
exit;

 }catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();
$flash=$e instanceof DomainException?'That report action is not allowed from its current status.':$e->getMessage();
$flashType='error';
}
}
$allowed=['all','submitted','resubmitted','under_review','correction_requested','rejected','approved','cancelled'];
$filter=(string)($_GET['status']??'all');
if(!in_array($filter,$allowed,true))$filter='all';
$sql='SELECT fr.id,fr.report_number,fr.reporter_name_snapshot,fr.location_description,fr.immediate_danger,fr.status,fr.submitted_at,(SELECT COUNT(*) FROM flood_report_photos p WHERE p.flood_report_id=fr.id) photo_count FROM flood_reports fr';
$params=[];
if($filter!=='all'){$sql.=' WHERE fr.status=:status';
$params[':status']=$filter;
}$sql.=' ORDER BY fr.immediate_danger DESC,fr.submitted_at DESC LIMIT 200';
$stmt=$pdo->prepare($sql);
$stmt->execute($params);
$reports=$stmt->fetchAll();

$selected=null;
$history=[];
$selectedId=filter_var($_GET['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
if($selectedId!==false){$stmt=$pdo->prepare('SELECT fr.*,u.email AS reporter_email,(SELECT id FROM flood_report_photos WHERE flood_report_id=fr.id ORDER BY id DESC LIMIT 1) photo_id FROM flood_reports fr JOIN users u ON u.id=fr.reporter_user_id WHERE fr.id=:id');
$stmt->execute([':id'=>$selectedId]);
$selected=$stmt->fetch();
if($selected){$h=$pdo->prepare('SELECT h.from_status,h.to_status,h.reason,h.changed_at,u.full_name changed_by_name FROM flood_report_status_history h JOIN users u ON u.id=h.changed_by WHERE h.flood_report_id=:id ORDER BY h.changed_at,h.id');
$h->execute([':id'=>$selectedId]);
$history=$h->fetchAll();
}}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Flood Reports | FloodGuard</title>
<link rel="stylesheet" href="../assets/css/admin.css">
<link rel="stylesheet" href="../assets/css/barangay.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/layout.php'; ?>
<div class="admin-page">
<header class="admin-topbar staff-topbar">
<div class="topbar-left"><button type="button" class="mobile-menu-button" id="mobileMenuButton" aria-label="Open navigation"><i class="bi bi-list"></i></button><div><h1>Resident Flood Reports</h1><p>Review queue and incident approval</p></div></div>
<div class="topbar-right"><div class="topbar-station-status"><span class="station-dot <?=$staffDeviceOnline?'online':'offline'?>"></span><div><span>Monitoring Station</span><strong><?=$staffDeviceOnline?'Receiving Data':'Waiting for Data'?></strong></div></div><div class="topbar-admin"><div class="admin-avatar"><?=floodguardEscape(strtoupper(substr((string)$staffUser['full_name'],0,1)))?></div><div><strong><?=floodguardEscape($staffUser['full_name'])?></strong><span>Barangay Personnel</span></div></div></div>
</header>
<main class="admin-content">
<div class="page-intro">
<div>
<span class="eyebrow">Incident intake</span>
<h2>Review resident flood reports</h2>
<p>Review resident-submitted flood conditions before creating an operational incident.</p>
</div>
<span class="role-pill">
<i class="bi bi-shield-check">
</i> <?=floodguardEscape($staffUser['role_name'])?>
</span>
</div>
<?php if($flash!==''):?>
<div class="message <?=$flashType?>">
<?=floodguardEscape($flash)?>
</div>
<?php endif;
?>
<section class="staff-grid">
<div class="queue-card">
<form class="filters" method="get">
<label>Status<select name="status" onchange="this.form.submit()">
<?php foreach($allowed as $value):?>
<option value="<?=$value?>" <?=$filter===$value?'selected':''?>>
<?=floodguardEscape(ucwords(str_replace('_',' ',$value)))?>
</option>
<?php endforeach;
?>
</select>
</label>
</form>
<div class="report-list">
<?php if(!$reports):?>
<div class="empty">No reports in this queue.</div>
<?php endif;
?>
<?php foreach($reports as $r):?>
<a href="?status=<?=urlencode($filter)?>&id=<?=$r['id']?>" class="report-row <?=$selectedId==(int)$r['id']?'active':''?>">
<div>
<strong>
<?=floodguardEscape($r['report_number'])?>
</strong>
<span>
<?=floodguardEscape($r['reporter_name_snapshot'])?> · <?=floodguardEscape($r['location_description'])?>
</span>
</div>
<div>
<span class="status status-<?=floodguardEscape($r['status'])?>">
<?=floodguardEscape(str_replace('_',' ',$r['status']))?>
</span>
<small>
<?=$r['immediate_danger']?'Immediate danger':''?>
</small>
</div>
</a>
<?php endforeach;
?>
</div>
</div>
<div class="detail-card">
<?php if(!$selected):?>
<div class="empty large">
<i class="bi bi-inbox">
</i>
<h2>Select a report</h2>
<p>Choose a report from the queue to review its verified details.</p>
</div>
<?php else:?>
<div class="detail-head">
<div>
<span class="kicker">Report details</span>
<h2>
<?=floodguardEscape($selected['report_number'])?>
</h2>
</div>
<span class="status status-<?=floodguardEscape($selected['status'])?>">
<?=floodguardEscape(str_replace('_',' ',$selected['status']))?>
</span>
</div>
<dl class="report-details">
<div>
<dt>Reporter</dt>
<dd>
<?=floodguardEscape($selected['reporter_name_snapshot'])?>
</dd>
</div>
<div>
<dt>Contact</dt>
<dd>
<?=floodguardEscape($selected['reporter_phone_snapshot'])?>
<br>
<?=floodguardEscape($selected['reporter_email'])?>
</dd>
</div>
<div>
<dt>Location</dt>
<dd>
<?=floodguardEscape($selected['location_description'])?>
<br>
<small>
<?=floodguardEscape($selected['latitude'])?>, <?=floodguardEscape($selected['longitude'])?>
</small>
</dd>
</div>
<div>
<dt>Description</dt>
<dd>
<?=nl2br(floodguardEscape($selected['flood_description']))?>
</dd>
</div>
<div>
<dt>Immediate danger</dt>
<dd>
<?=$selected['immediate_danger']?'Yes':'No'?>
</dd>
</div>
</dl>
<?php if($selected['photo_id']):?>
<a class="photo-link" href="report_photo.php?id=<?=$selected['photo_id']?>" target="_blank">
<i class="bi bi-image">
</i> View private submitted photograph</a>
<?php endif;
?>
<div class="history">
<h3>Status history</h3>
<?php foreach($history as $h):?>
<div>
<strong>
<?=floodguardEscape(str_replace('_',' ',$h['to_status']))?>
</strong>
<span>
<?=floodguardEscape($h['changed_at'])?> · <?=floodguardEscape($h['changed_by_name'])?>
</span>
<?php if($h['reason']):?>
<p>
<?=floodguardEscape($h['reason'])?>
</p>
<?php endif;
?>
</div>
<?php endforeach;
?>
</div>
<?php if(in_array($selected['status'],['submitted','resubmitted'],true)):?>
<form method="post" class="decision-form">
<input type="hidden" name="csrf_token" value="<?=floodguardEscape($staffCsrf)?>">
<input type="hidden" name="report_id" value="<?=$selected['id']?>">
<button name="action" value="start_review">Start review</button>
</form>
<?php elseif($selected['status']==='under_review'):?>
<form method="post" class="decision-form">
<input type="hidden" name="csrf_token" value="<?=floodguardEscape($staffCsrf)?>">
<input type="hidden" name="report_id" value="<?=$selected['id']?>">
<label>Reason for rejection or correction<textarea name="decision_reason" maxlength="1000">
</textarea>
</label>
<div class="button-row">
<button class="warning" name="action" value="correction_requested">Request correction</button>
<button class="danger" name="action" value="rejected">Reject</button>
</div>
<fieldset>
<legend>Approve and create incident</legend>
<label>Priority<select name="priority">
<option>low</option>
<option selected>medium</option>
<option>high</option>
<option>urgent</option>
</select>
</label>
<fieldset>
<legend>Public visibility</legend>
<label class="check">
<input type="radio" name="incident_visibility" value="private" checked> Keep this incident private (recommended)</label>
<label class="check">
<input type="radio" name="incident_visibility" value="public"> Publish verified non-personal information on the public portal</label>
</fieldset>
<label>Public location<input name="public_location" maxlength="255" value="<?=floodguardEscape($selected['location_description'])?>">
</label>
<label>Public condition<textarea name="public_condition" maxlength="1000">
<?=floodguardEscape($selected['flood_description'])?>
</textarea>
</label>
<label>Water level, cm (optional)<input type="number" name="public_water_level_cm" min="0" max="1000" step="0.01">
</label>
<button class="success" name="action" value="approved">Approve and create incident</button>
</fieldset>
</form>
<?php elseif($selected['decision_reason']):?>
<div class="decision-reason">
<strong>Decision reason</strong>
<p>
<?=floodguardEscape($selected['decision_reason'])?>
</p>
</div>
<?php endif;
?>
<?php endif;
?>
</div>
</section>
</main>
 </div>
<script src="../assets/js/admin.js"></script>
</body>
</html>
