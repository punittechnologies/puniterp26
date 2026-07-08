<?php

namespace App\Http\Controllers\Api\V1\Products;

use App\Http\Controllers\Controller;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\ProductAttribute;
use App\Models\ProductConfiguration\ProductAttributeValue;
use App\Models\ProductConfiguration\ProductConfigurationRevision;
use App\Models\ProductConfiguration\ProductDeviceAssignment;
use App\Models\ProductConfiguration\Unit;
use App\Models\ProductConfiguration\UnitConversionRule;
use App\Models\ProductConfiguration\WeightRule;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ProductConfigurationController extends Controller
{
    public function attributes(TenantContext $tenantContext): JsonResponse
    {
        return response()->json(ProductAttribute::query()
            ->with('values')
            ->where('tenant_id', $tenantContext->tenantId())
            ->orderBy('sort_order')
            ->get());
    }

    public function storeAttribute(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'internal_key' => ['required', 'regex:/^[a-z][a-z0-9_]*$/', Rule::unique('product_attributes', 'internal_key')->where('tenant_id', $tenantContext->tenantId())],
            'field_type' => ['required', Rule::in(['text', 'integer', 'decimal', 'dropdown', 'boolean'])],
            'is_required' => ['boolean'],
            'is_variant_defining' => ['boolean'],
            'visible_in_app' => ['boolean'],
            'printable' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
            'values' => ['array'],
        ]);

        $attribute = ProductAttribute::query()->create([...collect($data)->except('values')->all(), 'tenant_id' => $tenantContext->tenantId(), 'created_by' => $request->user()->id]);

        foreach ($data['values'] ?? [] as $index => $value) {
            ProductAttributeValue::query()->create([
                'tenant_id' => $tenantContext->tenantId(),
                'product_attribute_id' => $attribute->id,
                'display_value' => $value['display_value'],
                'internal_value' => $value['internal_value'] ?? Str::slug($value['display_value'], '_'),
                'sort_order' => $value['sort_order'] ?? $index,
                'is_active' => $value['is_active'] ?? true,
            ]);
        }

        return response()->json($attribute->load('values'), 201);
    }

    public function dynamicFields(TenantContext $tenantContext): JsonResponse
    {
        return response()->json(DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->orderBy('entity_type')
            ->orderBy('sort_order')
            ->get());
    }

    public function storeDynamicField(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'field_label' => ['required', 'string', 'max:255'],
            'internal_key' => ['required', 'regex:/^[a-z][a-z0-9_]*$/', Rule::unique('dynamic_field_definitions', 'internal_key')->where('tenant_id', $tenantContext->tenantId())->where('entity_type', $request->input('entity_type'))],
            'entity_type' => ['required', Rule::in(['product', 'product_variant', 'weighing_transaction', 'dispatch'])],
            'data_type' => ['required', Rule::in(['short_text', 'long_text', 'integer', 'decimal', 'dropdown', 'multi_select', 'checkbox', 'boolean', 'date', 'date_time', 'auto_number', 'formula'])],
            'description' => ['nullable', 'string'],
            'is_required' => ['boolean'],
            'default_value' => ['nullable', 'array'],
            'validation_rules' => ['nullable', 'array'],
            'dropdown_options' => ['nullable', 'array'],
            'conditional_visibility' => ['nullable', 'array'],
            'formula_definition' => ['nullable', 'array'],
            'visible_in_web' => ['boolean'],
            'visible_in_flutter' => ['boolean'],
            'editable_in_flutter' => ['boolean'],
            'printable_on_label' => ['boolean'],
            'visible_in_reports' => ['boolean'],
            'searchable' => ['boolean'],
            'filterable' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ]);

        $field = DynamicFieldDefinition::query()->create([...$data, 'tenant_id' => $tenantContext->tenantId(), 'created_by' => $request->user()->id]);

        return response()->json($field, 201);
    }

    public function units(TenantContext $tenantContext): JsonResponse
    {
        return response()->json(Unit::query()
            ->where(fn ($query) => $query->whereNull('tenant_id')->orWhere('tenant_id', $tenantContext->tenantId()))
            ->orderBy('category')
            ->orderBy('symbol')
            ->get());
    }

    public function storeUnit(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'symbol' => ['required', 'string', 'max:30'],
            'category' => ['required', Rule::in(['weight', 'quantity', 'length', 'packaging', 'custom'])],
            'conversion_factor_to_base' => ['required', 'numeric', 'gt:0'],
            'decimal_precision' => ['integer', 'between:0,6'],
            'is_active' => ['boolean'],
        ]);

        return response()->json(Unit::query()->create([...$data, 'tenant_id' => $tenantContext->tenantId(), 'is_system' => false]), 201);
    }

    public function storeConversionRule(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['nullable', 'uuid'],
            'variant_id' => ['nullable', 'uuid'],
            'method' => ['required', Rule::in(['weight_per_piece', 'pieces_per_kg', 'sample_based'])],
            'weight_per_piece' => ['nullable', 'numeric', 'gt:0'],
            'weight_unit_id' => ['nullable', 'uuid'],
            'pieces_per_kg' => ['nullable', 'numeric', 'gt:0'],
            'sample_weight' => ['nullable', 'numeric', 'gt:0'],
            'sample_weight_unit_id' => ['nullable', 'uuid'],
            'sample_piece_count' => ['nullable', 'integer', 'gt:0'],
            'rounding_method' => ['required', Rule::in(['none', 'nearest', 'floor', 'ceil'])],
            'decimal_places' => ['integer', 'between:0,6'],
            'is_active' => ['boolean'],
        ]);

        return response()->json(UnitConversionRule::query()->create([...$data, 'tenant_id' => $tenantContext->tenantId(), 'created_by' => $request->user()->id]), 201);
    }

    public function storeWeightRule(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['nullable', 'uuid'],
            'variant_id' => ['nullable', 'uuid'],
            'weight_unit_id' => ['nullable', 'uuid'],
            'minimum_weight' => ['nullable', 'numeric', 'min:0'],
            'maximum_weight' => ['nullable', 'numeric', 'min:0', 'gte:minimum_weight'],
            'target_weight' => ['nullable', 'numeric', 'min:0'],
            'tare_weight' => ['nullable', 'numeric', 'min:0'],
            'decimal_precision' => ['integer', 'between:0,6'],
            'stability_duration_ms' => ['integer', 'between:100,10000'],
            'stability_tolerance' => ['nullable', 'numeric', 'min:0'],
            'reset_threshold' => ['nullable', 'numeric', 'min:0'],
            'auto_print_enabled' => ['boolean'],
            'manual_print_enabled' => ['boolean'],
            'duplicate_print_prevention_enabled' => ['boolean'],
            'underweight_action' => ['required', Rule::in(['allow_with_warning', 'block_printing', 'require_supervisor_approval', 'hide_print_button', 'custom_message'])],
            'overweight_action' => ['required', Rule::in(['allow_with_warning', 'block_printing', 'require_supervisor_approval', 'hide_print_button', 'custom_message'])],
            'product_lock_mode' => ['nullable', 'string'],
            'variant_lock_mode' => ['nullable', 'string'],
            'is_active' => ['boolean'],
            'effective_at' => ['nullable', 'date'],
        ]);

        return response()->json(WeightRule::query()->create([...$data, 'tenant_id' => $tenantContext->tenantId(), 'created_by' => $request->user()->id]), 201);
    }

    public function storeDeviceAssignment(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $request->validate([
            'device_id' => ['required', 'uuid'],
            'product_id' => ['required', 'uuid'],
            'variant_id' => ['nullable', 'uuid'],
            'allowed' => ['boolean'],
            'locked' => ['boolean'],
            'default_selection' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
            'effective_at' => ['nullable', 'date'],
            'expires_at' => ['nullable', 'date', 'after:effective_at'],
            'is_active' => ['boolean'],
        ]);

        if (($data['locked'] ?? false) && ProductDeviceAssignment::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->where('device_id', $data['device_id'])
            ->where('locked', true)
            ->where('is_active', true)
            ->exists()) {
            abort(422, 'Device already has an active locked assignment.');
        }

        return response()->json(ProductDeviceAssignment::query()->create([...$data, 'tenant_id' => $tenantContext->tenantId(), 'created_by' => $request->user()->id]), 201);
    }

    public function history(TenantContext $tenantContext): JsonResponse
    {
        return response()->json(ProductConfigurationRevision::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->latest()
            ->paginate(20));
    }
}
