<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;

class FoundationController extends Controller
{
    public function health(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'apiVersion' => 'v1',
            'application' => 'Punit Weighing Platform',
        ]);
    }

    public function syncBootstrap(TenantContext $tenantContext): JsonResponse
    {
        return response()->json([
            'tenantId' => $tenantContext->tenantId(),
            'configurationVersion' => null,
            'features' => [
                'products' => true,
                'labels' => true,
                'inventory' => true,
                'dispatch' => true,
                'reports' => true,
                'realBluetoothScale' => true,
                'tvsPrinter' => false,
            ],
            'deviceAdapters' => [
                'scale' => ['classic_spp', 'simulated_development'],
                'printer' => ['disabled_tvs_pending'],
                'scanner' => ['keyboard', 'camera'],
            ],
        ]);
    }
}
