<?php

namespace App\Livewire\Products;

use App\Models\InventoryTransaction;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\UnitConversionRule;
use App\Models\ProductionTransaction;
use App\Support\ProductCustomerBarcode;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Livewire\Component;
use Livewire\WithPagination;

class ProductManager extends Component
{
    use WithPagination;

    public string $search = '';

    public ?string $editingProductId = null;

    public array $form = [];

    public bool $hasWeightRange = false;

    public bool $hasUnitConversion = false;

    public bool $hasCustomerBarcode = false;

    public function editProduct(string $productId): void
    {
        $product = Product::query()->where('tenant_id', $this->tenantId())->findOrFail($productId);
        $conversion = UnitConversionRule::query()
            ->where('tenant_id', $this->tenantId())
            ->where('product_id', $product->id)
            ->whereNull('variant_id')
            ->where('is_active', true)
            ->latest()
            ->first();

        $this->editingProductId = $product->id;
        $this->hasWeightRange = filled($product->getRawOriginal('minimum_weight')) || filled($product->getRawOriginal('maximum_weight'));
        $this->hasUnitConversion = (bool) $product->unit_conversion_enabled;
        $this->hasCustomerBarcode = (bool) $product->customer_barcode_enabled;
        $this->form = [
            'name' => $product->name,
            'default_tare_weight' => $this->decimalForForm($product->getRawOriginal('default_tare_weight') ?? 0),
            'minimum_weight' => $this->decimalForForm($product->getRawOriginal('minimum_weight')),
            'maximum_weight' => $this->decimalForForm($product->getRawOriginal('maximum_weight')),
            'pieces_per_kg' => $this->decimalForForm($conversion?->getRawOriginal('pieces_per_kg')),
            'customer_barcode_type' => $product->customer_barcode_type ?: 'code128',
            'customer_barcode_value' => $product->customer_barcode_value ?? '',
            'customer_barcode_caption' => $product->customer_barcode_caption ?? 'CUSTOMER SKU',
        ];
        $this->resetValidation();
    }

    public function newProduct(): void
    {
        $this->editingProductId = null;
        $this->hasWeightRange = false;
        $this->hasUnitConversion = false;
        $this->hasCustomerBarcode = false;
        $this->form = [
            'name' => '',
            'default_tare_weight' => '',
            'minimum_weight' => '',
            'maximum_weight' => '',
            'pieces_per_kg' => '',
            'customer_barcode_type' => 'code128',
            'customer_barcode_value' => '',
            'customer_barcode_caption' => 'CUSTOMER SKU',
        ];
        $this->resetValidation();
    }

    public function saveProduct(): void
    {
        $tenantId = $this->tenantId();
        $validated = $this->validate([
            'form.name' => ['required', 'string', 'max:255'],
            'form.default_tare_weight' => ['nullable', 'numeric', 'min:0'],
            'form.minimum_weight' => [$this->hasWeightRange ? 'required' : 'nullable', 'numeric', 'min:0'],
            'form.maximum_weight' => [$this->hasWeightRange ? 'required' : 'nullable', 'numeric', 'min:0', 'gte:form.minimum_weight'],
            'form.pieces_per_kg' => [$this->hasUnitConversion ? 'required' : 'nullable', 'numeric', 'min:0'],
            'form.customer_barcode_type' => [$this->hasCustomerBarcode ? 'required' : 'nullable', 'string', 'in:'.implode(',', array_keys(ProductCustomerBarcode::TYPES))],
            'form.customer_barcode_value' => [$this->hasCustomerBarcode ? 'required' : 'nullable', 'string', 'max:120'],
            'form.customer_barcode_caption' => ['nullable', 'string', 'max:80'],
        ])['form'];

        if ($this->hasCustomerBarcode) {
            $message = ProductCustomerBarcode::validationMessage(
                (string) ($validated['customer_barcode_type'] ?? ''),
                trim((string) ($validated['customer_barcode_value'] ?? '')),
            );
            if ($message) {
                $this->addError('form.customer_barcode_value', $message);

                return;
            }
        }

        $productData = [
            'name' => $validated['name'],
            'default_tare_weight' => $this->nullableDecimal($validated['default_tare_weight'] ?? null) ?? '0',
            'minimum_weight' => $this->hasWeightRange ? $this->nullableDecimal($validated['minimum_weight'] ?? null) : null,
            'maximum_weight' => $this->hasWeightRange ? $this->nullableDecimal($validated['maximum_weight'] ?? null) : null,
            'unit_conversion_enabled' => $this->hasUnitConversion,
            'customer_barcode_enabled' => $this->hasCustomerBarcode,
            'customer_barcode_type' => $this->hasCustomerBarcode ? $validated['customer_barcode_type'] : null,
            'customer_barcode_value' => $this->hasCustomerBarcode ? trim((string) $validated['customer_barcode_value']) : null,
            'customer_barcode_caption' => $this->hasCustomerBarcode
                ? (trim((string) ($validated['customer_barcode_caption'] ?? '')) ?: 'CUSTOMER SKU')
                : null,
            'updated_by' => Auth::id(),
            'configuration_activated_at' => now(),
        ];

        DB::transaction(function () use ($tenantId, $validated, $productData): void {
            if ($this->editingProductId) {
                $product = Product::query()->where('tenant_id', $tenantId)->findOrFail($this->editingProductId);
                $product->update([
                    ...$productData,
                    'configuration_version' => $product->configuration_version + 1,
                ]);
                session()->flash('status', 'Product updated.');
            } else {
                $this->releaseDeletedProductIdentity($validated['name'], $tenantId);
                $product = $this->createProductWithUniqueCode($validated['name'], $tenantId, $productData);
                session()->flash('status', 'Product created.');
            }

            UnitConversionRule::query()
                ->where('tenant_id', $tenantId)
                ->where('product_id', $product->id)
                ->whereNull('variant_id')
                ->update(['is_active' => false, 'updated_by' => Auth::id()]);

            if ($this->hasUnitConversion) {
                UnitConversionRule::query()->create([
                    'tenant_id' => $tenantId,
                    'product_id' => $product->id,
                    'method' => 'pieces_per_kg',
                    'pieces_per_kg' => $this->nullableDecimal($validated['pieces_per_kg'] ?? null),
                    'rounding_method' => 'nearest',
                    'decimal_places' => 0,
                    'is_active' => true,
                    'created_by' => Auth::id(),
                    'updated_by' => Auth::id(),
                ]);
            }
        });

        $this->newProduct();
    }

    public function deleteProduct(string $productId): void
    {
        $tenantId = $this->tenantId();
        $product = Product::query()->where('tenant_id', $tenantId)->findOrFail($productId);

        DB::transaction(function () use ($product, $tenantId): void {
            if (! $this->productHasTransactionHistory($product->id, $tenantId)) {
                $product->forceDelete();

                return;
            }

            $product->forceFill([
                'name' => 'Deleted product '.$product->id,
                'product_code' => 'DELETED-'.$product->id,
                'sku' => null,
                'is_active' => false,
                'updated_by' => Auth::id(),
            ])->save();
            $product->delete();
        });

        session()->flash('status', 'Product removed. Same product name can be created again.');
    }

    public function render(): mixed
    {
        $tenantId = $this->tenantId();
        $canBulkDelete = Auth::user()?->isSuperAdmin() || Auth::user()?->hasPermission('users.manage');

        return view('livewire.products.product-manager', [
            'customerBarcodeTypes' => ProductCustomerBarcode::TYPES,
            'canBulkDelete' => $canBulkDelete,
            'bulkDeleteCounts' => $canBulkDelete ? [
                'products' => Product::query()->where('tenant_id', $tenantId)->count(),
                'details' => DynamicFieldDefinition::query()
                    ->where('tenant_id', $tenantId)
                    ->where('entity_type', 'product_variant')
                    ->count(),
            ] : ['products' => 0, 'details' => 0],
            'products' => Product::query()
                ->where('tenant_id', $tenantId)
                ->when($this->search, fn ($query) => $query->where('name', 'like', '%'.$this->search.'%'))
                ->latest()
                ->paginate(12),
        ]);
    }

    private function nextProductCode(string $name, string $tenantId): string
    {
        $base = Str::of($name)->slug('-')->upper()->limit(40, '')->toString() ?: 'PRODUCT';
        $code = $base;
        $counter = 1;

        while (Product::query()->where('tenant_id', $tenantId)->where('product_code', $code)->exists()) {
            $counter++;
            $code = $base.'-'.$counter;
        }

        return $code;
    }

    private function createProductWithUniqueCode(string $name, string $tenantId, array $productData): Product
    {
        for ($attempt = 0; $attempt < 10; $attempt++) {
            try {
                return Product::query()->create([
                    'tenant_id' => $tenantId,
                    ...$productData,
                    'product_code' => $this->nextProductCode($name, $tenantId),
                    'is_active' => true,
                    'weight_decimal_precision' => 3,
                    'manual_print_enabled' => true,
                    'duplicate_print_prevention_enabled' => true,
                    'product_selection_mode' => 'operator_can_select',
                    'created_by' => Auth::id(),
                ]);
            } catch (QueryException $exception) {
                if (! $this->isProductCodeDuplicate($exception)) {
                    throw $exception;
                }
            }
        }

        throw new \RuntimeException('Unable to create a unique product code. Please try again.');
    }

    private function productHasTransactionHistory(string $productId, string $tenantId): bool
    {
        return ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('product_id', $productId)
            ->exists()
            || InventoryTransaction::query()
                ->where('tenant_id', $tenantId)
                ->where('product_id', $productId)
                ->exists();
    }

    private function releaseDeletedProductIdentity(string $name, string $tenantId): void
    {
        Product::onlyTrashed()
            ->where('tenant_id', $tenantId)
            ->where('name', $name)
            ->get()
            ->each(function (Product $product): void {
                $product->forceFill([
                    'name' => 'Deleted product '.$product->id,
                    'product_code' => 'DELETED-'.$product->id,
                    'sku' => null,
                    'updated_by' => Auth::id(),
                ])->save();
            });
    }

    private function isProductCodeDuplicate(QueryException $exception): bool
    {
        $message = $exception->getMessage();

        return str_contains($message, 'products.tenant_id, products.product_code')
            || str_contains($message, 'products_tenant_id_product_code_unique')
            || str_contains($message, "for key 'products_tenant_id_product_code_unique'");
    }

    private function nullableDecimal(mixed $value): ?string
    {
        if ($value === '' || $value === null) {
            return null;
        }

        return (string) $value;
    }

    private function decimalForForm(mixed $value): string
    {
        if ($value === '' || $value === null) {
            return '';
        }

        return rtrim(rtrim((string) $value, '0'), '.') ?: '0';
    }

    private function tenantId(): string
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);

        return $tenantId;
    }
}
