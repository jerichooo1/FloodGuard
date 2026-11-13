<?php

declare(strict_types=1);

require_once __DIR__.'/../app/Support/Security.php';require_once __DIR__.'/../app/Security/Csrf.php';floodguardStartSecureSession();if($_SERVER['REQUEST_METHOD']!=='POST'||!floodguardVerifyCsrf((string)($_POST['csrf_token']??''),'staff_operations')){http_response_code(405);exit('Valid sign-out request required.');}unset($_SESSION['staff_user_id'],$_SESSION['staff_last_activity'],$_SESSION['csrf_tokens']['staff_operations']);session_regenerate_id(true);header('Location: login.php?notice=logged_out');exit;
