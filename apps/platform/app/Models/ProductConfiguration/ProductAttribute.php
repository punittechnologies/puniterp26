<?php

namespace App\Models\ProductConfiguration;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'name', 'internal_key', 'field_type', 'is_required', 'is_variant_defining', 'visible_in_app', 'printable', 'sort_order', 'is_active', 'created_by', 'updated_by'])]
class ProductAttribute extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'is_required' => 'boolean',
            'is_variant_defining' => 'boolean',
            'visible_in_app' => 'boolean',
            'printable' => 'boolean',
            'sort_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function values(): HasMany
    {
        return $this->hasMany(ProductAttributeValue::class);
    }
}
