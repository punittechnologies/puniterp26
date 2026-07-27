@extends('layouts.admin')

@section('content')
    <section class="card">
        <div class="card-head">
            <div>
                <h2>Export Centre</h2>
                <p>Select a report, date range and download format. Every export is restricted to your company.</p>
            </div>
        </div>
        <form method="GET" action="" class="form-grid" onsubmit="this.action='{{ url('/exports') }}/'+this.elements.report.value+'/'+this.elements.format.value">
            <label>Report
                <select name="report" required>
                    @foreach(['inward' => 'Inward Report', 'dispatch' => 'Dispatch Report', 'inventory' => 'Inventory Report', 'inventory-ledger' => 'Inventory Ledger', 'audit' => 'Audit Report'] as $key => $label)
                        <option value="{{ $key }}" @selected($filters['report'] === $key)>{{ $label }}</option>
                    @endforeach
                </select>
            </label>
            <label>Format
                <select name="format" required>
                    <option value="pdf" @selected($filters['format'] === 'pdf')>PDF</option>
                    <option value="xlsx" @selected($filters['format'] === 'xlsx')>Excel (.xlsx)</option>
                    <option value="csv" @selected($filters['format'] === 'csv')>CSV</option>
                </select>
            </label>
            <label>Start date <input type="date" name="from" value="{{ $filters['from'] }}" required></label>
            <label>End date <input type="date" name="to" value="{{ $filters['to'] }}" required></label>
            <div class="form-actions">
                <button class="btn primary">Download Report</button>
            </div>
        </form>
    </section>
@endsection
