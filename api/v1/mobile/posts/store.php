<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';
require_once __DIR__.'/../../../../app/Support/Validation.php';
require_once __DIR__.'/../../../../app/Reports/ReportUpload.php';
require_once __DIR__.'/../../../../app/Audit/AuditLogger.php';

floodguardRequireMethod('POST');
$user = floodguardRequireApiUser($pdo, 'posts.create_own');
$userId = (int)$user['id'];
$stored = null;

try {
    $category = trim((string)($_POST['category'] ?? 'spillway_update'));
    $allowedCategories = ['spillway_update', 'road_condition', 'flood_update', 'community_update'];
    if (!in_array($category, $allowedCategories, true)) {
        throw new InvalidArgumentException('Select a valid post category.');
    }

    $title = floodguardRequiredString($_POST, 'title', 150);
    $content = floodguardRequiredString($_POST, 'content', 5000);
    $locationName = trim((string)($_POST['location_name'] ?? ''));
    if (mb_strlen($locationName) > 180) {
        throw new InvalidArgumentException('The location must not exceed 180 characters.');
    }

    $latitude = null;
    $longitude = null;
    $hasLatitude = isset($_POST['latitude']) && $_POST['latitude'] !== '';
    $hasLongitude = isset($_POST['longitude']) && $_POST['longitude'] !== '';
    if ($hasLatitude !== $hasLongitude) {
        throw new InvalidArgumentException('Provide both latitude and longitude, or leave both empty.');
    }
    if ($hasLatitude) {
        $latitude = filter_var($_POST['latitude'], FILTER_VALIDATE_FLOAT);
        $longitude = filter_var($_POST['longitude'], FILTER_VALIDATE_FLOAT);
        if ($latitude === false || $longitude === false
            || $latitude < -90 || $latitude > 90
            || $longitude < -180 || $longitude > 180) {
            throw new InvalidArgumentException('Provide valid coordinates.');
        }
    }

    $photo = floodguardValidateReportPhoto($pdo, $_FILES['photo'] ?? []);
    $postNumber = 'FG-POST-'.date('Ymd').'-'.strtoupper(bin2hex(random_bytes(4)));

    $pdo->beginTransaction();
    $insert = $pdo->prepare(
        'INSERT INTO community_posts
            (post_number, resident_user_id, category, title, content,
             location_name, latitude, longitude, status, submitted_at)
         VALUES
            (:number, :resident, :category, :title, :content,
             :location, :latitude, :longitude, "submitted", NOW())'
    );
    $insert->execute([
        ':number' => $postNumber,
        ':resident' => $userId,
        ':category' => $category,
        ':title' => $title,
        ':content' => $content,
        ':location' => $locationName === '' ? null : $locationName,
        ':latitude' => $latitude,
        ':longitude' => $longitude,
    ]);
    $postId = (int)$pdo->lastInsertId();

    $stored = floodguardStoreReportPhoto($photo);
    $pdo->prepare(
        'INSERT INTO community_post_photos
            (community_post_id, file_path, original_filename, mime_type, file_size_bytes)
         VALUES (:post, :path, :name, :mime, :size)'
    )->execute([
        ':post' => $postId,
        ':path' => $stored['storage_path'],
        ':name' => $photo['original_name'],
        ':mime' => $photo['mime_type'],
        ':size' => $photo['size'],
    ]);

    $pdo->prepare(
        'INSERT INTO community_post_status_history
            (community_post_id, previous_status, new_status, changed_by_user_id, notes)
         VALUES (:post, NULL, "submitted", :user, NULL)'
    )->execute([':post' => $postId, ':user' => $userId]);

    floodguardAudit(
        $pdo,
        $userId,
        'community_post.created',
        'community_post',
        $postId,
        null,
        ['post_number' => $postNumber, 'status' => 'submitted']
    );

    $pdo->commit();
    floodguardJsonResponse(201, [
        'success' => true,
        'message' => 'Your post was submitted for barangay review.',
        'data' => [
            'id' => $postId,
            'post_number' => $postNumber,
            'status' => 'submitted',
        ],
    ]);
} catch (InvalidArgumentException $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    floodguardJsonResponse(422, ['success' => false, 'message' => $e->getMessage()]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    if (isset($stored['absolute_path']) && is_file($stored['absolute_path'])) {
        unlink($stored['absolute_path']);
    }
    error_log('[Resident post store] '.$e->getMessage());
    floodguardJsonResponse(500, [
        'success' => false,
        'message' => 'Unable to submit your post.',
    ]);
}
