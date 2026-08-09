<?php

namespace App\Domain\Labels\Services;

use App\Models\ProductConfiguration\DynamicFieldDefinition;

class LabelBindingRegistry
{
    public function bindings(string $tenantId): array
    {
        $static = [
            ['key' => 'static.text', 'label' => 'Static text', 'type' => 'static'],
            ['key' => 'product.name', 'label' => 'Product name', 'type' => 'product'],
            ['key' => 'product.code', 'label' => 'Product code', 'type' => 'product'],
            ['key' => 'variant.name', 'label' => 'Variant name', 'type' => 'variant'],
            ['key' => 'variant.code', 'label' => 'Variant code', 'type' => 'variant'],
            ['key' => 'weight.gross', 'label' => 'Gross weight', 'type' => 'weighing'],
            ['key' => 'weight.tare', 'label' => 'Tare weight', 'type' => 'weighing'],
            ['key' => 'weight.net', 'label' => 'Net weight', 'type' => 'weighing'],
            ['key' => 'pieces.quantity', 'label' => 'Piece quantity', 'type' => 'weighing'],
            ['key' => 'batch.number', 'label' => 'Batch No', 'type' => 'product'],
            ['key' => 'serial.number', 'label' => 'Serial number', 'type' => 'system'],
            ['key' => 'barcode.value', 'label' => 'Barcode', 'type' => 'barcode'],
            ['key' => 'product.customer_barcode', 'label' => 'Product customer barcode', 'type' => 'barcode'],
            ['key' => 'qr.value', 'label' => 'QR code', 'type' => 'qr'],
            ['key' => 'date.current', 'label' => 'Date', 'type' => 'system'],
            ['key' => 'time.current', 'label' => 'Time', 'type' => 'system'],
            ['key' => 'operator.name', 'label' => 'Operator', 'type' => 'system'],
            ['key' => 'company.name', 'label' => 'Company name', 'type' => 'company'],
            ['key' => 'company.logo', 'label' => 'Company logo', 'type' => 'image'],
            ['key' => 'customer.name', 'label' => 'Customer', 'type' => 'future'],
            ['key' => 'warehouse.name', 'label' => 'Warehouse', 'type' => 'warehouse'],
        ];

        $dynamic = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->get()
            ->map(fn ($field) => [
                'key' => 'dynamic.'.$field->entity_type.'.'.$field->internal_key,
                'label' => $field->field_label,
                'type' => 'dynamic',
            ])
            ->all();

        $dividedWeights = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->where('use_as_weight_divisor', true)
            ->orderBy('sort_order')
            ->get()
            ->flatMap(fn ($field) => [
                [
                    'key' => 'weight.gross_per_piece.'.$field->internal_key,
                    'label' => 'Gross per piece ('.$field->field_label.')',
                    'type' => 'divided_weight',
                ],
                [
                    'key' => 'weight.net_per_piece.'.$field->internal_key,
                    'label' => 'Net per piece ('.$field->field_label.')',
                    'type' => 'divided_weight',
                ],
            ])
            ->values()
            ->all();

        return [...$static, ...$dividedWeights, ...$dynamic];
    }

    public function keys(string $tenantId): array
    {
        return collect($this->bindings($tenantId))->pluck('key')->all();
    }
}
