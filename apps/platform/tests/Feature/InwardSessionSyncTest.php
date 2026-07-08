<?php

namespace Tests\Feature;

use App\Models\BarcodeRecord;
use App\Models\Customer;
use App\Models\DispatchItem;
use App\Models\InventoryTransaction;
use App\Models\InwardSession;
use App\Models\Permission;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductionTransaction;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class InwardSessionSyncTest extends TestCase
{
    use RefreshDatabase;

    public function test_tablet_can_sync_finished_inward_session_and_production_entries(): void
    {
        [$tenant, $token] = $this->tenantToken(['production.capture']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Wire',
            'product_code' => 'WIRE',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);

        $sessionId = fake()->uuid();
        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/sync/inward_session', [
                'id' => $sessionId,
                'session_number' => 'INW-TEST-001',
                'status' => 'saved',
                'entry_count' => 1,
                'total_gross_weight' => 12.5,
                'total_tare_weight' => 0.5,
                'total_net_weight' => 12,
                'started_at' => now()->subMinute()->toISOString(),
                'ended_at' => now()->toISOString(),
            ])
            ->assertOk()
            ->assertJsonPath('session_number', 'INW-TEST-001');

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->withHeader('Idempotency-Key', 'idem-prod-inw-1')
            ->postJson('/api/v1/sync/production_transaction', [
                'id' => 'local-prod-1',
                'product_id' => $product->id,
                'inward_session_id' => $sessionId,
                'inward_session_number' => 'INW-TEST-001',
                'inward_session_status' => 'saved',
                'serial_number' => 'SER-INW-1',
                'barcode_value' => 'BAR-INW-1',
                'gross_weight' => 12.5,
                'tare_weight' => 0.5,
                'net_weight' => 12,
                'piece_quantity' => 24,
                'captured_at' => now()->toISOString(),
            ])
            ->assertOk();

        $session = InwardSession::query()->where('tenant_id', $tenant->id)->where('id', $sessionId)->firstOrFail();
        $this->assertSame('saved', $session->status);
        $this->assertSame(1, $session->entry_count);
        $this->assertSame('12.000000', (string) $session->total_net_weight);
    }

    public function test_repeated_inward_session_sync_updates_same_record(): void
    {
        [$tenant, $token] = $this->tenantToken(['production.capture']);
        $sessionId = fake()->uuid();

        foreach ([1, 2] as $count) {
            $this->withToken($token)
                ->withHeader('X-Tenant-Id', $tenant->id)
                ->postJson('/api/v1/sync/inward_session', [
                    'id' => $sessionId,
                    'session_number' => 'INW-RACE-001',
                    'status' => 'saved',
                    'entry_count' => $count,
                    'total_gross_weight' => $count * 10,
                    'total_net_weight' => $count * 9,
                    'started_at' => now()->subMinute()->toISOString(),
                    'ended_at' => now()->toISOString(),
                ])
                ->assertOk();
        }

        $this->assertSame(1, InwardSession::query()->where('tenant_id', $tenant->id)->where('session_number', 'INW-RACE-001')->count());
        $this->assertSame(2, InwardSession::query()->where('tenant_id', $tenant->id)->where('session_number', 'INW-RACE-001')->value('entry_count'));
    }

    public function test_duplicate_production_sync_is_idempotent(): void
    {
        [$tenant, $token] = $this->tenantToken(['production.capture']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Sheet',
            'product_code' => 'SHEET',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);
        $payload = [
            'id' => 'local-prod-idem-1',
            'product_id' => $product->id,
            'serial_number' => 'SER-IDEM-1',
            'barcode_value' => 'BAR-IDEM-1',
            'gross_weight' => 20,
            'tare_weight' => 1,
            'net_weight' => 19,
            'captured_at' => now()->toISOString(),
        ];

        foreach ([1, 2] as $_) {
            $this->withToken($token)
                ->withHeader('X-Tenant-Id', $tenant->id)
                ->withHeader('Idempotency-Key', 'idem-prod-repeat')
                ->postJson('/api/v1/sync/production_transaction', $payload)
                ->assertOk();
        }

        $this->assertSame(1, ProductionTransaction::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-IDEM-1')->count());
        $this->assertSame(1, BarcodeRecord::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-IDEM-1')->count());
        $this->assertSame(1, InventoryTransaction::query()->where('tenant_id', $tenant->id)->where('reference_type', 'production')->count());
    }

    public function test_dispatch_rejects_already_dispatched_barcode_without_server_error(): void
    {
        [$tenant, $token] = $this->tenantToken(['production.capture', 'dispatch.confirm']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Roll',
            'product_code' => 'ROLL',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);
        $customer = Customer::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Buyer',
            'code' => 'BUYER',
            'is_active' => true,
        ]);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->withHeader('Idempotency-Key', 'idem-prod-dispatch')
            ->postJson('/api/v1/sync/production_transaction', [
                'id' => 'local-prod-dispatch-1',
                'product_id' => $product->id,
                'serial_number' => 'SER-DSP-1',
                'barcode_value' => 'BAR-DSP-1',
                'gross_weight' => 15,
                'tare_weight' => 0,
                'net_weight' => 15,
                'captured_at' => now()->toISOString(),
            ])
            ->assertOk();

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->withHeader('Idempotency-Key', 'idem-dispatch-1')
            ->postJson('/api/v1/sync/dispatch', [
                'id' => 'local-dispatch-1',
                'customer_id' => $customer->id,
                'dispatch_number' => 'DSP-TEST-1',
                'barcodes' => ['BAR-DSP-1'],
                'confirmed_at' => now()->toISOString(),
            ])
            ->assertOk();

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->withHeader('Idempotency-Key', 'idem-dispatch-2')
            ->postJson('/api/v1/sync/dispatch', [
                'id' => 'local-dispatch-2',
                'customer_id' => $customer->id,
                'dispatch_number' => 'DSP-TEST-2',
                'barcodes' => ['BAR-DSP-1'],
                'confirmed_at' => now()->toISOString(),
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('barcode');

        $this->assertSame(1, DispatchItem::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-DSP-1')->count());
    }

    public function test_dispatch_lookup_repairs_missing_barcode_record_from_synced_production(): void
    {
        [$tenant, $token] = $this->tenantToken(['dispatch.confirm']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Repair Roll',
            'product_code' => 'REPAIR',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);
        $production = ProductionTransaction::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'serial_number' => 'SER-REPAIR-1',
            'barcode_value' => 'BAR-REPAIR-1',
            'product_snapshot' => ['product' => ['name' => 'Repair Roll']],
            'gross_weight' => 9,
            'tare_weight' => 0,
            'net_weight' => 9,
            'captured_at' => now(),
        ]);

        $this->assertSame(0, BarcodeRecord::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-REPAIR-1')->count());

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/dispatch/barcodes/BAR-REPAIR-1')
            ->assertOk()
            ->assertJsonPath('data.id', $production->id)
            ->assertJsonPath('data.barcode_value', 'BAR-REPAIR-1');

        $this->assertSame(1, BarcodeRecord::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-REPAIR-1')->count());
    }

    public function test_repeated_dispatch_sync_with_same_idempotency_is_safe(): void
    {
        [$tenant, $token] = $this->tenantToken(['production.capture', 'dispatch.confirm']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Bag',
            'product_code' => 'BAG',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);
        $customer = Customer::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Retailer',
            'code' => 'RET',
            'is_active' => true,
        ]);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->withHeader('Idempotency-Key', 'idem-prod-repeat-dispatch')
            ->postJson('/api/v1/sync/production_transaction', [
                'id' => 'local-prod-repeat-dispatch',
                'product_id' => $product->id,
                'serial_number' => 'SER-REP-DSP',
                'barcode_value' => 'BAR-REP-DSP',
                'gross_weight' => 8,
                'tare_weight' => 0,
                'net_weight' => 8,
                'captured_at' => now()->toISOString(),
            ])
            ->assertOk();

        $payload = [
            'id' => 'local-dispatch-repeat',
            'customer_id' => $customer->id,
            'dispatch_number' => 'DSP-REPEAT-1',
            'barcodes' => ['BAR-REP-DSP'],
            'confirmed_at' => now()->toISOString(),
        ];

        foreach ([1, 2] as $_) {
            $this->withToken($token)
                ->withHeader('X-Tenant-Id', $tenant->id)
                ->withHeader('Idempotency-Key', 'idem-dispatch-repeat')
                ->postJson('/api/v1/sync/dispatch', $payload)
                ->assertOk();
        }

        $this->assertSame(1, DispatchItem::query()->where('tenant_id', $tenant->id)->where('barcode_value', 'BAR-REP-DSP')->count());
    }

    private function tenantToken(array $permissionKeys): array
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => fake()->unique()->lexify('TEN???'), 'status' => 'active']);
        $permissions = collect($permissionKeys)->map(fn (string $key) => Permission::query()->firstOrCreate(
            ['key' => $key],
            ['name' => str($key)->headline()->toString(), 'module' => str($key)->before('.')->toString()]
        ));
        $role = Role::query()->create(['tenant_id' => $tenant->id, 'name' => 'Admin', 'key' => 'admin']);
        $role->permissions()->sync($permissions->pluck('id'));
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Admin',
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->roles()->attach($role);

        return [$tenant, $user->createToken('test')->plainTextToken];
    }
}
