<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'user_id', 'action', 'auditable_type', 'auditable_id', 'old_values', 'new_values', 'metadata', 'ip_address', 'user_agent'])]
class AuditLog extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return ['old_values' => 'array', 'new_values' => 'array', 'metadata' => 'array'];
    }
}
