<?php

namespace App\Models\ProductConfiguration;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'configuration_type', 'entity_id', 'previous_version', 'new_version', 'status', 'change_summary', 'payload', 'activated_at', 'rollback_payload', 'created_by', 'approved_by'])]
class ProductConfigurationRevision extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'previous_version' => 'integer',
            'new_version' => 'integer',
            'change_summary' => 'array',
            'payload' => 'array',
            'activated_at' => 'datetime',
            'rollback_payload' => 'array',
        ];
    }
}
