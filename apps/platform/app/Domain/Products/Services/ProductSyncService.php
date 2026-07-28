<?php

namespace App\Domain\Products\Services;

use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductBatch;
use App\Models\ProductConfiguration\ProductDeviceAssignment;
use App\Models\ProductConfiguration\Unit;
use App\Models\ProductConfiguration\WeightRule;
use Illuminate\Support\Collection;

class ProductSyncService
{
    public function __construct(private readonly EffectiveProductConfigurationService $effectiveConfiguration) {}

    public function payload(string $tenantId, ?string $deviceId = null, ?int $afterVersion = null): array
    {
        $products = $this->products($tenantId, $deviceId, $afterVersion);

        return [
            'configurationVersion' => $this->configurationVersion($tenantId),
            'products' => $products->map(fn (Product $product) => $this->productPayload($product))->values(),
            'batches' => $this->batchPayload($tenantId),
            'dynamicFields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $tenantId)
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->get()
                ->map(fn ($model) => $this->sanitizedAttributes($model))
                ->values(),
            'units' => Unit::query()
                ->where(fn ($query) => $query->whereNull('tenant_id')->orWhere('tenant_id', $tenantId))
                ->where('is_active', true)
                ->get()
                ->map(fn ($model) => $this->sanitizedAttributes($model))
                ->values(),
            'weightRules' => WeightRule::query()
                ->where('tenant_id', $tenantId)
                ->where('is_active', true)
                ->get()
                ->map(fn ($model) => $this->sanitizedAttributes($model))
                ->values(),
            'deviceAssignments' => $deviceId ? ProductDeviceAssignment::query()
                ->where('tenant_id', $tenantId)
                ->where('device_id', $deviceId)
                ->where('is_active', true)
                ->get()
                ->map(fn ($model) => $this->sanitizedAttributes($model))
                ->values() : [],
            'deleted' => [
                'products' => [],
                'variants' => [],
            ],
        ];
    }

    private function products(string $tenantId, ?string $deviceId, ?int $afterVersion): Collection
    {
        $query = Product::query()
            ->with(['variants', 'category', 'conversionRules'])
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->when($afterVersion, fn ($query) => $query->where('configuration_version', '>', $afterVersion));

        if ($deviceId) {
            $allowedProductIds = ProductDeviceAssignment::query()
                ->where('tenant_id', $tenantId)
                ->where('device_id', $deviceId)
                ->where('allowed', true)
                ->where('is_active', true)
                ->pluck('product_id');

            if ($allowedProductIds->isNotEmpty()) {
                $query->whereIn('id', $allowedProductIds);
            }
        }

        return $query->orderBy('name')->get();
    }

    private function productPayload(Product $product): array
    {
        return [
            ...$this->sanitizedAttributes($product),
            'effective' => $this->effectiveConfiguration->effectiveValues($product),
            'variants' => $product->variants
                ->where('is_active', true)
                ->map(fn ($variant) => [
                    ...$this->sanitizedAttributes($variant),
                    'effective' => $this->effectiveConfiguration->effectiveValues($product, $variant),
                ])
                ->values(),
        ];
    }

    public function batchPayload(string $tenantId): array
    {
        $products = Product::query()
            ->where('tenant_id', $tenantId)
            ->get(['id', 'name', 'product_code'])
            ->keyBy('id');

        return ProductBatch::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->whereNull('deleted_at')
            ->orderBy('batch_name')
            ->get()
            ->map(function (ProductBatch $batch) use ($products): array {
                $items = collect($batch->batch_items ?: [[
                    'product_id' => $batch->product_id,
                    'details' => $batch->detail_values ?: [
                        $batch->attribute_key => [
                            'label' => $batch->attribute_label,
                            'value' => $batch->attribute_value,
                        ],
                    ],
                ]])->map(function (array $item) use ($products): array {
                    $product = $products->get($item['product_id'] ?? null);

                    return [
                        'product_id' => $item['product_id'] ?? null,
                        'product_name' => $item['product_name'] ?? $product?->name,
                        'product_code' => $item['product_code'] ?? $product?->product_code,
                        'details' => $item['details'] ?? [],
                    ];
                })->values()->all();

                return [
                    'id' => $batch->id,
                    'name' => $batch->batch_name,
                    'batch_name' => $batch->batch_name,
                    'is_active' => $batch->is_active,
                    'created_at' => $batch->created_at?->toISOString(),
                    'products' => $items,
                    'items' => $items,
                ];
            })
            ->values()
            ->all();
    }

    private function sanitizedAttributes($model): array
    {
        $attributes = $model->getAttributes();
        $jsonKeys = [
            'metadata',
            'dropdown_options',
            'default_value',
            'validation_rules',
            'conditional_visibility',
            'formula_definition',
        ];

        foreach ($attributes as $key => $value) {
            if ($value === '') {
                $attributes[$key] = null;
            }

            if (in_array($key, $jsonKeys, true) && is_string($attributes[$key] ?? null)) {
                $decoded = json_decode($attributes[$key], true);
                $attributes[$key] = json_last_error() === JSON_ERROR_NONE ? $decoded : null;
            }
        }

        return $attributes;
    }

    private function configurationVersion(string $tenantId): int
    {
        return (int) Product::query()->where('tenant_id', $tenantId)->max('configuration_version') ?: 1;
    }
}
