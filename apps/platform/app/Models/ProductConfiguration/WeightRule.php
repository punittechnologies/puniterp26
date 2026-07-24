<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'product_id', 'variant_id', 'weight_unit_id', 'minimum_weight', 'maximum_weight', 'target_weight', 'tare_weight', 'decimal_precision', 'stability_duration_ms', 'stability_tolerance', 'reset_threshold', 'auto_print_enabled', 'manual_print_enabled', 'duplicate_print_prevention_enabled', 'underweight_action', 'overweight_action', 'underweight_message', 'overweight_message', 'product_lock_mode', 'variant_lock_mode', 'is_active', 'effective_at', 'configuration_version', 'created_by', 'updated_by'])]
class WeightRule extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'minimum_weight' => NullableDecimal::class.':3',
            'maximum_weight' => NullableDecimal::class.':3',
            'target_weight' => NullableDecimal::class.':3',
            'tare_weight' => NullableDecimal::class.':3',
            'decimal_precision' => 'integer',
            'stability_duration_ms' => 'integer',
            'stability_tolerance' => NullableDecimal::class.':3',
            'reset_threshold' => NullableDecimal::class.':3',
            'auto_print_enabled' => 'boolean',
            'manual_print_enabled' => 'boolean',
            'duplicate_print_prevention_enabled' => 'boolean',
            'is_active' => 'boolean',
            'effective_at' => 'datetime',
            'configuration_version' => 'integer',
        ];
    }
}
