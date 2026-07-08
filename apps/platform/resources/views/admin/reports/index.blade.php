@extends('layouts.admin')

@section('content')
    <form class="filter-bar" method="GET">
        <label>Start date <input type="date" name="from" value="{{ $filters['from'] }}"></label>
        <label>End date <input type="date" name="to" value="{{ $filters['to'] }}"></label>
        @if (in_array($report, ['inward', 'dispatch'], true))
            <label>Product
                <select name="product_id">
                    <option value="">All products</option>
                    @foreach($products as $product)
                        <option value="{{ $product->id }}" @selected(($filters['product_id'] ?? '') === $product->id)>{{ $product->name }}</option>
                    @endforeach
                </select>
            </label>
            <label>Product detail
                <select name="detail_key">
                    <option value="">Any field</option>
                    @foreach($productFields as $field)
                        <option value="{{ $field->internal_key }}" @selected(($filters['detail_key'] ?? '') === $field->internal_key)>{{ $field->field_label }}</option>
                    @endforeach
                </select>
            </label>
            <label>Detail value <input name="detail_value" value="{{ $filters['detail_value'] ?? '' }}" placeholder="e.g. blue, 350"></label>
            <label>Barcode <input name="barcode" value="{{ $filters['barcode'] ?? '' }}" placeholder="Scan/search barcode"></label>
        @endif
        <button class="btn primary">Apply</button>
        @unless (in_array($report, ['inward', 'dispatch'], true))
            <a class="btn" href="{{ route('admin.exports', [$report, 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
            <a class="btn" href="{{ route('admin.exports', [$report, 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
            <a class="btn" href="{{ route('admin.exports', [$report, 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
        @endunless
    </form>
    @if ($showTabs ?? true)
        <div class="tabs">
            @foreach(['inward' => 'Inward Report', 'inventory' => 'Inventory Report', 'inventory-ledger' => 'Inventory Ledger', 'dispatch' => 'Dispatch Report', 'customer-dispatch' => 'Customer Dispatch', 'audit' => 'Audit Report'] as $tab => $label)
                <a @class(['active' => $report === $tab]) href="{{ route('admin.reports', $tab) }}">{{ $label }}</a>
            @endforeach
        </div>
    @endif
    @if ($report === 'inward')
        <section class="dispatch-card-grid">
            @forelse ($rows as $session)
                <article class="dispatch-report-card">
                    <div class="dispatch-card-head">
                        <div>
                            <p class="eyebrow">Inward Transaction</p>
                            <h2>{{ $session->session_number ?? 'INW-'.\Carbon\Carbon::parse($session->session_key)->format('Ymd') }}</h2>
                            <span class="status-pill success">Saved</span>
                        </div>
                        <div class="dispatch-actions">
                            <a class="btn primary" href="{{ route('admin.inward.export', [$session->session_key, 'pdf']) }}">PDF</a>
                            <a class="btn" href="{{ route('admin.inward.export', [$session->session_key, 'xlsx']) }}">Excel</a>
                            <a class="btn" href="{{ route('admin.inward.export', [$session->session_key, 'csv']) }}">CSV</a>
                        </div>
                    </div>

                    <dl class="dispatch-stats">
                        <div><dt>Started</dt><dd>{{ \Carbon\Carbon::parse($session->started_at)->format('d M Y H:i') }}</dd></div>
                        <div><dt>Saved</dt><dd>{{ \Carbon\Carbon::parse($session->ended_at)->format('d M Y H:i') }}</dd></div>
                        <div><dt>Entries</dt><dd>{{ $session->entries_count }}</dd></div>
                        <div><dt>Gross weight</dt><dd>{{ number_format((float) $session->gross_weight, 3) }} kg</dd></div>
                        <div><dt>Tare</dt><dd>{{ number_format((float) $session->tare_weight, 3) }} kg</dd></div>
                        <div><dt>Net weight</dt><dd>{{ number_format((float) $session->net_weight, 3) }} kg</dd></div>
                        <div><dt>Converted unit</dt><dd>{{ number_format((float) $session->piece_quantity, 2) }}</dd></div>
                    </dl>
                </article>
            @empty
                <div class="card empty">No inward transactions found for this date range.</div>
            @endforelse
        </section>
    @elseif ($report === 'dispatch')
        <section class="dispatch-card-grid">
            @forelse ($rows as $dispatch)
                <article class="dispatch-report-card">
                    <div class="dispatch-card-head">
                        <div>
                            <p class="eyebrow">Dispatch Transaction</p>
                            <h2>{{ $dispatch->dispatch_number }}</h2>
                            <span class="status-pill">{{ $dispatch->status }}</span>
                        </div>
                        <div class="dispatch-actions">
                            <a class="btn primary" href="{{ route('admin.dispatch.export', [$dispatch, 'pdf']) }}">PDF</a>
                            <a class="btn" href="{{ route('admin.dispatch.export', [$dispatch, 'xlsx']) }}">Excel</a>
                            <a class="btn" href="{{ route('admin.dispatch.export', [$dispatch, 'csv']) }}">CSV</a>
                        </div>
                    </div>

                    <dl class="dispatch-stats">
                        <div><dt>Customer</dt><dd>{{ data_get($dispatch->customer_snapshot, 'name', '-') }}</dd></div>
                        <div><dt>Date</dt><dd>{{ ($dispatch->confirmed_at ?? $dispatch->created_at)?->format('d M Y H:i') }}</dd></div>
                        <div><dt>Barcodes</dt><dd>{{ $dispatch->items_count ?? 0 }}</dd></div>
                        <div><dt>Total weight</dt><dd>{{ $dispatch->total_weight }} kg</dd></div>
                        <div><dt>Total pieces</dt><dd>{{ $dispatch->total_pieces ?? '-' }}</dd></div>
                    </dl>
                </article>
            @empty
                <div class="card empty">No dispatch transactions found for this date range.</div>
            @endforelse
        </section>
    @else
        <x-admin.table-card :title="($report === 'inward' ? 'Inward Transaction Report' : str($report)->replace('-', ' ')->title().' Report')" :rows="$rows" :columns="$columns" />
    @endif

    {{ $rows->links() }}
@endsection
