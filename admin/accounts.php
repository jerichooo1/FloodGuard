<?php

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/../app/Audit/AuditLogger.php';

date_default_timezone_set('Asia/Manila');
try { $pdo->exec("SET time_zone = '+08:00'"); } catch (PDOException $exception) { /* Use server timezone. */ }

if (!isset($currentPermissions['users.manage'])) {
    http_response_code(403);
    exit('User account management permission is required.');
}

function accountEscape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function accountPasswordIsValid(string $password): bool
{
    return strlen($password) >= 12 && strlen($password) <= 72
        && preg_match('/[A-Za-z]/', $password) === 1
        && preg_match('/\d/', $password) === 1;
}

function accountRole(PDO $pdo, int $userId, bool $lock = false): ?array
{
    $sql = 'SELECT u.id,u.full_name,u.email,u.account_status,u.token_version,r.slug AS role_slug,r.name AS role_name
            FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id
            WHERE u.id=:id AND r.slug IN ("barangay_personnel","responder") LIMIT 1' . ($lock ? ' FOR UPDATE' : '');
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id' => $userId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

function accountReferenceCount(PDO $pdo, int $userId): int
{
    $stmt = $pdo->prepare(
        'SELECT
            (SELECT COUNT(*) FROM flood_reports WHERE reporter_user_id=:u1 OR reviewed_by=:u2) +
            (SELECT COUNT(*) FROM flood_report_photos WHERE uploaded_by=:u3) +
            (SELECT COUNT(*) FROM flood_report_status_history WHERE changed_by=:u4) +
            (SELECT COUNT(*) FROM flood_incidents WHERE created_by=:u5 OR public_approved_by=:u6 OR resolution_verified_by=:u7) +
            (SELECT COUNT(*) FROM response_teams WHERE created_by=:u8) +
            (SELECT COUNT(*) FROM response_team_members WHERE responder_user_id=:u9) +
            (SELECT COUNT(*) FROM incident_assignments WHERE assigned_by=:u10 OR accepted_by=:u11) +
            (SELECT COUNT(*) FROM incident_status_history WHERE changed_by=:u12) +
            (SELECT COUNT(*) FROM audit_logs WHERE actor_user_id=:u13)'
    );
    $params = [];
    for ($i = 1; $i <= 13; $i++) $params[':u' . $i] = $userId;
    $stmt->execute($params);
    return (int) $stmt->fetchColumn();
}

$flash = $_SESSION['account_flash'] ?? null;
unset($_SESSION['account_flash']);
$csrf = floodguardCsrfToken('admin_accounts');
$allowedRoles = ['barangay_personnel', 'responder'];
$allowedStatuses = ['active', 'inactive', 'suspended'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!floodguardVerifyCsrf((string) ($_POST['csrf_token'] ?? ''), 'admin_accounts')) {
            throw new RuntimeException('The form expired. Refresh the page and try again.');
        }
        $action = (string) ($_POST['action'] ?? '');
        $pdo->beginTransaction();

        if ($action === 'create') {
            $name = trim((string) ($_POST['full_name'] ?? ''));
            $email = strtolower(trim((string) ($_POST['email'] ?? '')));
            $role = (string) ($_POST['role'] ?? '');
            $password = (string) ($_POST['password'] ?? '');
            if ($name === '' || mb_strlen($name) > 150) throw new InvalidArgumentException('Full name is required and must not exceed 150 characters.');
            if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || strlen($email) > 190) throw new InvalidArgumentException('Enter a valid email address.');
            if (!in_array($role, $allowedRoles, true)) throw new InvalidArgumentException('Select an approved operational role.');
            if (!accountPasswordIsValid($password)) throw new InvalidArgumentException('Password must be 12–72 characters and contain a letter and number.');
            $exists = $pdo->prepare('SELECT COUNT(*) FROM users WHERE email=:email');
            $exists->execute([':email' => $email]);
            if ((int) $exists->fetchColumn() > 0) throw new InvalidArgumentException('An account already uses that email address.');
            $insert = $pdo->prepare('INSERT INTO users (full_name,email,password_hash,email_verified_at,account_status) VALUES (:name,:email,:password,NOW(),"active")');
            $insert->execute([':name' => $name, ':email' => $email, ':password' => password_hash($password, PASSWORD_DEFAULT)]);
            $userId = (int) $pdo->lastInsertId();
            $roleStmt = $pdo->prepare('INSERT INTO user_roles (user_id,role_id,assigned_by) SELECT :user,id,:admin FROM roles WHERE slug=:role');
            $roleStmt->execute([':user' => $userId, ':admin' => $currentUser['id'], ':role' => $role]);
            if ($roleStmt->rowCount() !== 1) throw new RuntimeException('The selected role is not installed.');
            floodguardAudit($pdo, (int) $currentUser['id'], 'user.created', 'user', $userId, null, ['full_name'=>$name,'email'=>$email,'role'=>$role,'account_status'=>'active']);
            $message = 'Account created successfully.';
        } else {
            $userId = filter_var($_POST['user_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            if ($userId === false) throw new InvalidArgumentException('Select a valid account.');
            $before = accountRole($pdo, (int) $userId, true);
            if (!$before) throw new RuntimeException('The selected operational account was not found.');

            if ($action === 'update') {
                $name = trim((string) ($_POST['full_name'] ?? ''));
                $email = strtolower(trim((string) ($_POST['email'] ?? '')));
                $role = (string) ($_POST['role'] ?? '');
                $status = (string) ($_POST['account_status'] ?? '');
                if ($name === '' || mb_strlen($name) > 150) throw new InvalidArgumentException('Full name is required and must not exceed 150 characters.');
                if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || strlen($email) > 190) throw new InvalidArgumentException('Enter a valid email address.');
                if (!in_array($role, $allowedRoles, true) || !in_array($status, $allowedStatuses, true)) throw new InvalidArgumentException('Select a valid role and account status.');
                if ($role !== $before['role_slug'] && accountReferenceCount($pdo, (int) $userId) > 0) {
                    throw new DomainException('This account already has operational history. Keep its current role, deactivate it if needed, and create a separate account for the other role.');
                }
                $exists = $pdo->prepare('SELECT COUNT(*) FROM users WHERE email=:email AND id<>:id');
                $exists->execute([':email' => $email, ':id' => $userId]);
                if ((int) $exists->fetchColumn() > 0) throw new InvalidArgumentException('Another account already uses that email address.');
                $pdo->prepare('UPDATE users SET full_name=:name,email=:email,account_status=:status,token_version=token_version+1 WHERE id=:id')->execute([':name'=>$name,':email'=>$email,':status'=>$status,':id'=>$userId]);
                $pdo->prepare('DELETE ur FROM user_roles ur JOIN roles r ON r.id=ur.role_id WHERE ur.user_id=:id AND r.slug IN ("barangay_personnel","responder")')->execute([':id'=>$userId]);
                $pdo->prepare('INSERT INTO user_roles (user_id,role_id,assigned_by) SELECT :user,id,:admin FROM roles WHERE slug=:role')->execute([':user'=>$userId,':admin'=>$currentUser['id'],':role'=>$role]);
                $pdo->prepare('UPDATE api_tokens SET revoked_at=COALESCE(revoked_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
                floodguardAudit($pdo,(int)$currentUser['id'],'user.updated','user',(int)$userId,$before,['full_name'=>$name,'email'=>$email,'role_slug'=>$role,'account_status'=>$status]);
                $message = 'Account details updated and existing sessions revoked.';
            } elseif ($action === 'reset_password') {
                $password = (string) ($_POST['new_password'] ?? '');
                $confirmation = (string) ($_POST['confirm_password'] ?? '');
                if (!accountPasswordIsValid($password)) throw new InvalidArgumentException('Password must be 12–72 characters and contain a letter and number.');
                if (!hash_equals($password, $confirmation)) throw new InvalidArgumentException('Password confirmation does not match.');
                $pdo->prepare('UPDATE users SET password_hash=:password,token_version=token_version+1 WHERE id=:id')->execute([':password'=>password_hash($password,PASSWORD_DEFAULT),':id'=>$userId]);
                $pdo->prepare('UPDATE api_tokens SET revoked_at=COALESCE(revoked_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
                floodguardAudit($pdo,(int)$currentUser['id'],'user.password_reset','user',(int)$userId,['token_version'=>$before['token_version']],['token_version'=>(int)$before['token_version']+1]);
                $message = 'Password reset successfully. Existing API sessions were revoked.';
            } elseif ($action === 'delete') {
                $references = accountReferenceCount($pdo, (int) $userId);
                if ($references > 0) {
                    $pdo->prepare('UPDATE users SET account_status="inactive",token_version=token_version+1 WHERE id=:id')->execute([':id'=>$userId]);
                    $pdo->prepare('UPDATE api_tokens SET revoked_at=COALESCE(revoked_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
                    floodguardAudit($pdo,(int)$currentUser['id'],'user.deactivated_for_retention','user',(int)$userId,$before,['account_status'=>'inactive','reference_count'=>$references]);
                    $message = 'Account has operational history, so it was safely deactivated instead of deleted.';
                } else {
                    floodguardAudit($pdo,(int)$currentUser['id'],'user.deleted','user',(int)$userId,$before,null);
                    $pdo->prepare('DELETE FROM users WHERE id=:id')->execute([':id'=>$userId]);
                    $message = 'Unused account permanently deleted.';
                }
            } else {
                throw new InvalidArgumentException('Invalid account action.');
            }
        }

        $pdo->commit();
        floodguardRotateCsrf('admin_accounts');
        $_SESSION['account_flash'] = ['type'=>'success','message'=>$message];
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        $_SESSION['account_flash'] = ['type'=>'error','message'=>$exception->getMessage()];
    }
    header('Location: accounts.php');
    exit;
}

$accounts = $pdo->query(
    'SELECT u.id,u.full_name,u.email,u.account_status,u.email_verified_at,u.last_login_at,u.created_at,r.slug AS role_slug,r.name AS role_name,
        ((SELECT COUNT(*) FROM flood_reports WHERE reporter_user_id=u.id OR reviewed_by=u.id) +
         (SELECT COUNT(*) FROM response_team_members WHERE responder_user_id=u.id) +
         (SELECT COUNT(*) FROM incident_assignments WHERE assigned_by=u.id OR accepted_by=u.id) +
         (SELECT COUNT(*) FROM incident_status_history WHERE changed_by=u.id) +
         (SELECT COUNT(*) FROM audit_logs WHERE actor_user_id=u.id)) AS reference_count
     FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id
     WHERE r.slug IN ("barangay_personnel","responder")
     ORDER BY FIELD(r.slug,"barangay_personnel","responder"),u.full_name'
)->fetchAll(PDO::FETCH_ASSOC);
$barangayCount = count(array_filter($accounts, fn(array $a): bool => $a['role_slug'] === 'barangay_personnel'));
$responderCount = count(array_filter($accounts, fn(array $a): bool => $a['role_slug'] === 'responder'));
$activeCount = count(array_filter($accounts, fn(array $a): bool => $a['account_status'] === 'active'));

$pageTitle = 'Account Management';
$pageSubtitle = 'Manage Barangay Personnel and Responder access.';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Account Management | FloodGuard</title>
    <link rel="stylesheet" href="../assets/css/admin.css"><link rel="stylesheet" href="../assets/css/account-management.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
</head>
<body>
<?php require __DIR__ . '/includes/sidebar.php'; ?>
<div class="admin-page">
<?php require __DIR__ . '/includes/topbar.php'; ?>
    <main class="admin-content standard-admin-page accounts-page">
    <?php if (is_array($flash)): ?><div class="account-alert <?= accountEscape($flash['type'] ?? 'error') ?>" role="status"><i class="bi <?= ($flash['type'] ?? '') === 'success' ? 'bi-check-circle-fill' : 'bi-exclamation-circle-fill' ?>"></i><span><?= accountEscape($flash['message'] ?? '') ?></span></div><?php endif; ?>
    <section class="account-summary" aria-label="Account summary">
        <article><span>Total managed accounts</span><strong><?= count($accounts) ?></strong><small>Operational users</small></article>
        <article><span>Barangay Personnel</span><strong><?= $barangayCount ?></strong><small>Review and dispatch access</small></article>
        <article><span>Responders</span><strong><?= $responderCount ?></strong><small>Field-response access</small></article>
        <article><span>Active accounts</span><strong><?= $activeCount ?></strong><small>Currently permitted to sign in</small></article>
    </section>
    <section class="accounts-panel">
        <header class="accounts-toolbar"><div><h2>Operational accounts</h2><p>Create and maintain access without exposing Administrator or Resident accounts.</p></div><div class="toolbar-actions"><label class="account-search"><i class="bi bi-search"></i><input id="accountSearch" type="search" placeholder="Search name or email" aria-label="Search accounts"></label><select class="role-filter" id="accountRoleFilter" aria-label="Filter by role"><option value="all">All roles</option><option value="barangay_personnel">Barangay Personnel</option><option value="responder">Responders</option></select><button class="account-button" type="button" data-open-modal="createAccountModal"><i class="bi bi-person-plus-fill"></i>Create account</button></div></header>
        <div class="accounts-table-wrap"><table class="accounts-table"><thead><tr><th>Account</th><th>Role</th><th>Status</th><th>Last sign in</th><th>Created</th><th><span class="visually-hidden">Actions</span></th></tr></thead><tbody>
        <?php if (!$accounts): ?><tr><td class="empty-accounts" colspan="6">No Barangay Personnel or Responder accounts found.</td></tr><?php endif; ?>
        <?php foreach ($accounts as $account): $data=['id'=>(int)$account['id'],'name'=>$account['full_name'],'email'=>$account['email'],'role'=>$account['role_slug'],'status'=>$account['account_status']]; $deleteData=['id'=>(int)$account['id'],'name'=>$account['full_name'],'email'=>$account['email'],'safe'=>(int)$account['reference_count']===0]; ?>
            <tr data-account-row data-role="<?= accountEscape($account['role_slug']) ?>" data-search="<?= accountEscape(strtolower($account['full_name'].' '.$account['email'])) ?>"><td><div class="account-person"><span class="account-avatar"><?= accountEscape(strtoupper(substr($account['full_name'],0,1))) ?></span><div><strong><?= accountEscape($account['full_name']) ?></strong><small><?= accountEscape($account['email']) ?></small></div></div></td><td><span class="role-chip <?= accountEscape($account['role_slug']) ?>"><?= accountEscape($account['role_name']) ?></span></td><td><span class="state-chip <?= accountEscape($account['account_status']) ?>"><?= accountEscape($account['account_status']) ?></span></td><td><?= accountEscape($account['last_login_at'] ?: 'Never') ?></td><td><?= accountEscape($account['created_at']) ?></td><td><div class="row-actions"><button type="button" class="icon-button" title="Edit account" aria-label="Edit <?= accountEscape($account['full_name']) ?>" data-edit-account="<?= accountEscape(json_encode($data,JSON_UNESCAPED_SLASHES) ?: '{}') ?>"><i class="bi bi-pencil-square"></i></button><button type="button" class="icon-button" title="Reset password" aria-label="Reset password for <?= accountEscape($account['full_name']) ?>" data-reset-account="<?= accountEscape(json_encode($data,JSON_UNESCAPED_SLASHES) ?: '{}') ?>"><i class="bi bi-key-fill"></i></button><button type="button" class="icon-button" title="Delete or deactivate" aria-label="Delete or deactivate <?= accountEscape($account['full_name']) ?>" data-delete-account="<?= accountEscape(json_encode($deleteData,JSON_UNESCAPED_SLASHES) ?: '{}') ?>"><i class="bi bi-trash3-fill"></i></button></div></td></tr>
        <?php endforeach; ?>
        </tbody></table></div>
    </section>
</main></div>

<div class="account-modal" id="createAccountModal" hidden><div class="account-modal-backdrop" data-close-modal></div><section class="account-dialog" role="dialog" aria-modal="true" aria-labelledby="createAccountTitle"><header class="account-modal-head"><div><span>Administrator action</span><h2 id="createAccountTitle">Create operational account</h2></div><button class="modal-close" type="button" data-close-modal aria-label="Close"><i class="bi bi-x-lg"></i></button></header><form method="post" class="account-form" data-submit-lock><input type="hidden" name="csrf_token" value="<?= accountEscape($csrf) ?>"><input type="hidden" name="action" value="create"><div class="account-form-grid"><label class="account-field wide">Full name<input name="full_name" maxlength="150" required autocomplete="name"></label><label class="account-field wide">Email address<input type="email" name="email" maxlength="190" required autocomplete="off"></label><label class="account-field">Role<select name="role" required><option value="barangay_personnel">Barangay Personnel</option><option value="responder">Responder</option></select></label><label class="account-field">Temporary password<input type="password" name="password" minlength="12" maxlength="72" required autocomplete="new-password"><small>12–72 characters with a letter and number.</small></label></div><div class="form-actions"><button type="button" class="secondary-button" data-close-modal>Cancel</button><button type="submit" class="account-button">Create account</button></div></form></section></div>

<div class="account-modal" id="editAccountModal" hidden><div class="account-modal-backdrop" data-close-modal></div><section class="account-dialog" role="dialog" aria-modal="true" aria-labelledby="editAccountTitle"><header class="account-modal-head"><div><span>Edit account</span><h2 id="editAccountTitle">Account details</h2></div><button class="modal-close" type="button" data-close-modal aria-label="Close"><i class="bi bi-x-lg"></i></button></header><form method="post" class="account-form" data-submit-lock><input type="hidden" name="csrf_token" value="<?= accountEscape($csrf) ?>"><input type="hidden" name="action" value="update"><input type="hidden" name="user_id" id="editUserId"><div class="account-form-grid"><label class="account-field wide">Full name<input name="full_name" id="editName" maxlength="150" required></label><label class="account-field wide">Email address<input type="email" name="email" id="editEmail" maxlength="190" required></label><label class="account-field">Role<select name="role" id="editRole"><option value="barangay_personnel">Barangay Personnel</option><option value="responder">Responder</option></select></label><label class="account-field">Account status<select name="account_status" id="editStatus"><option value="active">Active</option><option value="inactive">Inactive</option><option value="suspended">Suspended</option></select></label></div><div class="form-actions"><button type="button" class="secondary-button" data-close-modal>Cancel</button><button type="submit" class="account-button">Save changes</button></div></form></section></div>

<div class="account-modal" id="resetPasswordModal" hidden><div class="account-modal-backdrop" data-close-modal></div><section class="account-dialog small" role="dialog" aria-modal="true" aria-labelledby="resetPasswordTitle"><header class="account-modal-head"><div><span>Security action</span><h2 id="resetPasswordTitle">Reset password</h2></div><button class="modal-close" type="button" data-close-modal aria-label="Close"><i class="bi bi-x-lg"></i></button></header><div class="confirm-account"><strong id="resetAccountName"></strong><span id="resetAccountEmail"></span></div><form method="post" class="account-form" data-submit-lock><input type="hidden" name="csrf_token" value="<?= accountEscape($csrf) ?>"><input type="hidden" name="action" value="reset_password"><input type="hidden" name="user_id" id="resetUserId"><label class="account-field">New password<input type="password" name="new_password" minlength="12" maxlength="72" required autocomplete="new-password"><small>All existing API sessions will be revoked.</small></label><label class="account-field">Confirm password<input type="password" name="confirm_password" minlength="12" maxlength="72" required autocomplete="new-password"></label><div class="form-actions"><button type="button" class="secondary-button" data-close-modal>Cancel</button><button type="submit" class="account-button">Reset password</button></div></form></section></div>

<div class="account-modal" id="deleteAccountModal" hidden><div class="account-modal-backdrop" data-close-modal></div><section class="account-dialog small" role="dialog" aria-modal="true" aria-labelledby="deleteAccountTitle"><header class="account-modal-head"><div><span>Protected action</span><h2 id="deleteAccountTitle">Remove account access</h2></div><button class="modal-close" type="button" data-close-modal aria-label="Close"><i class="bi bi-x-lg"></i></button></header><p class="confirm-copy" id="deleteWarning"></p><div class="confirm-account"><strong id="deleteAccountName"></strong><span id="deleteAccountEmail"></span></div><form method="post" class="account-form" data-submit-lock><input type="hidden" name="csrf_token" value="<?= accountEscape($csrf) ?>"><input type="hidden" name="action" value="delete"><input type="hidden" name="user_id" id="deleteUserId"><div class="form-actions"><button type="button" class="secondary-button" data-close-modal>Cancel</button><button type="submit" class="danger-button" id="deleteButtonText">Remove account</button></div></form></section></div>

<script src="../assets/js/admin.js"></script><script src="../assets/js/account-management.js"></script>
</body></html>
