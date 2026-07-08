<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

#[Fillable(['key', 'name', 'module'])]
class Permission extends Model
{
    use HasUuidPrimaryKey;

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class);
    }
}
