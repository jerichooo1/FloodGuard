<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

if (!isset($currentPermissions['users.manage'])) {
    http_response_code(403);
    exit('Resident account management permission is required.');
}

$userId = filter_input(INPUT_GET, 'user_id', FILTER_VALIDATE_INT, [
    'options' => ['min_range' => 1],
]);
if (!$userId) {
    http_response_code(400);
    exit('A valid resident account is required.');
}

$statement = $pdo->prepare(
    'SELECT verification_proof_path, verification_proof_mime
     FROM resident_profiles
     WHERE user_id=:user_id
     LIMIT 1'
);
$statement->execute([':user_id' => $userId]);
$proof = $statement->fetch(PDO::FETCH_ASSOC);

if (!$proof || empty($proof['verification_proof_path'])) {
    http_response_code(404);
    exit('Proof image not found.');
}

$privateRoot = realpath(__DIR__ . '/../storage/private');
$candidate = realpath(
    __DIR__ . '/../storage/private/' . ltrim((string) $proof['verification_proof_path'], '/')
);
if ($privateRoot === false || $candidate === false || !str_starts_with($candidate, $privateRoot . DIRECTORY_SEPARATOR) || !is_file($candidate)) {
    http_response_code(404);
    exit('Proof image not found.');
}

$allowed = ['image/jpeg', 'image/png'];
$mime = (string) ($proof['verification_proof_mime'] ?? '');
if (!in_array($mime, $allowed, true)) {
    http_response_code(415);
    exit('Unsupported proof format.');
}

header('Content-Type: ' . $mime);
header('Content-Length: ' . (string) filesize($candidate));
header('Content-Disposition: inline; filename="resident-proof-' . $userId . '"');
header('Cache-Control: private, no-store, max-age=0');
header('X-Content-Type-Options: nosniff');
readfile($candidate);
exit;
