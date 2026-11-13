<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET'); $user=floodguardRequireApiUser($pdo,'assignments.view_own');
$stmt=$pdo->prepare('SELECT ia.id AS assignment_id,ia.status AS assignment_status,ia.assigned_at,ia.accepted_at,ia.completed_at,ia.notes,fi.id AS incident_id,fi.incident_number,fi.priority,fi.status AS incident_status,fr.location_description,fr.latitude,fr.longitude,fr.flood_description,rt.id AS team_id,rt.team_name FROM response_team_members rtm JOIN response_teams rt ON rt.id=rtm.response_team_id JOIN incident_assignments ia ON ia.response_team_id=rt.id JOIN flood_incidents fi ON fi.id=ia.flood_incident_id JOIN flood_reports fr ON fr.id=fi.source_report_id WHERE rtm.responder_user_id=:user AND ia.status NOT IN ("cancelled") ORDER BY FIELD(ia.status,"assigned","accepted","en_route","on_scene","response_in_progress","completed","declined"),ia.assigned_at DESC LIMIT 100');
$stmt->execute([':user'=>$user['id']]); $rows=$stmt->fetchAll();
foreach ($rows as &$row) { $row['assignment_id']=(int)$row['assignment_id']; $row['incident_id']=(int)$row['incident_id']; $row['team_id']=(int)$row['team_id']; $row['latitude']=(float)$row['latitude']; $row['longitude']=(float)$row['longitude']; } unset($row);
floodguardJsonResponse(200,['success'=>true,'data'=>$rows]);
