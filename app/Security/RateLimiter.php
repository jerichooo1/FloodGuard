<?php

declare(strict_types=1);

function floodguardRateLimitSubject(string $email): string
{
    $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? 'unknown');
    return hash('sha256', strtolower(trim($email)) . '|' . $ip);
}

function floodguardRateLimitRemaining(PDO $pdo, string $action, string $subjectHash): int
{
    $statement = $pdo->prepare(
        'SELECT GREATEST(0, TIMESTAMPDIFF(SECOND, NOW(), blocked_until))
         FROM rate_limits
         WHERE action_key = :action_key AND subject_hash = :subject_hash
         LIMIT 1'
    );
    $statement->execute([':action_key' => $action, ':subject_hash' => $subjectHash]);
    return max(0, (int) ($statement->fetchColumn() ?: 0));
}

function floodguardRecordFailedAttempt(
    PDO $pdo,
    string $action,
    string $subjectHash,
    int $maximumAttempts = 5,
    int $windowMinutes = 15,
    int $blockSeconds = 60
): int {
    $pdo->beginTransaction();
    try {
        $statement = $pdo->prepare(
            'SELECT id, attempt_count,
                    TIMESTAMPDIFF(SECOND, window_started_at, NOW()) AS window_age
             FROM rate_limits
             WHERE action_key = :action_key AND subject_hash = :subject_hash
             LIMIT 1 FOR UPDATE'
        );
        $statement->execute([':action_key' => $action, ':subject_hash' => $subjectHash]);
        $record = $statement->fetch(PDO::FETCH_ASSOC);

        $resetWindow = $record && (int) $record['window_age'] > $windowMinutes * 60;
        $attempts = $record && !$resetWindow
            ? (int) $record['attempt_count'] + 1
            : 1;
        $blockedUntil = $attempts >= $maximumAttempts
            ? date('Y-m-d H:i:s', time() + $blockSeconds)
            : null;

        if ($record) {
            $update = $pdo->prepare(
                'UPDATE rate_limits
                 SET attempt_count = :attempt_count,
                     window_started_at = CASE WHEN :reset_window = 1 THEN NOW() ELSE window_started_at END,
                     blocked_until = :blocked_until
                 WHERE id = :id'
            );
            $update->execute([
                ':attempt_count' => $attempts,
                ':reset_window' => (int) $resetWindow,
                ':blocked_until' => $blockedUntil,
                ':id' => $record['id']
            ]);
        } else {
            $insert = $pdo->prepare(
                'INSERT INTO rate_limits
                    (action_key, subject_hash, attempt_count, window_started_at, blocked_until)
                 VALUES (:action_key, :subject_hash, 1, NOW(), :blocked_until)'
            );
            $insert->execute([
                ':action_key' => $action,
                ':subject_hash' => $subjectHash,
                ':blocked_until' => $blockedUntil
            ]);
        }

        $pdo->commit();
        return $blockedUntil === null ? 0 : $blockSeconds;
    } catch (Throwable $exception) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $exception;
    }
}

function floodguardClearRateLimit(PDO $pdo, string $action, string $subjectHash): void
{
    $statement = $pdo->prepare(
        'DELETE FROM rate_limits
         WHERE action_key = :action_key AND subject_hash = :subject_hash'
    );
    $statement->execute([':action_key' => $action, ':subject_hash' => $subjectHash]);
}
