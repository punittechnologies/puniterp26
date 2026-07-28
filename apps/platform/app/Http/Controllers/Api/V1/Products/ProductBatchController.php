<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Domain\Products\Services\ProductSyncService;
use App\Http\Controllers\Controller;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;

class ProductBatchController extends Controller
{
    public function index(TenantContext $tenantContext, ProductSyncService $syncService): JsonResponse
    {
        return response()->json([
            'data' => $syncService->batchPayload($tenantContext->tenantId()),
        ]);
    }
}
