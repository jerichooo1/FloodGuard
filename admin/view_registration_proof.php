<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';

$registrationId = filter_input(
    INPUT_GET,
    'id',
    FILTER_VALIDATE_INT,
    ['options' => ['min_range' => 1]]
);

if ($registrationId === false || $registrationId === null) {
    http_response_code(400);
    exit('Invalid registration record.');
}

$proofStmt = $pdo->prepare(
    'SELECT
        proof_original_name,
        proof_stored_name,
        proof_mime_type
     FROM residents
     WHERE id = :id
     LIMIT 1'
);

$proofStmt->execute([
    ':id' => $registrationId
]);

$proof = $proofStmt->fetch(PDO::FETCH_ASSOC);

if (!$proof || empty($proof['proof_stored_name'])) {
    http_response_code(404);
    exit('Proof document not found.');
}

$allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'application/pdf'
];

if (!in_array($proof['proof_mime_type'], $allowedMimeTypes, true)) {
    http_response_code(415);
    exit('Unsupported proof document type.');
}

$uploadDirectory = realpath(
    __DIR__ . '/../assets/uploads/residency_proofs'
);

if ($uploadDirectory === false) {
    http_response_code(404);
    exit('Proof document folder not found.');
}

$storedName = basename((string) $proof['proof_stored_name']);
$filePath = realpath($uploadDirectory . DIRECTORY_SEPARATOR . $storedName);

if (
    $filePath === false ||
    !is_file($filePath) ||
    !str_starts_with($filePath, $uploadDirectory . DIRECTORY_SEPARATOR)
) {
    http_response_code(404);
    exit('Proof document not found.');
}

$downloadName = basename(
    (string) ($proof['proof_original_name'] ?: $storedName)
);

$asciiDownloadName = preg_replace(
    '/[^A-Za-z0-9._-]/',
    '_',
    $downloadName
) ?: 'proof-document';

header('Content-Type: ' . $proof['proof_mime_type']);
header('Content-Length: ' . filesize($filePath));
header('Content-Disposition: inline; filename="' . $asciiDownloadName . '"');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: private, no-store, max-age=0');
header('Pragma: no-cache');

readfile($filePath);
exit;
