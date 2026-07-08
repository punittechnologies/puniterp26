<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();
        $permissions = explode('|', $permission);

        if (! $user || ! collect($permissions)->contains(fn (string $key): bool => $user->hasPermission($key))) {
            abort(403, 'Missing permission: '.implode(' or ', $permissions));
        }

        return $next($request);
    }
}
