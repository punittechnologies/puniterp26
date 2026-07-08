<?php

namespace App\Http\Middleware;

use App\Models\Tenant;
use App\Support\TenantContext;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureTenantContext
{
    public function __construct(private readonly TenantContext $tenantContext) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $tenantId = $request->header('X-Tenant-Id') ?: $user?->tenant_id;

        if (! $tenantId) {
            abort(422, 'Tenant context is required.');
        }

        if ($user?->tenant_id && $user->tenant_id !== $tenantId) {
            abort(403, 'Tenant mismatch.');
        }

        $tenant = Tenant::query()->whereKey($tenantId)->where('status', 'active')->firstOrFail();
        $this->tenantContext->set($tenant);

        return $next($request);
    }
}
