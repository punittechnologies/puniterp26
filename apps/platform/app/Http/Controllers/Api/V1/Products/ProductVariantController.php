<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Domain\Products\Services\ProductConfigurationRevisionService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Products\StoreVariantRequest;
use App\Http\Resources\Api\V1\Products\ProductVariantResource;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Support\TenantContext;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class ProductVariantController extends Controller
{
    public function index(Product $product, TenantContext $tenantContext): AnonymousResourceCollection
    {
        $this->ensureProductTenant($product, $tenantContext);

        return ProductVariantResource::collection($product->variants()->with('product')->paginate(20));
    }

    public function store(StoreVariantRequest $request, Product $product, TenantContext $tenantContext, ProductConfigurationRevisionService $revisions): ProductVariantResource
    {
        $this->ensureProductTenant($product, $tenantContext);

        $variant = DB::transaction(function () use ($request, $product, $tenantContext, $revisions) {
            $variant = ProductVariant::query()->create([
                ...$request->validated(),
                'tenant_id' => $tenantContext->tenantId(),
                'product_id' => $product->id,
                'configuration_version' => 1,
                'created_by' => $request->user()->id,
            ]);
            $revisions->record($variant, 'product_variant', [], $variant->toArray());

            return $variant;
        });

        return new ProductVariantResource($variant->load('product'));
    }

    private function ensureProductTenant(Product $product, TenantContext $tenantContext): void
    {
        abort_unless($product->tenant_id === $tenantContext->tenantId(), 404);
    }
}
