<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';
require_once __DIR__.'/../../../../app/Audit/AuditLogger.php';

floodguardRequireMethod('POST');

$user = floodguardRequireApiUser($pdo, 'assignments.update_own');
$input = floodguardJsonInput();

$id = filter_var(
    $input['assignment_id'] ?? null,
    FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1]]
);

$to = (string) ($input['status'] ?? '');
$notes = trim((string) ($input['notes'] ?? ''));

if ($id === false || mb_strlen($notes) > 1000) {
    floodguardJsonResponse(422, [
        'success' => false,
        'message' => 'Valid assignment and notes are required.',
    ]);
}

$allowed = [
    'assigned' => ['accepted', 'declined'],
    'accepted' => ['en_route'],
    'en_route' => ['on_scene'],
    'on_scene' => ['response_in_progress', 'completed'],
    'response_in_progress' => ['completed'],
];

$incidentMap = [
    'accepted' => 'accepted',
    'en_route' => 'en_route',
    'on_scene' => 'on_scene',
    'response_in_progress' => 'response_in_progress',
    'completed' => 'resolved',
    'declined' => 'awaiting_assignment',
];

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare(
        'SELECT ia.*, fi.status AS incident_status
         FROM incident_assignments ia
         JOIN response_team_members rtm
           ON rtm.response_team_id = ia.response_team_id
          AND rtm.responder_user_id = :user
         JOIN flood_incidents fi
           ON fi.id = ia.flood_incident_id
         WHERE ia.id = :id
         FOR UPDATE'
    );

    $stmt->execute([
        ':user' => $user['id'],
        ':id' => $id,
    ]);

    $assignment = $stmt->fetch();

    if (!$assignment) {
        throw new RuntimeException('Assignment not found.');
    }

    $from = (string) $assignment['status'];

    if (!in_array($to, $allowed[$from] ?? [], true)) {
        throw new DomainException('That status change is not allowed.');
    }

    if ($to === 'completed' && $notes === '') {
        throw new InvalidArgumentException('Completion notes are required.');
    }

    /*
     * Use an integer flag instead of comparing the note parameter with an
     * empty string. This prevents collation conflicts on hosted MySQL.
     */
    $updateAssignment = $pdo->prepare(
        'UPDATE incident_assignments
         SET status = :status,
             accepted_by = IF(:accept_user = 1, :user, accepted_by),
             accepted_at = IF(:accept_time = 1, NOW(), accepted_at),
             completed_at = IF(:completed = 1, NOW(), completed_at),
             notes = IF(:has_notes = 1, :notes_value, notes)
         WHERE id = :id'
    );

    $updateAssignment->execute([
        ':status' => $to,
        ':accept_user' => (int) ($to === 'accepted'),
        ':user' => $user['id'],
        ':accept_time' => (int) ($to === 'accepted'),
        ':completed' => (int) ($to === 'completed'),
        ':has_notes' => (int) ($notes !== ''),
        ':notes_value' => $notes,
        ':id' => $id,
    ]);

    $incidentTo = $incidentMap[$to];
    $resolution = $to === 'completed' ? $notes : null;

    $updateIncident = $pdo->prepare(
        'UPDATE flood_incidents
         SET status = :status,
             resolution_summary = COALESCE(:resolution, resolution_summary),
             resolved_at = IF(:resolved = 1, NOW(), resolved_at)
         WHERE id = :id'
    );

    $updateIncident->execute([
        ':status' => $incidentTo,
        ':resolution' => $resolution,
        ':resolved' => (int) ($to === 'completed'),
        ':id' => $assignment['flood_incident_id'],
    ]);

    $teamStatus = in_array($to, ['declined', 'completed'], true)
        ? 'available'
        : 'assigned';

    $updateTeam = $pdo->prepare(
        'UPDATE response_teams
         SET duty_status = :status
         WHERE id = :id'
    );

    $updateTeam->execute([
        ':status' => $teamStatus,
        ':id' => $assignment['response_team_id'],
    ]);

    $insertHistory = $pdo->prepare(
        'INSERT INTO incident_status_history (
            flood_incident_id,
            assignment_id,
            from_status,
            to_status,
            notes,
            changed_by,
            changed_at
         ) VALUES (
            :incident,
            :assignment,
            :from,
            :to,
            :notes,
            :user,
            NOW()
         )'
    );

    $insertHistory->execute([
        ':incident' => $assignment['flood_incident_id'],
        ':assignment' => $id,
        ':from' => $assignment['incident_status'],
        ':to' => $incidentTo,
        ':notes' => $notes !== '' ? $notes : null,
        ':user' => $user['id'],
    ]);

    floodguardAudit(
        $pdo,
        (int) $user['id'],
        'assignment.'.$to,
        'incident_assignment',
        (int) $id,
        ['status' => $from],
        [
            'status' => $to,
            'notes' => $notes !== '' ? $notes : null,
        ]
    );

    $pdo->commit();

    floodguardJsonResponse(200, [
        'success' => true,
        'message' => 'Assignment status updated.',
        'data' => [
            'assignment_id' => (int) $id,
            'assignment_status' => $to,
            'incident_status' => $incidentTo,
        ],
    ]);
} catch (InvalidArgumentException|DomainException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    floodguardJsonResponse(422, [
        'success' => false,
        'message' => $e->getMessage(),
    ]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    error_log('[Responder assignment update] '.$e->getMessage());

    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Unable to update assignment.',
    ]);
}