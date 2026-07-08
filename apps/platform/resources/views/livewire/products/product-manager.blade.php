<div class="product-simple">
    <form wire:submit="saveProduct" class="card form-grid">
        <div class="card-head full">
            <div>
                <h2>{{ $editingProductId ? 'Edit Product' : 'Create Product' }}</h2>
                <p>Enter product name. Tare, weight range and unit conversion are optional.</p>
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
                            <td>{{ $product->created_at?->format('d M Y') }}</td>
                            <td class="actions">
                                <button class="btn" wire:click="editProduct('{{ $product->id }}')">Edit</button>
                                <button class="btn danger" wire:click="deleteProduct('{{ $product->id }}')" wire:confirm="Remove this product?">Delete</button>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="empty">No products yet. Create your first product above.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $products->links() }}
    </div>
</div>
