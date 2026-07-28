<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('product_batches', function (Blueprint $table): void {
            $table->json('batch_items')->nullable()->after('detail_values');
        });

        DB::table('product_batches')
            ->orderBy('id')
            ->get()
            ->each(function ($batch): void {
                $details = $batch->detail_values ? json_decode($batch->detail_values, true) : [
                    $batch->attribute_key => [
                        'label' => $batch->attribute_label,
                        'value' => $batch->attribute_value,
                    ],
                ];

                DB::table('product_batches')
                    ->where('id', $batch->id)
                    ->update([
                        'batch_items' => json_encode([[
                            'product_id' => $batch->product_id,
                            'product_name' => null,
                            'details' => $details,
                        ]]),
                    ]);
            });
    }

    public function down(): void
    {
        Schema::table('product_batches', function (Blueprint $table): void {
            $table->dropColumn('batch_items');
        });
    }
};
