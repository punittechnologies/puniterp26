<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'phone')) {
                $table->string('phone', 32)->nullable()->after('email')->index();
            }
        });

        Schema::create('tenant_onboarding_invites', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('phone', 32)->index();
            $table->string('company_name')->nullable();
            $table->uuid('tenant_id')->nullable()->index();
            $table->unsignedInteger('admin_limit')->default(1);
            $table->date('valid_until')->nullable();
            $table->string('status', 24)->default('pending')->index();
            $table->uuid('claimed_by')->nullable();
            $table->timestamp('claimed_at')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->unique(['phone', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_onboarding_invites');

        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'phone')) {
                $table->dropColumn('phone');
            }
        });
    }
};
