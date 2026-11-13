<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET'); $user=floodguardRequireApiUser($pdo,'assignments.view_own');
$id=filter_var($_GET['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]); if ($id===false) floodguardJsonResponse(422,['success'=>false,'message'=>'Valid assignment id required.']);
$stmt=$pdo->prepare('SELECT ia.id AS assignment_id,ia.status AS assignment_status,ia.assigned_at,ia.accepted_at,ia.completed_at,ia.notes,fi.id AS incident_id,fi.incident_number,fi.priority,fi.status AS incident_status,fi.resolution_summary,fr.location_description,fr.latitude,fr.longitude,fr.flood_description,fr.immediate_danger,rt.id AS team_id,rt.team_name FROM incident_assignments ia JOIN response_team_members rtm ON rtm.response_team_id=ia.response_team_id AND rtm.responder_user_id=:user JOIN response_teams rt ON rt.id=ia.response_team_id JOIN flood_incidents fi ON fi.id=ia.flood_incident_id JOIN flood_reports fr ON fr.id=fi.source_report_id WHERE ia.id=:id LIMIT 1');
$stmt->execute([':user'=>$user['id'],':id'=>$id]); $row=$stmt->fetch(); if (!$row) floodguardJsonResponse(404,['success'=>false,'message'=>'Assignment not found.']);
$history=$pdo->prepare('SELECT from_status,to_status,notes,changed_at FROM incident_status_history WHERE flood_incident_id=:incident ORDER BY id'); $history->execute([':incident'=>$row['incident_id']]);
$row['assignment_id']=(int)$row['assignment_id']; $row['incident_id']=(int)$row['incident_id']; $row['team_id']=(int)$row['team_id']; $row['latitude']=(float)$row['latitude']; $row['longitude']=(float)$row['longitude']; $row['immediate_danger']=(bool)$row['immediate_danger']; $row['status_history']=$history->fetchAll();
floodguardJsonResponse(200,['success'=>true,'data'=>$row]);
