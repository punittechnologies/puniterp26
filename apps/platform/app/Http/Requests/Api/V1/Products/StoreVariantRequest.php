<?php

namespace App\Http\Requests\Api\V1\Products;

use App\Support\TenantContext;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreVariantRequest extends FormRequest
{
    public function rules(TenantContext $tenantContext): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'variant_code' => ['required', 'string', 'max:100', Rule::unique('product_variants', 'variant_code')->where('tenant_id', $tenantContext->tenantId())],
            'sku' => ['nullable', 'string', 'max:100'],
            'barcode' => ['nullable', 'string', 'max:150'],
            'attribute_signature' => ['nullable', 'string', 'max:255'],
            'is_active' => ['boolean'],
            'tare_weight' => ['nullable', 'numeric', 'min:0'],
            'minimum_weight' => ['nullable', 'numeric', 'min:0'],
            'maximum_weight' => ['nullable', 'numeric', 'min:0', 'gte:minimum_weight'],
            'target_weight' => ['nullable', 'numeric', 'min:0'],
            'weight_decimal_precision' => ['nullable', 'integer', 'between:0,6'],
            'stability_duration_ms' => ['nullable', 'integer', 'between:100,10000'],
            'reset_threshold' => ['nullable', 'numeric', 'min:0'],
            'product_lock_mode' => ['nullable', 'string'],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
