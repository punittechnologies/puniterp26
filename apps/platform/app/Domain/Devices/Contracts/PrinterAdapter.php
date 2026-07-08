<?php

namespace App\Domain\Devices\Contracts;

use App\Domain\Devices\Data\DeviceConnection;
use App\Domain\Devices\Data\PrintJob;
use App\Domain\Devices\Data\PrintResult;

interface PrinterAdapter
{
    /** @return array<int, DeviceConnection> */
    public function discover(): array;

    public function connect(string $deviceIdentifier): DeviceConnection;

    public function disconnect(string $deviceIdentifier): void;

    public function print(PrintJob $job): PrintResult;
}
