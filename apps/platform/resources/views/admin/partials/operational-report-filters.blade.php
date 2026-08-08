@php
    $filterContext ??= $report ?? 'inventory';
    $isProductionReport = in_array($filterContext, ['inward', 'dispatch'], true);
    $isInventoryReport = in_array($filterContext, ['inventory', 'inventory-ledger'], true);
    $supportsProductFilters = $isProductionReport || $isInventoryReport || $filterContext === 'customer-dispatch';
    $filterAction ??= url()->current();
    $clearUrl ??= $filterAction;
    $today = now()->toDateString();
    $quickBase = request()->except(['from', 'to', 'page', 'ledger_page']);
    $selectedProductIds = $filters['product_ids'] ?? [];
    $selectedDetailFilters = $filters['detail_filters'] ?? [];
    $scalarLabels = [
        'from' => 'From', 'to' => 'To', 'serial' => 'Serial', 'barcode' => 'Barcode',
        'transaction_number' => $filterContext === 'dispatch' ? 'Dispatch no.' : 'Inward no.',
        'search' => 'Search', 'transaction_type' => 'Movement', 'status' => 'Status',
        'weight_min' => 'Min kg', 'weight_max' => 'Max kg', 'pieces_min' => 'Min PCS', 'pieces_max' => 'Max PCS',
    ];
@endphp

<section class="card report-filter-card"
    x-data="reportFilterBuilder(@js($products), @js($productFields), @js($selectedProductIds), @js($selectedDetailFilters))">
    <div class="card-head report-filter-head">
        <div>
            <h2>{{ $filterTitle ?? 'Precise Report Filters' }}</h2>
            <p>Choose several products and product details. Screen, PDF, Excel and CSV use the same selection.</p>
        </div>
        <a class="btn" href="{{ $clearUrl }}">Clear all</a>
    </div>

    <div class="report-filter-toolbar">
        <div class="report-quick-filters" aria-label="Quick date filters">
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => $today, 'to' => $today]) }}">Today</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->subDay()->toDateString(), 'to' => now()->subDay()->toDateString()]) }}">Yesterday</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->startOfWeek()->toDateString(), 'to' => $today]) }}">This week</a>
            <a class="btn" href="?{{ http_build_query([...$quickBase, 'from' => now()->startOfMonth()->toDateString(), 'to' => $today]) }}">This month</a>
        </div>
    </div>

    <form class="filter-bar report-filter-form" method="GET" action="{{ $filterAction }}">
        <div class="report-filter-primary-grid">
            <label>Start date <input type="date" name="from" value="{{ $filters['from'] ?? '' }}"></label>
            <label>End date <input type="date" name="to" value="{{ $filters['to'] ?? '' }}"></label>

            @if($supportsProductFilters)
            <div class="report-multiselect" @click.outside="productOpen = false">
                <span class="report-filter-label">Products</span>
                <button class="report-select-trigger" type="button" @click="productOpen = !productOpen" :aria-expanded="productOpen">
                    <span x-text="productLabel()"></span><span aria-hidden="true">⌄</span>
                </button>
                <div class="report-select-popover" x-cloak x-show="productOpen">
                    <input type="search" x-model="productSearch" placeholder="Search products" aria-label="Search products">
                    <div class="report-select-options">
                        <template x-for="product in filteredProducts()" :key="product.id">
                            <label><input type="checkbox" name="product_ids[]" :value="String(product.id)" x-model="selectedProductIds"><span x-text="product.name"></span></label>
                        </template>
                    </div>
                    <button type="button" class="report-popover-done" @click="productOpen = false">Done</button>
                </div>
            </div>
            @endif

            <div class="report-multiselect" @click.outside="detailOpen = false">
                <span class="report-filter-label">Product details</span>
                <button class="report-select-trigger" type="button" @click="detailOpen = !detailOpen" :aria-expanded="detailOpen">
                    <span x-text="detailLabel()"></span><span aria-hidden="true">⌄</span>
                </button>
                <div class="report-select-popover" x-cloak x-show="detailOpen">
                    <input type="search" x-model="detailSearch" placeholder="Search detail fields" aria-label="Search product-detail fields">
                    <div class="report-select-options">
                        <template x-for="field in filteredFields()" :key="field.internal_key">
                            <label><input type="checkbox" :checked="detailSelected(field.internal_key)" @change="toggleDetail(field.internal_key)"><span x-text="field.field_label"></span></label>
                        </template>
                        <p class="muted" x-show="!filteredFields().length">No matching detail fields.</p>
                    </div>
                    <button type="button" class="report-popover-done" @click="detailOpen = false">Done</button>
                </div>
            </div>

            @if($isProductionReport)
                <label>Serial number <input name="serial" value="{{ $filters['serial'] ?? '' }}" placeholder="Search serial"></label>
                <label>Barcode <input name="barcode" value="{{ $filters['barcode'] ?? '' }}" placeholder="Scan or search"></label>
                <label>{{ $filterContext === 'dispatch' ? 'Dispatch' : 'Inward' }} number
                    <input name="transaction_number" value="{{ $filters['transaction_number'] ?? '' }}" placeholder="Transaction number">
                </label>
                @if($filterContext === 'dispatch')
                    <label>Customer
                        <select name="customer_id"><option value="">All customers</option>@foreach($customers as $customer)<option value="{{ $customer->id }}" @selected(($filters['customer_id'] ?? '') === $customer->id)>{{ $customer->name }}</option>@endforeach</select>
                    </label>
                    <label>Status <select name="status"><option value="">All statuses</option>@foreach(['confirmed', 'draft', 'reversed', 'cancelled'] as $status)<option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ str($status)->title() }}</option>@endforeach</select></label>
                @endif
            @endif

            @if($isInventoryReport)
                <label>Movement type <select name="transaction_type"><option value="">All movement types</option>@foreach($transactionTypes as $type)<option value="{{ $type }}" @selected(($filters['transaction_type'] ?? '') === $type)>{{ str($type)->replace('_', ' ')->title() }}</option>@endforeach</select></label>
                <label>Search everything <input name="search" value="{{ $filters['search'] ?? '' }}" placeholder="Product, serial or barcode"></label>
            @endif
        </div>

        @if($supportsProductFilters)
        <div class="detail-condition-grid" x-show="activeDetailFields().length" x-cloak>
            <template x-for="field in activeDetailFields()" :key="field.internal_key">
                <div class="detail-condition-card">
                    <div class="detail-condition-head">
                        <strong x-text="field.field_label"></strong>
                        <button type="button" @click="toggleDetail(field.internal_key)" aria-label="Remove product-detail filter">×</button>
                    </div>
                    <div class="blue-value-chips" x-show="valuesFor(field.internal_key).length">
                        <template x-for="value in valuesFor(field.internal_key)" :key="value">
                            <span><span x-text="value"></span><button type="button" @click="removeDetailValue(field.internal_key, value)" aria-label="Remove value">×</button><input type="hidden" :name="'detail_filters[' + field.internal_key + '][]'" :value="value"></span>
                        </template>
                    </div>
                    <div class="detail-value-entry">
                        <input type="text" x-model="detailInputs[field.internal_key]" @keydown.enter.prevent="addDetailValue(field.internal_key)" :list="'detail-options-' + field.internal_key" placeholder="Type exact value">
                        <button class="btn" type="button" @click="addDetailValue(field.internal_key)">Add</button>
                        <datalist :id="'detail-options-' + field.internal_key">
                            <template x-for="option in fieldOptions(field)" :key="option"><option :value="option"></option></template>
                        </datalist>
                    </div>
                    <small>Values in this field match any; separate detail fields must all match.</small>
                </div>
            </template>
        </div>
        @endif

        <details class="report-advanced-filters" @if(filled($filters['weight_min'] ?? '') || filled($filters['weight_max'] ?? '') || filled($filters['pieces_min'] ?? '') || filled($filters['pieces_max'] ?? '')) open @endif>
            <summary>Weight and PCS ranges</summary>
            <div class="report-filter-grid">
                <label>Minimum net kg <input type="number" min="0" step="0.001" name="weight_min" value="{{ $filters['weight_min'] ?? '' }}"></label>
                <label>Maximum net kg <input type="number" min="0" step="0.001" name="weight_max" value="{{ $filters['weight_max'] ?? '' }}"></label>
                <label>Minimum PCS <input type="number" min="0" step="1" name="pieces_min" value="{{ $filters['pieces_min'] ?? '' }}"></label>
                <label>Maximum PCS <input type="number" min="0" step="1" name="pieces_max" value="{{ $filters['pieces_max'] ?? '' }}"></label>
            </div>
        </details>

        <div class="report-filter-actions">
            <button class="btn primary">Apply filters</button>
            <a class="btn" href="{{ $clearUrl }}">Reset</a>
            @if(! $isProductionReport && ($showFilterExports ?? false))
                <a class="btn" href="{{ route('admin.exports', [$filterContext, 'csv']) }}?{{ http_build_query(request()->query()) }}">CSV</a>
                <a class="btn" href="{{ route('admin.exports', [$filterContext, 'xlsx']) }}?{{ http_build_query(request()->query()) }}">Excel</a>
                <a class="btn" href="{{ route('admin.exports', [$filterContext, 'pdf']) }}?{{ http_build_query(request()->query()) }}">PDF</a>
            @endif
        </div>
    </form>

    @if($supportsProductFilters)
    <div class="active-filter-chips" x-show="selectedProductIds.length || Object.values(selectedDetails).some(values => values.length)">
        <template x-for="productId in selectedProductIds" :key="productId">
            <span><strong>Product:</strong> <span x-text="products.find(product => String(product.id) === productId)?.name || productId"></span></span>
        </template>
        <template x-for="field in activeDetailFields().filter(field => valuesFor(field.internal_key).length)" :key="field.internal_key">
            <span><strong x-text="field.field_label + ':'"></strong> <span x-text="valuesFor(field.internal_key).join(' or ')"></span></span>
        </template>
    </div>
    @endif
    @php($activeScalarFilters = collect($scalarLabels)->mapWithKeys(fn ($label, $key) => [$key => ['label' => $label, 'value' => $filters[$key] ?? '']])->filter(fn ($item) => filled($item['value'])))
    @if($activeScalarFilters->isNotEmpty())
        <div class="active-filter-chips">
            @foreach($activeScalarFilters as $item)<span><strong>{{ $item['label'] }}:</strong> {{ $item['value'] }}</span>@endforeach
        </div>
    @endif
</section>
