<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET');
$user = floodguardRequireApiUser($pdo, 'locations.view_incident');

$stmt = $pdo->prepare(
    'SELECT ia.id
     FROM incident_assignments ia
     JOIN flood_incidents fi ON fi.id = ia.flood_incident_id
     JOIN flood_reports fr ON fr.id = fi.source_report_id
     WHERE fr.reporter_user_id = :resident
       AND ia.status IN ("accepted", "en_route", "on_scene", "response_in_progress")
     ORDER BY ia.updated_at DESC, ia.id DESC
     LIMIT 1'
);
$stmt->execute([':resident' => $user['id']]);
$assignmentId = $stmt->fetchColumn();

if (!$assignmentId) {
    floodguardJsonResponse(200, ['success' => true, 'data' => null]);
}

$_GET['assignment_id'] = (string)$assignmentId;
require __DIR__.'/../../tracking/latest.php';
