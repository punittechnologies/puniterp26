<?php

namespace App\Http\Requests\Api\V1\Labels;

use App\Support\TenantContext;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class LabelTemplateRequest extends FormRequest
{
    public function rules(TenantContext $tenantContext): array
    {
        $templateId = $this->route('label_template')?->id ?? $this->route('label_template');

        return [
            'name' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:100', Rule::unique('label_templates', 'code')->where('tenant_id', $tenantContext->tenantId())->ignore($templateId)],
            'scope' => ['required', Rule::in(['tenant', 'product', 'variant'])],
            'product_id' => ['nullable', 'uuid'],
            'variant_id' => ['nullable', 'uuid'],
            'is_custom_size' => ['boolean'],
            'is_default' => ['boolean'],
            'template_json' => ['required', 'array'],
            'template_json.widthMm' => ['required', 'numeric', 'min:10', 'max:200'],
            'template_json.heightMm' => ['required', 'numeric', 'min:10', 'max:200'],
            'template_json.elements' => ['required', 'array'],
        ];
    }
}
