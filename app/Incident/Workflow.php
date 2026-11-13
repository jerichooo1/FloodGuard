<?php

declare(strict_types=1);

final class FloodGuardIncidentWorkflow
{
    private const REPORT_TRANSITIONS = [
        'submitted' => ['under_review', 'cancelled'],
        'under_review' => ['correction_requested', 'rejected', 'approved', 'cancelled'],
        'correction_requested' => ['resubmitted', 'cancelled'],
        'resubmitted' => ['under_review', 'cancelled'],
        'rejected' => [],
        'approved' => [],
        'cancelled' => [],
    ];

    private const INCIDENT_TRANSITIONS = [
        'awaiting_assignment' => ['assigned', 'cancelled'],
        'assigned' => ['accepted', 'awaiting_assignment', 'cancelled'],
        'accepted' => ['en_route', 'cancelled'],
        'en_route' => ['on_scene', 'cancelled'],
        'on_scene' => ['response_in_progress', 'resolved', 'cancelled'],
        'response_in_progress' => ['resolved', 'cancelled'],
        'resolved' => ['response_in_progress', 'closed'],
        'closed' => [],
        'cancelled' => [],
    ];

    public static function reportStates(): array
    {
        return array_keys(self::REPORT_TRANSITIONS);
    }

    public static function incidentStates(): array
    {
        return array_keys(self::INCIDENT_TRANSITIONS);
    }

    public static function canTransitionReport(string $from, string $to): bool
    {
        return in_array($to, self::REPORT_TRANSITIONS[$from] ?? [], true);
    }

    public static function canTransitionIncident(string $from, string $to): bool
    {
        return in_array($to, self::INCIDENT_TRANSITIONS[$from] ?? [], true);
    }

    public static function requireReportTransition(string $from, string $to): void
    {
        if (!self::canTransitionReport($from, $to)) {
            throw new DomainException("Invalid report transition from {$from} to {$to}.");
        }
    }

    public static function requireIncidentTransition(string $from, string $to): void
    {
        if (!self::canTransitionIncident($from, $to)) {
            throw new DomainException("Invalid incident transition from {$from} to {$to}.");
        }
    }

    public static function decisionRequiresReason(string $decision): bool
    {
        return in_array($decision, ['correction_requested', 'rejected', 'cancelled'], true);
    }
}
