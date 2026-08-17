@extends('layouts.admin')

@section('content')
    <form class="card form-grid" method="POST" action="{{ route('admin.production.create') }}">
        @csrf
        <div class="card-head full">
            <div>
                <h2>Add Inward / Production Transaction</h2>
                <p>Manual web entry for start-to-end inward records. Tablet scale captures still sync here automatically.</p>
            </div>
            <button class="btn primary">Save Inward Entry</button>
        </div>
        <label>Product
            <select name="product_id" required>
                <option value="">Select product</option>
                @foreach ($products as $product)
                    <option value="{{ $product->id }}">{{ $product->name }} - {{ $product->product_code }}</option>
                @endforeach
            </select>
        </label>
        <label>Gross weight <input name="gross_weight" inputmode="decimal" required></label>
        <label>Tare weight <input name="tare_weight" inputmode="decimal" placeholder="Uses product tare if blank"></label>
        <label>Pieces <input name="piece_quantity" inputmode="decimal" placeholder="Optional"></label>
        <label>Unit <input name="unit" value="kg"></label>
        <label>Serial number <input name="serial_number" placeholder="Auto if blank"></label>
        <label>Barcode <input name="barcode_value" placeholder="Auto if blank"></label>
        <label>Entry date/time <input type="datetime-local" name="captured_at"></label>
    </form>

    <form class="filter-bar" method="GET">
        <label>Start date <input type="date" name="from" value="{{ $filters['from'] }}"></label>
        <label>End date <input type="date" name="to" value="{{ $filters['to'] }}"></label>
        <label>Search <input name="search" value="{{ $filters['search'] }}" placeholder="Serial or barcode"></label>
        <label>Status <input name="status" value="{{ $filters['status'] }}" placeholder="active/cancelled"></label>
        <button class="btn primary">Filter</button>
        <a class="btn" href="{{ route('admin.exports', ['inward', 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
        <a class="btn" href="{{ route('admin.exports', ['inward', 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
        <a class="btn" href="{{ route('admin.exports', ['inward', 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
    </form>

    <div class="card">
        <div class="card-head"><h2>Production Transactions</h2></div>
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Serial</th><th>Barcode</th><th>Product</th><th>Gross</th><th>Tare</th><th>Net</th><th>PCS</th><th>Status</th><th>Date</th><th></th></tr></thead>
                <tbody>
                    @forelse ($rows as $row)
                        <tr>
                            <td>{{ $row->label_serial_number ?? $row->serial_number }}</td>
                            <td><code>{{ $row->barcode_value }}</code></td>
                            <td>{{ $row->product_snapshot['name'] ?? $productNames[$row->product_id] ?? 'Unknown product' }}</td>
                            <td>{{ $row->gross_weight }}</td>
                            <td>{{ $row->tare_weight }}</td>
                            <td><strong>{{ $row->net_weight }}</strong></td>
                            <td>{{ $row->piece_quantity ?? '-' }}</td>
                            <td><span class="status-pill">{{ $row->status }}</span></td>
                            <td>{{ $row->captured_at?->format('d M Y H:i') }}</td>
                            <td>
                                @if ($row->status === 'cancelled')
                                    <button class="btn small" disabled>Cancelled</button>
                                @else
                                    <form method="POST" action="{{ route('admin.production.cancel', $row) }}" onsubmit="return confirm('Cancel this production transaction and reverse inventory?')">
                                        @csrf
                                        <input type="hidden" name="reason" value="Cancelled from production transactions list.">
                                        <button class="btn small destructive">Cancel</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="10" class="empty">No production records found.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $rows->links() }}
    </div>
@endsection
