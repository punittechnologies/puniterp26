<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'name', 'adapter_key', 'settings', 'is_active', 'created_by', 'updated_by'])]
class PrinterProfile extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return ['settings' => 'array', 'is_active' => 'boolean'];
    }
}
