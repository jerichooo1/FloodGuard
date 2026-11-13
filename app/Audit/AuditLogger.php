<?php

declare(strict_types=1);

function floodguardAudit(PDO $pdo, ?int $actorId, string $action, string $entityType, ?int $entityId, ?array $before=null, ?array $after=null): void
{
    $statement=$pdo->prepare('INSERT INTO audit_logs (actor_user_id,action,entity_type,entity_id,ip_address,user_agent,before_json,after_json) VALUES (:actor,:action,:type,:entity,:ip,:agent,:before_json,:after_json)');
    $statement->execute([
        ':actor'=>$actorId, ':action'=>substr($action,0,100), ':type'=>substr($entityType,0,80), ':entity'=>$entityId,
        ':ip'=>substr((string)($_SERVER['REMOTE_ADDR']??''),0,45), ':agent'=>substr((string)($_SERVER['HTTP_USER_AGENT']??''),0,500),
        ':before_json'=>$before===null?null:json_encode($before,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
        ':after_json'=>$after===null?null:json_encode($after,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES)
    ]);
}
