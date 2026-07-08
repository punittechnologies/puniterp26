<?php

namespace App\Http\Requests\Api\V1\Products;

use App\Support\TenantContext;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductRequest extends FormRequest
{
    public function rules(TenantContext $tenantContext): array
    {
        $tenantId = $tenantContext->tenantId();
        $productId = $this->route('product')?->id ?? $this->route('product');

        return [
            'category_id' => ['nullable', 'uuid'],
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'product_code' => ['sometimes', 'required', 'string', 'max:100', Rule::unique('products', 'product_code')->where('tenant_id', $tenantId)->ignore($productId)],
            'sku' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'brand' => ['nullable', 'string', 'max:100'],
            'is_active' => ['boolean'],
            'default_tare_weight' => ['nullable', 'numeric', 'min:0'],
            'minimum_weight' => ['nullable', 'numeric', 'min:0'],
            'maximum_weight' => ['nullable', 'numeric', 'min:0', 'gte:minimum_weight'],
            'target_weight' => ['nullable', 'numeric', 'min:0'],
            'weight_decimal_precision' => ['nullable', 'integer', 'between:0,6'],
            'stability_duration_ms' => ['nullable', 'integer', 'between:100,10000'],
            'stability_tolerance' => ['nullable', 'numeric', 'min:0'],
            'reset_threshold' => ['nullable', 'numeric', 'min:0'],
            'auto_print_enabled' => ['boolean'],
            'manual_print_enabled' => ['boolean'],
            'duplicate_print_prevention_enabled' => ['boolean'],
            'unit_conversion_enabled' => ['boolean'],
            'product_lock_mode' => ['nullable', Rule::in(['none', 'device_specific', 'user_specific', 'role_specific', 'single_product'])],
            'variant_lock_mode' => ['nullable', Rule::in(['none', 'preselected_variant', 'device_specific_variant', 'user_restricted_variants'])],
            'product_selection_mode' => ['nullable', Rule::in(['operator_can_select', 'device_locked', 'user_restricted', 'hidden_from_app'])],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
