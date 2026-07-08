<?php

namespace App\Models\ProductConfiguration;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'field_label', 'internal_key', 'description', 'entity_type', 'data_type', 'is_required', 'default_value', 'placeholder', 'help_text', 'validation_rules', 'dropdown_options', 'visible_in_web', 'visible_in_flutter', 'editable_in_flutter', 'printable_on_label', 'visible_in_reports', 'searchable', 'filterable', 'sort_order', 'conditional_visibility', 'formula_definition', 'is_active', 'configuration_version', 'created_by', 'updated_by'])]
class DynamicFieldDefinition extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'is_required' => 'boolean',
            'default_value' => 'array',
            'validation_rules' => 'array',
            'dropdown_options' => 'array',
            'visible_in_web' => 'boolean',
            'visible_in_flutter' => 'boolean',
            'editable_in_flutter' => 'boolean',
            'printable_on_label' => 'boolean',
            'visible_in_reports' => 'boolean',
            'searchable' => 'boolean',
            'filterable' => 'boolean',
            'sort_order' => 'integer',
            'conditional_visibility' => 'array',
            'formula_definition' => 'array',
            'is_active' => 'boolean',
            'configuration_version' => 'integer',
        ];
    }

    public function values(): HasMany
    {
        return $this->hasMany(DynamicFieldValue::class);
    }
}
