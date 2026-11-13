<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('POST');
$user = floodguardRequireApiUser($pdo, 'locations.share_incident');
$input = floodguardJsonInput();

$assignmentId = filter_var($input['assignment_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
$latitude = filter_var($input['latitude'] ?? null, FILTER_VALIDATE_FLOAT);
$longitude = filter_var($input['longitude'] ?? null, FILTER_VALIDATE_FLOAT);
$accuracy = ($input['accuracy_meters'] ?? null) === null ? null : filter_var($input['accuracy_meters'], FILTER_VALIDATE_FLOAT);

if ($assignmentId === false || $latitude === false || $longitude === false
    || $latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180
    || ($accuracy !== null && ($accuracy === false || $accuracy < 0))) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Valid assignment and coordinates are required.']);
}

$check = $pdo->prepare(
    'SELECT ia.id
     FROM incident_assignments ia
     JOIN flood_incidents fi ON fi.id = ia.flood_incident_id
     JOIN flood_reports fr ON fr.id = fi.source_report_id
     JOIN resident_location_sharing rls
       ON rls.incident_assignment_id = ia.id
      AND rls.resident_user_id = fr.reporter_user_id
      AND rls.is_enabled = 1
     WHERE ia.id = :assignment
       AND fr.reporter_user_id = :resident
       AND ia.status IN ("accepted", "en_route", "on_scene", "response_in_progress")
     LIMIT 1'
);
$check->execute([':assignment' => $assignmentId, ':resident' => $user['id']]);
if (!$check->fetch()) {
    floodguardJsonResponse(403, ['success' => false, 'message' => 'Enable sharing before sending your location.']);
}

$insert = $pdo->prepare(
    'INSERT INTO resident_location_updates
        (incident_assignment_id, resident_user_id, latitude, longitude, accuracy_meters, recorded_at)
     VALUES (:assignment, :resident, :latitude, :longitude, :accuracy, NOW())'
);
$insert->execute([
    ':assignment' => $assignmentId,
    ':resident' => $user['id'],
    ':latitude' => $latitude,
    ':longitude' => $longitude,
    ':accuracy' => $accuracy,
]);

floodguardJsonResponse(200, [
    'success' => true,
    'message' => 'Resident location updated.',
    'data' => ['assignment_id' => (int)$assignmentId, 'recorded_at' => date('Y-m-d H:i:s')],
]);
