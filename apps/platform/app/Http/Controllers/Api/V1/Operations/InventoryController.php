<?php

namespace App\Http\Controllers\Api\V1\Operations;

use App\Http\Controllers\Controller;
use App\Models\InventoryTransaction;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductionTransaction;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InventoryController extends Controller
{
    public function summary(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $query = InventoryTransaction::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->when($request->filled('product_id'), fn ($query) => $query->where('product_id', $request->string('product_id')))
            ->when($request->filled('variant_id'), fn ($query) => $query->where('variant_id', $request->string('variant_id')))
            ->select([
                'product_id',
                'variant_id',
                DB::raw("sum(case when transaction_type in ('production_addition', 'opening_stock', 'manual_adjustment') then weight_quantity else -weight_quantity end) as closing_weight"),
                DB::raw("sum(case when transaction_type in ('production_addition', 'opening_stock', 'manual_adjustment') then coalesce(piece_quantity, 0) else -coalesce(piece_quantity, 0) end) as closing_pieces"),
                DB::raw('count(*) as movement_count'),
            ])
            ->groupBy('product_id', 'variant_id')
            ->orderBy('product_id')
            ->get();

        return response()->json([
            'data' => $query,
            'detail_cards' => $this->detailCards($tenantContext->tenantId()),
        ]);
    }

    public function ledger(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $transactions = InventoryTransaction::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->when($request->filled('product_id'), fn ($query) => $query->where('product_id', $request->string('product_id')))
            ->when($request->filled('variant_id'), fn ($query) => $query->where('variant_id', $request->string('variant_id')))
            ->when($request->filled('barcode'), fn ($query) => $query->where('barcode_value', $request->string('barcode')))
            ->orderByDesc('occurred_at')
            ->paginate((int) $request->integer('per_page', 50));

        return response()->json($transactions);
    }

    private function detailCards(string $tenantId)
    {
        $products = Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id');

        return ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('status', 'active')
            ->latest('captured_at')
            ->limit(300)
            ->get(['product_id', 'dynamic_values', 'net_weight', 'piece_quantity'])
            ->map(function (ProductionTransaction $row) use ($products) {
                $details = collect($row->dynamic_values ?? [])
                    ->filter(fn ($value) => filled($value))
                    ->mapWithKeys(fn ($value, $key) => [
                        str($key)->replace('_', ' ')->title()->toString() => is_array($value)
                            ? implode(', ', $value)
                            : (string) $value,
                    ])
                    ->all();

                return [
                    'product_id' => $row->product_id,
                    'product_name' => $products[$row->product_id] ?? 'Product',
                    'details' => $details,
                    'weight' => (float) $row->net_weight,
                    'pieces' => (float) ($row->piece_quantity ?? 0),
                ];
            })
            ->groupBy(fn ($row) => $row['product_id'].'|'.json_encode($row['details']))
            ->map(function ($rows) {
                $first = $rows->first();

                return [
                    'product_id' => $first['product_id'],
                    'product_name' => $first['product_name'],
                    'details' => $first['details'],
                    'weight' => $rows->sum('weight'),
                    'pieces' => $rows->sum('pieces'),
                    'entries' => $rows->count(),
                ];
            })
            ->sortByDesc('weight')
            ->values();
    }
}
