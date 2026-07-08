<?php

namespace App\Models\ProductConfiguration;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['tenant_id', 'device_id', 'product_id', 'variant_id', 'allowed', 'locked', 'default_selection', 'sort_order', 'effective_at', 'expires_at', 'is_active', 'configuration_version', 'created_by', 'updated_by'])]
class ProductDeviceAssignment extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'allowed' => 'boolean',
            'locked' => 'boolean',
            'default_selection' => 'boolean',
            'sort_order' => 'integer',
            'effective_at' => 'datetime',
            'expires_at' => 'datetime',
            'is_active' => 'boolean',
            'configuration_version' => 'integer',
        ];
    }
}
