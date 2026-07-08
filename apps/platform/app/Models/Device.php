<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'scale_profile_id', 'printer_profile_id', 'name', 'device_type', 'identifier', 'status', 'last_seen_at', 'settings', 'created_by', 'updated_by'])]
class Device extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return ['settings' => 'array', 'last_seen_at' => 'datetime'];
    }
}
