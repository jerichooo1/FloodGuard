<?php

declare(strict_types=1);

require_once __DIR__.'/../../../config/database.php';
require_once __DIR__.'/../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../app/Http/Request.php';
require_once __DIR__.'/../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET');
$user = floodguardRequireApiUser($pdo, 'locations.view_incident');
$assignmentId = filter_var($_GET['assignment_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
if ($assignmentId === false) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Valid assignment_id is required.']);
}

$access = $pdo->prepare(
    'SELECT ia.id, ia.status, fi.incident_number,
            fr.reporter_user_id,
            EXISTS(
                SELECT 1 FROM response_team_members rtm
                WHERE rtm.response_team_id = ia.response_team_id
                  AND rtm.responder_user_id = :responder
            ) AS is_responder,
            (fr.reporter_user_id = :resident) AS is_resident
     FROM incident_assignments ia
     JOIN flood_incidents fi ON fi.id = ia.flood_incident_id
     JOIN flood_reports fr ON fr.id = fi.source_report_id
     WHERE ia.id = :assignment
     LIMIT 1'
);
$access->execute([
    ':responder' => $user['id'],
    ':resident' => $user['id'],
    ':assignment' => $assignmentId,
]);
$assignment = $access->fetch();
if (!$assignment || (!(bool)$assignment['is_responder'] && !(bool)$assignment['is_resident'])) {
    floodguardJsonResponse(403, ['success' => false, 'message' => 'You cannot view tracking for this assignment.']);
}

$sharing = $pdo->prepare(
    'SELECT is_enabled, consented_at, stopped_at
     FROM resident_location_sharing
     WHERE incident_assignment_id = :assignment
       AND resident_user_id = :resident
     LIMIT 1'
);
$sharing->execute([':assignment' => $assignmentId, ':resident' => $assignment['reporter_user_id']]);
$sharingRow = $sharing->fetch() ?: null;
$residentSharing = $sharingRow !== null && (bool)$sharingRow['is_enabled'];

$residentLocation = null;
if ($residentSharing) {
    $stmt = $pdo->prepare(
        'SELECT latitude, longitude, accuracy_meters, recorded_at
         FROM resident_location_updates
         WHERE incident_assignment_id = :assignment
           AND resident_user_id = :resident
         ORDER BY recorded_at DESC, id DESC
         LIMIT 1'
    );
    $stmt->execute([':assignment' => $assignmentId, ':resident' => $assignment['reporter_user_id']]);
    $residentLocation = $stmt->fetch() ?: null;
}

$stmt = $pdo->prepare(
    'SELECT latitude, longitude, accuracy_meters, recorded_at
     FROM responder_location_updates
     WHERE incident_assignment_id = :assignment
     ORDER BY recorded_at DESC, id DESC
     LIMIT 1'
);
$stmt->execute([':assignment' => $assignmentId]);
$responderLocation = $stmt->fetch() ?: null;

floodguardJsonResponse(200, [
    'success' => true,
    'data' => [
        'assignment_id' => (int)$assignment['id'],
        'incident_number' => $assignment['incident_number'],
        'assignment_status' => $assignment['status'],
        'resident_sharing_enabled' => $residentSharing,
        'resident_location' => $residentLocation,
        'responder_location' => $responderLocation,
        'poll_after_seconds' => 5,
    ],
]);
