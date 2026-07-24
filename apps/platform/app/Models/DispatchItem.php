<?php

namespace App\Models;

use App\Casts\NullableDecimal;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'dispatch_id', 'production_transaction_id', 'barcode_value', 'weight_quantity', 'piece_quantity'])]
class DispatchItem extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return ['weight_quantity' => NullableDecimal::class.':6', 'piece_quantity' => NullableDecimal::class.':6'];
    }
}
