<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table): void {
            $table->boolean('customer_barcode_enabled')->default(false)->after('barcode_rule');
            $table->string('customer_barcode_type', 20)->nullable()->after('customer_barcode_enabled');
            $table->string('customer_barcode_value', 120)->nullable()->after('customer_barcode_type');
            $table->string('customer_barcode_caption', 80)->nullable()->after('customer_barcode_value');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table): void {
            $table->dropColumn([
                'customer_barcode_enabled',
                'customer_barcode_type',
                'customer_barcode_value',
                'customer_barcode_caption',
            ]);
        });
    }
};
