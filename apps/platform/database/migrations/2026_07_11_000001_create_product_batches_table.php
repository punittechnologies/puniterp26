<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_batches', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('product_id')->index();
            $table->string('batch_name');
            $table->string('attribute_key');
            $table->string('attribute_label');
            $table->string('attribute_value');
            $table->boolean('is_active')->default(true)->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->unique(
                ['tenant_id', 'batch_name', 'product_id', 'attribute_key', 'attribute_value'],
                'product_batches_unique',
            );
            $table->index(['tenant_id', 'product_id', 'is_active']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_batches');
    }
};
