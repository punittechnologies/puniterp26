<?php

namespace App\Http\Resources\Api\V1\Products;

use App\Domain\Products\Services\EffectiveProductConfigurationService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductVariantResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $effective = app(EffectiveProductConfigurationService::class);

        return [
            ...parent::toArray($request),
            'effective' => $this->product ? $effective->effectiveValues($this->product, $this->resource) : null,
        ];
    }
}
