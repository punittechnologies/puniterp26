<?php

namespace App\Domain\Devices\Contracts;

use App\Domain\Devices\Data\DeviceConnection;

interface ScannerAdapter
{
    public function connect(string $deviceIdentifier): DeviceConnection;

    public function disconnect(string $deviceIdentifier): void;

    public function parse(string $rawInput): string;
}
