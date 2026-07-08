<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['tenant_id', 'customer_id', 'dispatch_number', 'customer_snapshot', 'status', 'vehicle_number', 'driver_name', 'transporter', 'po_reference', 'invoice_reference', 'total_weight', 'total_pieces', 'metadata', 'client_id', 'idempotency_key', 'created_by', 'updated_by', 'confirmed_at'])]
class Dispatch extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'customer_snapshot' => 'array',
            'metadata' => 'array',
            'total_weight' => 'decimal:6',
            'total_pieces' => 'decimal:6',
            'confirmed_at' => 'datetime',
        ];
    }

    public function items(): HasMany
    {
        return $this->hasMany(DispatchItem::class);
    }
}
