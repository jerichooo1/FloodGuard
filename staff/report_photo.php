<?php

declare(strict_types=1);

require_once __DIR__.'/../config/database.php';require_once __DIR__.'/includes/auth.php';
if(!isset($staffPermissions['reports.review'])){http_response_code(403);exit('Permission denied.');}$id=filter_var($_GET['id']??null,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);if($id===false){http_response_code(404);exit;}$stmt=$pdo->prepare('SELECT storage_path,mime_type FROM flood_report_photos WHERE id=:id LIMIT 1');$stmt->execute([':id'=>$id]);$photo=$stmt->fetch();if(!$photo){http_response_code(404);exit;}$root=realpath(dirname(__DIR__).'/storage/private/report_photos');$path=realpath(dirname(__DIR__).'/'.$photo['storage_path']);if($root===false||$path===false||!str_starts_with($path,$root.DIRECTORY_SEPARATOR)||!is_file($path)){http_response_code(404);exit;}header('Content-Type: '.$photo['mime_type']);header('Content-Disposition: inline; filename="report-photo"');header('Cache-Control: private, no-store');header('X-Content-Type-Options: nosniff');readfile($path);
