<?php

namespace App\Models;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'warehouse_id', 'product_id', 'variant_id', 'serial_number', 'label_serial_number', 'barcode_value', 'transaction_type', 'weight_quantity', 'piece_quantity', 'reference_type', 'reference_id', 'sync_status', 'reason', 'device_id', 'created_by', 'occurred_at'])]
class InventoryTransaction extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'weight_quantity' => NullableDecimal::class.':6',
            'piece_quantity' => NullableDecimal::class.':6',
            'occurred_at' => 'datetime',
        ];
    }
}
