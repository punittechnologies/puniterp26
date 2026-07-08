<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Domain\Products\Services\ProductConfigurationRevisionService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Products\StoreProductRequest;
use App\Http\Requests\Api\V1\Products\UpdateProductRequest;
use App\Http\Resources\Api\V1\Products\ProductResource;
use App\Models\ProductConfiguration\Product;
use App\Support\TenantContext;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{
    public function index(TenantContext $tenantContext): AnonymousResourceCollection
    {
        $products = Product::query()
            ->with('variants.product')
            ->where('tenant_id', $tenantContext->tenantId())
            ->when(request('search'), function ($query, $search): void {
                $query->where(fn ($query) => $query
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('product_code', 'like', "%{$search}%")
                    ->orWhere('sku', 'like', "%{$search}%"));
            })
            ->orderBy(request('sort', 'name'))
            ->paginate((int) request('per_page', 15));

        return ProductResource::collection($products);
    }

    public function store(StoreProductRequest $request, TenantContext $tenantContext, ProductConfigurationRevisionService $revisions): ProductResource
    {
        $product = DB::transaction(function () use ($request, $tenantContext, $revisions) {
            Product::onlyTrashed()
                ->where('tenant_id', $tenantContext->tenantId())
                ->where(function ($query) use ($request): void {
                    $query->where('name', $request->string('name'))
                        ->orWhere('product_code', $request->string('product_code'));
                })
                ->get()
                ->each(function (Product $product) use ($request): void {
                    $product->forceFill([
                        'name' => 'Deleted product '.$product->id,
                        'product_code' => 'DELETED-'.$product->id,
                        'sku' => null,
                        'updated_by' => $request->user()->id,
                    ])->save();
                });

            $product = Product::query()->create([
                ...$request->validated(),
                'tenant_id' => $tenantContext->tenantId(),
                'default_tare_weight' => $request->input('default_tare_weight', 0),
                'configuration_activated_at' => now(),
                'created_by' => $request->user()->id,
            ]);

            $revisions->record($product, 'product', [], $product->toArray());

            return $product;
        });

        return new ProductResource($product->load('variants.product'));
    }

    public function show(Product $product, TenantContext $tenantContext): ProductResource
    {
        $this->ensureTenant($product, $tenantContext);

        return new ProductResource($product->load('variants.product', 'category'));
    }

    public function update(UpdateProductRequest $request, Product $product, TenantContext $tenantContext, ProductConfigurationRevisionService $revisions): ProductResource
    {
        $this->ensureTenant($product, $tenantContext);
        $old = $product->toArray();

        DB::transaction(function () use ($request, $product, $revisions, $old): void {
            $product->fill([
                ...$request->validated(),
                'configuration_version' => $product->configuration_version + 1,
                'configuration_activated_at' => now(),
                'updated_by' => $request->user()->id,
            ]);
            $product->save();
            $revisions->record($product, 'product', $old, $product->fresh()->toArray());
        });

        return new ProductResource($product->fresh()->load('variants.product'));
    }

    public function destroy(Product $product, TenantContext $tenantContext): Response
    {
        $this->ensureTenant($product, $tenantContext);
        $product->delete();

        return response()->noContent();
    }

    private function ensureTenant(Product $product, TenantContext $tenantContext): void
    {
        abort_unless($product->tenant_id === $tenantContext->tenantId(), 404);
    }
}
