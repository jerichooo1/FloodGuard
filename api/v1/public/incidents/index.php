<?php

declare(strict_types=1);

require_once __DIR__.'/../../../../config/database.php';require_once __DIR__.'/../../../../app/Http/JsonResponse.php';require_once __DIR__.'/../../../../app/Http/Request.php';
floodguardRequireMethod('GET');
try{$stmt=$pdo->query('SELECT incident_number,public_location,public_condition,public_water_level_cm,status,public_approved_at,created_at,updated_at FROM flood_incidents WHERE public_approved=1 AND status NOT IN ("cancelled") ORDER BY created_at DESC LIMIT 20');$rows=$stmt->fetchAll();foreach($rows as &$row){$row['public_water_level_cm']=$row['public_water_level_cm']===null?null:(float)$row['public_water_level_cm'];}unset($row);floodguardJsonResponse(200,['success'=>true,'data'=>$rows]);}catch(Throwable $e){error_log('[Public incidents] '.$e->getMessage());floodguardJsonResponse(500,['success'=>false,'message'=>'Public incident information is temporarily unavailable.']);}
