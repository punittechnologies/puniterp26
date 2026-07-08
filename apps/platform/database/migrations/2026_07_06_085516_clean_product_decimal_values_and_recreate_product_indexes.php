<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('products')
            ->whereNull('default_tare_weight')
            ->orWhere('default_tare_weight', '')
            ->update(['default_tare_weight' => 0]);

        foreach ([
            'minimum_weight',
            'maximum_weight',
            'target_weight',
            'stability_tolerance',
            'reset_threshold',
        ] as $column) {
            DB::table('products')
                ->where($column, '')
                ->update([$column => null]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
