<?php

namespace App\Http\Resources\Api\V1\Products;

use App\Domain\Products\Services\EffectiveProductConfigurationService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $effective = app(EffectiveProductConfigurationService::class);

        return [
            ...parent::toArray($request),
            'effective' => $effective->effectiveValues($this->resource),
            'variants' => ProductVariantResource::collection($this->whenLoaded('variants')),
        ];
    }
}
