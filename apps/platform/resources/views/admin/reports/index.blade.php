@extends('layouts.admin')

@section('content')
    @include('admin.partials.operational-report-filters', [
        'filterContext' => $report,
        'filterAction' => url()->current(),
        'clearUrl' => url()->current(),
        'showFilterExports' => ! in_array($report, ['inward', 'dispatch'], true),
    ])
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
