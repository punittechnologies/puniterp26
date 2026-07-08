<?php

namespace App\Domain\Devices\Data;

final readonly class DeviceConnection
{
    public function __construct(
        public string $identifier,
        public string $name,
        public string $status,
        public array $metadata = [],
    ) {}
}
