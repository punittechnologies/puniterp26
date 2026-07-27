<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('qr_page_settings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->unique();
            $table->boolean('is_enabled')->default(false);
            $table->boolean('complaints_enabled')->default(false);
            $table->boolean('email_notifications_enabled')->default(true);
            $table->string('company_logo_path')->nullable();
            $table->string('company_name')->nullable();
            $table->string('gst_number')->nullable();
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->text('address')->nullable();
            $table->string('contact_person')->nullable();
            $table->string('website')->nullable();
            $table->text('custom_text')->nullable();
            $table->text('authenticity_statement')->nullable();
            $table->string('made_in_text')->default('Made in India');
            $table->string('complaint_email')->nullable();
            $table->json('theme')->nullable();
            $table->json('display_fields')->nullable();
            $table->json('section_order')->nullable();
            $table->json('complaint_fields')->nullable();
            $table->uuid('created_by')->nullable();
            $table->uuid('updated_by')->nullable();
            $table->timestamps();
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
        });

        Schema::create('qr_verifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('qr_page_setting_id')->nullable()->index();
            $table->string('source_transaction_id', 120);
            $table->char('token_hash', 64)->unique();
            $table->text('token_encrypted');
            $table->string('status')->default('authentic')->index();
            $table->uuid('product_id')->nullable()->index();
            $table->uuid('variant_id')->nullable()->index();
            $table->string('serial_number')->nullable()->index();
            $table->string('barcode_value')->nullable()->index();
            $table->json('snapshot');
            $table->timestamp('printed_at');
            $table->unsignedBigInteger('scan_count')->default(0);
            $table->timestamp('last_scanned_at')->nullable();
            $table->uuid('created_by')->nullable();
            $table->timestamps();
            $table->unique(['tenant_id', 'source_transaction_id'], 'qr_verification_source_unique');
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('qr_page_setting_id')->references('id')->on('qr_page_settings')->nullOnDelete();
        });

        Schema::create('qr_complaints', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('tenant_id')->index();
            $table->uuid('qr_verification_id')->index();
            $table->string('status')->default('new')->index();
            $table->string('customer_company_name')->nullable();
            $table->string('customer_name')->nullable();
            $table->string('phone')->nullable();
            $table->string('email')->nullable();
            $table->string('contact_person')->nullable();
            $table->string('order_reference')->nullable();
            $table->text('message')->nullable();
            $table->string('photo_path')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->foreign('tenant_id')->references('id')->on('tenants')->cascadeOnDelete();
            $table->foreign('qr_verification_id')->references('id')->on('qr_verifications')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('qr_complaints');
        Schema::dropIfExists('qr_verifications');
        Schema::dropIfExists('qr_page_settings');
    }
};
