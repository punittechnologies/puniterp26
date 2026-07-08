<?php

namespace App\Domain\Devices\Contracts;

use App\Domain\Devices\Data\DeviceConnection;
use App\Domain\Devices\Data\WeightReading;

interface ScaleAdapter
{
    /** @return array<int, DeviceConnection> */
    public function discover(): array;

    public function connect(string $deviceIdentifier): DeviceConnection;

    public function disconnect(string $deviceIdentifier): void;

    public function read(string $deviceIdentifier): WeightReading;

    public function zero(string $deviceIdentifier): void;

    public function tare(string $deviceIdentifier): void;
}
