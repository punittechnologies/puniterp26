<?php

namespace Tests\Feature;

use App\Domain\Labels\Services\LabelTemplateService;
use App\Models\Permission;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PhaseThreeLabelTemplateTest extends TestCase
{
    use RefreshDatabase;

    public function test_label_template_crud_requires_tenant_and_valid_json(): void
    {
        [$tenant, $token] = $this->tenantToken();

        $this->withToken($token)->withHeader('X-Tenant-Id', $tenant->id)->postJson('/api/v1/label-templates', [
            'name' => '75x75 Product',
            'code' => 'LBL-75',
            'scope' => 'tenant',
            'is_default' => true,
            'template_json' => $this->templateJson(),
        ])->assertCreated()->assertJsonPath('data.code', 'LBL-75');

        $this->withToken($token)->withHeader('X-Tenant-Id', $tenant->id)->postJson('/api/v1/label-templates', [
            'name' => 'Bad',
            'code' => 'BAD',
            'scope' => 'tenant',
            'template_json' => ['widthMm' => 75, 'heightMm' => 75, 'elements' => [['type' => 'bad']]],
        ])->assertUnprocessable();
    }

    public function test_effective_template_resolution_prefers_variant_product_tenant_system(): void
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => 'TEN', 'status' => 'active']);
        $product = Product::query()->create(['tenant_id' => $tenant->id, 'name' => 'Pipe', 'product_code' => 'PIPE']);
        $variant = ProductVariant::query()->create(['tenant_id' => $tenant->id, 'product_id' => $product->id, 'name' => 'Blue', 'variant_code' => 'PIPE-B']);
        $service = app(LabelTemplateService::class);

        $service->create(['name' => 'Tenant', 'code' => 'TENANT', 'scope' => 'tenant', 'is_default' => true, 'template_json' => $this->templateJson('tenant')], $tenant->id);
        $service->create(['name' => 'Product', 'code' => 'PRODUCT', 'scope' => 'product', 'product_id' => $product->id, 'template_json' => $this->templateJson('product')], $tenant->id);
        $variantTemplate = $service->create(['name' => 'Variant', 'code' => 'VARIANT', 'scope' => 'variant', 'product_id' => $product->id, 'variant_id' => $variant->id, 'template_json' => $this->templateJson('variant')], $tenant->id);

        $this->assertSame($variantTemplate->id, $service->effective($tenant->id, $product->id, $variant->id)->id);
    }

    public function test_rollback_reactivates_previous_template_json(): void
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => 'TEN', 'status' => 'active']);
        $service = app(LabelTemplateService::class);
        $template = $service->create(['name' => 'Label', 'code' => 'LBL', 'scope' => 'tenant', 'template_json' => $this->templateJson('v1')], $tenant->id);
        $service->update($template, ['template_json' => $this->templateJson('v2')]);
        $rolledBack = $service->rollback($template->fresh(), 1);

        $this->assertSame('v1', $rolledBack->template_json['elements'][0]['text']);
        $this->assertSame(3, $rolledBack->active_version);
    }

    private function tenantToken(): array
    {
        $tenant = Tenant::query()->create(['name' => 'Tenant', 'code' => 'TEN'.random_int(100, 999), 'status' => 'active']);
        $permissions = collect(['label_templates.manage', 'label_templates.view', 'label_templates.rollback'])->map(fn ($key) => Permission::query()->firstOrCreate(['key' => $key], ['name' => $key, 'module' => 'labels']));
        $role = Role::query()->create(['tenant_id' => $tenant->id, 'name' => 'Admin', 'key' => 'admin']);
        $role->permissions()->sync($permissions->pluck('id'));
        $user = User::query()->create(['tenant_id' => $tenant->id, 'name' => 'Admin', 'email' => fake()->unique()->safeEmail(), 'password' => Hash::make('password'), 'is_active' => true]);
        $user->roles()->attach($role);

        return [$tenant, $user->createToken('test')->plainTextToken];
    }

    private function templateJson(string $text = 'Product'): array
    {
        return [
            'widthMm' => 75,
            'heightMm' => 75,
            'elements' => [
                ['key' => 'txt', 'type' => 'text', 'text' => $text, 'x' => 5, 'y' => 5, 'width' => 40, 'height' => 10],
            ],
        ];
    }
}
