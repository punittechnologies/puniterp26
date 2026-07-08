<?php

namespace App\Domain\Devices\Data;

final readonly class PrintResult
{
    public function __construct(
        public string $jobId,
        public string $status,
        public ?string $message = null,
    ) {}
}
