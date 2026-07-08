<?php

namespace App\Domain\Ai\Contracts;

use App\Domain\Ai\Data\ConfigurationChangePlan;

interface AiConfigurationProvider
{
    public function draftChangePlan(string $tenantId, string $prompt, array $currentConfiguration): ConfigurationChangePlan;
}
