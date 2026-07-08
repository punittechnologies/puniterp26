<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['tenant_id', 'name', 'code', 'contact_person', 'phone', 'email', 'billing_address', 'shipping_address', 'tax_number', 'is_active', 'metadata', 'created_by', 'updated_by'])]
class Customer extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return ['metadata' => 'array', 'is_active' => 'boolean'];
    }
}
