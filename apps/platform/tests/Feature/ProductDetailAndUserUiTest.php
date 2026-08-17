<?php

namespace Tests\Feature;

use App\Livewire\Products\ProductDetailsManager;
use App\Models\Permission;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Livewire\Livewire;
use Tests\TestCase;

class ProductDetailAndUserUiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_add_multiple_values_to_an_existing_product_detail_field(): void
    {
        [$tenant, $admin] = $this->tenantUser();
        $field = DynamicFieldDefinition::query()->create([
            'tenant_id' => $tenant->id,
            'field_label' => 'Color',
            'internal_key' => 'color',
            'entity_type' => 'product_variant',
            'data_type' => 'dropdown',
            'dropdown_options' => [['label' => 'Black', 'value' => 'black']],
            'is_active' => true,
        ]);

        Livewire::actingAs($admin)
            ->test(ProductDetailsManager::class)
            ->set('optionInputs.'.$field->id, "Red, Blue\nGreen, Red")
            ->call('addOption', $field->id)
            ->assertSet('optionInputs.'.$field->id, '');

        $this->assertSame(
            ['black', 'red', 'blue', 'green'],
            collect($field->fresh()->dropdown_options)->pluck('value')->all(),
        );
    }

    public function test_user_edit_shows_a_typed_password_toggle_without_exposing_the_saved_password(): void
    {
        [$tenant, $admin] = $this->tenantUser();
        $operator = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Operator',
            'app_username' => 'operator01',
            'email' => 'operator@example.test',
            'password' => Hash::make('secret12'),
            'app_only' => true,
            'is_active' => true,
        ]);

        $this->actingAs($admin)
            ->get('/app-users?edit='.$operator->id)
            ->assertOk()
            ->assertSee('Show typed password')
            ->assertSee('the saved password cannot be viewed')
            ->assertDontSee('secret12');
    }

    private function tenantUser(): array
    {
        $tenant = Tenant::query()->create([
            'name' => 'UI Test Tenant',
            'code' => 'UI-TEST',
            'status' => 'active',
        ]);
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Admin',
            'email' => 'admin@example.test',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $permission = Permission::query()->create([
            'name' => 'Manage users',
            'key' => 'users.manage',
            'module' => 'users',
        ]);
        $role = Role::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Company Admin',
            'key' => 'company-admin',
            'is_system' => true,
        ]);
        $role->permissions()->sync([$permission->id]);
        $user->roles()->sync([$role->id]);

        return [$tenant, $user];
    }
}
