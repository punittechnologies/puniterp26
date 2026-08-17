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
        $cancelProductionId = (string) Str::uuid();
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
            'product_snapshot' => json_encode([]),
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

        DB::table('production_transactions')->insert([
            'id' => $cancelProductionId,
            'tenant_id' => $tenant->id,
            'product_id' => $productId,
            'serial_number' => 'CANCEL-SR-1',
            'barcode_value' => 'CANCEL-BC-1',
            'product_snapshot' => json_encode(['name' => 'Legacy Product']),
            'dynamic_values' => json_encode([]),
            'gross_weight' => 12,
            'tare_weight' => 2,
            'net_weight' => 10,
            'piece_quantity' => 1,
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
        $this->actingAs($admin)->get('/production')
            ->assertOk()
            ->assertSee('Production')
            ->assertSee('<td>Legacy Product</td>', false)
            ->assertDontSee('<td>'.$productId.'</td>', false)
            ->assertDontSee('<label>Variant', false)
            ->assertDontSee('>View</a>', false)
            ->assertSee('/production/'.$productionId.'/cancel', false)
            ->assertSee('>Cancel</button>', false)
            ->assertDontSee('Other Reports');
        $this->actingAs($admin)->post('/production/'.$cancelProductionId.'/cancel', [
            'reason' => 'Cancelled from production transactions list.',
        ])->assertRedirect();
        $this->assertDatabaseHas('production_transactions', [
            'id' => $cancelProductionId,
            'status' => 'cancelled',
        ]);
        $this->assertDatabaseHas('inventory_transactions', [
            'reference_id' => $cancelProductionId,
            'transaction_type' => 'production_cancellation',
        ]);
        $this->actingAs($admin)->get('/dispatch')->assertOk()->assertSee('Dispatch');
        $this->actingAs($admin)->get('/reports/inventory')->assertOk()->assertSee('Inventory Report');
        $this->actingAs($admin)->get('/reports/inventory-ledger')->assertOk();
        $this->actingAs($admin)->get('/reports/audit')->assertOk();
    }

    public function test_admin_can_edit_an_app_user_without_resetting_an_unchanged_password(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/app-users', [
            'access_type' => 'app',
            'name' => 'Scale Operator',
            'app_username' => 'scale01',
            'email' => 'scale01@example.test',
            'password' => 'secret12',
            'password_confirmation' => 'secret12',
            'access_modules' => ['production'],
        ])->assertRedirect();

        $operator = User::query()
            ->where('tenant_id', $tenant->id)
            ->where('app_username', 'scale01')
            ->firstOrFail();
        $passwordBefore = $operator->password;

        $this->actingAs($admin)
            ->get('/app-users?edit='.$operator->id)
            ->assertOk()
            ->assertSee('Edit App User')
            ->assertSee('scale01')
            ->assertSee('Save User Changes');

        $this->actingAs($admin)->patch('/app-users/'.$operator->id, [
            'access_type' => 'web',
            'name' => 'Stores Operator',
            'app_username' => 'stores01',
            'email' => 'stores01@example.test',
            'password' => '',
            'password_confirmation' => '',
            'access_modules' => ['inventory', 'reports'],
        ])->assertRedirect('/app-users');

        $operator->refresh()->load('roles.permissions');
        $this->assertSame('Stores Operator', $operator->name);
        $this->assertSame('stores01', $operator->app_username);
        $this->assertSame('stores01@example.test', $operator->email);
        $this->assertFalse($operator->app_only);
        $this->assertSame($passwordBefore, $operator->password);
        $this->assertEqualsCanonicalizing(
            ['dashboard.view', 'inventory.view', 'reports.view'],
            $operator->roles->flatMap->permissions->pluck('key')->unique()->values()->all(),
        );
    }

    public function test_admin_cannot_edit_an_app_user_from_another_tenant(): void
    {
        [, $admin] = $this->adminUser();
        $otherTenant = Tenant::query()->create([
            'name' => 'Other Tenant',
            'code' => 'OTHER-APP-USERS',
            'status' => 'active',
        ]);
        $otherUser = User::query()->create([
            'tenant_id' => $otherTenant->id,
            'name' => 'Other Operator',
            'app_username' => 'other01',
            'email' => 'other01@example.test',
            'password' => Hash::make('secret12'),
            'app_only' => true,
            'is_active' => true,
        ]);

        $this->actingAs($admin)->patch('/app-users/'.$otherUser->id, [
            'access_type' => 'app',
            'name' => 'Changed',
            'app_username' => 'changed01',
            'email' => 'changed01@example.test',
            'access_modules' => ['production'],
        ])->assertNotFound();

        $this->assertSame('Other Operator', $otherUser->fresh()->name);
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
