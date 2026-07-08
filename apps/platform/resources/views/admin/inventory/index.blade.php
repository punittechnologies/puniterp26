@extends('layouts.admin')

@section('content')
    <section class="metric-grid">
        <x-admin.metric label="Current weight" :value="number_format($totals['weight'], 3).' kg'" />
        <x-admin.metric label="Current pieces" :value="number_format($totals['pieces'], 0)" />
        <x-admin.metric label="Product rows" :value="$summary->total()" />
    </section>

    <section class="card">
        <div class="card-head">
            <div>
                <h2>Product-wise Inventory</h2>
                <p>Bird’s-eye stock position by product and product detail fields.</p>
            </div>
        </div>
        <div class="inventory-card-grid">
            @forelse($summary->take(12) as $row)
                <div class="inventory-card">
                    <span>{{ $productNames[$row->product_id] ?? 'Product' }}</span>
                    <strong>{{ number_format((float)$row->weight, 3) }} kg</strong>
                    <small>{{ $variantNames[$row->variant_id] ?? 'All details' }} · {{ number_format((float)$row->pieces, 0) }} pcs</small>
                </div>
            @empty
                <p class="empty">No inventory yet.</p>
            @endforelse
        </div>
    </section>

    <section class="card">
        <div class="card-head"><h2>Product Detail-wise Inventory</h2></div>
        <div class="inventory-card-grid compact">
            @forelse($detailCards as $card)
                <div class="inventory-card soft">
                    <span>{{ $card['product'] }}</span>
                    <strong>{{ number_format($card['weight'], 3) }} kg</strong>
                    <div class="inventory-detail-tags">
                        @forelse($card['details'] as $field => $value)
                            <em>{{ $field }}: {{ $value }}</em>
                        @empty
                            <em>Base product</em>
                        @endforelse
                    </div>
                    <small>{{ $card['entries'] }} entries · {{ number_format($card['pieces'], 0) }} pcs</small>
                </div>
            @empty
                <p class="empty">No product-detail inventory split yet.</p>
            @endforelse
        </div>
    </section>

    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Manual Adjustment</h2></div>
            <form method="POST" action="{{ route('admin.inventory.adjust') }}" class="form-grid">
                @csrf
                <label>Product<select name="product_id" required>@foreach($products as $product)<option value="{{ $product->id }}">{{ $product->name }}</option>@endforeach</select></label>
                <label>Type<select name="transaction_type"><option value="manual_adjustment">Manual adjustment</option><option value="opening_stock">Opening stock</option></select></label>
                <label>Weight<input name="weight_quantity" type="number" step="0.001" required></label>
                <label>Pieces<input name="piece_quantity" type="number" step="1"></label>
                <label class="full">Reason<textarea name="reason" required></textarea></label>
                <button class="btn primary">Post adjustment</button>
            </form>
        </div>
        @if (auth()->user()?->isSuperAdmin() || auth()->user()?->hasPermission('users.manage'))
            <div class="card">
                <div class="card-head"><h2>Clear Inventory Data</h2></div>
                <p class="muted">Admin-only action. This clears only operational stock data for this tenant: inward entries, barcode records, dispatches and inventory ledger. Products, product details, customers, users and settings remain unchanged.</p>
                <form method="POST" action="{{ route('admin.inventory.clear') }}" class="form-grid" onsubmit="return confirm('This will permanently clear tenant inventory, inward and dispatch transaction data. Continue?');">
                    @csrf
                    @method('DELETE')
                    <label class="full">Type CLEAR INVENTORY to confirm
                        <input name="confirm" placeholder="CLEAR INVENTORY" required>
                    </label>
                    <label class="full">Admin password
                        <input name="password" type="password" placeholder="Enter your login password" required autocomplete="current-password">
                    </label>
                    <button class="btn destructive full">Clear inventory transaction data</button>
                </form>
            </div>
        @endif
    </section>

    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Product-wise Inventory</h2></div>
            <div class="table-wrap"><table class="data-table"><thead><tr><th>Product</th><th>Variant</th><th>Weight</th><th>PCS</th><th>Last movement</th></tr></thead><tbody>
                @foreach($summary as $row)
                    <tr><td>{{ $productNames[$row->product_id] ?? $row->product_id }}</td><td>{{ $variantNames[$row->variant_id] ?? '-' }}</td><td>{{ number_format((float)$row->weight, 3) }}</td><td>{{ number_format((float)$row->pieces, 0) }}</td><td>{{ $row->last_movement }}</td></tr>
                @endforeach
            </tbody></table></div>
            {{ $summary->links() }}
        </div>
    </section>

    <div class="card">
        <div class="card-head"><h2>Inventory Ledger</h2><a class="btn" href="{{ route('admin.exports', ['inventory-ledger', 'csv']) }}">Export CSV</a></div>
        <div class="table-wrap"><table class="data-table"><thead><tr><th>Type</th><th>Product</th><th>Barcode</th><th>Weight</th><th>PCS</th><th>Reference</th><th>Date</th></tr></thead><tbody>
            @foreach($ledger as $row)
                <tr><td>{{ $row->transaction_type }}</td><td>{{ $productNames[$row->product_id] ?? $row->product_id }}</td><td>{{ $row->barcode_value ?? '-' }}</td><td>{{ $row->weight_quantity }}</td><td>{{ $row->piece_quantity ?? '-' }}</td><td>{{ $row->reference_type }}</td><td>{{ $row->occurred_at?->format('d M Y H:i') }}</td></tr>
            @endforeach
        </tbody></table></div>
        {{ $ledger->links() }}
    </div>
@endsection
