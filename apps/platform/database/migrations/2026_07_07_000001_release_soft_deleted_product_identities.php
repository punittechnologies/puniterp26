<?php

use App\Models\ProductConfiguration\Product;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        Product::onlyTrashed()
            ->where('name', 'not like', 'Deleted product %')
            ->get()
            ->each(function (Product $product): void {
                $product->forceFill([
                    'name' => 'Deleted product '.$product->id,
                    'product_code' => 'DELETED-'.$product->id,
                    'sku' => null,
                ])->save();
            });
    }

    public function down(): void
    {
        //
    }
};
