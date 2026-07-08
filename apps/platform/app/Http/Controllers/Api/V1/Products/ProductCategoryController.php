<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Products\ProductCategoryRequest;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductCategory;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;

class ProductCategoryController extends Controller
{
    public function index(TenantContext $tenantContext): JsonResponse
    {
        return response()->json(ProductCategory::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get());
    }

    public function store(ProductCategoryRequest $request, TenantContext $tenantContext): JsonResponse
    {
        $category = ProductCategory::query()->create([
            ...$request->validated(),
            'tenant_id' => $tenantContext->tenantId(),
            'created_by' => $request->user()->id,
        ]);

        return response()->json($category, 201);
    }

    public function update(ProductCategoryRequest $request, ProductCategory $productCategory, TenantContext $tenantContext): JsonResponse
    {
        abort_unless($productCategory->tenant_id === $tenantContext->tenantId(), 404);
        abort_if($this->wouldCreateCycle($productCategory, $request->input('parent_id')), 422, 'Category parent would create a cycle.');

        $productCategory->update([...$request->validated(), 'updated_by' => $request->user()->id]);

        return response()->json($productCategory);
    }

    public function destroy(ProductCategory $productCategory, TenantContext $tenantContext): JsonResponse
    {
        abort_unless($productCategory->tenant_id === $tenantContext->tenantId(), 404);
        abort_if(Product::query()->where('category_id', $productCategory->id)->where('is_active', true)->exists(), 422, 'Active products depend on this category.');
        $productCategory->delete();

        return response()->json(null, 204);
    }

    private function wouldCreateCycle(ProductCategory $category, ?string $parentId): bool
    {
        while ($parentId) {
            if ($parentId === $category->id) {
                return true;
            }
            $parentId = ProductCategory::query()->find($parentId)?->parent_id;
        }

        return false;
    }
}
