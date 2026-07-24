<?php

namespace App\Models\ProductConfiguration;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'dynamic_field_definition_id', 'entity_type', 'entity_id', 'text_value', 'decimal_value', 'integer_value', 'boolean_value', 'date_value', 'json_value', 'created_by', 'updated_by'])]
class DynamicFieldValue extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'decimal_value' => NullableDecimal::class.':6',
            'integer_value' => 'integer',
            'boolean_value' => 'boolean',
            'date_value' => 'datetime',
            'json_value' => 'array',
        ];
    }
}
