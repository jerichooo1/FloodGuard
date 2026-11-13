<?php

declare(strict_types=1);

require_once __DIR__.'/../config/database.php';

if(PHP_SAPI!=='cli'){http_response_code(404);exit;}
$name=trim((string)getenv('FG_SETUP_STAFF_NAME'));$email=strtolower(trim((string)getenv('FG_SETUP_STAFF_EMAIL')));$password=(string)getenv('FG_SETUP_STAFF_PASSWORD');$role='barangay_personnel';
if($name===''||strlen($name)>150||filter_var($email,FILTER_VALIDATE_EMAIL)===false||strlen($email)>190){fwrite(STDERR,"Valid staff name and email environment values are required.\n");exit(1);}
if(strlen($password)<12||strlen($password)>72||!preg_match('/[A-Za-z]/',$password)||!preg_match('/\d/',$password)){fwrite(STDERR,"Password must be 12-72 characters and contain a letter and number.\n");exit(1);}
try{$pdo->beginTransaction();$stmt=$pdo->prepare('SELECT u.id,MAX(r.slug="administrator") AS is_administrator FROM users u LEFT JOIN user_roles ur ON ur.user_id=u.id LEFT JOIN roles r ON r.id=ur.role_id WHERE u.email=:email GROUP BY u.id FOR UPDATE');$stmt->execute([':email'=>$email]);$existing=$stmt->fetch();if($existing&&!empty($existing['is_administrator']))throw new RuntimeException('Use a separate staff identity; the administrator account cannot receive operational roles.');$userId=$existing['id']??null;if($userId){$pdo->prepare('UPDATE users SET full_name=:name,password_hash=:password,email_verified_at=COALESCE(email_verified_at,NOW()),account_status="active",token_version=token_version+1 WHERE id=:id')->execute([':name'=>$name,':password'=>password_hash($password,PASSWORD_DEFAULT),':id'=>$userId]);}else{$pdo->prepare('INSERT INTO users (full_name,email,password_hash,email_verified_at,account_status) VALUES (:name,:email,:password,NOW(),"active")')->execute([':name'=>$name,':email'=>$email,':password'=>password_hash($password,PASSWORD_DEFAULT)]);$userId=$pdo->lastInsertId();}$pdo->prepare('INSERT IGNORE INTO user_roles (user_id,role_id) SELECT :user,id FROM roles WHERE slug=:role')->execute([':user'=>$userId,':role'=>$role]);$pdo->commit();echo "Staff account ready: {$email} ({$role}).\n";}catch(Throwable $e){if($pdo->inTransaction())$pdo->rollBack();fwrite(STDERR,"Unable to create staff account: {$e->getMessage()}\n");exit(1);}
