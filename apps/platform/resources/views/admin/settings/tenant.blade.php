@extends('layouts.admin')

@section('content')
    @php($settings = $tenant->settings ?? [])
    @php($baseColumns = ['sr' => 'S/R', 'barcode_value' => 'Barcode', 'product_name' => 'Product', 'gross_weight' => 'Gross kg', 'tare_weight' => 'Tare kg', 'net_weight' => 'Net kg', 'converted_unit' => 'Unit Conv.'])
    @php($inwardColumns = array_merge($baseColumns, ['captured_at' => 'Time']))
    @php($dispatchColumns = $baseColumns)
    @php($dynamicColumns = $productFields->pluck('field_label', 'internal_key')->all())
    @php($inwardSelected = old('settings.reportColumns.inward', data_get($settings, 'reportColumns.inward', array_keys(array_merge($inwardColumns, $dynamicColumns)))))
    @php($dispatchSelected = old('settings.reportColumns.dispatch', data_get($settings, 'reportColumns.dispatch', array_keys(array_merge($dispatchColumns, $dynamicColumns)))))
    @php($summaryMetrics = ['sticker_pcs' => 'Sticker PCS', 'gross_kg' => 'Gross kg', 'tare_kg' => 'Tare kg', 'net_kg' => 'Net kg', 'converted_pcs' => 'Converted PCS'])
    <form class="card form-grid" method="POST" action="{{ route('admin.tenant-settings.save') }}" enctype="multipart/form-data">
        @csrf
        <div class="card-head full">
            <div>
                <h2>Report Customiser</h2>
                <p>Set company details, report footer and fixed PDF / Excel columns for inward and dispatch reports.</p>
            </div>
            <button class="btn primary">Save settings</button>
        </div>

        <label>Company name <input name="name" value="{{ old('name', $tenant->name) }}" required></label>
        <label>GST / tax number <input name="settings[taxNumber]" value="{{ old('settings.taxNumber', $settings['taxNumber'] ?? '') }}"></label>
        <label>Logo URL <input name="settings[logoUrl]" value="{{ old('settings.logoUrl', $settings['logoUrl'] ?? '') }}" placeholder="https://..."></label>
        <label>Upload logo <input type="file" name="logo" accept="image/*"></label>
        @if(! empty($settings['logoPath']))
            <div class="report-logo-preview">
                <span>Current logo</span>
                <img src="{{ asset('storage/'.$settings['logoPath']) }}" alt="Company logo">
            </div>
        @endif
        <label class="full">Company address <textarea name="settings[companyAddress]" rows="3">{{ old('settings.companyAddress', $settings['companyAddress'] ?? '') }}</textarea></label>
        <label>Date format <input name="settings[dateFormat]" value="{{ old('settings.dateFormat', $settings['dateFormat'] ?? 'd M Y') }}"></label>
        <label>Number format <input name="settings[numberFormat]" value="{{ old('settings.numberFormat', $settings['numberFormat'] ?? 'en_IN') }}"></label>
        <label>Weight precision <input type="number" min="0" max="6" name="settings[weightPrecision]" value="{{ old('settings.weightPrecision', $settings['weightPrecision'] ?? 3) }}"></label>

        <div class="full card subtle">
            <h3>PDF / Excel Header</h3>
            <div class="form-grid">
                <label>Phone <input name="settings[reportHeader][phone]" value="{{ old('settings.reportHeader.phone', data_get($settings, 'reportHeader.phone')) }}"></label>
                <label>Email <input name="settings[reportHeader][email]" value="{{ old('settings.reportHeader.email', data_get($settings, 'reportHeader.email')) }}"></label>
                <label>GST shown on report <input name="settings[reportHeader][gst]" value="{{ old('settings.reportHeader.gst', data_get($settings, 'reportHeader.gst', $settings['taxNumber'] ?? '')) }}"></label>
                <label>Contact person <input name="settings[reportHeader][contact]" value="{{ old('settings.reportHeader.contact', data_get($settings, 'reportHeader.contact')) }}"></label>
                <label class="full">Report address <input name="settings[reportHeader][address]" value="{{ old('settings.reportHeader.address', data_get($settings, 'reportHeader.address', $settings['companyAddress'] ?? '')) }}"></label>
                <label>Extra header field 1 <input name="settings[reportHeader][extra1]" value="{{ old('settings.reportHeader.extra1', data_get($settings, 'reportHeader.extra1')) }}"></label>
                <label>Extra header field 2 <input name="settings[reportHeader][extra2]" value="{{ old('settings.reportHeader.extra2', data_get($settings, 'reportHeader.extra2')) }}"></label>
            </div>
        </div>

        <div class="full card subtle">
            <h3>PDF Footer</h3>
            <p class="muted">Default footer is Punit’s in-house software credit and support number. You can override each line if needed.</p>
            <div class="form-grid">
                <label class="full">Footer line 1 <input name="settings[reportFooter][0]" value="{{ old('settings.reportFooter.0', data_get($settings, 'reportFooter.0', 'Solution fully built inhouse by engineers of Punit Instrument Pvt Ltd and Punit Technologies using patented tech | 30 years of R & D | proudly 100% made in India')) }}"></label>
                <label class="full">Footer line 2 <input name="settings[reportFooter][1]" value="{{ old('settings.reportFooter.1', data_get($settings, 'reportFooter.1', 'For software training support contact us 9737599004')) }}"></label>
                <label class="full">Footer line 3 <input name="settings[reportFooter][2]" value="{{ old('settings.reportFooter.2', data_get($settings, 'reportFooter.2')) }}"></label>
            </div>
        </div>

        <div class="full card subtle">
            <h3>Email Report Notification</h3>
            <p class="muted">After inward stop or dispatch save, reports are emailed to these addresses when server mail is configured.</p>
            <div class="form-grid">
                <label class="full">Report email recipients <input name="settings[reportEmail][to]" value="{{ old('settings.reportEmail.to', data_get($settings, 'reportEmail.to')) }}" placeholder="owner@example.com, accounts@example.com"></label>
                <label><input type="checkbox" name="settings[reportEmail][pdf]" value="1" @checked(data_get($settings, 'reportEmail.pdf', true))> Send PDF</label>
                <label><input type="checkbox" name="settings[reportEmail][excel]" value="1" @checked(data_get($settings, 'reportEmail.excel', false))> Send Excel/CSV</label>
            </div>
        </div>

        <div class="full card subtle">
            <h3>Inward Report Columns</h3>
            <div class="checkbox-grid">
                @foreach(array_merge($inwardColumns, $dynamicColumns) as $key => $label)
                    <label><input type="checkbox" name="settings[reportColumns][inward][]" value="{{ $key }}" @checked(in_array($key, $inwardSelected ?? [], true))> {{ $label }}</label>
                @endforeach
            </div>
        </div>

        <div class="full card subtle">
            <h3>Dispatch Report Columns</h3>
            <div class="checkbox-grid">
                @foreach(array_merge($dispatchColumns, $dynamicColumns) as $key => $label)
                    <label><input type="checkbox" name="settings[reportColumns][dispatch][]" value="{{ $key }}" @checked(in_array($key, $dispatchSelected ?? [], true))> {{ $label }}</label>
                @endforeach
            </div>
        </div>

        @foreach(['inward' => 'Inward', 'dispatch' => 'Dispatch'] as $reportKey => $reportLabel)
            @php($summaryEnabled = (bool) old("settings.reportSummary.$reportKey.enabled", data_get($settings, "reportSummary.$reportKey.enabled", true)))
            @php($summaryGroups = old("settings.reportSummary.$reportKey.groupBy", data_get($settings, "reportSummary.$reportKey.groupBy", ['product_name', ...array_keys($dynamicColumns)])))
            @php($selectedMetrics = old("settings.reportSummary.$reportKey.metrics", data_get($settings, "reportSummary.$reportKey.metrics", array_keys($summaryMetrics))))
            <div class="full card subtle report-summary-settings">
                <div class="card-head">
                    <div>
                        <h3>{{ $reportLabel }} Product Summary</h3>
                        <p class="muted">Choose whether the summary is included and how filtered rows are grouped and totalled.</p>
                    </div>
                    <label class="blue-toggle">
                        <input type="hidden" name="settings[reportSummary][{{ $reportKey }}][enabled]" value="0">
                        <input type="checkbox" name="settings[reportSummary][{{ $reportKey }}][enabled]" value="1" @checked($summaryEnabled)>
                        Include summary
                    </label>
                </div>
                <div class="report-customiser-grid">
                    <div>
                        <strong>Group rows by</strong>
                        <div class="checkbox-grid compact">
                            <label><input type="checkbox" name="settings[reportSummary][{{ $reportKey }}][groupBy][]" value="product_name" @checked(in_array('product_name', $summaryGroups ?? [], true))> Product</label>
                            @foreach($dynamicColumns as $key => $label)
                                <label><input type="checkbox" name="settings[reportSummary][{{ $reportKey }}][groupBy][]" value="{{ $key }}" @checked(in_array($key, $summaryGroups ?? [], true))> {{ $label }}</label>
                            @endforeach
                        </div>
                    </div>
                    <div>
                        <strong>Summary totals</strong>
                        <div class="checkbox-grid compact">
                            @foreach($summaryMetrics as $key => $label)
                                <label><input type="checkbox" name="settings[reportSummary][{{ $reportKey }}][metrics][]" value="{{ $key }}" @checked(in_array($key, $selectedMetrics ?? [], true))> {{ $label }}</label>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>
        @endforeach
    </form>
@endsection
