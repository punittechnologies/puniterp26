@extends('layouts.admin')

@section('content')
    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Transaction</h2><span class="status-pill">{{ $row->status }}</span></div>
            <dl class="detail-list">
                <div><dt>Serial</dt><dd>{{ $row->label_serial_number ?? $row->serial_number }}</dd></div>
                <div><dt>Barcode</dt><dd><code>{{ $row->barcode_value }}</code></dd></div>
                <div><dt>Gross / Tare / Net</dt><dd>{{ $row->gross_weight }} / {{ $row->tare_weight }} / {{ $row->net_weight }} {{ $row->unit }}</dd></div>
                <div><dt>Pieces</dt><dd>{{ $row->piece_quantity ?? '-' }}</dd></div>
                <div><dt>Captured</dt><dd>{{ $row->captured_at?->format('d M Y H:i') }}</dd></div>
                <div><dt>Product snapshot</dt><dd><pre>{{ json_encode($row->product_snapshot, JSON_PRETTY_PRINT) }}</pre></dd></div>
                <div><dt>Raw scale reading</dt><dd><pre>{{ json_encode($row->raw_reading, JSON_PRETTY_PRINT) }}</pre></dd></div>
            </dl>
        </div>
        <div class="card">
            <div class="card-head"><h2>Controls</h2></div>
            <form method="POST" action="{{ route('admin.production.cancel', $row) }}" class="stack">
                @csrf
                <textarea name="reason" placeholder="Cancellation/reversal reason" required></textarea>
                <button class="btn destructive" @disabled($row->status === 'cancelled')>Cancel and reverse inventory</button>
            </form>
        </div>
        <x-admin.table-card title="Inventory impact" :rows="$inventory" :columns="['transaction_type', 'weight_quantity', 'piece_quantity', 'occurred_at']" />
        <x-admin.table-card title="Audit history" :rows="$audit" :columns="['action', 'created_at', 'metadata']" />
    </section>
@endsection
