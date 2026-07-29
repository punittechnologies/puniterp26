<?php

namespace Tests\Feature;

use App\Models\InventoryTransaction;
use App\Models\Permission;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\DynamicFieldValue;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductBatch;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductionTransaction;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminDataRestorationTest extends TestCase
{
    use RefreshDatabase;

    public function test_restored_admin_pages_are_available(): void
    {
        [, $admin] = $this->adminUser();

        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('Import Centre')
            ->assertSee('Product Spreadsheet')
            ->assertSee('Product Details Spreadsheet')
            ->assertSee('Export Current Products');
        $this->actingAs($admin)->get('/export')
            ->assertOk()
            ->assertSee('Export Centre');
        $this->actingAs($admin)->get('/inventory')
            ->assertOk()
            ->assertSee('Inventory Filters')
            ->assertSee('Closing Stock');
        $this->actingAs($admin)->get('/admin/roles')
            ->assertOk()
            ->assertSee('Create Role');
    }

    public function test_product_import_requires_preview_then_confirmation(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $response = $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Product Code,Tare Weight,Unit\nWidget,WID-001,0.125,kg\n",
            ),
        ]);

        $response->assertRedirect('/import');
        $this->assertDatabaseMissing('products', [
            'tenant_id' => $tenant->id,
            'product_code' => 'WID-001',
        ]);
        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('Confirm Product Import')
            ->assertSee('WID-001');

        $this->actingAs($admin)->post('/import/products', ['confirm' => '1'])
            ->assertRedirect('/import');
        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'name' => 'Widget',
            'product_code' => 'WID-001',
        ]);
    }

    public function test_product_import_skips_existing_rows_and_imports_only_new_products(): void
    {
        [$tenant, $admin] = $this->adminUser();
        Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Existing Widget',
            'product_code' => 'WID-001',
            'default_tare_weight' => 9,
            'is_active' => true,
        ]);

        $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Product Code,Tare Weight,Unit,Extra Column\n".
                "Existing Widget,WID-001,99,kg,ignored\n".
                "New Widget,NEW-001,,,ignored\n".
                "New Widget,NEW-001,5,kg,ignored\n",
            ),
        ])->assertRedirect('/import');

        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('1 new')
            ->assertSee('2 skipped')
            ->assertSee('Existing or duplicate rows will be skipped')
            ->assertSee('New Widget')
            ->assertSee('0.000')
            ->assertSee('kg')
            ->assertSee('Confirm Product Import')
            ->assertDontSee('New-product import blocked');
        $this->actingAs($admin)->post('/import/products', ['confirm' => '1'])
            ->assertRedirect('/import')
            ->assertSessionHasNoErrors()
            ->assertSessionHas('status', 'Product import completed. Created 1 new products; skipped 2 existing or duplicate rows.');
        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'name' => 'Existing Widget',
            'product_code' => 'WID-001',
            'default_tare_weight' => 9,
        ]);
        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'name' => 'New Widget',
            'product_code' => 'NEW-001',
            'default_tare_weight' => 0,
        ]);
    }

    public function test_product_import_only_requires_product_name_and_ignores_extra_columns(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Notes,Unused Value\nWidget,keep this outside import,123\n",
            ),
        ])->assertRedirect('/import');
        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('1 new')
            ->assertSee('0.000')
            ->assertSee('kg')
            ->assertSee('Confirm Product Import');
        $this->actingAs($admin)->post('/import/products', ['confirm' => '1'])
            ->assertRedirect('/import');

        $product = Product::query()
            ->where('tenant_id', $tenant->id)
            ->where('name', 'Widget')
            ->firstOrFail();
        $this->assertSame(0.0, (float) $product->default_tare_weight);
        $this->assertSame('kg', $product->defaultWeightUnit?->symbol);
    }

    public function test_product_import_accepts_optional_customer_barcode_columns(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Product Code,Customer Barcode Enabled,Customer Barcode Type,Customer Barcode,Customer Barcode Caption\n".
                "Retail Coil,RETAIL-COIL,Yes,EAN-13 / GTIN-13,4006381333931,Retail GTIN\n".
                "Internal Coil,INTERNAL-COIL,No,,,\n",
            ),
        ])->assertRedirect('/import');

        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('4006381333931')
            ->assertSee('EAN-13 / GTIN-13');

        $this->actingAs($admin)->post('/import/products', ['confirm' => '1'])
            ->assertRedirect('/import')
            ->assertSessionHasNoErrors();

        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'product_code' => 'RETAIL-COIL',
            'customer_barcode_enabled' => true,
            'customer_barcode_type' => 'ean13',
            'customer_barcode_value' => '4006381333931',
        ]);
        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'product_code' => 'INTERNAL-COIL',
            'customer_barcode_enabled' => false,
            'customer_barcode_value' => null,
        ]);
    }

    public function test_product_import_accepts_optional_product_weight_range(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Product Code,Minimum Weight (kg),Maximum Weight (kg)\n".
                "Weighted Product,WEIGHT-001,10.500,25.750\n".
                "Unrestricted Product,WEIGHT-002,,\n",
            ),
        ])->assertRedirect('/import');

        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('10.500')
            ->assertSee('25.750')
            ->assertSee('Confirm Product Import');

        $this->actingAs($admin)->post('/import/products', ['confirm' => '1'])
            ->assertRedirect('/import')
            ->assertSessionHasNoErrors();

        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'product_code' => 'WEIGHT-001',
            'minimum_weight' => 10.500,
            'maximum_weight' => 25.750,
        ]);
        $this->assertDatabaseHas('products', [
            'tenant_id' => $tenant->id,
            'product_code' => 'WEIGHT-002',
            'minimum_weight' => null,
            'maximum_weight' => null,
        ]);
    }

    public function test_product_import_rejects_invalid_or_incomplete_product_weight_ranges(): void
    {
        [, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/import/products', [
            'file' => UploadedFile::fake()->createWithContent(
                'products.csv',
                "Product Name,Minimum Weight (kg),Maximum Weight (kg)\n".
                "Incomplete Range,10,\n".
                "Reversed Range,20,10\n".
                "Negative Range,-1,10\n",
            ),
        ])->assertRedirect('/import');

        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('Minimum Weight and Maximum Weight must both be provided')
            ->assertSee('Maximum Weight must be greater than or equal to Minimum Weight')
            ->assertSee('Minimum Weight must be zero or a positive number')
            ->assertDontSee('Confirm Product Import');
    }

    public function test_product_export_is_import_compatible_and_existing_rows_are_skipped(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $this->product($tenant, 'Exported Product', 'EXP-001');
        $otherTenant = Tenant::query()->create([
            'name' => 'Other Tenant',
            'code' => 'EXPORT-OTHER',
            'status' => 'active',
        ]);
        $this->product($otherTenant, 'Hidden Product', 'HIDDEN-001');

        $export = $this->actingAs($admin)->get('/import/products/export');
        $export->assertOk()
            ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        $upload = UploadedFile::fake()->createWithContent('products-export.xlsx', $export->getContent());
        $this->actingAs($admin)->post('/import/products', ['file' => $upload])
            ->assertRedirect('/import');
        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('0 new')
            ->assertSee('1 skipped')
            ->assertSee('Exported Product')
            ->assertDontSee('Hidden Product')
            ->assertDontSee('New-product import blocked');
    }

    public function test_generated_excel_template_can_be_uploaded_and_previewed(): void
    {
        [, $admin] = $this->adminUser();
        $template = $this->actingAs($admin)->get('/import/template/products');
        $template->assertOk()
            ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        $upload = UploadedFile::fake()->createWithContent('products.xlsx', $template->getContent());
        $this->actingAs($admin)->post('/import/products', ['file' => $upload])
            ->assertRedirect('/import');
        $this->actingAs($admin)->get('/import')
            ->assertOk()
            ->assertSee('Confirm Product Import')
            ->assertSee('PRINTER-001');
    }

    public function test_product_detail_import_previews_then_creates_dropdown_fields(): void
    {
        [$tenant, $admin] = $this->adminUser();

        $this->actingAs($admin)->post('/import/product-details', [
            'file' => UploadedFile::fake()->createWithContent(
                'product-details.csv',
                "Color,Size\nRed,Small\nBlue,Large\n",
            ),
        ])->assertRedirect('/import');

        $this->assertSame(
            0,
            DynamicFieldDefinition::query()->where('tenant_id', $tenant->id)->count(),
        );
        $this->actingAs($admin)->get('/import')
            ->assertSee('Confirm Product Details Import')
            ->assertSee('Color')
            ->assertSee('Red');

        $this->actingAs($admin)->post('/import/product-details', ['confirm' => '1'])
            ->assertRedirect('/import');

        $color = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenant->id)
            ->where('internal_key', 'color')
            ->firstOrFail();
        $this->assertSame('dropdown', $color->data_type);
        $this->assertSame(['red', 'blue'], collect($color->dropdown_options)->pluck('value')->all());
        $this->assertDatabaseHas('dynamic_field_definitions', [
            'tenant_id' => $tenant->id,
            'internal_key' => 'size',
        ]);
    }

    public function test_inventory_filters_and_closing_stock_exports_are_tenant_scoped(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $matching = $this->product($tenant, 'Matching Product', 'MATCH');
        $other = $this->product($tenant, 'Other Product', 'OTHER');
        $this->inventoryTransaction($tenant, $matching, 'MATCH-BC', 'opening_stock', 12.5);
        $this->inventoryTransaction($tenant, $other, 'OTHER-BC', 'manual_adjustment', 8);

        $otherTenant = Tenant::query()->create([
            'name' => 'Other Tenant',
            'code' => 'OTHER',
            'status' => 'active',
        ]);
        $hidden = $this->product($otherTenant, 'Hidden Product', 'HIDDEN');
        $this->inventoryTransaction($otherTenant, $hidden, 'HIDDEN-BC', 'opening_stock', 99);

        $this->actingAs($admin)->get('/inventory?'.http_build_query([
            'product_id' => $matching->id,
            'transaction_type' => 'opening_stock',
            'search' => 'MATCH-BC',
            'from' => now()->subDay()->toDateString(),
            'to' => now()->addDay()->toDateString(),
        ]))
            ->assertOk()
            ->assertSee('MATCH-BC')
            ->assertDontSee('OTHER-BC')
            ->assertDontSee('HIDDEN-BC');

        $this->actingAs($admin)->get('/inventory/closing-stock/export?'.http_build_query([
            'stock_date' => now()->toDateString(),
            'format' => 'xlsx',
            'product_id' => $matching->id,
        ]))
            ->assertOk()
            ->assertHeader('content-type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        $this->actingAs($admin)->get('/inventory/closing-stock/export?'.http_build_query([
            'stock_date' => now()->toDateString(),
            'format' => 'pdf',
            'product_id' => $matching->id,
        ]))
            ->assertOk()
            ->assertHeader('content-type', 'application/pdf');
    }

    public function test_role_creation_is_tenant_scoped_and_rejects_duplicates(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $otherTenant = Tenant::query()->create([
            'name' => 'Other Tenant',
            'code' => 'OTHER',
            'status' => 'active',
        ]);
        Role::query()->create([
            'tenant_id' => $otherTenant->id,
            'name' => 'Warehouse Manager',
            'key' => 'warehouse-manager',
            'is_system' => false,
        ]);

        $this->actingAs($admin)->post('/admin/roles', ['name' => 'Warehouse Manager'])
            ->assertSessionHasNoErrors();
        $this->assertDatabaseHas('roles', [
            'tenant_id' => $tenant->id,
            'name' => 'Warehouse Manager',
            'key' => 'warehouse-manager',
        ]);

        $this->actingAs($admin)->post('/admin/roles', ['name' => 'Warehouse Manager'])
            ->assertSessionHasErrors('name');
        $this->assertSame(
            1,
            Role::query()
                ->where('tenant_id', $tenant->id)
                ->where('key', 'warehouse-manager')
                ->count(),
        );
    }

    public function test_admin_can_clear_only_their_tenant_product_setup_while_preserving_history(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $product = $this->product($tenant, 'Old Product', 'OLD-PRODUCT');
        $variant = ProductVariant::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'name' => 'Old Detail',
            'variant_code' => 'OLD-DETAIL',
            'is_active' => true,
        ]);
        ProductBatch::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'batch_name' => 'Old Batch',
            'attribute_key' => 'lot',
            'attribute_label' => 'Lot',
            'attribute_value' => 'A',
            'is_active' => true,
        ]);
        $field = DynamicFieldDefinition::query()->create([
            'tenant_id' => $tenant->id,
            'field_label' => 'Color',
            'internal_key' => 'color',
            'entity_type' => 'product_variant',
            'data_type' => 'dropdown',
            'dropdown_options' => [['label' => 'Red', 'value' => 'red']],
            'is_active' => true,
        ]);
        DynamicFieldValue::query()->create([
            'tenant_id' => $tenant->id,
            'dynamic_field_definition_id' => $field->id,
            'entity_type' => 'product_variant',
            'entity_id' => $variant->id,
            'text_value' => 'red',
        ]);
        $history = ProductionTransaction::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'variant_id' => $variant->id,
            'serial_number' => 'SER-HISTORY',
            'barcode_value' => 'BAR-HISTORY',
            'product_snapshot' => ['name' => 'Old Product'],
            'variant_snapshot' => ['name' => 'Old Detail'],
            'gross_weight' => 2,
            'tare_weight' => 0,
            'net_weight' => 2,
            'captured_at' => now(),
        ]);

        $otherTenant = Tenant::query()->create([
            'name' => 'Other Tenant',
            'code' => 'OTHER-CLEAR',
            'status' => 'active',
        ]);
        $otherProduct = $this->product($otherTenant, 'Other Product', 'OTHER-PRODUCT');

        $this->actingAs($admin)->get('/products')
            ->assertOk()
            ->assertSee('Delete All Product Setup')
            ->assertSee('No automatic backup is created.');

        $this->actingAs($admin)->delete('/products/clear', [
            'confirm' => 'DELETE ALL PRODUCTS',
            'password' => 'password',
        ])->assertRedirect('/products')
            ->assertSessionHasNoErrors();

        $this->assertSame(0, Product::query()->where('tenant_id', $tenant->id)->count());
        $this->assertSame(1, Product::onlyTrashed()->where('tenant_id', $tenant->id)->count());
        $this->assertStringStartsWith('DELETED-', Product::withTrashed()->findOrFail($product->id)->product_code);
        $this->assertSame(0, ProductVariant::query()->where('tenant_id', $tenant->id)->count());
        $this->assertSame(0, ProductBatch::query()->where('tenant_id', $tenant->id)->count());
        $this->assertSame(0, DynamicFieldDefinition::withTrashed()->where('tenant_id', $tenant->id)->count());
        $this->assertSame(0, DynamicFieldValue::query()->where('tenant_id', $tenant->id)->count());
        $this->assertDatabaseHas('production_transactions', ['id' => $history->id]);
        $this->assertDatabaseHas('products', ['id' => $otherProduct->id, 'is_active' => true]);
        $this->assertDatabaseHas('audit_logs', [
            'tenant_id' => $tenant->id,
            'action' => 'products.cleared',
        ]);
    }

    public function test_product_setup_clear_requires_exact_confirmation_password_and_admin_permission(): void
    {
        [$tenant, $admin] = $this->adminUser();
        $product = $this->product($tenant, 'Protected Product', 'PROTECTED');

        $this->actingAs($admin)->delete('/products/clear', [
            'confirm' => 'DELETE PRODUCTS',
            'password' => 'password',
        ])->assertSessionHasErrors('confirm');
        $this->assertDatabaseHas('products', ['id' => $product->id, 'is_active' => true]);

        $this->actingAs($admin)->delete('/products/clear', [
            'confirm' => 'DELETE ALL PRODUCTS',
            'password' => 'wrong-password',
        ])->assertSessionHasErrors('password');
        $this->assertDatabaseHas('products', ['id' => $product->id, 'is_active' => true]);

        [, $operator] = $this->adminUser(['products.view']);
        $this->actingAs($operator)->delete('/products/clear', [
            'confirm' => 'DELETE ALL PRODUCTS',
            'password' => 'password',
        ])->assertForbidden();
        $this->assertDatabaseHas('products', ['id' => $product->id, 'is_active' => true]);
    }

    public function test_restored_data_actions_require_their_permissions(): void
    {
        [, $user] = $this->adminUser(['dashboard.view']);

        $this->actingAs($user)->get('/import')->assertForbidden();
        $this->actingAs($user)->get('/export')->assertForbidden();
        $this->actingAs($user)->get('/inventory/closing-stock/export?stock_date='.now()->toDateString().'&format=xlsx')
            ->assertForbidden();
        $this->actingAs($user)->post('/admin/roles', ['name' => 'No Access'])
            ->assertForbidden();
    }

    private function adminUser(?array $permissionKeys = null): array
    {
        $tenant = Tenant::query()->create([
            'name' => 'Admin Tenant',
            'code' => 'ADMIN-'.Str::lower(Str::random(5)),
            'status' => 'active',
        ]);
        $permissionKeys ??= [
            'dashboard.view',
            'users.manage',
            'roles.manage',
            'products.view',
            'inventory.view',
            'reports.view',
            'configuration.manage',
        ];
        $permissions = collect($permissionKeys)
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
            'email' => Str::lower(Str::random(8)).'@example.test',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->roles()->sync([$role->id]);

        return [$tenant, $user];
    }

    private function product(Tenant $tenant, string $name, string $code): Product
    {
        return Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => $name,
            'product_code' => $code,
            'default_tare_weight' => 0,
            'is_active' => true,
        ]);
    }

    private function inventoryTransaction(
        Tenant $tenant,
        Product $product,
        string $barcode,
        string $type,
        float $weight,
    ): InventoryTransaction {
        return InventoryTransaction::query()->create([
            'tenant_id' => $tenant->id,
            'product_id' => $product->id,
            'barcode_value' => $barcode,
            'transaction_type' => $type,
            'weight_quantity' => $weight,
            'piece_quantity' => 1,
            'reference_type' => 'test',
            'reference_id' => (string) Str::uuid(),
            'occurred_at' => now(),
        ]);
    }
}
