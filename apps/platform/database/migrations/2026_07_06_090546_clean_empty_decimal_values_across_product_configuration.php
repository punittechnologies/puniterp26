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
        $this->clean('products', [
            'default_tare_weight' => 0,
            'minimum_weight' => null,
            'maximum_weight' => null,
            'target_weight' => null,
            'stability_tolerance' => 0,
            'reset_threshold' => 0,
        ]);

        $this->clean('product_variants', [
            'tare_weight' => null,
            'minimum_weight' => null,
            'maximum_weight' => null,
            'target_weight' => null,
            'reset_threshold' => null,
        ]);

        $this->clean('unit_conversion_rules', [
            'weight_per_piece' => null,
            'pieces_per_kg' => null,
            'sample_weight' => null,
        ]);

        $this->clean('weight_rules', [
            'minimum_weight' => null,
            'maximum_weight' => null,
            'target_weight' => null,
            'tare_weight' => null,
            'stability_tolerance' => null,
            'reset_threshold' => null,
        ]);

        $this->clean('units', [
            'conversion_factor_to_base' => null,
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }

    private function clean(string $table, array $columns): void
    {
        foreach ($columns as $column => $replacement) {
            DB::table($table)
                ->where($column, '')
                ->orWhereNull($column)
                ->update([$column => $replacement]);
        }
    }
};
