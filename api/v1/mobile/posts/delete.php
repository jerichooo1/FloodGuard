<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';
require_once __DIR__.'/../../../../app/Audit/AuditLogger.php';

floodguardRequireMethod('DELETE');
$user = floodguardRequireApiUser($pdo, 'posts.view_own');
$input = floodguardJsonInput();
$id = filter_var(
    $input['post_id'] ?? null,
    FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1]]
);

if ($id === false) {
    floodguardJsonResponse(422, [
        'success' => false,
        'message' => 'A valid post is required.',
    ]);
}

try {
    $pdo->beginTransaction();

    $find = $pdo->prepare(
        'SELECT id, post_number, status
         FROM community_posts
         WHERE id = :id AND resident_user_id = :resident
         FOR UPDATE'
    );
    $find->execute([
        ':id' => $id,
        ':resident' => $user['id'],
    ]);
    $post = $find->fetch();

    if (!$post) {
        $pdo->rollBack();
        floodguardJsonResponse(404, [
            'success' => false,
            'message' => 'Post not found or you are not allowed to delete it.',
        ]);
    }

    $pdo->prepare(
        'DELETE FROM community_post_status_history
         WHERE community_post_id = :id'
    )->execute([':id' => $id]);

    $pdo->prepare(
        'DELETE FROM community_post_photos
         WHERE community_post_id = :id'
    )->execute([':id' => $id]);

    $pdo->prepare(
        'DELETE FROM community_posts
         WHERE id = :id AND resident_user_id = :resident'
    )->execute([
        ':id' => $id,
        ':resident' => $user['id'],
    ]);

    floodguardAudit(
        $pdo,
        (int) $user['id'],
        'community_post.deleted',
        'community_post',
        (int) $id,
        [
            'post_number' => $post['post_number'],
            'status' => $post['status'],
        ],
        null
    );

    $pdo->commit();

    floodguardJsonResponse(200, [
        'success' => true,
        'message' => 'Your post was deleted.',
    ]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('[Resident post delete] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Unable to delete the post.',
    ]);
}
