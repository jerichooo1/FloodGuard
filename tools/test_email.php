<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once __DIR__ . '/../config/environment.php';
require_once __DIR__ . '/../app/Mail/Mailer.php';

$recipient = trim((string) ($argv[1] ?? ''));
if (!filter_var($recipient, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Usage: php tools/test_email.php recipient@example.com\n");
    exit(1);
}

$sent = floodguardSendPasswordResetCodeEmail($recipient, 'FloodGuard Test Recipient', '123456');
if (!$sent) {
    fwrite(STDERR, 'Email failed: ' . (floodguardMailError() ?? 'Unknown SMTP error. Check the PHP error log.') . PHP_EOL);
    exit(1);
}

fwrite(STDOUT, "Test email sent successfully to {$recipient}. Check Inbox and Spam.\n");
