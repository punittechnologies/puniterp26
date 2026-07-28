@extends('layouts.admin')

@section('content')
    <style>
        .batch-grid{display:grid;gap:18px}.batch-builder{background:linear-gradient(145deg,#fff,#f7fbff);border:1px solid #bfdbfe;border-radius:22px;padding:20px;box-shadow:0 16px 40px rgba(37,99,235,.08)}.batch-builder-head{display:flex;align-items:flex-start;justify-content:space-between;gap:18px;margin-bottom:18px}.batch-builder-head h2,.batch-card h3{margin:0;color:#10233f}.batch-builder-head p,.batch-card p{margin:5px 0 0;color:#64748b}.batch-name{display:grid;gap:7px;margin-bottom:16px}.batch-name span,.batch-field span{font-size:11px;font-weight:900;letter-spacing:.06em;text-transform:uppercase;color:#52627a}.batch-name input,.batch-field select,.batch-field input{width:100%;min-height:45px;border:1px solid #bfd2ec;border-radius:13px;background:#fff;padding:10px 12px;color:#10233f;font:inherit}.batch-items{display:grid;gap:12px}.batch-item{border:1px solid #dbeafe;border-radius:17px;background:#f8fbff;padding:14px}.batch-item-head,.batch-detail{display:grid;grid-template-columns:minmax(180px,1fr) auto;gap:10px;align-items:end}.batch-detail{grid-template-columns:minmax(150px,.8fr) minmax(180px,1fr) auto;margin-top:10px}.batch-details{display:grid;gap:2px}.batch-field{display:grid;gap:6px}.batch-actions{display:flex;align-items:center;flex-wrap:wrap;gap:9px;margin-top:14px}.batch-icon-btn{width:38px;height:38px;display:grid;place-items:center;border:0;border-radius:12px;background:#eaf2ff;color:#1d4ed8;font-size:20px;font-weight:900;cursor:pointer}.batch-icon-btn.danger{background:#fee2e2;color:#b91c1c}.batch-save{border:0;border-radius:13px;padding:12px 18px;background:linear-gradient(135deg,#2563eb,#38bdf8);color:#fff;font-weight:900;cursor:pointer}.batch-list{display:grid;gap:12px}.batch-card{background:#fff;border:1px solid #dbe7f5;border-radius:19px;padding:17px;box-shadow:0 10px 28px rgba(15,35,64,.05)}.batch-card-top{display:flex;align-items:flex-start;justify-content:space-between;gap:14px}.batch-product-list{display:grid;gap:9px;margin-top:14px}.batch-product{padding:12px;border-radius:14px;background:#f8fbff;border:1px solid #e0ebf8}.batch-product strong{color:#17345b}.batch-chips{display:flex;flex-wrap:wrap;gap:7px;margin-top:8px}.batch-chip{display:inline-flex;align-items:center;gap:7px;padding:6px 9px;border-radius:999px;background:#eaf2ff;color:#1d4ed8;font-size:12px;font-weight:800}.batch-chip form{display:inline}.batch-chip button{border:0;background:transparent;color:#b91c1c;font-weight:950;cursor:pointer;padding:0}.batch-empty{padding:26px;text-align:center;color:#64748b}.batch-hidden{display:none!important}
        @media(max-width:680px){.batch-builder-head,.batch-card-top{display:grid}.batch-item-head,.batch-detail{grid-template-columns:1fr}.batch-icon-btn{width:100%}.batch-detail .batch-icon-btn{width:100%}}
    </style>

    <div class="batch-grid">
        <form method="POST" action="{{ route('admin.batches.store') }}" class="batch-builder" id="batch-form">
            @csrf
            <div class="batch-builder-head">
                <div>
                    <h2>Create product batch</h2>
                    <p>Group one or more products with their fixed product-detail values. The app uses these values in Batch Entry mode.</p>
                </div>
            </div>

            <label class="batch-name">
                <span>Batch name</span>
                <input name="batch_name" value="{{ old('batch_name') }}" maxlength="120" placeholder="Example: July Production A" required>
            </label>

            <div class="batch-items" id="batch-items">
                <div class="batch-item" data-batch-item>
                    <div class="batch-item-head">
                        <label class="batch-field">
                            <span>Product</span>
                            <select data-product required>
                                <option value="">Select product</option>
                                @foreach($products as $product)
                                    <option value="{{ $product->id }}">{{ $product->name }} @if($product->product_code)({{ $product->product_code }})@endif</option>
                                @endforeach
                            </select>
                        </label>
                        <button class="batch-icon-btn danger" type="button" data-remove-product title="Remove product">×</button>
                    </div>
                    <div class="batch-details" data-details>
                        <div class="batch-detail" data-detail>
                            <label class="batch-field">
                                <span>Product detail</span>
                                <select data-field required>
                                    <option value="">Select detail</option>
                                    @foreach($fields as $field)
                                        <option value="{{ $field->id }}" data-list="batch-options-{{ $field->id }}">{{ $field->field_label }}</option>
                                    @endforeach
                                </select>
                            </label>
                            <label class="batch-field">
                                <span>Value</span>
                                <input data-value maxlength="255" placeholder="Select or enter value" required>
                            </label>
                            <button class="batch-icon-btn danger" type="button" data-remove-detail title="Remove detail">×</button>
                        </div>
                    </div>
                    <div class="batch-actions">
                        <button class="batch-icon-btn" type="button" data-add-detail title="Add another product detail">+</button>
                        <span class="muted">Add detail</span>
                    </div>
                </div>
            </div>

            @foreach($fields as $field)
                <datalist id="batch-options-{{ $field->id }}">
                    @foreach(($field->dropdown_options ?? []) as $option)
                        @php($value = is_array($option) ? ($option['label'] ?? $option['value'] ?? null) : $option)
                        @if(filled($value))<option value="{{ $value }}"></option>@endif
                    @endforeach
                </datalist>
            @endforeach

            <div class="batch-actions">
                <button class="batch-icon-btn" type="button" id="add-product" title="Add another product">+</button>
                <span class="muted">Add product</span>
                <button class="batch-save" type="submit">Save batch</button>
            </div>
        </form>

        <section class="batch-list">
            <div class="card-head">
                <div><h2>Saved batches</h2><p>The existing batch data is preserved and synced tenant-by-tenant.</p></div>
                <span class="status-pill">{{ $rows->total() }} records</span>
            </div>
            @forelse($rows as $batch)
                @php($items = collect($batch->displayItems()))
                <article class="batch-card">
                    <div class="batch-card-top">
                        <div>
                            <h3>{{ $batch->batch_name }}</h3>
                            <p>{{ $items->count() }} {{ str('product')->plural($items->count()) }} · Updated {{ $batch->updated_at?->diffForHumans() }}</p>
                        </div>
                        <form method="POST" action="{{ route('admin.batches.destroy', $batch) }}" onsubmit="return confirm('Remove this batch from app sync? Existing transactions will remain unchanged.');">
                            @csrf @method('DELETE')
                            <button class="btn danger">Delete batch</button>
                        </form>
                    </div>
                    <div class="batch-product-list">
                        @foreach($items as $itemIndex => $item)
                            <div class="batch-product">
                                <strong>{{ $item['product_name'] ?? $products->firstWhere('id', $item['product_id'] ?? null)?->name ?? 'Product' }}</strong>
                                <div class="batch-chips">
                                    @forelse(($item['details'] ?? []) as $fieldKey => $detail)
                                        <span class="batch-chip">
                                            {{ $detail['label'] ?? str($fieldKey)->headline() }}: {{ $detail['value'] ?? '-' }}
                                            <form method="POST" action="{{ route('admin.batches.fields.destroy', [$batch, $itemIndex, $fieldKey]) }}" onsubmit="return confirm('Remove this field from the batch?');">
                                                @csrf @method('DELETE')
                                                <button title="Remove field">×</button>
                                            </form>
                                        </span>
                                    @empty
                                        <span class="muted">No details</span>
                                    @endforelse
                                </div>
                            </div>
                        @endforeach
                    </div>
                </article>
            @empty
                <div class="batch-card batch-empty">No batches created yet.</div>
            @endforelse
            {{ $rows->links() }}
        </section>
    </div>

    <script>
        (() => {
            const items = document.getElementById('batch-items');
            const firstItem = items.querySelector('[data-batch-item]');
            const firstDetail = firstItem.querySelector('[data-detail]');

            const reindex = () => {
                items.querySelectorAll('[data-batch-item]').forEach((item, itemIndex) => {
                    item.querySelector('[data-product]').name = `items[${itemIndex}][product_id]`;
                    item.querySelectorAll('[data-detail]').forEach((detail, detailIndex) => {
                        detail.querySelector('[data-field]').name = `items[${itemIndex}][details][${detailIndex}][field_id]`;
                        detail.querySelector('[data-value]').name = `items[${itemIndex}][details][${detailIndex}][value]`;
                    });
                });
            };

            const wireDetail = (detail) => {
                detail.querySelector('[data-field]').addEventListener('change', (event) => {
                    const selected = event.target.selectedOptions[0];
                    const input = detail.querySelector('[data-value]');
                    input.setAttribute('list', selected?.dataset.list || '');
                    input.value = '';
                });
                detail.querySelector('[data-remove-detail]').addEventListener('click', () => {
                    const group = detail.closest('[data-details]');
                    if (group.querySelectorAll('[data-detail]').length > 1) detail.remove();
                    reindex();
                });
            };

            const wireItem = (item) => {
                item.querySelectorAll('[data-detail]').forEach(wireDetail);
                item.querySelector('[data-add-detail]').addEventListener('click', () => {
                    const detail = firstDetail.cloneNode(true);
                    detail.querySelector('[data-field]').value = '';
                    detail.querySelector('[data-value]').value = '';
                    detail.querySelector('[data-value]').removeAttribute('list');
                    item.querySelector('[data-details]').append(detail);
                    wireDetail(detail);
                    reindex();
                });
                item.querySelector('[data-remove-product]').addEventListener('click', () => {
                    if (items.querySelectorAll('[data-batch-item]').length > 1) item.remove();
                    reindex();
                });
            };

            wireItem(firstItem);
            document.getElementById('add-product').addEventListener('click', () => {
                const item = firstItem.cloneNode(true);
                item.querySelector('[data-product]').value = '';
                item.querySelectorAll('[data-detail]').forEach((detail, index) => {
                    if (index > 0) detail.remove();
                });
                item.querySelector('[data-field]').value = '';
                item.querySelector('[data-value]').value = '';
                item.querySelector('[data-value]').removeAttribute('list');
                items.append(item);
                wireItem(item);
                reindex();
            });
            reindex();
        })();
    </script>
@endsection
