<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'tenantId' => $this->tenant_id,
            'name' => $this->name,
            'email' => $this->email,
            'appUsername' => $this->app_username,
            'appOnly' => (bool) $this->app_only,
            'tenant' => $this->whenLoaded('tenant', fn () => [
                'id' => $this->tenant->id,
                'name' => $this->tenant->name,
                'code' => $this->tenant->code,
            ]),
            'roles' => $this->whenLoaded('roles', fn () => $this->roles->map(fn ($role) => [
                'key' => $role->key,
                'name' => $role->name,
                'permissions' => $role->permissions->pluck('key')->values(),
            ])->values()),
        ];
    }
}
