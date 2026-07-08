<?php

namespace App\Models\Labeling;

use App\Models\Concerns\HasUuidPrimaryKey;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'product_id', 'variant_id', 'name', 'code', 'scope', 'width_mm', 'height_mm', 'is_custom_size', 'is_default', 'is_active', 'is_archived', 'active_version', 'template_json', 'warnings', 'created_by', 'updated_by'])]
class LabelTemplate extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'width_mm' => 'decimal:2',
            'height_mm' => 'decimal:2',
            'is_custom_size' => 'boolean',
            'is_default' => 'boolean',
            'is_active' => 'boolean',
            'is_archived' => 'boolean',
            'active_version' => 'integer',
            'template_json' => 'array',
            'warnings' => 'array',
        ];
    }

    public function versions(): HasMany
    {
        return $this->hasMany(LabelTemplateVersion::class);
    }

    public function elements(): HasMany
    {
        return $this->hasMany(LabelTemplateElement::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function variant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }
}
