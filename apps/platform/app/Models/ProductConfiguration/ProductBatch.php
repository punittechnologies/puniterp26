<?php

namespace App\Models\ProductConfiguration;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'tenant_id',
    'product_id',
    'batch_name',
    'attribute_key',
    'attribute_label',
    'attribute_value',
    'detail_values',
    'batch_items',
    'detail_signature',
    'is_active',
    'created_by',
    'updated_by',
])]
class ProductBatch extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'detail_values' => 'array',
            'batch_items' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function displayItems(): array
    {
        if (! empty($this->batch_items)) {
            return array_values($this->batch_items);
        }

        return [[
            'product_id' => $this->product_id,
            'product_name' => $this->product?->name,
            'details' => $this->detail_values ?: [
                $this->attribute_key => [
                    'label' => $this->attribute_label,
                    'value' => $this->attribute_value,
                ],
            ],
        ]];
    }
}
