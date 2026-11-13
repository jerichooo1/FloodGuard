<?php

declare(strict_types=1);

function floodguardIssueApiToken(PDO $pdo, int $userId, string $name='resident-mobile'): string
{
    $plain = bin2hex(random_bytes(32));
    $days = (int) ($pdo->query("SELECT setting_value FROM system_settings WHERE setting_key='mobile_access_token_days' LIMIT 1")->fetchColumn() ?: 30);
    $days = max(1, min(90, $days));
    $expires=date('Y-m-d H:i:s',time()+$days*86400);
    $statement = $pdo->prepare('INSERT INTO api_tokens (user_id,token_name,token_hash,expires_at) VALUES (:user_id,:name,:hash,:expires)');
    $statement->bindValue(':user_id', $userId, PDO::PARAM_INT);
    $statement->bindValue(':name', substr($name, 0, 100));
    $statement->bindValue(':hash', hash('sha256', $plain));
    $statement->bindValue(':expires', $expires);
    $statement->execute();
    return $plain;
}

function floodguardRequireApiUser(PDO $pdo, ?string $permission=null): array
{
    $token = floodguardBearerToken();
    if ($token === null || strlen($token) !== 64 || !ctype_xdigit($token)) {
        floodguardJsonResponse(401, ['success'=>false,'message'=>'Valid bearer token required.']);
    }
    $statement = $pdo->prepare(
        'SELECT u.id,u.full_name,u.email,u.account_status,t.id AS token_id
         FROM api_tokens t JOIN users u ON u.id=t.user_id
         WHERE t.token_hash=:hash AND t.revoked_at IS NULL AND t.expires_at>NOW()
           AND u.account_status="active" AND u.email_verified_at IS NOT NULL LIMIT 1'
    );
    $statement->execute([':hash'=>hash('sha256', $token)]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        floodguardJsonResponse(401, ['success'=>false,'message'=>'Authentication token is invalid or expired.']);
    }
    if ($permission !== null && !floodguardUserCan($pdo, (int) $user['id'], $permission)) {
        floodguardJsonResponse(403, ['success'=>false,'message'=>'Permission denied.']);
    }
    $pdo->prepare('UPDATE api_tokens SET last_used_at=NOW() WHERE id=:id')->execute([':id'=>$user['token_id']]);
    return $user;
}
