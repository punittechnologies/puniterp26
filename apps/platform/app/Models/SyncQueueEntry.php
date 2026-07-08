<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'user_id', 'client_id', 'operation', 'entity_type', 'entity_id', 'idempotency_key', 'status', 'attempt_count', 'payload', 'last_error', 'processed_at'])]
class SyncQueueEntry extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return ['payload' => 'array', 'processed_at' => 'datetime'];
    }
}
