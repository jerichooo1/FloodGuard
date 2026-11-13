<?php

declare(strict_types=1);

function floodguardValidateReportPhoto(PDO $pdo,array $file): array
{
    if(($file['error']??UPLOAD_ERR_NO_FILE)!==UPLOAD_ERR_OK)throw new InvalidArgumentException('A flood photograph is required.');
    $size=(int)($file['size']??0);$maximum=(int)($pdo->query("SELECT setting_value FROM system_settings WHERE setting_key='flood_report_max_photo_bytes' LIMIT 1")->fetchColumn()?:10485760);
    if($size<1||$size>$maximum)throw new InvalidArgumentException('The photograph must not exceed 10 MiB.');
    $temporary=(string)($file['tmp_name']??'');if(!is_uploaded_file($temporary))throw new InvalidArgumentException('The photograph upload is invalid.');
    $mime=(new finfo(FILEINFO_MIME_TYPE))->file($temporary);$extensions=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp'];
    if(!isset($extensions[$mime]))throw new InvalidArgumentException('The photograph must be JPEG, PNG, or WebP.');
    return ['temporary_path'=>$temporary,'original_name'=>substr(basename((string)($file['name']??'photo')),0,255),'mime_type'=>$mime,'size'=>$size,'extension'=>$extensions[$mime],'sha256'=>hash_file('sha256',$temporary)];
}

function floodguardStoreReportPhoto(array $photo): array
{
    $directory=dirname(__DIR__,2).'/storage/private/report_photos';
    if(!is_dir($directory)&&!mkdir($directory,0750,true)&&!is_dir($directory))throw new RuntimeException('Unable to prepare private photograph storage.');
    $filename=bin2hex(random_bytes(24)).'.'.$photo['extension'];$absolute=$directory.'/'.$filename;
    if(!move_uploaded_file($photo['temporary_path'],$absolute))throw new RuntimeException('Unable to store the photograph.');
    return ['absolute_path'=>$absolute,'storage_path'=>'storage/private/report_photos/'.$filename];
}

function floodguardReportCoordinates(array $input): array
{
    $latitude=filter_var($input['latitude']??null,FILTER_VALIDATE_FLOAT);$longitude=filter_var($input['longitude']??null,FILTER_VALIDATE_FLOAT);
    if($latitude===false||$latitude<-90||$latitude>90||$longitude===false||$longitude<-180||$longitude>180)throw new InvalidArgumentException('Valid latitude and longitude are required.');
    return [(float)$latitude,(float)$longitude];
}
