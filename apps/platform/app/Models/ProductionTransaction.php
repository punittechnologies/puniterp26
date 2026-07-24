<?php

namespace App\Models;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'warehouse_id', 'product_id', 'variant_id', 'inward_session_id', 'serial_number', 'barcode_value', 'product_snapshot', 'dynamic_values', 'gross_weight', 'tare_weight', 'net_weight', 'piece_quantity', 'unit', 'raw_reading', 'status', 'sync_status', 'client_id', 'idempotency_key', 'captured_at', 'created_by', 'updated_by'])]
class ProductionTransaction extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'product_snapshot' => 'array',
            'dynamic_values' => 'array',
            'raw_reading' => 'array',
            'gross_weight' => NullableDecimal::class.':6',
            'tare_weight' => NullableDecimal::class.':6',
            'net_weight' => NullableDecimal::class.':6',
            'piece_quantity' => NullableDecimal::class.':6',
            'captured_at' => 'datetime',
        ];
    }
}
