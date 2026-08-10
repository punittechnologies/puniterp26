@extends('layouts.admin')

@section('content')
    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Create Web Dispatch</h2></div>
            <form method="POST" action="{{ route('admin.dispatch.create') }}" class="form-grid">
                @csrf
                <label class="full">Customer<select name="customer_id" required>@foreach($customers as $customer)<option value="{{ $customer->id }}">{{ $customer->name }}</option>@endforeach</select></label>
                <label class="full">Barcodes<textarea name="barcodes" rows="6" required placeholder="Paste or scan barcode values, one per line"></textarea></label>
                <button class="btn primary">Validate and confirm dispatch</button>
            </form>
        </div>
        <div class="card">
            <div class="card-head"><h2>Available Recent Barcodes</h2></div>
            <div class="table-wrap"><table class="data-table"><thead><tr><th>Barcode</th><th>Serial</th><th>Weight</th></tr></thead><tbody>
                @foreach($recentAvailable as $row)
                    <tr><td><code>{{ $row->barcode_value }}</code></td><td>{{ $row->label_serial_number ?? $row->serial_number }}</td><td>{{ $row->net_weight }}</td></tr>
                @endforeach
            </tbody></table></div>
        </div>
    </section>

    <div class="card">
        <div class="card-head"><h2>Dispatch History</h2><a class="btn" href="{{ route('admin.exports', ['dispatch', 'csv']) }}">Export CSV</a></div>
        <div class="table-wrap"><table class="data-table"><thead><tr><th>Number</th><th>Customer</th><th>Barcodes shown</th><th>Status</th><th>Total kg</th><th>PCS</th><th>Date</th><th>Reverse</th></tr></thead><tbody>
            @foreach($rows as $row)
                <tr>
                    <td>{{ $row->dispatch_number }}</td>
                    <td>{{ $row->customer_snapshot['name'] ?? $row->customer_id }}</td>
                    <td>
                        <div class="stacked-actions">
                            @foreach($row->items as $item)
                                <form method="POST" action="{{ route('admin.dispatch.items.delete', [$row, $item]) }}" class="inline-form" onsubmit="return confirm('Remove barcode {{ $item->barcode_value }} from this dispatch and restore it to available inventory?');">
                                    @csrf
                                    @method('DELETE')
                                    <code>{{ $item->barcode_value }}</code>
                                    <button class="btn small destructive" @disabled($row->status === 'reversed')>Delete barcode</button>
                                </form>
                            @endforeach
                            @if($row->items->isEmpty())
                                <span class="muted">No barcodes</span>
                            @endif
                        </div>
                    </td>
                    <td><span class="status-pill">{{ $row->status }}</span></td>
                    <td>{{ $row->total_weight }}</td>
                    <td>{{ $row->total_pieces ?? '-' }}</td>
                    <td>{{ $row->confirmed_at?->format('d M Y H:i') ?? $row->created_at->format('d M Y H:i') }}</td>
                    <td>
                        <form method="POST" action="{{ route('admin.dispatch.reverse', $row) }}" class="inline-form">@csrf<input name="reason" placeholder="Reason" required><button class="btn small destructive" @disabled($row->status === 'reversed')>Reverse</button></form>
                    </td>
                </tr>
            @endforeach
        </tbody></table></div>
        {{ $rows->links() }}
    </div>
@endsection
