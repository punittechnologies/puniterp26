<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'configuration_schema_id', 'version', 'status', 'configuration', 'change_summary', 'approved_at', 'activated_at', 'created_by', 'approved_by'])]
class ConfigurationVersion extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'configuration' => 'array',
            'change_summary' => 'array',
            'approved_at' => 'datetime',
            'activated_at' => 'datetime',
        ];
    }
}
