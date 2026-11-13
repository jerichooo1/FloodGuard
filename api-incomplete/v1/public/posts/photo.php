<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/Request.php';

floodguardRequireMethod('GET');

$id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
if ($id === false) {
    http_response_code(404);
    exit;
}

$stmt = $pdo->prepare(
    'SELECT cpp.file_path, cpp.mime_type
     FROM community_post_photos cpp
     JOIN community_posts cp ON cp.id=cpp.community_post_id
     WHERE cpp.id=:id
       AND cp.status IN ("approved", "published")
     LIMIT 1'
);
$stmt->execute([':id' => $id]);
$photo = $stmt->fetch();
if (!$photo) {
    http_response_code(404);
    exit;
}

$privateRoot = realpath(dirname(__DIR__, 4).'/storage/private');
$path = realpath(dirname(__DIR__, 4).'/'.$photo['file_path']);
if ($privateRoot === false || $path === false
    || !str_starts_with($path, $privateRoot.DIRECTORY_SEPARATOR)
    || !is_file($path)) {
    http_response_code(404);
    exit;
}

header('Content-Type: '.$photo['mime_type']);
header('Content-Disposition: inline; filename="floodguard-community-update"');
header('Cache-Control: public, max-age=300');
header('X-Content-Type-Options: nosniff');
readfile($path);
