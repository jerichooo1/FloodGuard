<?php

declare(strict_types=1);

require_once __DIR__.'/../config/database.php';
require_once __DIR__.'/includes/auth.php';
require_once __DIR__.'/../app/Audit/AuditLogger.php';

if (!isset($staffPermissions['posts.review'])) {
    http_response_code(403);
    exit('Barangay personnel post-review access required.');
}

$flash = isset($_GET['updated']) ? 'Post review updated successfully.' : '';
$flashType = 'success';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!floodguardVerifyCsrf((string)($_POST['csrf_token'] ?? ''), 'staff_operations')) {
            throw new RuntimeException('The form expired. Please try again.');
        }
        if (!isset($staffPermissions['posts.decide'])) {
            throw new RuntimeException('Permission denied.');
        }

        $postId = filter_var($_POST['post_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        $action = (string)($_POST['action'] ?? '');
        if ($postId === false) {
            throw new InvalidArgumentException('Select a valid post.');
        }

        $pdo->beginTransaction();
        $stmt = $pdo->prepare('SELECT * FROM community_posts WHERE id=:id FOR UPDATE');
        $stmt->execute([':id' => $postId]);
        $post = $stmt->fetch();
        if (!$post) {
            throw new RuntimeException('Post not found.');
        }

        $from = (string)$post['status'];
        $notes = trim((string)($_POST['review_notes'] ?? ''));
        if (mb_strlen($notes) > 1000) {
            throw new InvalidArgumentException('Review notes must not exceed 1000 characters.');
        }

        if ($action === 'revision_requested') {
            if (!in_array($from, ['submitted', 'under_review'], true)) {
                throw new DomainException('Only a pending post can receive a revision request.');
            }
            if ($notes === '') {
                throw new InvalidArgumentException('Explain what the resident must revise.');
            }
            $to = 'revision_requested';
            $pdo->prepare(
                'UPDATE community_posts
                 SET status=:status, reviewer_user_id=:reviewer,
                     review_notes=:notes, reviewed_at=NOW()
                 WHERE id=:id'
            )->execute([
                ':status' => $to,
                ':reviewer' => $staffUser['id'],
                ':notes' => $notes,
                ':id' => $postId,
            ]);
        } elseif ($action === 'rejected') {
            if (!in_array($from, ['submitted', 'under_review'], true)) {
                throw new DomainException('Only a pending post can be rejected.');
            }
            if ($notes === '') {
                throw new InvalidArgumentException('Provide a reason for rejection.');
            }
            $to = 'rejected';
            $pdo->prepare(
                'UPDATE community_posts
                 SET status=:status, reviewer_user_id=:reviewer,
                     review_notes=:notes, reviewed_at=NOW(), published_at=NULL
                 WHERE id=:id'
            )->execute([
                ':status' => $to,
                ':reviewer' => $staffUser['id'],
                ':notes' => $notes,
                ':id' => $postId,
            ]);
        } elseif ($action === 'published') {
            if (!in_array($from, ['submitted', 'under_review'], true)) {
                throw new DomainException('Only a pending post can be published.');
            }
            $to = 'published';
            $pdo->prepare(
                'UPDATE community_posts
                 SET status=:status, reviewer_user_id=:reviewer,
                     review_notes=:notes, reviewed_at=NOW(), published_at=NOW()
                 WHERE id=:id'
            )->execute([
                ':status' => $to,
                ':reviewer' => $staffUser['id'],
                ':notes' => $notes === '' ? null : $notes,
                ':id' => $postId,
            ]);
        } else {
            throw new InvalidArgumentException('Invalid post-review action.');
        }

        $pdo->prepare(
            'INSERT INTO community_post_status_history
                (community_post_id, previous_status, new_status, changed_by_user_id, notes)
             VALUES (:post, :previous, :new, :user, :notes)'
        )->execute([
            ':post' => $postId,
            ':previous' => $from,
            ':new' => $to,
            ':user' => $staffUser['id'],
            ':notes' => $notes === '' ? null : $notes,
        ]);

        floodguardAudit(
            $pdo,
            (int)$staffUser['id'],
            'community_post.'.$to,
            'community_post',
            (int)$postId,
            ['status' => $from],
            ['status' => $to, 'notes' => $notes === '' ? null : $notes]
        );

        $pdo->commit();
        floodguardRotateCsrf('staff_operations');
        header('Location: posts.php?id='.(int)$postId.'&updated=1');
        exit;
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $flash = $e instanceof DomainException
            ? 'That post action is not allowed from its current status.'
            : $e->getMessage();
        $flashType = 'error';
    }
}

$allowed = ['all', 'submitted', 'revision_requested', 'rejected', 'published', 'archived'];
$filter = (string)($_GET['status'] ?? 'all');
if (!in_array($filter, $allowed, true)) {
    $filter = 'all';
}

$sql =
    'SELECT cp.id, cp.post_number, cp.title, cp.category, cp.status,
            cp.submitted_at, u.full_name AS resident_name,
            (SELECT COUNT(*) FROM community_post_photos cpp
             WHERE cpp.community_post_id=cp.id) AS photo_count
     FROM community_posts cp
     JOIN users u ON u.id=cp.resident_user_id';
$params = [];
if ($filter !== 'all') {
    $sql .= ' WHERE cp.status=:status';
    $params[':status'] = $filter;
}
$sql .= ' ORDER BY cp.submitted_at DESC, cp.id DESC LIMIT 200';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$posts = $stmt->fetchAll();

$selected = null;
$history = [];
$selectedId = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
if ($selectedId !== false) {
    $stmt = $pdo->prepare(
        'SELECT cp.*, u.full_name AS resident_name, u.email AS resident_email,
                (SELECT id FROM community_post_photos
                 WHERE community_post_id=cp.id ORDER BY id DESC LIMIT 1) AS photo_id
         FROM community_posts cp
         JOIN users u ON u.id=cp.resident_user_id
         WHERE cp.id=:id'
    );
    $stmt->execute([':id' => $selectedId]);
    $selected = $stmt->fetch();
    if ($selected) {
        $historyStmt = $pdo->prepare(
            'SELECT h.previous_status, h.new_status, h.notes, h.created_at,
                    COALESCE(u.full_name, "System") AS changed_by_name
             FROM community_post_status_history h
             LEFT JOIN users u ON u.id=h.changed_by_user_id
             WHERE h.community_post_id=:id
             ORDER BY h.created_at, h.id'
        );
        $historyStmt->execute([':id' => $selectedId]);
        $history = $historyStmt->fetchAll();
    }
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Post Review | FloodGuard</title>
<link rel="stylesheet" href="../assets/css/admin.css">
<link rel="stylesheet" href="../assets/css/barangay.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__.'/includes/layout.php'; ?>
<div class="admin-page">
<header class="admin-topbar staff-topbar">
<div class="topbar-left"><button type="button" class="mobile-menu-button" id="mobileMenuButton" aria-label="Open navigation"><i class="bi bi-list"></i></button><div><h1>Post Review</h1><p>Review resident updates before public publication</p></div></div>
<div class="topbar-right"><div class="topbar-station-status"><span class="station-dot <?=$staffDeviceOnline?'online':'offline'?>"></span><div><span>Monitoring Station</span><strong><?=$staffDeviceOnline?'Receiving Data':'Waiting for Data'?></strong></div></div><div class="topbar-admin"><div class="admin-avatar"><?=floodguardEscape(strtoupper(substr((string)$staffUser['full_name'],0,1)))?></div><div><strong><?=floodguardEscape($staffUser['full_name'])?></strong><span>Barangay Personnel</span></div></div></div>
</header>
<main class="admin-content">
<div class="page-intro"><div><span class="eyebrow">Public information</span><h2>Review resident community posts</h2><p>Approve only verified and appropriate updates for the public FloodGuard website.</p></div><span class="role-pill"><i class="bi bi-shield-check"></i> <?=floodguardEscape($staffUser['role_name'])?></span></div>
<?php if ($flash !== ''): ?><div class="message <?=$flashType?>"><?=floodguardEscape($flash)?></div><?php endif; ?>
<section class="staff-grid">
<div class="queue-card">
<form class="filters" method="get"><label>Status<select name="status" onchange="this.form.submit()">
<?php foreach ($allowed as $value): ?><option value="<?=$value?>" <?=$filter===$value?'selected':''?>><?=floodguardEscape(ucwords(str_replace('_',' ',$value)))?></option><?php endforeach; ?>
</select></label></form>
<div class="report-list">
<?php if (!$posts): ?><div class="empty">No posts in this queue.</div><?php endif; ?>
<?php foreach ($posts as $row): ?>
<a href="?status=<?=urlencode($filter)?>&id=<?=$row['id']?>" class="report-row <?=$selectedId===(int)$row['id']?'active':''?>">
<div><strong><?=floodguardEscape($row['post_number'])?></strong><span><?=floodguardEscape($row['resident_name'])?> · <?=floodguardEscape($row['title'])?></span></div>
<div><span class="status status-<?=floodguardEscape($row['status'])?>"><?=floodguardEscape(str_replace('_',' ',$row['status']))?></span><small><?=floodguardEscape(ucwords(str_replace('_',' ',$row['category'])))?></small></div>
</a>
<?php endforeach; ?>
</div></div>
<div class="detail-card">
<?php if (!$selected): ?>
<div class="empty large"><i class="bi bi-newspaper"></i><h2>Select a post</h2><p>Choose a resident post to inspect its content and photograph.</p></div>
<?php else: ?>
<div class="detail-head"><div><span class="kicker">Post details</span><h2><?=floodguardEscape($selected['post_number'])?></h2></div><span class="status status-<?=floodguardEscape($selected['status'])?>"><?=floodguardEscape(str_replace('_',' ',$selected['status']))?></span></div>
<dl class="report-details">
<div><dt>Resident</dt><dd><?=floodguardEscape($selected['resident_name'])?><br><small><?=floodguardEscape($selected['resident_email'])?></small></dd></div>
<div><dt>Category</dt><dd><?=floodguardEscape(ucwords(str_replace('_',' ',$selected['category'])))?></dd></div>
<div><dt>Title</dt><dd><?=floodguardEscape($selected['title'])?></dd></div>
<div><dt>Post content</dt><dd><?=nl2br(floodguardEscape($selected['content']))?></dd></div>
<div><dt>Location</dt><dd><?=floodguardEscape($selected['location_name'] ?: 'Not provided')?><?php if ($selected['latitude'] !== null): ?><br><small><?=floodguardEscape($selected['latitude'])?>, <?=floodguardEscape($selected['longitude'])?></small><?php endif; ?></dd></div>
<div><dt>Submitted</dt><dd><?=floodguardEscape($selected['submitted_at'])?></dd></div>
</dl>
<?php if ($selected['photo_id']): ?><a class="photo-link" href="post_photo.php?id=<?=$selected['photo_id']?>" target="_blank"><i class="bi bi-image"></i> View submitted photograph</a><?php endif; ?>
<div class="history"><h3>Status history</h3>
<?php foreach ($history as $item): ?><div><strong><?=floodguardEscape(str_replace('_',' ',$item['new_status']))?></strong><span><?=floodguardEscape($item['created_at'])?> · <?=floodguardEscape($item['changed_by_name'])?></span><?php if ($item['notes']): ?><p><?=floodguardEscape($item['notes'])?></p><?php endif; ?></div><?php endforeach; ?>
</div>
<?php if (in_array($selected['status'], ['submitted', 'under_review'], true)): ?>
<form method="post" class="decision-form"><input type="hidden" name="csrf_token" value="<?=floodguardEscape($staffCsrf)?>"><input type="hidden" name="post_id" value="<?=$selected['id']?>"><label>Review notes<textarea name="review_notes" maxlength="1000" placeholder="Required for revision requests and rejection"></textarea></label><div class="button-row"><button class="warning" name="action" value="revision_requested">Request revision</button><button class="danger" name="action" value="rejected">Reject</button></div><button class="success" name="action" value="published">Approve and publish</button></form>
<?php elseif ($selected['review_notes']): ?><div class="decision-reason"><strong>Review notes</strong><p><?=floodguardEscape($selected['review_notes'])?></p></div><?php endif; ?>
<?php endif; ?>
</div></section>
</main></div>
<script src="../assets/js/admin.js"></script>
</body></html>
