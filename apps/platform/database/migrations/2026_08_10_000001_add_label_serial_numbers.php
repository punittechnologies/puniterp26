<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('production_transactions', function (Blueprint $table): void {
            $table->string('label_serial_number')->nullable()->after('serial_number')->index();
        });
        Schema::table('barcode_records', function (Blueprint $table): void {
            $table->string('label_serial_number')->nullable()->after('serial_number')->index();
        });
        Schema::table('inventory_transactions', function (Blueprint $table): void {
            $table->string('label_serial_number')->nullable()->after('serial_number')->index();
        });
    }

    public function down(): void
    {
        Schema::table('inventory_transactions', fn (Blueprint $table) => $table->dropColumn('label_serial_number'));
        Schema::table('barcode_records', fn (Blueprint $table) => $table->dropColumn('label_serial_number'));
        Schema::table('production_transactions', fn (Blueprint $table) => $table->dropColumn('label_serial_number'));
    }
};
