<?php

namespace Tests\Feature;

use App\Models\Permission;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class FoundationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_and_fetch_sync_bootstrap_for_their_tenant(): void
    {
        $tenant = Tenant::query()->create([
            'name' => 'Demo Tenant',
            'code' => 'DEMO',
            'status' => 'active',
        ]);

        $permission = Permission::query()->create([
            'key' => 'dashboard.view',
            'name' => 'View dashboard',
            'module' => 'dashboard',
        ]);
        $appPermission = Permission::query()->firstOrCreate(
            ['key' => 'app.login'],
            ['name' => 'Login to tablet app', 'module' => 'app'],
        );

        $role = Role::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Company Admin',
            'key' => 'company-admin',
            'is_system' => true,
        ]);
        $role->permissions()->attach([$permission->id, $appPermission->id]);

        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'App Operator',
            'email' => 'operator@example.test',
            'app_username' => 'operator01',
            'app_only' => true,
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->roles()->attach($role);

        $login = $this->postJson('/api/v1/auth/login', [
            'login' => 'operator01',
            'password' => 'password',
            'device_name' => 'tablet-test',
        ]);

        $login->assertOk()
            ->assertJsonPath('user.tenantId', $tenant->id)
            ->assertJsonStructure(['access_token']);

        $token = $login->json('access_token');

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/sync/bootstrap')
            ->assertOk()
            ->assertJsonPath('tenantId', $tenant->id)
            ->assertJsonPath('features.products', true)
            ->assertJsonPath('features.tvsPrinter', false);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/auth/confirm-password', [
                'password' => 'password',
                'action' => 'label_serial.updated',
                'old_values' => ['next_number' => '1'],
                'new_values' => ['prefix' => 'SPM-', 'next_number' => '3000'],
            ])
            ->assertOk()
            ->assertJsonPath('confirmed', true);

        $this->assertDatabaseHas('audit_logs', [
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'action' => 'label_serial.updated',
        ]);
    }
}
