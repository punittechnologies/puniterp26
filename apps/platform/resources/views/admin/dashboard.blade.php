@extends('layouts.admin')

@section('content')
    <form class="filter-bar" method="GET">
        <label>From <input type="date" name="from" value="{{ $filters['from'] }}"></label>
        <label>To <input type="date" name="to" value="{{ $filters['to'] }}"></label>
        <button class="btn primary">Apply filters</button>
    </form>

    <section class="metric-grid">
        <x-admin.metric label="Today production kg" :value="number_format($kpis['productionWeight'], 3)" />
        <x-admin.metric label="Production entries" :value="$kpis['productionEntries']" />
        <x-admin.metric label="Pieces produced" :value="number_format($kpis['productionPieces'], 0)" />
        <x-admin.metric label="Dispatch kg" :value="number_format($kpis['dispatchWeight'], 3)" />
        <x-admin.metric label="Dispatch pieces" :value="number_format($kpis['dispatchPieces'], 0)" />
        <x-admin.metric label="Net inventory kg" :value="number_format($kpis['inventoryWeight'], 3)" />
        <x-admin.metric label="Net inventory pcs" :value="number_format($kpis['inventoryPieces'], 0)" />
        <x-admin.metric label="Pending sync" :value="$kpis['pendingSync']" tone="warning" />
        <x-admin.metric label="Failed sync" :value="$kpis['failedSync']" tone="error" />
        <x-admin.metric label="Active products" :value="$kpis['activeProducts']" />
        <x-admin.metric label="Active devices" :value="$kpis['activeDevices']" />
    </section>

    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Production by Date</h2></div>
            <div class="chart-list">
                @forelse ($productionByDate as $point)
                    <div><span>{{ $point->day }}</span><b>{{ number_format((float) $point->total, 3) }} kg</b></div>
                @empty
                    <p class="empty">No production in this date range.</p>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Dispatch by Date</h2></div>
            <div class="chart-list">
                @forelse ($dispatchByDate as $point)
                    <div><span>{{ $point->day }}</span><b>{{ number_format((float) $point->total, 3) }} kg</b></div>
                @empty
                    <p class="empty">No dispatches in this date range.</p>
                @endforelse
            </div>
        </div>
    </section>

    <section class="grid two">
        <x-admin.table-card title="Recent production" :rows="$recentProduction" :columns="['serial_number', 'barcode_value', 'net_weight', 'captured_at']" />
        <x-admin.table-card title="Recent dispatches" :rows="$recentDispatches" :columns="['dispatch_number', 'customer_id', 'total_weight', 'status']" />
        <x-admin.table-card title="Failed sync records" :rows="$failedSync" :columns="['entity_type', 'operation', 'attempt_count', 'last_error']" />
        <x-admin.table-card title="Recently active devices" :rows="$recentDevices" :columns="['name', 'identifier', 'status', 'last_seen_at']" />
    </section>

    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Last 5 Inward Reports</h2><a class="btn" href="{{ route('admin.inward-report') }}">View all</a></div>
            <div class="report-card-list">
                @forelse($recentInwardCards as $session)
                    <a class="mini-report-card" href="{{ route('admin.inward-report') }}">
                        <strong>{{ $session->session_number }}</strong>
                        <span>{{ $session->started_at?->format('d M Y H:i') }}</span>
                        <b>{{ number_format((float) $session->total_net_weight, 3) }} kg</b>
                    </a>
                @empty
                    <p class="empty">No inward sessions yet.</p>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Last 5 Dispatch / Packing Lists</h2><a class="btn" href="{{ route('admin.dispatch-report') }}">View all</a></div>
            <div class="report-card-list">
                @forelse($recentDispatchCards as $dispatch)
                    <a class="mini-report-card" href="{{ route('admin.dispatch-report') }}">
                        <strong>{{ $dispatch->dispatch_number }}</strong>
                        <span>{{ $customerNames[$dispatch->customer_id] ?? data_get($dispatch->customer_snapshot, 'name', 'Customer') }}</span>
                        <b>{{ number_format((float) $dispatch->total_weight, 3) }} kg</b>
                    </a>
                @empty
                    <p class="empty">No dispatches yet.</p>
                @endforelse
            </div>
        </div>
    </section>

    <section class="grid two">
        <div class="card">
            <div class="card-head"><h2>Inventory Bird’s Eye View</h2><a class="btn" href="{{ route('admin.inventory') }}">Open inventory</a></div>
            <div class="inventory-card-grid compact">
                @forelse($inventoryByProduct as $row)
                    <div class="inventory-card">
                        <span>{{ $productNames[$row->product_id] ?? 'Product' }}</span>
                        <strong>{{ number_format((float) $row->weight, 3) }} kg</strong>
                        <small>{{ number_format((float) $row->pieces, 0) }} pcs</small>
                    </div>
                @empty
                    <p class="empty">No inventory movement yet.</p>
                @endforelse
            </div>
        </div>
        <div class="card">
            <div class="card-head"><h2>Customer Dispatch Analysis</h2></div>
            <div class="chart-list">
                @forelse($customerDispatchAnalysis as $row)
                    <div>
                        <span>{{ $customerNames[$row->customer_id] ?? 'Customer' }} · {{ $row->dispatch_count }} dispatches</span>
                        <b>{{ number_format((float) $row->total_weight, 3) }} kg</b>
                    </div>
                @empty
                    <p class="empty">No customer dispatch data yet.</p>
                @endforelse
            </div>
        </div>
    </section>
@endsection
