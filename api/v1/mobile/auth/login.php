<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Auth/Authorization.php';
require_once __DIR__.'/../../../../app/Auth/ApiAuth.php';
require_once __DIR__.'/../../../../app/Security/RateLimiter.php';
require_once __DIR__.'/../../../../app/Support/Validation.php';

floodguardRequireMethod('POST');$input=floodguardJsonInput();
try{$email=floodguardEmail($input);$password=(string)($input['password']??'');$subject=floodguardRateLimitSubject($email);$remaining=floodguardRateLimitRemaining($pdo,'resident_login',$subject);if($remaining>0)floodguardJsonResponse(429,['success'=>false,'message'=>'Too many failed sign-in attempts.','retry_after_seconds'=>$remaining]);
$stmt=$pdo->prepare('SELECT u.id,u.full_name,u.email,u.password_hash,u.email_verified_at,u.account_status,rp.approval_status,rp.rejection_reason FROM users u JOIN user_roles ur ON ur.user_id=u.id JOIN roles r ON r.id=ur.role_id LEFT JOIN resident_profiles rp ON rp.user_id=u.id WHERE u.email=:email AND r.slug="resident" LIMIT 1');$stmt->execute([':email'=>$email]);$user=$stmt->fetch();
if(!$user||!password_verify($password,(string)$user['password_hash'])){floodguardRecordFailedAttempt($pdo,'resident_login',$subject,5,15,60);floodguardJsonResponse(401,['success'=>false,'message'=>'Invalid email or password.']);}
if($user['email_verified_at']===null)floodguardJsonResponse(403,['success'=>false,'message'=>'Verify your email before signing in.']);if($user['approval_status']==='pending')floodguardJsonResponse(403,['success'=>false,'message'=>'Your resident application is waiting for administrator approval.']);if($user['approval_status']==='rejected')floodguardJsonResponse(403,['success'=>false,'message'=>'Your resident application was rejected.'.($user['rejection_reason']?' Reason: '.$user['rejection_reason']:'' )]);if($user['account_status']!=='active')floodguardJsonResponse(403,['success'=>false,'message'=>'This account is not active.']);
floodguardClearRateLimit($pdo,'resident_login',$subject);$token=floodguardIssueApiToken($pdo,(int)$user['id']);$pdo->prepare('UPDATE users SET last_login_at=NOW() WHERE id=:id')->execute([':id'=>$user['id']]);
floodguardJsonResponse(200,['success'=>true,'message'=>'Signed in successfully.','access_token'=>$token,'token_type'=>'Bearer','user'=>['id'=>(int)$user['id'],'full_name'=>$user['full_name'],'email'=>$user['email'],'role'=>'resident']]);
}catch(InvalidArgumentException $e){floodguardJsonResponse(422,['success'=>false,'message'=>$e->getMessage()]);}catch(Throwable $e){error_log('[Resident login] '.$e->getMessage());floodguardJsonResponse(500,['success'=>false,'message'=>'Unable to sign in.']);}
