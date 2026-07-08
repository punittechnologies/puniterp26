<?php

namespace App\Domain\Devices\Data;

final readonly class WeightReading
{
    public function __construct(
        public string $grossWeight,
        public string $unit,
        public bool $isStable,
        public string $rawPayload,
    ) {}
}
