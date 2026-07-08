<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['key', 'name', 'module', 'schema', 'is_active'])]
class ConfigurationSchema extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return ['schema' => 'array', 'is_active' => 'boolean'];
    }
}
