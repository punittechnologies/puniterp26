@extends('layouts.admin')

@section('content')
    @php
        $today = now()->toDateString();
        $quickBase = request()->except(['from', 'to', 'page']);
        $activeFilters = collect($filters)->filter(fn ($value) => filled($value));
    @endphp
    <section class="card report-filter-card">
        <div class="card-head">
            <div>
                <h2>Precise Report Filters</h2>
                <p>The same filters are applied to the screen, PDF, Excel and CSV downloads.</p>
            </div>
            <a class="btn" href="{{ url()->current() }}">Clear all</a>
        </div>
        <div class="report-quick-filters">
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => $today, 'to' => $today]) }}">Today</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->subDay()->toDateString(), 'to' => now()->subDay()->toDateString()]) }}">Yesterday</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->startOfWeek()->toDateString(), 'to' => $today]) }}">This week</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->startOfMonth()->toDateString(), 'to' => $today]) }}">This month</a>
        </div>
        <form class="filter-bar report-filter-grid" method="GET">
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
            <label>Product variant
                <select name="variant_id">
                    <option value="">All variants</option>
                    @foreach($variants as $variant)
                        <option value="{{ $variant->id }}" @selected(($filters['variant_id'] ?? '') === $variant->id)>{{ $variant->name }}</option>
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
            <label>Exact detail value <input name="detail_value" value="{{ $filters['detail_value'] ?? '' }}" placeholder="Exact value, e.g. Blue"></label>
            <label>Serial number <input name="serial" value="{{ $filters['serial'] ?? '' }}" placeholder="Search serial"></label>
            <label>Barcode <input name="barcode" value="{{ $filters['barcode'] ?? '' }}" placeholder="Scan/search barcode"></label>
            <label>{{ $report === 'dispatch' ? 'Dispatch' : 'Inward' }} number
                <input name="transaction_number" value="{{ $filters['transaction_number'] ?? '' }}" placeholder="Transaction number">
            </label>
            @if($report === 'dispatch')
                <label>Customer
                    <select name="customer_id"><option value="">All customers</option>@foreach($customers as $customer)<option value="{{ $customer->id }}" @selected(($filters['customer_id'] ?? '') === $customer->id)>{{ $customer->name }}</option>@endforeach</select>
                </label>
                <label>Status <select name="status"><option value="">All statuses</option>@foreach(['confirmed', 'draft', 'reversed', 'cancelled'] as $status)<option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ str($status)->title() }}</option>@endforeach</select></label>
            @endif
        @endif
            @if(in_array($report, ['inventory', 'inventory-ledger'], true))
                <label>Movement type <select name="transaction_type"><option value="">All movement types</option>@foreach($transactionTypes as $type)<option value="{{ $type }}" @selected(($filters['transaction_type'] ?? '') === $type)>{{ str($type)->replace('_', ' ')->title() }}</option>@endforeach</select></label>
                <label>Search everything <input name="search" value="{{ $filters['search'] ?? '' }}" placeholder="Product, variant, serial or barcode"></label>
            @endif
            <details class="report-advanced-filters">
                <summary>Advanced weight and PCS filters</summary>
                <div class="report-filter-grid">
                    <label>Minimum net kg <input type="number" min="0" step="0.001" name="weight_min" value="{{ $filters['weight_min'] ?? '' }}"></label>
                    <label>Maximum net kg <input type="number" min="0" step="0.001" name="weight_max" value="{{ $filters['weight_max'] ?? '' }}"></label>
                    <label>Minimum converted PCS <input type="number" min="0" step="1" name="pieces_min" value="{{ $filters['pieces_min'] ?? '' }}"></label>
                    <label>Maximum converted PCS <input type="number" min="0" step="1" name="pieces_max" value="{{ $filters['pieces_max'] ?? '' }}"></label>
                </div>
            </details>
            <button class="btn primary">Apply filters</button>
        @unless (in_array($report, ['inward', 'dispatch'], true))
            <a class="btn" href="{{ route('admin.exports', [$report, 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
            <a class="btn" href="{{ route('admin.exports', [$report, 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
            <a class="btn" href="{{ route('admin.exports', [$report, 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
        @endunless
        </form>
        @if($activeFilters->isNotEmpty())
            <div class="active-filter-chips">
                @foreach($activeFilters as $key => $value)<span><strong>{{ str($key)->replace('_', ' ')->title() }}:</strong> {{ $value }}</span>@endforeach
            </div>
        @endif
    </section>
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
                            <a class="btn primary" href="{{ route('admin.inward.export', [$session->session_key, 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
                            <a class="btn" href="{{ route('admin.inward.export', [$session->session_key, 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
                            <a class="btn" href="{{ route('admin.inward.export', [$session->session_key, 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
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
                            <a class="btn primary" href="{{ route('admin.dispatch.export', [$dispatch, 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
                            <a class="btn" href="{{ route('admin.dispatch.export', [$dispatch, 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
                            <a class="btn" href="{{ route('admin.dispatch.export', [$dispatch, 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
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
