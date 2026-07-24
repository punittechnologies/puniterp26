<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use App\Models\Warehouse;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'category_id', 'default_weight_unit_id', 'default_inventory_unit_id', 'default_warehouse_id', 'name', 'product_code', 'sku', 'description', 'brand', 'image_path', 'is_active', 'barcode_rule', 'default_tare_weight', 'minimum_weight', 'maximum_weight', 'target_weight', 'weight_decimal_precision', 'stability_duration_ms', 'stability_tolerance', 'reset_threshold', 'auto_print_enabled', 'manual_print_enabled', 'duplicate_print_prevention_enabled', 'unit_conversion_enabled', 'default_label_template_id', 'product_lock_mode', 'variant_lock_mode', 'product_selection_mode', 'metadata', 'configuration_version', 'configuration_activated_at', 'created_by', 'updated_by'])]
class Product extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'default_tare_weight' => NullableDecimal::class.':3',
            'minimum_weight' => NullableDecimal::class.':3',
            'maximum_weight' => NullableDecimal::class.':3',
            'target_weight' => NullableDecimal::class.':3',
            'weight_decimal_precision' => 'integer',
            'stability_duration_ms' => 'integer',
            'stability_tolerance' => NullableDecimal::class.':3',
            'reset_threshold' => NullableDecimal::class.':3',
            'auto_print_enabled' => 'boolean',
            'manual_print_enabled' => 'boolean',
            'duplicate_print_prevention_enabled' => 'boolean',
            'unit_conversion_enabled' => 'boolean',
            'metadata' => 'array',
            'configuration_version' => 'integer',
            'configuration_activated_at' => 'datetime',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(ProductCategory::class);
    }

    public function defaultWeightUnit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'default_weight_unit_id');
    }

    public function defaultInventoryUnit(): BelongsTo
    {
        return $this->belongsTo(Unit::class, 'default_inventory_unit_id');
    }

    public function defaultWarehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class, 'default_warehouse_id');
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function conversionRules(): HasMany
    {
        return $this->hasMany(UnitConversionRule::class);
    }

    public function weightRules(): HasMany
    {
        return $this->hasMany(WeightRule::class);
    }
}
