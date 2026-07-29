@extends('layouts.admin')

@section('content')
    <section class="import-hero">
        <div>
            <p class="eyebrow">Administration</p>
            <h2>Import Centre</h2>
            <span>Download the Excel template, upload your completed file, review validation results, then confirm.</span>
        </div>
        <div class="import-hero-actions">
            <a class="btn" href="{{ route('admin.imports.products.export') }}">Export Current Products</a>
            <a class="btn" href="{{ route('admin.imports.template', 'products') }}">Download Product Excel</a>
            <a class="btn" href="{{ route('admin.imports.template', 'product-details') }}">Download Product Details Excel</a>
        </div>
    </section>

    <div class="import-grid">
        <section class="import-card">
            <div class="import-card-head">
                <span class="import-icon">P</span>
                <div>
                    <h2>Product Spreadsheet Import</h2>
                    <p>Add each new product as a new row. Only Product Name is required; blank tare becomes 0, blank unit becomes kg, and the customer barcode columns are optional.</p>
                </div>
            </div>
            <form method="POST" action="{{ route('admin.imports.products') }}" enctype="multipart/form-data" class="import-upload">
                @csrf
                <label>
                    <span>Select product Excel or CSV</span>
                    <input type="file" name="file" accept=".xlsx,.csv,.txt" required>
                </label>
                <button class="btn primary">Validate and Preview</button>
            </form>

            @if($productPreview)
                <div class="import-preview">
                    <div class="card-head subtle">
                        <h3>Product validation preview</h3>
                        <div class="inline-actions">
                            <span class="status-pill success">{{ count($productPreview['records'] ?? []) }} new</span>
                            <span class="status-pill">{{ count($productPreview['skipped'] ?? []) }} skipped</span>
                        </div>
                    </div>
                    @if(($productPreview['skipped'] ?? []) !== [])
                        <div class="notice">
                            <strong>Existing or duplicate rows will be skipped without changing them:</strong>
                            <ul>
                                @foreach(array_slice($productPreview['skipped'], 0, 50) as $row)
                                    <li>Row {{ $row['line'] }}: {{ $row['name'] }}{{ $row['product_code'] ? ' ('.$row['product_code'].')' : '' }} — {{ $row['reason'] }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @endif
                    @if(($productPreview['errors'] ?? []) !== [])
                        <div class="notice error">
                            <strong>New-product import blocked until these issues are corrected:</strong>
                            <ul>
                                @foreach(array_slice($productPreview['errors'], 0, 50) as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @elseif(($productPreview['records'] ?? []) !== [])
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead><tr><th>Product</th><th>Code</th><th>Tare</th><th>Unit</th><th>Customer Barcode</th></tr></thead>
                                <tbody>
                                    @foreach(array_slice($productPreview['records'], 0, 20) as $row)
                                        <tr>
                                            <td>{{ $row['name'] }}</td>
                                            <td>{{ $row['product_code'] }}</td>
                                            <td>{{ number_format($row['tare_weight'], 3) }}</td>
                                            <td>{{ $row['unit'] }}</td>
                                            <td>{{ $row['customer_barcode_enabled'] ? (($customerBarcodeTypes[$row['customer_barcode_type']] ?? strtoupper((string) $row['customer_barcode_type'])).': '.$row['customer_barcode_value']) : '-' }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                        <form method="POST" action="{{ route('admin.imports.products') }}" class="form-actions" onsubmit="return confirm('Create these products now?');">
                            @csrf
                            <input type="hidden" name="confirm" value="1">
                            <button class="btn primary">Confirm Product Import</button>
                        </form>
                    @else
                        <div class="notice success">
                            No new products need importing. All populated rows already exist or were duplicates.
                        </div>
                    @endif
                    <form method="POST" action="{{ route('admin.imports.preview.clear', 'products') }}" class="form-actions">
                        @csrf
                        @method('DELETE')
                        <button class="btn">Clear Preview</button>
                    </form>
                </div>
            @endif

            <div class="import-preview">
                <div class="card-head subtle">
                    <h3>Recent Products</h3>
                    <span class="status-pill">{{ $products->count() }} shown</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead><tr><th>Product</th><th>Tare</th><th>Created</th></tr></thead>
                        <tbody>
                            @forelse ($products as $product)
                                <tr>
                                    <td><strong>{{ $product->name }}</strong></td>
                                    <td>{{ number_format((float) $product->default_tare_weight, 3) }}</td>
                                    <td>{{ $product->created_at?->format('d M Y') }}</td>
                                </tr>
                            @empty
                                <tr><td colspan="3">No products yet.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <section class="import-card">
            <div class="import-card-head">
                <span class="import-icon">D</span>
                <div>
                    <h2>Product Details Spreadsheet Import</h2>
                    <p>Each column becomes one product-detail field; unique cell values become its selectable options.</p>
                </div>
            </div>
            <form method="POST" action="{{ route('admin.imports.product-details') }}" enctype="multipart/form-data" class="import-upload">
                @csrf
                <label>
                    <span>Select product-details Excel or CSV</span>
                    <input type="file" name="file" accept=".xlsx,.csv,.txt" required>
                </label>
                <button class="btn primary">Validate and Preview</button>
            </form>

            @if($detailPreview)
                <div class="import-preview">
                    <div class="card-head subtle">
                        <h3>Product-detail validation preview</h3>
                        <span class="status-pill">{{ count($detailPreview['fields'] ?? []) }} fields</span>
                    </div>
                    @if(($detailPreview['errors'] ?? []) !== [])
                        <div class="notice error">
                            <ul>
                                @foreach(array_slice($detailPreview['errors'], 0, 50) as $error)
                                    <li>{{ $error }}</li>
                                @endforeach
                            </ul>
                        </div>
                    @else
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead><tr><th>Field</th><th>Values to add</th></tr></thead>
                                <tbody>
                                    @foreach($detailPreview['fields'] as $field)
                                        <tr>
                                            <td><strong>{{ $field['label'] }}</strong></td>
                                            <td>{{ collect($field['options'])->take(20)->join(', ') }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                        <form method="POST" action="{{ route('admin.imports.product-details') }}" class="form-actions" onsubmit="return confirm('Create or extend these product-detail fields now?');">
                            @csrf
                            <input type="hidden" name="confirm" value="1">
                            <button class="btn primary">Confirm Product Details Import</button>
                        </form>
                    @endif
                    <form method="POST" action="{{ route('admin.imports.preview.clear', 'product-details') }}" class="form-actions">
                        @csrf
                        @method('DELETE')
                        <button class="btn">Clear Preview</button>
                    </form>
                </div>
            @endif

            <div class="import-preview">
                <div class="card-head subtle">
                    <h3>Existing Product Detail Fields</h3>
                    <span class="status-pill">{{ $productFields->count() }} fields</span>
                </div>
                <div class="table-wrap">
                    <table class="data-table">
                        <thead><tr><th>Field</th><th>Values</th></tr></thead>
                        <tbody>
                            @forelse ($productFields as $field)
                                <tr>
                                    <td><strong>{{ $field->field_label }}</strong></td>
                                    <td>{{ collect($field->dropdown_options ?? [])->map(fn ($option) => is_array($option) ? ($option['label'] ?? $option['value'] ?? '') : $option)->filter()->join(', ') ?: '-' }}</td>
                                </tr>
                            @empty
                                <tr><td colspan="2">No product-detail fields yet.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </section>
    </div>
@endsection
