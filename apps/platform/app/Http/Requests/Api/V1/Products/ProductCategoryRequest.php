<?php

namespace App\Http\Requests\Api\V1\Products;

use App\Support\TenantContext;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProductCategoryRequest extends FormRequest
{
    public function rules(TenantContext $tenantContext): array
    {
        return [
            'parent_id' => ['nullable', 'uuid'],
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:100', Rule::unique('product_categories', 'code')->where('tenant_id', $tenantContext->tenantId())->ignore($this->route('product_category'))],
            'description' => ['nullable', 'string'],
            'is_active' => ['boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
