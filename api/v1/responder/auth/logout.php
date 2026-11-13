<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';

floodguardRequireMethod('POST'); $token=floodguardBearerToken();
if ($token===null || strlen($token)!==64 || !ctype_xdigit($token)) floodguardJsonResponse(401,['success'=>false,'message'=>'Valid bearer token required.']);
try {
    $stmt=$pdo->prepare('UPDATE api_tokens SET revoked_at=NOW() WHERE token_hash=:hash AND revoked_at IS NULL'); $stmt->execute([':hash'=>hash('sha256',$token)]);
    if ($stmt->rowCount()===0) floodguardJsonResponse(401,['success'=>false,'message'=>'Authentication token is invalid or already revoked.']);
    floodguardJsonResponse(200,['success'=>true,'message'=>'Responder signed out successfully.']);
} catch (Throwable $e) { error_log('[Responder logout] '.$e->getMessage()); floodguardJsonResponse(500,['success'=>false,'message'=>'Unable to sign out.']); }
