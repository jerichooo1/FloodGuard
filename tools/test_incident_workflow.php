<?php

declare(strict_types=1);

require_once __DIR__ . '/../app/Incident/Workflow.php';

$checks = [
    ['report submitted -> under_review', FloodGuardIncidentWorkflow::canTransitionReport('submitted', 'under_review'), true],
    ['report under_review -> approved', FloodGuardIncidentWorkflow::canTransitionReport('under_review', 'approved'), true],
    ['report approved -> submitted', FloodGuardIncidentWorkflow::canTransitionReport('approved', 'submitted'), false],
    ['incident assigned -> accepted', FloodGuardIncidentWorkflow::canTransitionIncident('assigned', 'accepted'), true],
    ['incident accepted -> closed', FloodGuardIncidentWorkflow::canTransitionIncident('accepted', 'closed'), false],
    ['rejection requires reason', FloodGuardIncidentWorkflow::decisionRequiresReason('rejected'), true],
];

$failed = 0;
foreach ($checks as [$name, $actual, $expected]) {
    $passed = $actual === $expected;
    echo ($passed ? '[PASS] ' : '[FAIL] ') . $name . PHP_EOL;
    if (!$passed) {
        $failed++;
    }
}

if ($failed > 0) {
    fwrite(STDERR, "{$failed} workflow check(s) failed." . PHP_EOL);
    exit(1);
}

echo 'All workflow checks passed.' . PHP_EOL;
