<div class="product-simple">
    <form wire:submit="saveProduct" class="card form-grid">
        <div class="card-head full">
            <div>
                <h2>{{ $editingProductId ? 'Edit Product' : 'Create Product' }}</h2>
                <p>Enter product name. Tare, weight range, unit conversion and customer barcode are optional.</p>
            </div>
            @if ($editingProductId)
                <button type="button" wire:click="newProduct" class="btn">New Product</button>
            @endif
        </div>

        <label class="full">Product name
            <input wire:model="form.name" placeholder="Example: HDPE Roll" autofocus>
        </label>
        <label class="full">Tare weight optional
            <input wire:model="form.default_tare_weight" inputmode="decimal" placeholder="Leave blank for 0 kg">
        </label>

        <label class="inline-check full">
            <input type="checkbox" wire:model.live="hasWeightRange">
            Add weight range
        </label>
        @if ($hasWeightRange)
            <label>Minimum weight
                <input wire:model="form.minimum_weight" inputmode="decimal" placeholder="Min kg">
            </label>
            <label>Maximum weight
                <input wire:model="form.maximum_weight" inputmode="decimal" placeholder="Max kg">
            </label>
        @endif

        <label class="inline-check full">
            <input type="checkbox" wire:model.live="hasUnitConversion">
            Add unit conversion
        </label>
        @if ($hasUnitConversion)
            <label class="full">Pieces per kg
                <input wire:model="form.pieces_per_kg" inputmode="decimal" placeholder="Example: 25">
            </label>
        @endif

        <label class="inline-check full">
            <input type="checkbox" wire:model.live="hasCustomerBarcode">
            Add customer SKU / GTIN barcode
        </label>
        @if ($hasCustomerBarcode)
            <label>Barcode type
                <select wire:model="form.customer_barcode_type">
                    @foreach ($customerBarcodeTypes as $value => $label)
                        <option value="{{ $value }}">{{ $label }}</option>
                    @endforeach
                </select>
            </label>
            <label>Barcode value
                <input wire:model="form.customer_barcode_value" placeholder="Customer SKU, GTIN, EAN or UPC" autocomplete="off">
            </label>
            <label class="full">Text printed with barcode
                <input wire:model="form.customer_barcode_caption" placeholder="Example: CUSTOMER SKU">
                <small>This caption can be positioned above or below the customer barcode in Label Templates.</small>
            </label>
        @endif

        @error('*') <p class="notice error full">{{ $message }}</p> @enderror
        <button class="btn primary full">{{ $editingProductId ? 'Update Product' : 'Create Product' }}</button>
    </form>

    <div class="card">
        <div class="card-head">
            <div>
                <h2>Created Products</h2>
                <p>These names are shown to the operator in the tablet app.</p>
            </div>
            <input wire:model.live.debounce.300ms="search" placeholder="Search products">
        </div>
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Product Name</th>
                        <th>Tare</th>
                        <th>Weight Range</th>
                        <th>Conversion</th>
                        <th>Customer Barcode</th>
                        <th>Created</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($products as $product)
                        <tr>
                            <td><strong>{{ $product->name }}</strong></td>
                            <td>{{ $product->getRawOriginal('default_tare_weight') ?? '0' }} kg</td>
                            <td>{{ $product->getRawOriginal('minimum_weight') || $product->getRawOriginal('maximum_weight') ? (($product->getRawOriginal('minimum_weight') ?? '-') . ' - ' . ($product->getRawOriginal('maximum_weight') ?? '-') . ' kg') : '-' }}</td>
                            <td>{{ $product->unit_conversion_enabled ? 'Pieces/kg enabled' : '-' }}</td>
                            <td>
                                @if ($product->customer_barcode_enabled && $product->customer_barcode_value)
                                    <strong>{{ $customerBarcodeTypes[$product->customer_barcode_type] ?? strtoupper((string) $product->customer_barcode_type) }}</strong><br>
                                    <code>{{ $product->customer_barcode_value }}</code>
                                @else
                                    -
                                @endif
                            </td>
                            <td>{{ $product->created_at?->format('d M Y') }}</td>
                            <td class="actions">
                                <button class="btn" wire:click="editProduct('{{ $product->id }}')">Edit</button>
                                <button class="btn danger" wire:click="deleteProduct('{{ $product->id }}')" wire:confirm="Remove this product?">Delete</button>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" class="empty">No products yet. Create your first product above.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $products->links() }}
    </div>
</div>
