<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Domain\Products\Services\ProductSyncService;
use App\Http\Controllers\Controller;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductSyncController extends Controller
{
    public function __invoke(Request $request, TenantContext $tenantContext, ProductSyncService $syncService): JsonResponse
    {
        $data = $request->validate([
            'device_id' => ['nullable', 'uuid'],
            'last_configuration_version' => ['nullable', 'integer', 'min:0'],
            'last_sync_at' => ['nullable', 'date'],
        ]);

        return response()->json($syncService->payload(
            tenantId: $tenantContext->tenantId(),
            deviceId: $data['device_id'] ?? null,
            afterVersion: $data['last_configuration_version'] ?? null,
        ));
    }
}
