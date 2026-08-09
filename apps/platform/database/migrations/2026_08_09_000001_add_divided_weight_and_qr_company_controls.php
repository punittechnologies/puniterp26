<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('dynamic_field_definitions', function (Blueprint $table): void {
            $table->boolean('use_as_weight_divisor')->default(false)->after('printable_on_label');
        });

        Schema::table('qr_page_settings', function (Blueprint $table): void {
            $table->boolean('show_company_name')->default(true)->after('company_name');
        });
    }

    public function down(): void
    {
        Schema::table('dynamic_field_definitions', function (Blueprint $table): void {
            $table->dropColumn('use_as_weight_divisor');
        });

        Schema::table('qr_page_settings', function (Blueprint $table): void {
            $table->dropColumn('show_company_name');
        });
    }
};
