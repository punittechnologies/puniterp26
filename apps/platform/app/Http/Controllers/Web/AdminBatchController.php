<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductBatch;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class AdminBatchController extends Controller
{
    public function index(): View
    {
        $tenantId = $this->tenantId();

        return view('admin.batches.index', [
            'title' => 'Product Batches',
            'rows' => ProductBatch::query()
                ->with('product:id,name,product_code')
                ->where('tenant_id', $tenantId)
                ->latest()
                ->paginate(25),
            'products' => Product::query()
                ->where('tenant_id', $tenantId)
                ->where('is_active', true)
                ->orderBy('name')
                ->get(['id', 'name', 'product_code']),
            'fields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $tenantId)
                ->where('entity_type', 'product_variant')
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('field_label')
                ->get(['id', 'internal_key', 'field_label', 'dropdown_options']),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $tenantId = $this->tenantId();
        $data = $request->validate([
            'batch_name' => ['required', 'string', 'max:120'],
            'items' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.product_id' => [
                'required',
                Rule::exists('products', 'id')->where('tenant_id', $tenantId),
            ],
            'items.*.details' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.details.*.field_id' => [
                'required',
                Rule::exists('dynamic_field_definitions', 'id')
                    ->where('tenant_id', $tenantId)
                    ->where('entity_type', 'product_variant'),
            ],
            'items.*.details.*.value' => ['required', 'string', 'max:255'],
        ]);

        $fieldIds = collect($data['items'])
            ->flatMap(fn (array $item) => collect($item['details'])->pluck('field_id'))
            ->map(fn ($id) => (string) $id)
            ->unique()
            ->values();
        $fields = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('entity_type', 'product_variant')
            ->where('is_active', true)
            ->whereIn('id', $fieldIds)
            ->get()
            ->keyBy('id');
        abort_if($fields->count() !== $fieldIds->count(), 422, 'Select valid active product details.');

        $products = Product::query()
            ->where('tenant_id', $tenantId)
            ->whereIn('id', collect($data['items'])->pluck('product_id')->unique())
            ->get(['id', 'name', 'product_code'])
            ->keyBy('id');

        $batchItems = collect($data['items'])->map(function (array $item) use ($fields, $products): array {
            $details = collect($item['details']);
            abort_if($details->pluck('field_id')->duplicates()->isNotEmpty(), 422, 'Select each field once per product.');

            $normalizedDetails = $details->mapWithKeys(function (array $detail) use ($fields): array {
                $field = $fields->get((string) $detail['field_id']);
                $value = trim((string) $detail['value']);
                abort_if(! $field || $value === '', 422, 'Select a value for every product detail.');

                return [
                    $field->internal_key => [
                        'label' => $field->field_label,
                        'value' => $value,
                    ],
                ];
            })->all();
            $product = $products->get($item['product_id']);

            return [
                'product_id' => $item['product_id'],
                'product_name' => $product?->name,
                'product_code' => $product?->product_code,
                'details' => $normalizedDetails,
            ];
        })->values()->all();

        [$firstKey, $firstDetail, $firstDetails, $signature] = $this->legacyValues($batchItems);
        $batchName = trim($data['batch_name']);
        $batch = ProductBatch::withTrashed()
            ->where('tenant_id', $tenantId)
            ->where('batch_name', $batchName)
            ->where('product_id', $batchItems[0]['product_id'])
            ->where('detail_signature', $signature)
            ->first();
        $created = ! $batch;
        $values = [
            'tenant_id' => $tenantId,
            'batch_name' => $batchName,
            'product_id' => $batchItems[0]['product_id'],
            'attribute_key' => $firstKey,
            'attribute_label' => $firstDetail['label'],
            'attribute_value' => $firstDetail['value'],
            'detail_values' => $firstDetails,
            'batch_items' => $batchItems,
            'detail_signature' => $signature,
            'is_active' => true,
            'updated_by' => Auth::id(),
        ];

        if ($batch) {
            $old = $batch->toArray();
            $batch->restore();
            $batch->update($values);
        } else {
            $old = [];
            $batch = ProductBatch::query()->create([
                ...$values,
                'created_by' => Auth::id(),
            ]);
        }

        $this->audit($created ? 'batch.created' : 'batch.updated', $batch, $old, $batch->fresh()->toArray());

        return back()->with('status', 'Batch saved and ready to sync with the app.');
    }

    public function destroy(ProductBatch $batch): RedirectResponse
    {
        $this->ensureTenant($batch);
        $old = $batch->toArray();
        $batch->update(['is_active' => false, 'updated_by' => Auth::id()]);
        $batch->delete();
        $this->audit('batch.deleted', $batch, $old, ['deleted_at' => now()->toISOString()]);

        return back()->with('status', 'Batch removed from app sync.');
    }

    public function destroyField(ProductBatch $batch, int $itemIndex, string $fieldKey): RedirectResponse
    {
        $this->ensureTenant($batch);
        $old = $batch->toArray();
        $items = collect($batch->batch_items ?: [[
            'product_id' => $batch->product_id,
            'product_name' => $batch->product?->name,
            'details' => $batch->detail_values ?: [],
        ]])->values()->all();

        abort_unless(isset($items[$itemIndex]['details'][$fieldKey]), 404);
        unset($items[$itemIndex]['details'][$fieldKey]);
        abort_if(collect($items)->every(fn (array $item) => empty($item['details'])), 422, 'A batch must keep at least one detail.');

        [$firstKey, $firstDetail, $firstDetails, $signature] = $this->legacyValues($items);
        $batch->update([
            'attribute_key' => $firstKey,
            'attribute_label' => $firstDetail['label'],
            'attribute_value' => $firstDetail['value'],
            'detail_values' => $firstDetails,
            'batch_items' => $items,
            'detail_signature' => $signature,
            'updated_by' => Auth::id(),
        ]);
        $this->audit('batch.field_deleted', $batch, $old, $batch->fresh()->toArray());

        return back()->with('status', 'Batch field removed.');
    }

    private function legacyValues(array $batchItems): array
    {
        $firstDetails = collect($batchItems)
            ->first(fn (array $item) => ! empty($item['details']))['details'] ?? [];
        $firstKey = (string) array_key_first($firstDetails);
        $firstDetail = $firstDetails[$firstKey] ?? ['label' => '', 'value' => ''];
        $signature = md5(json_encode(collect($batchItems)->map(fn (array $item) => [
            'product_id' => $item['product_id'] ?? null,
            'details' => collect($item['details'] ?? [])
                ->mapWithKeys(fn (array $detail, string $key) => [$key => $detail['value'] ?? ''])
                ->sortKeys()
                ->all(),
        ])->values()->all()));

        return [$firstKey, $firstDetail, $firstDetails, $signature];
    }

    private function tenantId(): string
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);

        return $tenantId;
    }

    private function ensureTenant(ProductBatch $batch): void
    {
        abort_unless($batch->tenant_id === $this->tenantId(), 404);
    }

    private function audit(string $action, ProductBatch $batch, array $old, array $new): void
    {
        AuditLog::query()->create([
            'tenant_id' => $this->tenantId(),
            'user_id' => Auth::id(),
            'action' => $action,
            'auditable_type' => ProductBatch::class,
            'auditable_id' => $batch->id,
            'old_values' => $old,
            'new_values' => $new,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }
}
