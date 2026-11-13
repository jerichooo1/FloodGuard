<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';
require_once __DIR__.'/../../../../app/Http/JsonResponse.php';
require_once __DIR__.'/../../../../app/Http/Request.php';
require_once __DIR__.'/../../../../app/Security/RateLimiter.php';
require_once __DIR__.'/../../../../app/Support/Validation.php';
require_once __DIR__.'/../../../../app/Mail/Mailer.php';

floodguardRequireMethod('POST');
$input = $_POST;
$storedProofPath = null;
$oldProofPath = null;
try {
    $name=floodguardPersonName($input);$email=floodguardEmail($input);$mobile=floodguardPhilippineMobile((string)($input['mobile_number']??''));
    $address=floodguardProperCase(floodguardRequiredString($input,'address_line',500));$password=(string)($input['password']??'');
    $notificationConsent=filter_var($input['push_notifications_enabled']??null,FILTER_VALIDATE_BOOLEAN,FILTER_NULL_ON_FAILURE);
    if($notificationConsent!==true) throw new InvalidArgumentException('Notification consent is required to create a resident account.');
    if (strlen($password)<10 || strlen($password)>72 || !preg_match('/[A-Za-z]/',$password) || !preg_match('/\d/',$password)) throw new InvalidArgumentException('Password must be 10-72 characters and contain a letter and number.');
    $proof=$_FILES['residency_proof']??null;
    if(!is_array($proof)||($proof['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK) throw new InvalidArgumentException('Upload a valid ID or proof of residency.');
    if((int)($proof['size']??0)<1||(int)$proof['size']>5*1024*1024) throw new InvalidArgumentException('The proof image must not exceed 5 MB.');
    $temporaryPath=(string)($proof['tmp_name']??'');
    $mime=(new finfo(FILEINFO_MIME_TYPE))->file($temporaryPath)?:'';
    $extensions=['image/jpeg'=>'jpg','image/png'=>'png'];
    if(!isset($extensions[$mime])) throw new InvalidArgumentException('The proof must be a JPG or PNG image.');
    $proofDirectory=dirname(__DIR__,4).'/storage/private/resident_proofs';
    if(!is_dir($proofDirectory)&&!mkdir($proofDirectory,0750,true)&&!is_dir($proofDirectory)) throw new RuntimeException('Unable to prepare proof storage.');
    $subject=floodguardRateLimitSubject($email);$remaining=floodguardRateLimitRemaining($pdo,'resident_register',$subject);
    if($remaining>0) floodguardJsonResponse(429,['success'=>false,'message'=>'Too many attempts. Try again later.','retry_after_seconds'=>$remaining]);
    $existing=$pdo->prepare('SELECT u.id,u.email,rp.mobile_number,rp.approval_status,rp.verification_proof_path FROM users u LEFT JOIN resident_profiles rp ON rp.user_id=u.id WHERE u.email=:email OR rp.mobile_number=:mobile');
    $existing->execute([':email'=>$email,':mobile'=>$mobile]);
    $reapplication=null;
    foreach($existing->fetchAll(PDO::FETCH_ASSOC) as $match){
        if($match['approval_status']!=='rejected'||($reapplication!==null&&(int)$reapplication['id']!==(int)$match['id'])){
            floodguardRecordFailedAttempt($pdo,'resident_register',$subject,5,60,300);
            floodguardJsonResponse(409,['success'=>false,'message'=>'An active or pending account already uses that email address or mobile number.']);
        }
        $reapplication=$match;
    }
    $proofFilename=bin2hex(random_bytes(24)).'.'.$extensions[$mime];
    $storedProofPath='resident_proofs/'.$proofFilename;
    if(!move_uploaded_file($temporaryPath,$proofDirectory.'/'.$proofFilename)) throw new RuntimeException('Unable to securely store the proof image.');
    $verificationCode=str_pad((string)random_int(0,999999),6,'0',STR_PAD_LEFT);$minutes=(int)($pdo->query("SELECT setting_value FROM system_settings WHERE setting_key='email_verification_minutes' LIMIT 1")->fetchColumn()?:30);$expires=date('Y-m-d H:i:s',time()+max(10,min(1440,$minutes))*60);
    $pdo->beginTransaction();
    if($reapplication!==null){
        $userId=(int)$reapplication['id'];$oldProofPath=$reapplication['verification_proof_path']?:null;
        $pdo->prepare('UPDATE users SET full_name=:name,email=:email,password_hash=:password,email_verified_at=NULL,account_status="pending",token_version=token_version+1 WHERE id=:id')->execute([':name'=>$name,':email'=>$email,':password'=>password_hash($password,PASSWORD_DEFAULT),':id'=>$userId]);
        $pdo->prepare('UPDATE resident_profiles SET mobile_number=:mobile,address_line=:address,verification_proof_path=:proof_path,verification_proof_mime=:proof_mime,push_notifications_enabled=1,notification_consented_at=NOW(),location_sharing_consent=0,approval_status="pending",reviewed_by=NULL,reviewed_at=NULL,rejection_reason=NULL,created_at=NOW() WHERE user_id=:id')->execute([':mobile'=>$mobile,':address'=>$address,':proof_path'=>$storedProofPath,':proof_mime'=>$mime,':id'=>$userId]);
        $pdo->prepare('UPDATE api_tokens SET revoked_at=COALESCE(revoked_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
        $pdo->prepare('UPDATE email_verification_tokens SET used_at=COALESCE(used_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
        $pdo->prepare('UPDATE password_reset_tokens SET used_at=COALESCE(used_at,NOW()) WHERE user_id=:id')->execute([':id'=>$userId]);
    }else{
        $stmt=$pdo->prepare('INSERT INTO users (full_name,email,password_hash,account_status) VALUES (:name,:email,:password,"pending")');$stmt->execute([':name'=>$name,':email'=>$email,':password'=>password_hash($password,PASSWORD_DEFAULT)]);$userId=(int)$pdo->lastInsertId();
        $stmt=$pdo->prepare('INSERT INTO resident_profiles (user_id,mobile_number,address_line,verification_proof_path,verification_proof_mime,push_notifications_enabled,notification_consented_at,approval_status) VALUES (:user_id,:mobile,:address,:proof_path,:proof_mime,1,NOW(),"pending")');$stmt->execute([':user_id'=>$userId,':mobile'=>$mobile,':address'=>$address,':proof_path'=>$storedProofPath,':proof_mime'=>$mime]);
        $pdo->prepare('INSERT INTO user_roles (user_id,role_id) SELECT :user_id,id FROM roles WHERE slug="resident"')->execute([':user_id'=>$userId]);
    }
    $pdo->prepare('INSERT INTO email_verification_tokens (user_id,token_hash,expires_at) VALUES (:user_id,:hash,:expires)')->execute([':user_id'=>$userId,':hash'=>hash('sha256',$email.'|'.$verificationCode),':expires'=>$expires]);
    $pdo->commit();floodguardClearRateLimit($pdo,'resident_register',$subject);
    if($oldProofPath!==null&&$oldProofPath!==$storedProofPath){$oldFile=dirname(__DIR__,4).'/storage/private/'.$oldProofPath;if(is_file($oldFile))unlink($oldFile);}
    $sent=floodguardSendVerificationEmail($email,$name,$verificationCode);$response=['success'=>true,'message'=>$sent?'Enter the six-digit code sent to your email.':'Your account was created, but the verification email could not be sent. Use Resend code.','email_sent'=>$sent,'approval_status'=>'pending'];
    floodguardJsonResponse(201,$response);
} catch(InvalidArgumentException $e){if($storedProofPath!==null){$file=dirname(__DIR__,4).'/storage/private/'.$storedProofPath;if(is_file($file))unlink($file);}floodguardJsonResponse(422,['success'=>false,'message'=>$e->getMessage()]);}
catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();if($storedProofPath!==null){$file=dirname(__DIR__,4).'/storage/private/'.$storedProofPath;if(is_file($file))unlink($file);}error_log('[Resident register] '.$e->getMessage());floodguardJsonResponse(500,['success'=>false,'message'=>'Unable to create the account.']);}
