<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['id', 'tenant_id', 'session_number', 'status', 'entry_count', 'total_gross_weight', 'total_tare_weight', 'total_net_weight', 'total_piece_quantity', 'metadata', 'started_at', 'ended_at', 'created_by', 'updated_by'])]
class InwardSession extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'entry_count' => 'integer',
            'total_gross_weight' => 'decimal:6',
            'total_tare_weight' => 'decimal:6',
            'total_net_weight' => 'decimal:6',
            'total_piece_quantity' => 'decimal:6',
            'metadata' => 'array',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }

    public function productions(): HasMany
    {
        return $this->hasMany(ProductionTransaction::class, 'inward_session_id');
    }
}
