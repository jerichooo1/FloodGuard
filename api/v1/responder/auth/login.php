<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';
require_once __DIR__.'/../../../../app/Security/RateLimiter.php';

floodguardRequireMethod('POST'); $input=floodguardJsonInput();
try {
    $email=strtolower(trim((string)($input['email']??''))); $password=(string)($input['password']??'');
    if (filter_var($email,FILTER_VALIDATE_EMAIL)===false) throw new InvalidArgumentException('Valid email required.');
    $subject=floodguardRateLimitSubject($email); $remaining=floodguardRateLimitRemaining($pdo,'responder_login',$subject);
    if ($remaining>0) floodguardJsonResponse(429,['success'=>false,'message'=>'Too many failed sign-in attempts.','retry_after_seconds'=>$remaining]);
    $stmt=$pdo->prepare('SELECT u.id,u.full_name,u.email,u.password_hash,u.email_verified_at,u.account_status FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id WHERE u.email=:email AND r.slug="responder" LIMIT 1');
    $stmt->execute([':email'=>$email]); $user=$stmt->fetch();
    if (!$user || !password_verify($password,(string)$user['password_hash'])) { floodguardRecordFailedAttempt($pdo,'responder_login',$subject,5,15,60); floodguardJsonResponse(401,['success'=>false,'message'=>'Invalid email or password.']); }
    if ($user['email_verified_at']===null || $user['account_status']!=='active') floodguardJsonResponse(403,['success'=>false,'message'=>'This responder account is unavailable.']);
    floodguardClearRateLimit($pdo,'responder_login',$subject); $token=floodguardIssueApiToken($pdo,(int)$user['id'],'responder-mobile');
    $pdo->prepare('UPDATE users SET last_login_at=NOW() WHERE id=:id')->execute([':id'=>$user['id']]);
    floodguardJsonResponse(200,['success'=>true,'message'=>'Responder signed in successfully.','access_token'=>$token,'token_type'=>'Bearer','user'=>['id'=>(int)$user['id'],'full_name'=>$user['full_name'],'email'=>$user['email'],'role'=>'responder']]);
} catch (InvalidArgumentException $e) { floodguardJsonResponse(422,['success'=>false,'message'=>$e->getMessage()]); }
catch (Throwable $e) { error_log('[Responder login] '.$e->getMessage()); floodguardJsonResponse(500,['success'=>false,'message'=>'Unable to sign in.']); }
