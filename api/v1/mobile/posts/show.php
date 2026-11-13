<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET');
$user = floodguardRequireApiUser($pdo, 'posts.view_own');
$id = filter_var(
    $_GET['id'] ?? null,
    FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1]]
);
if ($id === false) {
    floodguardJsonResponse(422, ['success' => false, 'message' => 'Valid post id required.']);
}

try {
    $stmt = $pdo->prepare(
        'SELECT id, post_number, category, title, content, location_name,
                latitude, longitude, status, review_notes, submitted_at,
                reviewed_at, published_at, updated_at
         FROM community_posts
         WHERE id = :id AND resident_user_id = :resident
         LIMIT 1'
    );
    $stmt->execute([':id' => $id, ':resident' => $user['id']]);
    $post = $stmt->fetch();
    if (!$post) {
        floodguardJsonResponse(404, ['success' => false, 'message' => 'Post not found.']);
    }

    $history = $pdo->prepare(
        'SELECT previous_status, new_status, notes, created_at
         FROM community_post_status_history
         WHERE community_post_id = :id
         ORDER BY created_at, id'
    );
    $history->execute([':id' => $id]);
    $post['status_history'] = $history->fetchAll();

    $photos = $pdo->prepare(
        'SELECT id, original_filename, mime_type, file_size_bytes, created_at
         FROM community_post_photos
         WHERE community_post_id = :id
         ORDER BY id'
    );
    $photos->execute([':id' => $id]);
    $post['photos'] = $photos->fetchAll();

    $post['can_delete'] = true;

    floodguardJsonResponse(200, ['success' => true, 'data' => $post]);
} catch (Throwable $e) {
    error_log('[Resident post show] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Unable to load the post.',
    ]);
}
