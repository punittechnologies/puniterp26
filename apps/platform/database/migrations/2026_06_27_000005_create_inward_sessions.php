<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inward_sessions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id');
            $table->string('session_number');
            $table->string('status')->default('open');
            $table->unsignedInteger('entry_count')->default(0);
            $table->decimal('total_gross_weight', 18, 6)->default(0);
            $table->decimal('total_tare_weight', 18, 6)->default(0);
            $table->decimal('total_net_weight', 18, 6)->default(0);
            $table->decimal('total_piece_quantity', 18, 6)->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'session_number']);
            $table->index(['tenant_id', 'status']);
            $table->index(['tenant_id', 'started_at']);
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::table('production_transactions', function (Blueprint $table): void {
            $table->uuid('inward_session_id')->nullable()->after('variant_id');
            $table->index(['tenant_id', 'inward_session_id']);
            $table->foreign('inward_session_id')->references('id')->on('inward_sessions')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('production_transactions', function (Blueprint $table): void {
            $table->dropForeign(['inward_session_id']);
            $table->dropIndex(['tenant_id', 'inward_session_id']);
            $table->dropColumn('inward_session_id');
        });

        Schema::dropIfExists('inward_sessions');
    }
};
