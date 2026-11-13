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
$enabled = filter_var($input['enabled'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
if ($assignmentId === false || $enabled === null) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Valid assignment_id and enabled value are required.']);
}

$check = $pdo->prepare(
    'SELECT ia.id, ia.status
     FROM incident_assignments ia
     JOIN flood_incidents fi ON fi.id = ia.flood_incident_id
     JOIN flood_reports fr ON fr.id = fi.source_report_id
     WHERE ia.id = :assignment
       AND fr.reporter_user_id = :resident
     LIMIT 1'
);
$check->execute([':assignment' => $assignmentId, ':resident' => $user['id']]);
$assignment = $check->fetch();
if (!$assignment) {
    floodguardJsonResponse(403, ['success' => false, 'message' => 'This assignment does not belong to your report.']);
}

$active = in_array($assignment['status'], ['accepted', 'en_route', 'on_scene', 'response_in_progress'], true);
if ($enabled && !$active) {
    floodguardJsonResponse(409, ['success' => false, 'message' => 'Live location can be shared only during an active response.']);
}

$stmt = $pdo->prepare(
    'INSERT INTO resident_location_sharing
        (incident_assignment_id, resident_user_id, is_enabled, consented_at, stopped_at)
     VALUES (:assignment, :resident, :enabled, IF(:enabled2 = 1, NOW(), NULL), IF(:enabled3 = 0, NOW(), NULL))
     ON DUPLICATE KEY UPDATE
        resident_user_id = VALUES(resident_user_id),
        is_enabled = VALUES(is_enabled),
        consented_at = IF(VALUES(is_enabled) = 1, NOW(), consented_at),
        stopped_at = IF(VALUES(is_enabled) = 0, NOW(), NULL)'
);
$flag = $enabled ? 1 : 0;
$stmt->execute([
    ':assignment' => $assignmentId,
    ':resident' => $user['id'],
    ':enabled' => $flag,
    ':enabled2' => $flag,
    ':enabled3' => $flag,
]);

floodguardJsonResponse(200, [
    'success' => true,
    'message' => $enabled ? 'Resident live-location sharing enabled.' : 'Resident live-location sharing stopped.',
    'data' => ['assignment_id' => (int)$assignmentId, 'enabled' => $enabled],
]);
