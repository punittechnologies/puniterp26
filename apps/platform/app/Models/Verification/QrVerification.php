<?php

namespace App\Models\Verification;

use App\Models\Concerns\HasUuidPrimaryKey;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'tenant_id',
    'qr_page_setting_id',
    'source_transaction_id',
    'token_hash',
    'token_encrypted',
    'status',
    'product_id',
    'variant_id',
    'serial_number',
    'barcode_value',
    'snapshot',
    'printed_at',
    'scan_count',
    'last_scanned_at',
    'created_by',
])]
class QrVerification extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'snapshot' => 'array',
            'printed_at' => 'datetime',
            'last_scanned_at' => 'datetime',
            'scan_count' => 'integer',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function setting(): BelongsTo
    {
        return $this->belongsTo(QrPageSetting::class, 'qr_page_setting_id');
    }

    public function complaints(): HasMany
    {
        return $this->hasMany(QrComplaint::class);
    }
}
