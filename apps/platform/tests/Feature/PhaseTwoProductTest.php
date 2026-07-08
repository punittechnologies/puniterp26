<?php

namespace Tests\Feature;

use App\Domain\Products\Services\ConversionCalculator;
use App\Domain\Products\Services\EffectiveProductConfigurationService;
use App\Livewire\Products\ProductManager;
use App\Models\Permission;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductConfiguration\Unit;
use App\Models\ProductConfiguration\UnitConversionRule;
use App\Models\ProductionTransaction;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Livewire\Livewire;
use Tests\TestCase;

class PhaseTwoProductTest extends TestCase
{
    use RefreshDatabase;

    public function test_product_creation_is_tenant_scoped_and_duplicate_codes_are_blocked(): void
    {
        [$tenant, $token] = $this->tenantToken();

        $this->withToken($token)->withHeader('X-Tenant-Id', $tenant->id)->postJson('/api/v1/products', [
            'name' => 'Steel Coil',
            'product_code' => 'COIL',
            'default_tare_weight' => 0,
        ])->assertCreated();

        $this->withToken($token)->withHeader('X-Tenant-Id', $tenant->id)->postJson('/api/v1/products', [
            'name' => 'Steel Coil Duplicate',
            'product_code' => 'COIL',
        ])->assertUnprocessable();
    }

    public function test_web_product_can_be_recreated_after_delete_with_same_name(): void
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => fake()->unique()->lexify('TEN???'), 'status' => 'active']);
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Admin',
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);

        $this->actingAs($user);

        Livewire::test(ProductManager::class)
            ->set('form.name', 'BULIDING ROLL')
            ->call('saveProduct')
            ->call('deleteProduct', Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->firstOrFail()->id)
            ->set('form.name', 'BULIDING ROLL')
            ->call('saveProduct')
            ->assertHasNoErrors();

        $this->assertSame(1, Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->count());
        $this->assertSame(1, Product::withTrashed()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->count());
        $this->assertSame('BULIDING-ROLL', Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->firstOrFail()->product_code);
    }

    public function test_web_product_can_be_recreated_after_deleted_product_has_history(): void
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => fake()->unique()->lexify('TEN???'), 'status' => 'active']);
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Admin',
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);

        $this->actingAs($user);

        Livewire::test(ProductManager::class)
            ->set('form.name', 'BULIDING ROLL')
            ->call('saveProduct')
            ->assertHasNoErrors();

        $product = Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->firstOrFail();
        ProductionTransaction::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'serial_number' => 'SER-1',
            'barcode_value' => 'BAR-1',
            'product_snapshot' => ['name' => $product->name],
            'gross_weight' => '1.000',
            'tare_weight' => '0.000',
            'net_weight' => '1.000',
            'captured_at' => now(),
        ]);

        Livewire::test(ProductManager::class)
            ->call('deleteProduct', $product->id)
            ->set('form.name', 'BULIDING ROLL')
            ->call('saveProduct')
            ->assertHasNoErrors();

        $this->assertSame(1, Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->count());
        $this->assertSame('BULIDING-ROLL', Product::query()->where('tenant_id', $tenant->id)->where('name', 'BULIDING ROLL')->firstOrFail()->product_code);
        $this->assertSame(1, Product::onlyTrashed()->where('tenant_id', $tenant->id)->where('name', 'like', 'Deleted product %')->count());
    }

    public function test_variant_effective_values_inherit_from_product(): void
    {
        $tenant = Tenant::query()->create(['name' => 'T', 'code' => 'T', 'status' => 'active']);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Rod',
            'product_code' => 'ROD',
            'default_tare_weight' => '2.000',
            'minimum_weight' => '10.000',
            'maximum_weight' => '20.000',
        ]);
        $variant = ProductVariant::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'name' => 'Blue',
            'variant_code' => 'ROD-BLUE',
            'tare_weight' => null,
        ]);

        $effective = app(EffectiveProductConfigurationService::class)->effectiveValues($product, $variant);

        $this->assertSame('2.000', (string) $effective['tare_weight']);
        $this->assertSame('10.000', (string) $effective['minimum_weight']);
    }

    public function test_conversion_methods_and_rounding_are_deterministic(): void
    {
        $calculator = app(ConversionCalculator::class);

        $this->assertSame('5', $calculator->calculate('10', [
            'method' => 'weight_per_piece',
            'weight_per_piece' => '2',
            'rounding_method' => 'nearest',
            'decimal_places' => 0,
        ])['rounded_quantity']);

        $this->assertSame('31', $calculator->calculate('10.25', [
            'method' => 'pieces_per_kg',
            'pieces_per_kg' => '3',
            'rounding_method' => 'nearest',
            'decimal_places' => 0,
        ])['rounded_quantity']);

        $this->assertSame('9', $calculator->calculate('10', [
            'method' => 'sample_based',
            'sample_weight' => '11',
            'sample_piece_count' => 10,
            'rounding_method' => 'floor',
            'decimal_places' => 0,
        ])['rounded_quantity']);
    }

    public function test_sync_payload_contains_effective_product_configuration(): void
    {
        [$tenant, $token] = $this->tenantToken();
        $kg = Unit::query()->create(['name' => 'Kilogram', 'symbol' => 'kg', 'category' => 'weight', 'conversion_factor_to_base' => 1, 'is_system' => true]);
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'default_weight_unit_id' => $kg->id,
            'name' => 'Pipe',
            'product_code' => 'PIPE',
            'default_tare_weight' => 1,
            'is_active' => true,
        ]);
        UnitConversionRule::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'method' => 'pieces_per_kg',
            'pieces_per_kg' => 2,
            'rounding_method' => 'nearest',
        ]);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/sync/products')
            ->assertOk()
            ->assertJsonPath('products.0.effective.tare_weight', '1.000')
            ->assertJsonPath('products.0.effective.conversion_rule.method', 'pieces_per_kg');
    }

    public function test_sync_payload_does_not_crash_when_old_decimal_values_are_blank(): void
    {
        [$tenant, $token] = $this->tenantToken();
        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Old Dirty Product',
            'product_code' => 'OLD-DIRTY',
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);

        DB::table('products')
            ->where('id', $product->id)
            ->update([
                'default_tare_weight' => '',
                'minimum_weight' => '',
                'maximum_weight' => '',
            ]);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/sync/products')
            ->assertOk()
            ->assertJsonPath('products.0.effective.tare_weight', '0.000');
    }

    private function tenantToken(): array
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => fake()->unique()->lexify('TEN???'), 'status' => 'active']);
        $permissions = collect(['products.view'])->map(fn ($key) => Permission::query()->firstOrCreate(['key' => $key], ['name' => $key, 'module' => 'products']));
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
