<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Permission;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminOperationalPagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_operational_admin_pages_load_with_legacy_blank_decimal_values(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $productId = (string) Str::uuid();
        $productionId = (string) Str::uuid();
        $dispatchId = (string) Str::uuid();
        $dispatchItemId = (string) Str::uuid();
        $customer = Customer::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Test Customer',
            'is_active' => true,
        ]);
        $now = now();

        DB::table('products')->insert([
            'id' => $productId,
            'tenant_id' => $tenant->id,
            'name' => 'Legacy Product',
            'product_code' => 'LEGACY-PRODUCT',
            'is_active' => true,
            'default_tare_weight' => '',
            'minimum_weight' => '',
            'maximum_weight' => '',
            'target_weight' => '',
            'stability_tolerance' => '',
            'reset_threshold' => '',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('production_transactions')->insert([
            'id' => $productionId,
            'tenant_id' => $tenant->id,
            'product_id' => $productId,
            'serial_number' => 'LEGACY-SR-1',
            'barcode_value' => 'LEGACY-BC-1',
            'product_snapshot' => json_encode(['name' => 'Legacy Product']),
            'dynamic_values' => json_encode([]),
            'gross_weight' => '',
            'tare_weight' => '',
            'net_weight' => '',
            'piece_quantity' => '',
            'unit' => 'kg',
            'status' => 'active',
            'sync_status' => 'synced',
            'captured_at' => $now,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('dispatches')->insert([
            'id' => $dispatchId,
            'tenant_id' => $tenant->id,
            'customer_id' => $customer->id,
            'dispatch_number' => 'DSP-LEGACY-1',
            'customer_snapshot' => json_encode(['name' => 'Test Customer']),
            'status' => 'confirmed',
            'total_weight' => '',
            'total_pieces' => '',
            'confirmed_at' => $now,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('dispatch_items')->insert([
            'id' => $dispatchItemId,
            'tenant_id' => $tenant->id,
            'dispatch_id' => $dispatchId,
            'production_transaction_id' => $productionId,
            'barcode_value' => 'LEGACY-BC-1',
            'weight_quantity' => '',
            'piece_quantity' => '',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $this->actingAs($admin)->get('/app-users')->assertOk();
        $this->actingAs($admin)->get('/production')->assertOk()->assertSee('Production');
        $this->actingAs($admin)->get('/dispatch')->assertOk()->assertSee('Dispatch');
    }

    private function adminUser(): array
    {
        $tenant = Tenant::query()->create([
            'name' => 'Admin Tenant',
            'code' => 'ADMIN',
            'status' => 'active',
        ]);

        $permissions = collect(['users.manage', 'production.capture', 'dispatch.confirm', 'reports.view'])
            ->map(fn (string $key) => Permission::query()->firstOrCreate(
                ['key' => $key],
                [
                    'name' => str($key)->replace('.', ' ')->title()->toString(),
                    'module' => str($key)->before('.')->toString(),
                ],
            ));

        $role = Role::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Company Admin',
            'key' => 'company-admin',
            'is_system' => true,
        ]);
        $role->permissions()->sync($permissions->pluck('id'));

        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->roles()->sync([$role->id]);

        return [$tenant, $user];
    }
}
