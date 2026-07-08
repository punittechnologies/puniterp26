<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'production_transaction_id', 'serial_number', 'barcode_value', 'inventory_status', 'dispatch_status'])]
class BarcodeRecord extends Model
{
    use HasUuidPrimaryKey;
}
