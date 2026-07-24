<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'name', 'symbol', 'category', 'conversion_factor_to_base', 'decimal_precision', 'is_system', 'is_active'])]
class Unit extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'conversion_factor_to_base' => NullableDecimal::class.':8',
            'decimal_precision' => 'integer',
            'is_system' => 'boolean',
            'is_active' => 'boolean',
        ];
    }
}
