<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(LoginRequest $request): JsonResponse
    {
        $login = trim((string) ($request->input('login') ?: $request->input('email')));
        $phone = preg_replace('/\D+/', '', $login);
        $user = User::query()
            ->where(function ($query) use ($login, $phone): void {
                $query->where('email', $login);
                $query->orWhere('app_username', $login);
                if ($phone !== '') {
                    $query->orWhere('phone', $phone);
                }
            })
            ->where('is_active', true)
            ->first();

        if (! $user || ! Hash::check($request->input('password'), $user->password)) {
            throw ValidationException::withMessages(['login' => 'Invalid credentials.']);
        }

        if (! $user->app_only || ! $user->hasPermission('app.login')) {
            throw ValidationException::withMessages(['login' => 'This login is not allowed for the tablet app. Ask the web admin to create an app user.']);
        }

        $token = $user->createToken($request->input('device_name', 'api-client'))->plainTextToken;

        return response()->json([
            'token_type' => 'Bearer',
            'access_token' => $token,
            'user' => new UserResource($user->load('tenant', 'roles.permissions')),
        ]);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('tenant', 'roles.permissions'));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function confirmPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'password' => ['required', 'string'],
            'action' => ['required', 'string', 'in:label_serial.updated'],
            'old_values' => ['nullable', 'array'],
            'new_values' => ['required', 'array'],
        ]);
        $user = $request->user();
        if (! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['password' => 'Password is incorrect.']);
        }

        AuditLog::query()->create([
            'tenant_id' => $user->tenant_id,
            'user_id' => $user->id,
            'action' => $data['action'],
            'auditable_type' => User::class,
            'auditable_id' => $user->id,
            'old_values' => $data['old_values'] ?? [],
            'new_values' => $data['new_values'],
            'metadata' => ['source' => 'tablet_app'],
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return response()->json(['confirmed' => true]);
    }
}
