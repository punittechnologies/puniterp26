<?php

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['phone', 'company_name', 'tenant_id', 'admin_limit', 'valid_until', 'status', 'claimed_by', 'claimed_at', 'created_by', 'updated_by'])]
class TenantOnboardingInvite extends Model
{
    use HasUuidPrimaryKey, SoftDeletes;

    protected function casts(): array
    {
        return [
            'admin_limit' => 'integer',
            'valid_until' => 'date',
            'claimed_at' => 'datetime',
        ];
    }

    public function isClaimable(): bool
    {
        return $this->status === 'pending'
            && (! $this->valid_until || $this->valid_until->endOfDay()->isFuture());
    }
}
