<?php

namespace App\Domain\Ai\Data;

final readonly class ConfigurationChangePlan
{
    public function __construct(
        public string $summary,
        public array $proposedChanges,
        public array $risks,
        public bool $requiresApproval = true,
    ) {}
}
