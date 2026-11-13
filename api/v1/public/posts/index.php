<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';

floodguardRequireMethod('GET');

try {
    $stmt = $pdo->query(
        'SELECT cp.post_number, cp.category, cp.title, cp.content,
                cp.location_name,
                COALESCE(cp.published_at, cp.reviewed_at, cp.updated_at) AS published_at,
                (SELECT cpp.id
                 FROM community_post_photos cpp
                 WHERE cpp.community_post_id=cp.id
                 ORDER BY cpp.id DESC LIMIT 1) AS photo_id
         FROM community_posts cp
         WHERE cp.status IN ("approved", "published")
         ORDER BY COALESCE(cp.published_at, cp.reviewed_at, cp.updated_at) DESC, cp.id DESC
         LIMIT 30'
    );
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
        $row['photo_url'] = $row['photo_id'] === null
            ? null
            : 'api/v1/public/posts/photo.php?id='.(int)$row['photo_id'];
        unset($row['photo_id']);
    }
    unset($row);

    floodguardJsonResponse(200, ['success' => true, 'data' => $rows]);
} catch (Throwable $e) {
    error_log('[Public community posts] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Public community updates are temporarily unavailable.',
    ]);
}
