<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customers', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->string('name');
            $table->string('code')->nullable();
            $table->string('contact_person')->nullable();
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->text('billing_address')->nullable();
            $table->text('shipping_address')->nullable();
            $table->string('tax_number')->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->json('metadata')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->softDeletes();
            $table->timestamps();
            $table->unique(['tenant_id', 'code']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::create('production_transactions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('warehouse_id')->nullable()->index();
            $table->uuid('product_id')->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->string('serial_number');
            $table->string('barcode_value');
            $table->json('product_snapshot');
            $table->json('dynamic_values')->nullable();
            $table->decimal('gross_weight', 20, 6);
            $table->decimal('tare_weight', 20, 6)->default(0);
            $table->decimal('net_weight', 20, 6);
            $table->decimal('piece_quantity', 20, 6)->nullable();
            $table->string('unit')->default('kg');
            $table->json('raw_reading')->nullable();
            $table->string('status')->default('active')->index();
            $table->string('sync_status')->default('synced')->index();
            $table->string('client_id')->nullable()->index();
            $table->string('idempotency_key')->nullable()->index();
            $table->timestamp('captured_at')->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->unique(['tenant_id', 'serial_number']);
            $table->unique(['tenant_id', 'barcode_value']);
            $table->unique(['tenant_id', 'idempotency_key']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('warehouse_id')->references('id')->on('warehouses')->nullOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->nullOnDelete();
        });

        Schema::create('barcode_records', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('production_transaction_id')->index();
            $table->string('serial_number');
            $table->string('barcode_value');
            $table->string('inventory_status')->default('available')->index();
            $table->string('dispatch_status')->default('not_dispatched')->index();
            $table->timestamps();
            $table->unique(['tenant_id', 'barcode_value']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('production_transaction_id')->references('id')->on('production_transactions')->cascadeOnDelete();
        });

        Schema::create('inventory_transactions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('warehouse_id')->nullable()->index();
            $table->uuid('product_id')->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->string('serial_number')->nullable();
            $table->string('barcode_value')->nullable()->index();
            $table->string('transaction_type')->index();
            $table->decimal('weight_quantity', 20, 6);
            $table->decimal('piece_quantity', 20, 6)->nullable();
            $table->string('reference_type');
            $table->uuid('reference_id');
            $table->string('sync_status')->default('synced')->index();
            $table->text('reason')->nullable();
            $table->uuid('device_id')->nullable();
            $table->uuid('created_by')->nullable();
            $table->timestamp('occurred_at')->index();
            $table->timestamps();
            $table->index(['tenant_id', 'product_id', 'variant_id']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('warehouse_id')->references('id')->on('warehouses')->nullOnDelete();
            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
            $table->foreign('variant_id')->references('id')->on('product_variants')->nullOnDelete();
        });

        Schema::create('dispatches', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('customer_id')->index();
            $table->string('dispatch_number');
            $table->json('customer_snapshot');
            $table->string('status')->default('confirmed')->index();
            $table->string('vehicle_number')->nullable();
            $table->string('driver_name')->nullable();
            $table->string('transporter')->nullable();
            $table->string('po_reference')->nullable();
            $table->string('invoice_reference')->nullable();
            $table->decimal('total_weight', 20, 6)->default(0);
            $table->decimal('total_pieces', 20, 6)->nullable();
            $table->json('metadata')->nullable();
            $table->string('client_id')->nullable()->index();
            $table->string('idempotency_key')->nullable()->index();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();
            $table->unique(['tenant_id', 'dispatch_number']);
            $table->unique(['tenant_id', 'idempotency_key']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('customer_id')->references('id')->on('customers')->cascadeOnDelete();
        });

        Schema::create('dispatch_items', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('dispatch_id')->index();
            $table->uuid('production_transaction_id')->index();
            $table->string('barcode_value');
            $table->decimal('weight_quantity', 20, 6);
            $table->decimal('piece_quantity', 20, 6)->nullable();
            $table->timestamps();
            $table->unique(['tenant_id', 'barcode_value']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('dispatch_id')->references('id')->on('dispatches')->cascadeOnDelete();
            $table->foreign('production_transaction_id')->references('id')->on('production_transactions')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dispatch_items');
        Schema::dropIfExists('dispatches');
        Schema::dropIfExists('inventory_transactions');
        Schema::dropIfExists('barcode_records');
        Schema::dropIfExists('production_transactions');
        Schema::dropIfExists('customers');
    }
};
