<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';

floodguardRequireMethod('GET');
$user = floodguardRequireApiUser($pdo, 'posts.view_own');

try {
    $stmt = $pdo->prepare(
        'SELECT cp.id, cp.post_number, cp.category, cp.title, cp.content,
                cp.location_name, cp.latitude, cp.longitude, cp.status,
                cp.review_notes, cp.submitted_at, cp.reviewed_at,
                cp.published_at, cp.updated_at,
                EXISTS(
                    SELECT 1 FROM community_post_photos cpp
                    WHERE cpp.community_post_id = cp.id
                ) AS has_photo
         FROM community_posts cp
         WHERE cp.resident_user_id = :resident
         ORDER BY cp.submitted_at DESC, cp.id DESC
         LIMIT 100'
    );
    $stmt->execute([':resident' => $user['id']]);

    floodguardJsonResponse(200, [
        'success' => true,
        'data' => $stmt->fetchAll(),
    ]);
} catch (Throwable $e) {
    error_log('[Resident posts index] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Unable to load your posts.',
    ]);
}
