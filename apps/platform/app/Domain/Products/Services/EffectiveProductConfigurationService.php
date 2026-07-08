<?php

namespace App\Domain\Products\Services;

use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductConfiguration\UnitConversionRule;
use App\Models\ProductConfiguration\WeightRule;

class EffectiveProductConfigurationService
{
    public function effectiveValues(Product $product, ?ProductVariant $variant = null): array
    {
        $weightRule = $this->resolveWeightRule($product, $variant);
        $conversionRule = $this->resolveConversionRule($product, $variant);

        return [
            'tare_weight' => $this->rawDecimal($variant, 'tare_weight') ?? $this->rawDecimal($weightRule, 'tare_weight') ?? $this->rawDecimal($product, 'default_tare_weight') ?? '0.000',
            'minimum_weight' => $this->rawDecimal($variant, 'minimum_weight') ?? $this->rawDecimal($weightRule, 'minimum_weight') ?? $this->rawDecimal($product, 'minimum_weight'),
            'maximum_weight' => $this->rawDecimal($variant, 'maximum_weight') ?? $this->rawDecimal($weightRule, 'maximum_weight') ?? $this->rawDecimal($product, 'maximum_weight'),
            'target_weight' => $this->rawDecimal($variant, 'target_weight') ?? $this->rawDecimal($weightRule, 'target_weight') ?? $this->rawDecimal($product, 'target_weight'),
            'weight_decimal_precision' => $variant?->getRawOriginal('weight_decimal_precision') ?? $weightRule?->getRawOriginal('decimal_precision') ?? $product->getRawOriginal('weight_decimal_precision'),
            'stability_duration_ms' => $variant?->getRawOriginal('stability_duration_ms') ?? $weightRule?->getRawOriginal('stability_duration_ms') ?? $product->getRawOriginal('stability_duration_ms'),
            'reset_threshold' => $this->rawDecimal($variant, 'reset_threshold') ?? $this->rawDecimal($weightRule, 'reset_threshold') ?? $this->rawDecimal($product, 'reset_threshold'),
            'auto_print_enabled' => $weightRule?->auto_print_enabled ?? $product->auto_print_enabled,
            'manual_print_enabled' => $weightRule?->manual_print_enabled ?? $product->manual_print_enabled,
            'duplicate_print_prevention_enabled' => $weightRule?->duplicate_print_prevention_enabled ?? $product->duplicate_print_prevention_enabled,
            'product_lock_mode' => $variant?->product_lock_mode ?? $weightRule?->product_lock_mode ?? $product->product_lock_mode,
            'variant_lock_mode' => $weightRule?->variant_lock_mode ?? $product->variant_lock_mode,
            'conversion_rule' => $this->rawAttributes($conversionRule),
        ];
    }

    private function rawAttributes($model): ?array
    {
        if (! $model) {
            return null;
        }

        $attributes = $model->getAttributes();
        foreach ($attributes as $key => $value) {
            if ($value === '') {
                $attributes[$key] = null;
            }
        }

        return $attributes;
    }

    private function rawDecimal($model, string $key): mixed
    {
        if (! $model) {
            return null;
        }
        $value = $model->getRawOriginal($key);

        if ($value === '' || $value === null) {
            return null;
        }

        return is_numeric($value) ? number_format((float) $value, 3, '.', '') : $value;
    }

    public function resolveWeightRule(Product $product, ?ProductVariant $variant = null): ?WeightRule
    {
        if ($variant) {
            $rule = WeightRule::query()
                ->where('tenant_id', $product->tenant_id)
                ->where('variant_id', $variant->id)
                ->where('is_active', true)
                ->latest('effective_at')
                ->first();

            if ($rule) {
                return $rule;
            }
        }

        return WeightRule::query()
            ->where('tenant_id', $product->tenant_id)
            ->where('product_id', $product->id)
            ->whereNull('variant_id')
            ->where('is_active', true)
            ->latest('effective_at')
            ->first();
    }

    public function resolveConversionRule(Product $product, ?ProductVariant $variant = null): ?UnitConversionRule
    {
        if ($variant) {
            $rule = UnitConversionRule::query()
                ->where('tenant_id', $product->tenant_id)
                ->where('variant_id', $variant->id)
                ->where('is_active', true)
                ->latest()
                ->first();

            if ($rule) {
                return $rule;
            }
        }

        return UnitConversionRule::query()
            ->where('tenant_id', $product->tenant_id)
            ->where('product_id', $product->id)
            ->whereNull('variant_id')
            ->where('is_active', true)
            ->latest()
            ->first();
    }
}
