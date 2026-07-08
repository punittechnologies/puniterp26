<?php

namespace Database\Seeders;

use App\Models\ConfigurationSchema;
use App\Models\Labeling\LabelTemplate;
use App\Models\Permission;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductCategory;
use App\Models\ProductConfiguration\Unit;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use App\Models\Warehouse;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::query()->firstOrCreate(
            ['code' => 'PUNIT-DEMO'],
            [
                'name' => 'Punit Demo Industries',
                'status' => 'active',
                'settings' => [
                    'numberFormat' => 'en_IN',
                    'dateFormat' => 'd-m-Y',
                    'weightPrecision' => 3,
                ],
            ],
        );

        Warehouse::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'code' => 'MAIN'],
            ['name' => 'Main Warehouse', 'is_active' => true],
        );

        $permissions = collect([
            ['key' => 'dashboard.view', 'name' => 'View dashboard', 'module' => 'dashboard'],
            ['key' => 'app.login', 'name' => 'Login to tablet app', 'module' => 'app'],
            ['key' => 'users.manage', 'name' => 'Manage users', 'module' => 'users'],
            ['key' => 'roles.manage', 'name' => 'Manage roles', 'module' => 'roles'],
            ['key' => 'devices.configure', 'name' => 'Configure devices', 'module' => 'devices'],
            ['key' => 'configuration.manage', 'name' => 'Manage configuration', 'module' => 'configuration'],
            ['key' => 'configuration.approve', 'name' => 'Approve configuration changes', 'module' => 'configuration'],
            ['key' => 'products.view', 'name' => 'View products', 'module' => 'products'],
            ['key' => 'products.create', 'name' => 'Create products', 'module' => 'products'],
            ['key' => 'products.edit', 'name' => 'Edit products', 'module' => 'products'],
            ['key' => 'products.delete', 'name' => 'Delete products', 'module' => 'products'],
            ['key' => 'categories.manage', 'name' => 'Manage categories', 'module' => 'products'],
            ['key' => 'attributes.manage', 'name' => 'Manage attributes', 'module' => 'products'],
            ['key' => 'variants.manage', 'name' => 'Manage variants', 'module' => 'products'],
            ['key' => 'dynamic_fields.manage', 'name' => 'Manage dynamic fields', 'module' => 'products'],
            ['key' => 'units.manage', 'name' => 'Manage units', 'module' => 'products'],
            ['key' => 'conversion_rules.manage', 'name' => 'Manage conversion rules', 'module' => 'products'],
            ['key' => 'weight_rules.manage', 'name' => 'Manage weight rules', 'module' => 'products'],
            ['key' => 'product_device_assignments.manage', 'name' => 'Manage product-device assignments', 'module' => 'products'],
            ['key' => 'configuration.history.view', 'name' => 'View configuration history', 'module' => 'products'],
            ['key' => 'products.export', 'name' => 'Export products', 'module' => 'products'],
            ['key' => 'label_templates.view', 'name' => 'View label templates', 'module' => 'labels'],
            ['key' => 'label_templates.manage', 'name' => 'Manage label templates', 'module' => 'labels'],
            ['key' => 'label_templates.rollback', 'name' => 'Roll back label templates', 'module' => 'labels'],
            ['key' => 'customers.manage', 'name' => 'Manage customers', 'module' => 'customers'],
            ['key' => 'inventory.view', 'name' => 'View inventory', 'module' => 'inventory'],
            ['key' => 'production.capture', 'name' => 'Capture production', 'module' => 'production'],
            ['key' => 'dispatch.confirm', 'name' => 'Confirm dispatch', 'module' => 'dispatch'],
            ['key' => 'reports.view', 'name' => 'View reports', 'module' => 'reports'],
        ])->mapWithKeys(fn (array $permission) => [
            $permission['key'] => Permission::query()->firstOrCreate(['key' => $permission['key']], $permission),
        ]);

        $role = Role::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'key' => 'company-admin'],
            ['name' => 'Company Admin', 'is_system' => true],
        );
        $role->permissions()->sync($permissions->pluck('id'));

        $user = User::query()->firstOrCreate(
            ['email' => 'admin@punit.test'],
            [
                'tenant_id' => $tenant->id,
                'name' => 'Punit Admin',
                'password' => Hash::make('password'),
                'is_active' => true,
            ],
        );
        $user->forceFill(['phone' => $user->phone ?: '9737599004'])->save();
        $user->roles()->syncWithoutDetaching([$role->id]);

        User::query()->updateOrCreate(
            ['email' => 'super@punit.test'],
            [
                'tenant_id' => $tenant->id,
                'name' => 'Punit Super Admin',
                'phone' => '9004900040',
                'password' => Hash::make('password'),
                'is_active' => true,
            ],
        )->roles()->syncWithoutDetaching([$role->id]);

        ConfigurationSchema::query()->firstOrCreate(
            ['key' => 'tenant.general'],
            [
                'name' => 'Tenant General Settings',
                'module' => 'configuration',
                'schema' => [
                    'type' => 'object',
                    'required' => ['companyName'],
                    'properties' => [
                        'companyName' => ['type' => 'string'],
                        'logoPath' => ['type' => ['string', 'null']],
                        'dateFormat' => ['type' => 'string'],
                        'numberFormat' => ['type' => 'string'],
                    ],
                ],
                'is_active' => true,
            ],
        );

        $kg = Unit::query()->firstOrCreate(
            ['tenant_id' => null, 'symbol' => 'kg', 'category' => 'weight'],
            ['name' => 'Kilogram', 'conversion_factor_to_base' => 1, 'decimal_precision' => 3, 'is_system' => true, 'is_active' => true],
        );
        Unit::query()->firstOrCreate(['tenant_id' => null, 'symbol' => 'g', 'category' => 'weight'], ['name' => 'Gram', 'conversion_factor_to_base' => 0.001, 'decimal_precision' => 3, 'is_system' => true, 'is_active' => true]);
        Unit::query()->firstOrCreate(['tenant_id' => null, 'symbol' => 'pcs', 'category' => 'quantity'], ['name' => 'Pieces', 'conversion_factor_to_base' => 1, 'decimal_precision' => 0, 'is_system' => true, 'is_active' => true]);

        $category = ProductCategory::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'code' => 'RAW'],
            ['name' => 'Raw Material', 'is_active' => true],
        );

        Product::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'product_code' => 'DEMO-ROD'],
            [
                'category_id' => $category->id,
                'default_weight_unit_id' => $kg->id,
                'default_inventory_unit_id' => $kg->id,
                'name' => 'Demo Steel Rod',
                'sku' => 'DEMO-ROD',
                'default_tare_weight' => 0,
                'minimum_weight' => 1,
                'maximum_weight' => 100,
                'target_weight' => 25,
                'is_active' => true,
                'configuration_activated_at' => now(),
            ],
        );

        $fallbackJson = [
            'widthMm' => 75,
            'heightMm' => 75,
            'gridMm' => 2.5,
            'elements' => [
                ['key' => 'product_name', 'type' => 'binding_text', 'bindingKey' => 'product.name', 'x' => 5, 'y' => 5, 'width' => 65, 'height' => 10, 'style' => ['fontSize' => 12, 'fontWeight' => 'bold']],
                ['key' => 'net_weight', 'type' => 'binding_text', 'bindingKey' => 'weight.net', 'x' => 5, 'y' => 20, 'width' => 35, 'height' => 10, 'prefix' => 'Net: '],
                ['key' => 'barcode', 'type' => 'barcode', 'bindingKey' => 'barcode.value', 'x' => 5, 'y' => 40, 'width' => 55, 'height' => 20],
            ],
        ];

        LabelTemplate::query()->firstOrCreate(
            ['tenant_id' => null, 'code' => 'SYSTEM-FALLBACK'],
            [
                'name' => 'System Fallback 75x75',
                'scope' => 'system',
                'width_mm' => 75,
                'height_mm' => 75,
                'is_default' => true,
                'is_active' => true,
                'template_json' => $fallbackJson,
            ],
        );

        LabelTemplate::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'code' => 'TENANT-DEFAULT'],
            [
                'name' => 'Tenant Default 75x75',
                'scope' => 'tenant',
                'width_mm' => 75,
                'height_mm' => 75,
                'is_default' => true,
                'is_active' => true,
                'template_json' => $fallbackJson,
                'created_by' => $user->id,
            ],
        );
    }
}
