<?php

declare(strict_types=1);

function floodguardRequiredString(array $input, string $key, int $maximum): string
{
    $value=preg_replace('/\s+/u', ' ', trim((string)($input[$key]??'')))??'';
    if ($value==='' || mb_strlen($value)>$maximum) {
        throw new InvalidArgumentException("{$key} is required and must not exceed {$maximum} characters.");
    }
    return $value;
}

function floodguardProperCase(string $value): string
{
    $normalized=preg_replace('/\s+/u', ' ', trim($value))??'';
    return mb_convert_case(mb_strtolower($normalized, 'UTF-8'), MB_CASE_TITLE, 'UTF-8');
}

function floodguardPersonName(array $input, string $key='full_name'): string
{
    $name=floodguardProperCase(floodguardRequiredString($input,$key,150));
    if (mb_strlen($name)<2 || preg_match("/^[\p{L}\p{M} .'-]+$/u",$name)!==1) {
        throw new InvalidArgumentException('A valid full name is required.');
    }
    return $name;
}

function floodguardEmail(array $input): string
{
    $email=strtolower(trim((string)($input['email']??'')));
    if (strlen($email)>190 || filter_var($email,FILTER_VALIDATE_EMAIL)===false) {
        throw new InvalidArgumentException('A valid email address is required.');
    }
    return $email;
}

function floodguardPhilippineMobile(string $value): string
{
    $digits=preg_replace('/\D+/', '', $value)??'';
    if (preg_match('/^09\d{9}$/',$digits)===1) $digits='63'.substr($digits,1);
    if (preg_match('/^639\d{9}$/',$digits)!==1) throw new InvalidArgumentException('A valid Philippine mobile number is required.');
    return '+'.$digits;
}
