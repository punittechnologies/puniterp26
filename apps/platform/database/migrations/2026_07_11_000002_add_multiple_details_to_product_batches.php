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
            $table->json('detail_values')->nullable()->after('attribute_value');
            $table->string('detail_signature')->nullable()->after('detail_values');
        });

        DB::table('product_batches')
            ->orderBy('id')
            ->get()
            ->each(function ($batch): void {
                $details = [
                    $batch->attribute_key => [
                        'label' => $batch->attribute_label,
                        'value' => $batch->attribute_value,
                    ],
                ];

                DB::table('product_batches')
                    ->where('id', $batch->id)
                    ->update([
                        'detail_values' => json_encode($details),
                        'detail_signature' => md5(json_encode([$batch->attribute_key => $batch->attribute_value])),
                    ]);
            });

        Schema::table('product_batches', function (Blueprint $table): void {
            $table->dropUnique('product_batches_unique');
            $table->unique(
                ['tenant_id', 'batch_name', 'product_id', 'detail_signature'],
                'product_batches_detail_unique',
            );
        });
    }

    public function down(): void
    {
        Schema::table('product_batches', function (Blueprint $table): void {
            $table->dropUnique('product_batches_detail_unique');
            $table->unique(
                ['tenant_id', 'batch_name', 'product_id', 'attribute_key', 'attribute_value'],
                'product_batches_unique',
            );
            $table->dropColumn(['detail_values', 'detail_signature']);
        });
    }
};
