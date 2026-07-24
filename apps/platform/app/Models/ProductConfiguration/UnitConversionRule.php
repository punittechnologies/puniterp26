<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'product_id', 'variant_id', 'method', 'weight_per_piece', 'weight_unit_id', 'pieces_per_kg', 'sample_weight', 'sample_weight_unit_id', 'sample_piece_count', 'rounding_method', 'decimal_places', 'is_active', 'configuration_version', 'created_by', 'updated_by'])]
class UnitConversionRule extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'weight_per_piece' => NullableDecimal::class.':6',
            'pieces_per_kg' => NullableDecimal::class.':6',
            'sample_weight' => NullableDecimal::class.':6',
            'sample_piece_count' => 'integer',
            'decimal_places' => 'integer',
            'is_active' => 'boolean',
            'configuration_version' => 'integer',
        ];
    }
}
