<?php

declare(strict_types=1);

function floodguardUserPermissions(PDO $pdo, int $userId): array
{
    $statement = $pdo->prepare(
        'SELECT DISTINCT p.slug
         FROM permissions p
         INNER JOIN role_permissions rp ON rp.permission_id = p.id
         INNER JOIN user_roles ur ON ur.role_id = rp.role_id
         WHERE ur.user_id = :user_id'
    );
    $statement->execute([':user_id' => $userId]);
    return array_fill_keys($statement->fetchAll(PDO::FETCH_COLUMN), true);
}

function floodguardUserCan(PDO $pdo, int $userId, string $permission): bool
{
    return isset(floodguardUserPermissions($pdo, $userId)[$permission]);
}

function floodguardRequirePermission(PDO $pdo, int $userId, string $permission): void
{
    if (!floodguardUserCan($pdo, $userId, $permission)) {
        http_response_code(403);
        exit('You are not authorized to perform this action.');
    }
}
