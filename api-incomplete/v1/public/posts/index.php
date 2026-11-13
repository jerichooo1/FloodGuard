<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';

floodguardRequireMethod('GET');

try {
    $allowedCategories = ['spillway_update', 'road_condition', 'flood_update', 'community_update'];
    $category = trim((string) ($_GET['category'] ?? ''));
    if ($category !== '' && !in_array($category, $allowedCategories, true)) {
        floodguardJsonResponse(422, ['success' => false, 'message' => 'Invalid post category.']);
    }

    $page = max(1, filter_var($_GET['page'] ?? 1, FILTER_VALIDATE_INT) ?: 1);
    $limit = filter_var($_GET['limit'] ?? 10, FILTER_VALIDATE_INT) ?: 10;
    $limit = max(1, min(12, $limit));
    $offset = ($page - 1) * $limit;
    $where = 'cp.status IN ("approved", "published")';
    $parameters = [];
    if ($category !== '') {
        $where .= ' AND cp.category=:category';
        $parameters[':category'] = $category;
    }

    $countStmt = $pdo->prepare('SELECT COUNT(*) FROM community_posts cp WHERE '.$where);
    $countStmt->execute($parameters);
    $total = (int) $countStmt->fetchColumn();
    $pages = max(1, (int) ceil($total / $limit));
    if ($page > $pages) {
        $page = $pages;
        $offset = ($page - 1) * $limit;
    }

    $stmt = $pdo->prepare(
        'SELECT cp.post_number, cp.category, cp.title, cp.content,
                cp.location_name,
                COALESCE(cp.published_at, cp.reviewed_at, cp.updated_at) AS published_at,
                (SELECT cpp.id
                 FROM community_post_photos cpp
                 WHERE cpp.community_post_id=cp.id
                 ORDER BY cpp.id DESC LIMIT 1) AS photo_id
         FROM community_posts cp
         WHERE '.$where.'
         ORDER BY COALESCE(cp.published_at, cp.reviewed_at, cp.updated_at) DESC, cp.id DESC
         LIMIT :limit OFFSET :offset'
    );
    foreach ($parameters as $key => $value) {
        $stmt->bindValue($key, $value, PDO::PARAM_STR);
    }
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
        $row['photo_url'] = $row['photo_id'] === null
            ? null
            : 'api/v1/public/posts/photo.php?id='.(int)$row['photo_id'];
        unset($row['photo_id']);
    }
    unset($row);

    floodguardJsonResponse(200, [
        'success' => true,
        'data' => $rows,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'pages' => $pages,
        ],
    ]);
} catch (Throwable $e) {
    error_log('[Public community posts] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Public community updates are temporarily unavailable.',
    ]);
}
