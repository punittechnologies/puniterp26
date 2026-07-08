<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('production_transactions', function (Blueprint $table): void {
            $table->index(['tenant_id', 'product_id', 'captured_at'], 'pt_tenant_product_time_idx');
            $table->index(['tenant_id', 'variant_id', 'captured_at'], 'pt_tenant_variant_time_idx');
            $table->index(['tenant_id', 'status', 'captured_at'], 'pt_tenant_status_time_idx');
            $table->index(['tenant_id', 'inward_session_id', 'captured_at'], 'pt_tenant_session_time_idx');
            $table->index(['tenant_id', 'client_id'], 'pt_tenant_client_idx');
        });

        Schema::table('barcode_records', function (Blueprint $table): void {
            $table->index(['tenant_id', 'dispatch_status', 'inventory_status'], 'br_tenant_status_idx');
            $table->index(['tenant_id', 'production_transaction_id'], 'br_tenant_production_idx');
        });

        Schema::table('inventory_transactions', function (Blueprint $table): void {
            $table->index(['tenant_id', 'occurred_at'], 'it_tenant_time_idx');
            $table->index(['tenant_id', 'transaction_type', 'occurred_at'], 'it_tenant_type_time_idx');
            $table->index(['tenant_id', 'barcode_value'], 'it_tenant_barcode_idx');
            $table->index(['tenant_id', 'reference_type', 'reference_id'], 'it_tenant_reference_idx');
        });

        Schema::table('dispatches', function (Blueprint $table): void {
            $table->index(['tenant_id', 'confirmed_at'], 'd_tenant_confirmed_idx');
            $table->index(['tenant_id', 'status', 'confirmed_at'], 'd_tenant_status_time_idx');
            $table->index(['tenant_id', 'customer_id', 'confirmed_at'], 'd_tenant_customer_time_idx');
            $table->index(['tenant_id', 'client_id'], 'd_tenant_client_idx');
        });

        Schema::table('dispatch_items', function (Blueprint $table): void {
            $table->index(['tenant_id', 'dispatch_id'], 'di_tenant_dispatch_idx');
            $table->index(['tenant_id', 'production_transaction_id'], 'di_tenant_production_idx');
        });

        Schema::table('inward_sessions', function (Blueprint $table): void {
            $table->index(['tenant_id', 'status', 'started_at'], 'is_tenant_status_time_idx');
        });
    }

    public function down(): void
    {
        Schema::table('production_transactions', function (Blueprint $table): void {
            $table->dropIndex('pt_tenant_product_time_idx');
            $table->dropIndex('pt_tenant_variant_time_idx');
            $table->dropIndex('pt_tenant_status_time_idx');
            $table->dropIndex('pt_tenant_session_time_idx');
            $table->dropIndex('pt_tenant_client_idx');
        });

        Schema::table('barcode_records', function (Blueprint $table): void {
            $table->dropIndex('br_tenant_status_idx');
            $table->dropIndex('br_tenant_production_idx');
        });

        Schema::table('inventory_transactions', function (Blueprint $table): void {
            $table->dropIndex('it_tenant_time_idx');
            $table->dropIndex('it_tenant_type_time_idx');
            $table->dropIndex('it_tenant_barcode_idx');
            $table->dropIndex('it_tenant_reference_idx');
        });

        Schema::table('dispatches', function (Blueprint $table): void {
            $table->dropIndex('d_tenant_confirmed_idx');
            $table->dropIndex('d_tenant_status_time_idx');
            $table->dropIndex('d_tenant_customer_time_idx');
            $table->dropIndex('d_tenant_client_idx');
        });

        Schema::table('dispatch_items', function (Blueprint $table): void {
            $table->dropIndex('di_tenant_dispatch_idx');
            $table->dropIndex('di_tenant_production_idx');
        });

        Schema::table('inward_sessions', function (Blueprint $table): void {
            $table->dropIndex('is_tenant_status_time_idx');
        });
    }
};
