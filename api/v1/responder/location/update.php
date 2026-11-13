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
$accuracy = ($input['accuracy_meters'] ?? null) === null
    ? null
    : filter_var($input['accuracy_meters'], FILTER_VALIDATE_FLOAT);

if ($assignmentId === false || $latitude === false || $longitude === false
    || $latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180
    || ($accuracy !== null && ($accuracy === false || $accuracy < 0))) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Valid assignment and coordinates are required.']);
}

$stmt = $pdo->prepare(
    'SELECT ia.id
     FROM incident_assignments ia
     JOIN response_team_members rtm
       ON rtm.response_team_id = ia.response_team_id
      AND rtm.responder_user_id = :user
     WHERE ia.id = :assignment
       AND ia.status IN ("accepted", "en_route", "on_scene", "response_in_progress")
     LIMIT 1'
);
$stmt->execute([':user' => $user['id'], ':assignment' => $assignmentId]);
if (!$stmt->fetch()) {
    floodguardJsonResponse(403, ['success' => false, 'message' => 'Location sharing is allowed only for your active assignment.']);
}

$insert = $pdo->prepare(
    'INSERT INTO responder_location_updates
        (incident_assignment_id, responder_user_id, latitude, longitude, accuracy_meters, recorded_at)
     VALUES (:assignment, :user, :latitude, :longitude, :accuracy, NOW())'
);
$insert->execute([
    ':assignment' => $assignmentId,
    ':user' => $user['id'],
    ':latitude' => $latitude,
    ':longitude' => $longitude,
    ':accuracy' => $accuracy,
]);

floodguardJsonResponse(200, [
    'success' => true,
    'message' => 'Responder location updated.',
    'data' => ['assignment_id' => (int)$assignmentId, 'recorded_at' => date('Y-m-d H:i:s')],
]);
