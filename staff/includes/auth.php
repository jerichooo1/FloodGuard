<?php

declare(strict_types=1);

require_once __DIR__.'/../../app/Support/Security.php';require_once __DIR__.'/../../app/Security/Csrf.php';require_once __DIR__.'/../../app/Auth/Authorization.php';
floodguardApplySecurityHeaders();floodguardStartSecureSession();
if(empty($_SESSION['staff_user_id'])){header('Location: login.php');exit;}
if(isset($_SESSION['staff_last_activity'])&&time()-(int)$_SESSION['staff_last_activity']>3600){unset($_SESSION['staff_user_id'],$_SESSION['staff_last_activity']);header('Location: login.php?notice=session_expired');exit;}
$stmt=$pdo->prepare('SELECT DISTINCT u.id,u.full_name,u.email,r.slug AS role_slug,r.name AS role_name FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE u.id=:id AND u.account_status="active" AND r.slug="barangay_personnel" LIMIT 1');$stmt->execute([':id'=>$_SESSION['staff_user_id']]);$staffUser=$stmt->fetch();if(!$staffUser){unset($_SESSION['staff_user_id']);header('Location: login.php?notice=account_unavailable');exit;}
$staffPermissions=floodguardUserPermissions($pdo,(int)$staffUser['id']);$_SESSION['staff_last_activity']=time();$staffCsrf=floodguardCsrfToken('staff_operations');
