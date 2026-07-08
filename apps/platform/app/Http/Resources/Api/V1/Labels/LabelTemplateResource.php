<?php

namespace App\Http\Resources\Api\V1\Labels;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LabelTemplateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'tenantId' => $this->tenant_id,
            'productId' => $this->product_id,
            'variantId' => $this->variant_id,
            'name' => $this->name,
            'code' => $this->code,
            'scope' => $this->scope,
            'widthMm' => $this->width_mm,
            'heightMm' => $this->height_mm,
            'isCustomSize' => $this->is_custom_size,
            'isDefault' => $this->is_default,
            'isActive' => $this->is_active,
            'isArchived' => $this->is_archived,
            'activeVersion' => $this->active_version,
            'templateJson' => $this->template_json,
            'warnings' => $this->warnings ?? [],
            'updatedAt' => $this->updated_at?->toISOString(),
        ];
    }
}
