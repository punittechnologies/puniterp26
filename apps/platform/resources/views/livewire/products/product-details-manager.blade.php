<div class="attribute-manager">
    <div class="card">
        <div class="card-head">
            <div>
                <h2>Product Detail Fields & Options</h2>
                <p>Create fields like MTR, Size, Quality, Color, Packing or Dimension. Every field is a dropdown by default and can be used in labels.</p>
            </div>
            <a class="btn" href="{{ route('admin.products') }}">Go to Products</a>
        </div>
        <form wire:submit="createField" class="attribute-create-shot">
            <label>Field name
                <input wire:model="newFieldName" placeholder="Example: SIZE">
            </label>
            <label>Values
                <input wire:model="newFieldValues" placeholder="Example: 16, 18, 20 or RED, BLUE, GREEN">
            </label>
            <label class="inline-check print-check">
                <input type="checkbox" wire:model="newPrintableOnLabel">
                Print this field on label
            </label>
            <label class="inline-check print-check">
                <input type="checkbox" wire:model="newUseAsWeightDivisor">
                Use this field as quantity for divided weight
            </label>
            @error('newFieldValues') <small class="error">{{ $message }}</small> @enderror
            <button class="btn primary">Save Field & Values</button>
        </form>
    </div>

    <section class="attribute-grid">
        @forelse ($fields as $field)
            <article class="attribute-card" wire:key="detail-field-card-{{ $field->id }}">
                <div class="attribute-row">
                    <input wire:key="detail-field-name-{{ $field->id }}" wire:model="fieldNames.{{ $field->id }}" placeholder="Field name">
                    <button class="icon-btn save" wire:click="saveFieldName('{{ $field->id }}')" title="Save field" type="button">✓</button>
                    <button class="icon-btn danger" wire:click="deleteField('{{ $field->id }}')" wire:confirm="Remove this field?" title="Delete field" type="button">×</button>
                </div>

                <div class="attribute-row">
                    <input wire:key="detail-field-option-input-{{ $field->id }}" wire:model="optionInputs.{{ $field->id }}" wire:keydown.enter.prevent="addOption('{{ $field->id }}')" placeholder="Add option">
                    <button class="icon-btn add" wire:click="addOption('{{ $field->id }}')" title="Add option" type="button">+</button>
                </div>

                <div class="option-chips">
                    <span class="print-chip">
                        Label: {{ $field->printable_on_label ? 'Yes' : 'No' }}
                        <button wire:click="togglePrintable('{{ $field->id }}')" type="button">{{ $field->printable_on_label ? '×' : '+' }}</button>
                    </span>
                    <span class="print-chip">
                        Divided weight: {{ $field->use_as_weight_divisor ? 'Yes' : 'No' }}
                        <button wire:click="toggleWeightDivisor('{{ $field->id }}')" type="button">{{ $field->use_as_weight_divisor ? '×' : '+' }}</button>
                    </span>
                    @forelse (($field->dropdown_options ?? []) as $option)
                        <span wire:key="detail-field-option-{{ $field->id }}-{{ $option['value'] ?? md5($option['label'] ?? '') }}">{{ $option['label'] ?? $option['value'] ?? '' }}
                            <button wire:click="removeOption('{{ $field->id }}', '{{ $option['value'] ?? '' }}')" type="button">×</button>
                        </span>
                    @empty
                        <p class="empty">No options yet.</p>
                    @endforelse
                </div>
                @error('optionInputs.'.$field->id) <small class="error">{{ $message }}</small> @enderror
                @if($field->use_as_weight_divisor)
                    <p class="empty">This dropdown supplies the bundle quantity. Labels can print Gross ÷ quantity or Net ÷ quantity in kg.</p>
                @endif
            </article>
        @empty
            <div class="card empty">No product detail fields yet. Add MTR, SIZE, QUALITY, COLOR, PACKING or any field you need.</div>
        @endforelse
    </section>
</div>
