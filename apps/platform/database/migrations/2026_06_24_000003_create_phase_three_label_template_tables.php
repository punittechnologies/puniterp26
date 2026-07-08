<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('label_templates', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->nullable()->index();
            $table->uuid('product_id')->nullable()->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->string('name');
            $table->string('code');
            $table->string('scope')->default('tenant');
            $table->decimal('width_mm', 8, 2);
            $table->decimal('height_mm', 8, 2);
            $table->boolean('is_custom_size')->default(false);
            $table->boolean('is_default')->default(false);
            $table->boolean('is_active')->default(true)->index();
            $table->boolean('is_archived')->default(false)->index();
            $table->unsignedInteger('active_version')->default(1);
            $table->json('template_json');
            $table->json('warnings')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'code']);
            $table->index(['tenant_id', 'scope', 'is_default']);
            $table->index(['tenant_id', 'updated_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->nullOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->nullOnDelete();
        });

        Schema::create('label_template_versions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->nullable()->index();
            $table->uuid('label_template_id')->index();
            $table->unsignedInteger('version');
            $table->string('status')->default('active');
            $table->json('template_json');
            $table->json('change_summary')->nullable();
            $table->json('warnings')->nullable();
            $table->timestamp('activated_at')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('approved_by')->nullable();
            $table->timestamps();
            $table->unique(['label_template_id', 'version']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('label_template_id')->references('id')->on('label_templates')->cascadeOnDelete();
        });

        Schema::create('label_template_elements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->nullable()->index();
            $table->uuid('label_template_id')->index();
            $table->uuid('label_template_version_id')->nullable()->index();
            $table->string('element_key');
            $table->string('type');
            $table->string('binding_key')->nullable();
            $table->decimal('x', 10, 2)->default(0);
            $table->decimal('y', 10, 2)->default(0);
            $table->decimal('width', 10, 2)->default(10);
            $table->decimal('height', 10, 2)->default(10);
            $table->unsignedInteger('layer_order')->default(0);
            $table->json('style')->nullable();
            $table->json('format')->nullable();
            $table->json('visibility')->nullable();
            $table->string('prefix')->nullable();
            $table->string('suffix')->nullable();
            $table->timestamps();
            $table->index(['tenant_id', 'label_template_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('label_template_id')->references('id')->on('label_templates')->cascadeOnDelete();
            $table->foreign('label_template_version_id')->references('id')->on('label_template_versions')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('label_template_elements');
        Schema::dropIfExists('label_template_versions');
        Schema::dropIfExists('label_templates');
    }
};
