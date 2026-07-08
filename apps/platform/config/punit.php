<?php

return [
    'api_version' => 'v1',
    'hosting_profile' => 'hostinger-cloud-hpanel',
    'tenant_header' => 'X-Tenant-Id',
    'idempotency_header' => 'Idempotency-Key',
    'device_adapters' => [
        'scale' => ['mock'],
        'printer' => ['mock'],
        'scanner' => ['keyboard', 'camera-placeholder'],
    ],
];
