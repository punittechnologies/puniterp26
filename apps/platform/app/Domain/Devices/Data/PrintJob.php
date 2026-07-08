<?php

namespace App\Domain\Devices\Data;

final readonly class PrintJob
{
    public function __construct(
        public string $jobId,
        public string $printerIdentifier,
        public array $template,
        public array $data,
    ) {}
}
