<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'product_id', 'unit_conversion_rule_id', 'name', 'variant_code', 'sku', 'barcode', 'image_path', 'attribute_signature', 'is_active', 'tare_weight', 'minimum_weight', 'maximum_weight', 'target_weight', 'weight_decimal_precision', 'stability_duration_ms', 'reset_threshold', 'product_lock_mode', 'label_template_id', 'metadata', 'configuration_version', 'created_by', 'updated_by'])]
class ProductVariant extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'tare_weight' => NullableDecimal::class.':3',
            'minimum_weight' => NullableDecimal::class.':3',
            'maximum_weight' => NullableDecimal::class.':3',
            'target_weight' => NullableDecimal::class.':3',
            'weight_decimal_precision' => 'integer',
            'stability_duration_ms' => 'integer',
            'reset_threshold' => NullableDecimal::class.':3',
            'metadata' => 'array',
            'configuration_version' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function conversionRule(): BelongsTo
    {
        return $this->belongsTo(UnitConversionRule::class, 'unit_conversion_rule_id');
    }
}
