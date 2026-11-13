<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
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
    http_response_code(404);
    exit;
}

$stmt = $pdo->prepare(
    'SELECT cpp.file_path, cpp.mime_type
     FROM community_post_photos cpp
     JOIN community_posts cp ON cp.id = cpp.community_post_id
     WHERE cpp.id = :id
       AND cp.resident_user_id = :resident
     LIMIT 1'
);
$stmt->execute([':id' => $id, ':resident' => $user['id']]);
$photo = $stmt->fetch();
if (!$photo) {
    http_response_code(404);
    exit;
}

$applicationRoot = dirname(__DIR__, 4);
$privateRoot = realpath($applicationRoot.'/storage/private');
$path = realpath($applicationRoot.'/'.$photo['file_path']);
if (
    $privateRoot === false ||
    $path === false ||
    !str_starts_with($path, $privateRoot.DIRECTORY_SEPARATOR) ||
    !is_file($path)
) {
    http_response_code(404);
    exit;
}

header('Content-Type: '.$photo['mime_type']);
header('Content-Disposition: inline; filename="floodguard-community-post"');
header('Cache-Control: private, max-age=300');
header('X-Content-Type-Options: nosniff');
readfile($path);
