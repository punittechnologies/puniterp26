<?php

namespace Tests\Feature;

use App\Domain\Labels\Services\LabelBindingRegistry;
use App\Models\Permission;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductBatch;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProductBatchModuleTest extends TestCase
{
    use RefreshDatabase;

    public function test_company_admin_can_create_a_multi_product_batch_and_existing_label_bindings_include_batch(): void
    {
        [$tenant, $user] = $this->tenantUser();
        $first = $this->product($tenant, 'Cable A', 'CABLE-A');
        $second = $this->product($tenant, 'Cable B', 'CABLE-B');
        $field = $this->field($tenant, 'Colour', 'colour');

        $this->actingAs($user)
            ->get('/batches')
            ->assertOk()
            ->assertSee('Create product batch');

        $this->actingAs($user)
            ->post('/batches', [
                'batch_name' => 'July Batch',
                'items' => [
                    [
                        'product_id' => $first->id,
                        'details' => [['field_id' => $field->id, 'value' => 'Red']],
                    ],
                    [
                        'product_id' => $second->id,
                        'details' => [['field_id' => $field->id, 'value' => 'Blue']],
                    ],
                ],
            ])
            ->assertRedirect()
            ->assertSessionHas('status');

        $batch = ProductBatch::query()->firstOrFail();
        $this->assertSame($tenant->id, $batch->tenant_id);
        $this->assertSame('July Batch', $batch->batch_name);
        $this->assertCount(2, $batch->batch_items);
        $this->assertSame('Red', data_get($batch->batch_items, '0.details.colour.value'));
        $this->assertContains(
            'batch.number',
            app(LabelBindingRegistry::class)->keys($tenant->id),
        );
    }

    public function test_batch_sync_is_tenant_scoped_and_included_in_product_sync(): void
    {
        [$tenant, $user] = $this->tenantUser();
        [$otherTenant] = $this->tenantUser();
        $product = $this->product($tenant, 'Own Product', 'OWN');
        $otherProduct = $this->product($otherTenant, 'Other Product', 'OTHER');
        $this->batch($tenant, $product, 'Own Batch');
        $this->batch($otherTenant, $otherProduct, 'Other Batch');
        $token = $user->createToken('batch-test')->plainTextToken;

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/sync/batches')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Own Batch')
            ->assertJsonMissing(['name' => 'Other Batch']);

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->getJson('/api/v1/sync/products')
            ->assertOk()
            ->assertJsonCount(1, 'batches')
            ->assertJsonPath('batches.0.name', 'Own Batch')
            ->assertJsonMissing(['name' => 'Other Batch']);
    }

    private function tenantUser(): array
    {
        $tenant = Tenant::query()->create([
            'name' => 'Batch Tenant '.str()->random(6),
            'code' => 'BAT-'.str()->upper(str()->random(8)),
            'status' => 'active',
        ]);
        $permission = Permission::query()->firstOrCreate(
            ['key' => 'products.view'],
            ['name' => 'View products', 'module' => 'products'],
        );
        $appPermission = Permission::query()->firstOrCreate(
            ['key' => 'app.login'],
            ['name' => 'App login', 'module' => 'foundation'],
        );
        $role = Role::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Batch Manager',
            'key' => 'batch-manager-'.str()->lower(str()->random(6)),
        ]);
        $role->permissions()->attach([$permission->id, $appPermission->id]);
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Batch User',
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->roles()->attach($role);

        return [$tenant, $user];
    }

    private function product(Tenant $tenant, string $name, string $code): Product
    {
        return Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => $name,
            'product_code' => $code,
            'is_active' => true,
        ]);
    }

    private function field(Tenant $tenant, string $label, string $key): DynamicFieldDefinition
    {
        return DynamicFieldDefinition::query()->create([
            'tenant_id' => $tenant->id,
            'field_label' => $label,
            'internal_key' => $key,
            'entity_type' => 'product_variant',
            'data_type' => 'text',
            'visible_in_flutter' => true,
            'is_active' => true,
        ]);
    }

    private function batch(Tenant $tenant, Product $product, string $name): ProductBatch
    {
        $details = ['colour' => ['label' => 'Colour', 'value' => 'Red']];

        return ProductBatch::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'batch_name' => $name,
            'attribute_key' => 'colour',
            'attribute_label' => 'Colour',
            'attribute_value' => 'Red',
            'detail_values' => $details,
            'batch_items' => [[
                'product_id' => $product->id,
                'product_name' => $product->name,
                'details' => $details,
            ]],
            'detail_signature' => md5($tenant->id.$name),
            'is_active' => true,
        ]);
    }
}
