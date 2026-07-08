<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'user_id', 'key', 'method', 'endpoint', 'request_hash', 'response_status', 'response_body', 'locked_until', 'processed_at'])]
class IdempotencyKey extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return ['response_body' => 'array', 'locked_until' => 'datetime', 'processed_at' => 'datetime'];
    }
}
