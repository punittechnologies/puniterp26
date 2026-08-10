<?php

return [
    'api_version' => 'v1',
    'hosting_profile' => 'hostinger-cloud-hpanel',
    'tenant_header' => 'X-Tenant-Id',
    'idempotency_header' => 'Idempotency-Key',
    'android_app' => [
        'version' => '1.1.20',
        'build' => 25,
        'filename' => 'PUNIT-ERP-v1.1.20-build25.apk',
    ],
    'device_adapters' => [
        'scale' => ['mock'],
        'printer' => ['mock'],
        'scanner' => ['keyboard', 'camera-placeholder'],
    ],
];
