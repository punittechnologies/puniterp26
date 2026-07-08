<?php

namespace App\Models\Labeling;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'label_template_id', 'label_template_version_id', 'element_key', 'type', 'binding_key', 'x', 'y', 'width', 'height', 'layer_order', 'style', 'format', 'visibility', 'prefix', 'suffix'])]
class LabelTemplateElement extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'x' => 'decimal:2',
            'y' => 'decimal:2',
            'width' => 'decimal:2',
            'height' => 'decimal:2',
            'layer_order' => 'integer',
            'style' => 'array',
            'format' => 'array',
            'visibility' => 'array',
        ];
    }
}
