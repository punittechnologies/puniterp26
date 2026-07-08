<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('units', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->nullable()->index();
            $table->string('name');
            $table->string('symbol');
            $table->string('category');
            $table->decimal('conversion_factor_to_base', 20, 8)->default(1);
            $table->unsignedTinyInteger('decimal_precision')->default(3);
            $table->boolean('is_system')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['tenant_id', 'symbol', 'category']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::create('product_categories', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('parent_id')->nullable()->index();
            $table->string('name');
            $table->string('code');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedInteger('sort_order')->default(0);
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'code']);
            $table->index(['tenant_id', 'is_active']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('parent_id')->references('id')->on('product_categories')->nullOnDelete();
        });

        Schema::create('products', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('category_id')->nullable()->index();
            $table->uuid('default_weight_unit_id')->nullable();
            $table->uuid('default_inventory_unit_id')->nullable();
            $table->uuid('default_warehouse_id')->nullable();
            $table->string('name');
            $table->string('product_code');
            $table->string('sku')->nullable();
            $table->text('description')->nullable();
            $table->string('brand')->nullable();
            $table->string('image_path')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->string('barcode_rule')->nullable();
            $table->decimal('default_tare_weight', 15, 3)->default(0);
            $table->decimal('minimum_weight', 15, 3)->nullable();
            $table->decimal('maximum_weight', 15, 3)->nullable();
            $table->decimal('target_weight', 15, 3)->nullable();
            $table->unsignedTinyInteger('weight_decimal_precision')->default(3);
            $table->unsignedInteger('stability_duration_ms')->default(1000);
            $table->decimal('stability_tolerance', 15, 3)->default(0);
            $table->decimal('reset_threshold', 15, 3)->default(0);
            $table->boolean('auto_print_enabled')->default(false);
            $table->boolean('manual_print_enabled')->default(true);
            $table->boolean('duplicate_print_prevention_enabled')->default(true);
            $table->boolean('unit_conversion_enabled')->default(false);
            $table->uuid('default_label_template_id')->nullable();
            $table->string('product_lock_mode')->default('none');
            $table->string('variant_lock_mode')->default('none');
            $table->string('product_selection_mode')->default('operator_can_select');
            $table->json('metadata')->nullable();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->timestamp('configuration_activated_at')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'product_code']);
            $table->index(['tenant_id', 'sku']);
            $table->index(['tenant_id', 'category_id']);
            $table->index(['tenant_id', 'updated_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('category_id')->references('id')->on('product_categories')->nullOnDelete();
            $table->foreign('default_weight_unit_id')->references('id')->on('units')->nullOnDelete();
            $table->foreign('default_inventory_unit_id')->references('id')->on('units')->nullOnDelete();
            $table->foreign('default_warehouse_id')->references('id')->on('warehouses')->nullOnDelete();
        });

        Schema::create('product_attributes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->string('name');
            $table->string('internal_key');
            $table->string('field_type');
            $table->boolean('is_required')->default(false);
            $table->boolean('is_variant_defining')->default(false);
            $table->boolean('visible_in_app')->default(true);
            $table->boolean('printable')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'internal_key']);
            $table->index(['tenant_id', 'is_active']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::create('product_attribute_values', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('product_attribute_id')->index();
            $table->string('display_value');
            $table->string('internal_value');
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['product_attribute_id', 'internal_value'], 'attr_values_attr_internal_unique');
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_attribute_id')->references('id')->on('product_attributes')->cascadeOnDelete();
        });

        Schema::create('product_variants', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('product_id')->index();
            $table->uuid('unit_conversion_rule_id')->nullable();
            $table->string('name');
            $table->string('variant_code');
            $table->string('sku')->nullable();
            $table->string('barcode')->nullable();
            $table->string('image_path')->nullable();
            $table->string('attribute_signature')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->decimal('tare_weight', 15, 3)->nullable();
            $table->decimal('minimum_weight', 15, 3)->nullable();
            $table->decimal('maximum_weight', 15, 3)->nullable();
            $table->decimal('target_weight', 15, 3)->nullable();
            $table->unsignedTinyInteger('weight_decimal_precision')->nullable();
            $table->unsignedInteger('stability_duration_ms')->nullable();
            $table->decimal('reset_threshold', 15, 3)->nullable();
            $table->string('product_lock_mode')->nullable();
            $table->uuid('label_template_id')->nullable();
            $table->json('metadata')->nullable();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'variant_code']);
            $table->unique(['product_id', 'attribute_signature'], 'variants_product_signature_unique');
            $table->index(['tenant_id', 'product_id']);
            $table->index(['tenant_id', 'updated_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
        });

        Schema::create('product_variant_attribute_values', function (Blueprint $table) {
            $table->uuid('variant_id');
            $table->uuid('product_attribute_id');
            $table->uuid('product_attribute_value_id')->nullable();
            $table->string('raw_value')->nullable();
            $table->primary(['variant_id', 'product_attribute_id'], 'variant_attribute_primary');
            $table->foreign('variant_id')->references('id')->on('product_variants')->cascadeOnDelete();
            $table->foreign('product_attribute_id')->references('id')->on('product_attributes')->cascadeOnDelete();
            $table->foreign('product_attribute_value_id', 'variant_attr_value_fk')->references('id')->on('product_attribute_values')->nullOnDelete();
        });

        Schema::create('dynamic_field_definitions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->string('field_label');
            $table->string('internal_key');
            $table->text('description')->nullable();
            $table->string('entity_type');
            $table->string('data_type');
            $table->boolean('is_required')->default(false);
            $table->json('default_value')->nullable();
            $table->string('placeholder')->nullable();
            $table->string('help_text')->nullable();
            $table->json('validation_rules')->nullable();
            $table->json('dropdown_options')->nullable();
            $table->boolean('visible_in_web')->default(true);
            $table->boolean('visible_in_flutter')->default(true);
            $table->boolean('editable_in_flutter')->default(true);
            $table->boolean('printable_on_label')->default(false);
            $table->boolean('visible_in_reports')->default(false);
            $table->boolean('searchable')->default(false);
            $table->boolean('filterable')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->json('conditional_visibility')->nullable();
            $table->json('formula_definition')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'entity_type', 'internal_key'], 'dynamic_field_unique_key');
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::create('dynamic_field_values', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('dynamic_field_definition_id')->index();
            $table->string('entity_type');
            $table->uuid('entity_id');
            $table->text('text_value')->nullable();
            $table->decimal('decimal_value', 20, 6)->nullable();
            $table->bigInteger('integer_value')->nullable();
            $table->boolean('boolean_value')->nullable();
            $table->dateTime('date_value')->nullable();
            $table->json('json_value')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->unique(['dynamic_field_definition_id', 'entity_type', 'entity_id'], 'dynamic_field_entity_unique');
            $table->index(['tenant_id', 'entity_type', 'entity_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('dynamic_field_definition_id')->references('id')->on('dynamic_field_definitions')->cascadeOnDelete();
        });

        Schema::create('unit_conversion_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('product_id')->nullable()->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->string('method');
            $table->decimal('weight_per_piece', 20, 6)->nullable();
            $table->uuid('weight_unit_id')->nullable();
            $table->decimal('pieces_per_kg', 20, 6)->nullable();
            $table->decimal('sample_weight', 20, 6)->nullable();
            $table->uuid('sample_weight_unit_id')->nullable();
            $table->unsignedInteger('sample_piece_count')->nullable();
            $table->string('rounding_method')->default('none');
            $table->unsignedTinyInteger('decimal_places')->default(0);
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->cascadeOnDelete();
            $table->foreign('weight_unit_id')->references('id')->on('units')->nullOnDelete();
            $table->foreign('sample_weight_unit_id')->references('id')->on('units')->nullOnDelete();
        });

        Schema::create('weight_rules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('product_id')->nullable()->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->uuid('weight_unit_id')->nullable();
            $table->decimal('minimum_weight', 15, 3)->nullable();
            $table->decimal('maximum_weight', 15, 3)->nullable();
            $table->decimal('target_weight', 15, 3)->nullable();
            $table->decimal('tare_weight', 15, 3)->default(0);
            $table->unsignedTinyInteger('decimal_precision')->default(3);
            $table->unsignedInteger('stability_duration_ms')->default(1000);
            $table->decimal('stability_tolerance', 15, 3)->default(0);
            $table->decimal('reset_threshold', 15, 3)->default(0);
            $table->boolean('auto_print_enabled')->default(false);
            $table->boolean('manual_print_enabled')->default(true);
            $table->boolean('duplicate_print_prevention_enabled')->default(true);
            $table->string('underweight_action')->default('allow_with_warning');
            $table->string('overweight_action')->default('allow_with_warning');
            $table->string('underweight_message')->nullable();
            $table->string('overweight_message')->nullable();
            $table->string('product_lock_mode')->default('none');
            $table->string('variant_lock_mode')->default('none');
            $table->boolean('is_active')->default(true)->index();
            $table->dateTime('effective_at')->nullable();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->index(['tenant_id', 'product_id']);
            $table->index(['tenant_id', 'variant_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->cascadeOnDelete();
            $table->foreign('weight_unit_id')->references('id')->on('units')->nullOnDelete();
        });

        Schema::create('product_device_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('device_id')->index();
            $table->uuid('product_id')->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->boolean('allowed')->default(true);
            $table->boolean('locked')->default(false);
            $table->boolean('default_selection')->default(false);
            $table->unsignedInteger('sort_order')->default(0);
            $table->dateTime('effective_at')->nullable();
            $table->dateTime('expires_at')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->unsignedInteger('configuration_version')->default(1)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->unique(['device_id', 'product_id', 'variant_id'], 'device_product_variant_unique');
            $table->index(['tenant_id', 'device_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('device_id')->references('id')->on('devices')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->cascadeOnDelete();
        });

        Schema::create('product_configuration_revisions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->string('configuration_type');
            $table->uuid('entity_id')->nullable();
            $table->unsignedInteger('previous_version')->nullable();
            $table->unsignedInteger('new_version');
            $table->string('status')->default('active');
            $table->json('change_summary')->nullable();
            $table->json('payload');
            $table->timestamp('activated_at')->nullable();
            $table->json('rollback_payload')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('approved_by')->nullable();
            $table->timestamps();
            $table->index(['tenant_id', 'configuration_type'], 'prod_config_rev_tenant_type_idx');
            $table->index(['tenant_id', 'entity_id'], 'prod_config_rev_tenant_entity_idx');
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_configuration_revisions');
        Schema::dropIfExists('product_device_assignments');
        Schema::dropIfExists('weight_rules');
        Schema::dropIfExists('unit_conversion_rules');
        Schema::dropIfExists('dynamic_field_values');
        Schema::dropIfExists('dynamic_field_definitions');
        Schema::dropIfExists('product_variant_attribute_values');
        Schema::dropIfExists('product_variants');
        Schema::dropIfExists('product_attribute_values');
        Schema::dropIfExists('product_attributes');
        Schema::dropIfExists('products');
        Schema::dropIfExists('product_categories');
        Schema::dropIfExists('units');
    }
};
