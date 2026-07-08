<?php

namespace App\Domain\Products\Services;

use App\Models\AuditLog;
use App\Models\ProductConfiguration\ProductConfigurationRevision;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class ProductConfigurationRevisionService
{
    public function record(Model $model, string $type, array $oldValues, array $newValues): ProductConfigurationRevision
    {
        $tenantId = $model->tenant_id;
        $previous = (int) ($model->getOriginal('configuration_version') ?? 0);
        $new = max($previous + 1, (int) ($model->configuration_version ?? 1));

        $revision = ProductConfigurationRevision::query()->create([
            'tenant_id' => $tenantId,
            'configuration_type' => $type,
            'entity_id' => $model->getKey(),
            'previous_version' => $previous ?: null,
            'new_version' => $new,
            'status' => 'active',
            'change_summary' => ['changed' => array_keys($newValues)],
            'payload' => $newValues,
            'rollback_payload' => $oldValues,
            'activated_at' => now(),
            'created_by' => Auth::id(),
            'approved_by' => Auth::id(),
        ]);

        AuditLog::query()->create([
            'tenant_id' => $tenantId,
            'user_id' => Auth::id(),
            'action' => $type.'.updated',
            'auditable_type' => $model::class,
            'auditable_id' => $model->getKey(),
            'old_values' => $oldValues,
            'new_values' => $newValues,
        ]);

        return $revision;
    }
}
