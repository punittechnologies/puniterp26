<?php

namespace App\Models\Verification;

use App\Models\Concerns\HasUuidPrimaryKey;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'tenant_id',
    'qr_verification_id',
    'status',
    'customer_company_name',
    'customer_name',
    'phone',
    'email',
    'contact_person',
    'order_reference',
    'message',
    'photo_path',
    'metadata',
])]
class QrComplaint extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function verification(): BelongsTo
    {
        return $this->belongsTo(QrVerification::class, 'qr_verification_id');
    }
}
