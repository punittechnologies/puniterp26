<div
    class="label-studio"
    x-data="labelDesigner(@entangle('templateJsonText').live, @entangle('widthMm').live, @entangle('heightMm').live)"
    x-init="init()"
>
    <textarea class="hidden" x-model="templateJsonText" wire:model.live.debounce.350ms="templateJsonText"></textarea>

    <section class="label-studio-hero">
        <div>
            <p class="admin-eyebrow">Label management</p>
            <h2>Label Templates</h2>
            <p>Create a reusable TVS/TSPL-ready label. Click a field, drag it on the label, resize it, and save.</p>
        </div>
        <div class="label-studio-actions">
            <a href="{{ route('admin.labels') }}" class="admin-btn admin-btn-ghost">New template</a>
            <button type="button" wire:click="save" wire:loading.attr="disabled" wire:target="save" class="admin-btn admin-btn-primary label-save-button">
                <span wire:loading.remove wire:target="save">Save Template</span>
                <span wire:loading wire:target="save">Saving...</span>
            </button>
        </div>
    </section>

    @if ($statusMessage)
        <div class="label-studio-status">{{ $statusMessage }}</div>
    @endif

    <section class="label-template-strip">
        <div class="label-template-strip__header">
            <div>
                <p class="admin-eyebrow">Saved templates</p>
                <strong>Select an existing template to edit</strong>
            </div>
            <span>{{ $templates->count() }} active</span>
        </div>
        <div class="label-template-list">
            @forelse ($templates as $template)
                <a
                    href="{{ route('admin.labels', ['template' => $template->id]) }}"
                    class="label-template-card {{ $templateId === $template->id ? 'is-active' : '' }}"
                >
                    <strong>{{ $template->name }}</strong>
                    <span>{{ number_format((float) $template->width_mm, 0) }} x {{ number_format((float) $template->height_mm, 0) }} mm · v{{ $template->active_version }}</span>
                </a>
            @empty
                <div class="label-template-empty">No templates yet. Create the first one below.</div>
            @endforelse
        </div>
    </section>

    <section class="label-studio-topbar">
        <label>
            <span>Template name</span>
            <input wire:model.live.debounce.300ms="name" placeholder="Example: 75mm packing label">
        </label>
        <label>
            <span>Template code</span>
            <input wire:model.live.debounce.300ms="code" placeholder="Example: PACKING-75">
        </label>
        <label>
            <span>Use for</span>
            <select wire:model.live="scope">
                <option value="tenant">All products / tenant default</option>
                <option value="product">Product default later</option>
                <option value="variant">Product detail default later</option>
            </select>
        </label>
        <label>
            <span>Label size</span>
            <select wire:model.live="size" x-on:change="$nextTick(() => syncSize({{ '$wire.widthMm' }}, {{ '$wire.heightMm' }}))">
                @foreach ($labelSizes as $sizeKey => $sizeLabel)
                    <option value="{{ $sizeKey }}">{{ $sizeLabel }}</option>
                @endforeach
            </select>
        </label>
        <label>
            <span>Width mm</span>
            <input type="number" min="20" max="300" step="1" wire:model.live.debounce.300ms="widthMm" x-on:change="$nextTick(() => syncSize({{ '$wire.widthMm' }}, {{ '$wire.heightMm' }}))">
        </label>
        <label>
            <span>Height mm</span>
            <input type="number" min="20" max="300" step="1" wire:model.live.debounce.300ms="heightMm" x-on:change="$nextTick(() => syncSize({{ '$wire.widthMm' }}, {{ '$wire.heightMm' }}))">
        </label>
        <label class="label-check">
            <input type="checkbox" wire:model.live="isDefault">
            <span>Make default</span>
        </label>
    </section>

    <div class="label-studio-grid">
        <aside class="label-studio-panel label-studio-panel--left">
            <div class="label-panel-title">
                <span>1</span>
                <div>
                    <h3>Content Fields</h3>
                    <p>Click to add on label</p>
                </div>
            </div>

            <div class="label-tool-group">
                <button type="button" x-on:click="addBinding('company.name', 'Company name')">Company name</button>
                <button type="button" x-on:click="addBinding('product.name', 'Product name')">Product name</button>
                <button type="button" x-on:click="addBinding('serial.number', 'Sr. No')">Sr. No</button>
                <button type="button" x-on:click="addBinding('date.current', 'Date')">Date</button>
                <button type="button" x-on:click="addBinding('time.current', 'Time')">Time</button>
            </div>

            <div class="label-tool-section">
                <h4>Weights</h4>
                <div class="label-tool-group">
                    <button type="button" x-on:click="addBinding('weight.gross', 'Gross weight')">Gross</button>
                    <button type="button" x-on:click="addBinding('weight.tare', 'Tare weight')">Tare</button>
                    <button type="button" x-on:click="addBinding('weight.net', 'Net weight')">Net</button>
                    <button type="button" x-on:click="addBinding('pieces.quantity', 'Pieces')">Pieces</button>
                </div>
            </div>

            <div class="label-tool-section">
                <h4>Product Details</h4>
                <div class="label-tool-group label-tool-group--scroll">
                    @foreach ($bindings as $binding)
                        @php
                            $key = $binding['key'];
                            $isProductDetail = str($key)->startsWith('dynamic.product.') || str($key)->startsWith('dynamic.product_variant.');
                        @endphp
                        @continue(! $isProductDetail)
                        <button type="button" x-on:click="addBinding(@js($key), @js($binding['label']))">
                            {{ $binding['label'] }}
                        </button>
                    @endforeach
                </div>
            </div>

            <div class="label-tool-section">
                <h4>Custom</h4>
                <div class="label-tool-group">
                    <button type="button" x-on:click="addText()">Text box</button>
                    <button type="button" x-on:click="addLine()">Line</button>
                    <button type="button" x-on:click="addRect()">Rectangle</button>
                </div>
                <div class="label-upload-box">
                    <label>
                        <span>Upload logo / image</span>
                        <input type="file" wire:model="imageUpload" accept="image/*">
                    </label>
                    <button type="button" wire:click="addUploadedImage" wire:loading.attr="disabled">
                        Add image
                    </button>
                    <small>Images are saved in the template JSON and printed by supported new APK builds.</small>
                </div>
            </div>

            <div class="label-barcode-note">
                <strong>Barcode is mandatory</strong>
                <span>You can move and resize it, but it cannot be removed.</span>
            </div>
        </aside>

        <main class="label-studio-canvas-card">
            <div class="label-canvas-header">
                <div>
                    <p class="admin-eyebrow">2 · Live preview</p>
                    <h3><span></span> Actual label canvas</h3>
                </div>
                <div class="label-canvas-tools">
                    <button type="button" x-on:click="undo()" x-bind:disabled="history.length < 2">Undo</button>
                    <button type="button" x-on:click="redo()" x-bind:disabled="!future.length">Redo</button>
                    <button type="button" x-on:click="zoomOut()">Zoom -</button>
                    <button type="button" x-on:click="zoomIn()">Zoom +</button>
                    <button type="button" x-on:click="duplicate()">Duplicate</button>
                </div>
            </div>
            <p class="label-canvas-help">Click one field, then drag it. Only the selected field moves. Resize from the blue handles.</p>
            <div class="label-canvas-wrap">
                <div id="label-stage" wire:ignore></div>
            </div>
            <div class="label-warning-row" x-show="warnings.length">
                <template x-for="warning in warnings" :key="warning.type + (warning.element || '')">
                    <span x-text="warning.type"></span>
                </template>
            </div>
        </main>

        <aside class="label-studio-panel label-studio-panel--right">
            <div class="label-panel-title">
                <span>3</span>
                <div>
                    <h3>Format Field</h3>
                    <p>Style selected content</p>
                </div>
            </div>

            <div class="label-empty-selection" x-show="!selectedElement">
                <strong>Select a field</strong>
                <p>Click anything on the label preview to edit text, size, position, font and alignment.</p>
            </div>

            <div class="label-format-form" x-show="selectedElement">
                <div class="label-selected-name">
                    <span>Selected</span>
                    <strong x-text="selectedElement?.type === 'barcode' ? 'Mandatory barcode' : (selectedElement?.bindingKey || selectedElement?.text || selectedElement?.type)"></strong>
                </div>

                <label x-show="selectedElement?.type === 'text'">
                    <span>Text</span>
                    <input x-model="selectedElement.text" x-on:change="updateSelected('text', selectedElement.text)">
                </label>

                <div class="label-binding-note" x-show="selectedElement?.type === 'binding_text'">
                    <strong>Linked field stays connected</strong>
                    <span>Binding: <code x-text="selectedElement?.bindingKey"></code></span>
                    <small>Use Prefix for the printed caption. Example: Prefix “Color: ” + value “Red” prints “Color: Red”.</small>
                </div>

                <div class="label-prefix-focus" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <label>
                        <span>Prefix / printed caption</span>
                        <input placeholder="Example: Color: " x-model="selectedElement.prefix" x-on:change="updateSelected('prefix', selectedElement.prefix || '')">
                    </label>
                    <label>
                        <span>Suffix / printed unit</span>
                        <input placeholder="Example: kg, pcs, mm" x-model="selectedElement.suffix" x-on:change="updateSelected('suffix', selectedElement.suffix || '')">
                    </label>
                    <p x-show="selectedElement?.type === 'binding_text'" class="label-preview-value-note">
                        Preview uses sample value: <strong x-text="selectedElement?.previewValue || previewValueForBinding(selectedElement?.bindingKey, selectedElement?.text)"></strong>
                    </p>
                </div>

                <div class="label-field-editor-title">
                    <strong>Move selected field</strong>
                    <span>For text, use font size instead of stretching a box.</span>
                </div>

                <div class="label-format-grid">
                    <label>
                        <span>X mm</span>
                        <input type="number" step="1" x-model.number="selectedElement.x" x-on:change="updateSelected('x', selectedElement.x)">
                    </label>
                    <label>
                        <span>Y mm</span>
                        <input type="number" step="1" x-model.number="selectedElement.y" x-on:change="updateSelected('y', selectedElement.y)">
                    </label>
                </div>

                <div class="label-format-grid" x-show="['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <label>
                        <span>Width</span>
                        <input type="number" step="1" x-model.number="selectedElement.width" x-on:change="updateSelected('width', selectedElement.width)">
                    </label>
                    <label>
                        <span>Height</span>
                        <input type="number" step="1" x-model.number="selectedElement.height" x-on:change="updateSelected('height', selectedElement.height)">
                    </label>
                </div>

                <details class="label-text-width-details" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <summary>Advanced text line width</summary>
                    <div class="label-format-grid">
                        <label>
                            <span>Line width</span>
                            <input type="number" step="1" x-model.number="selectedElement.width" x-on:change="updateSelected('width', selectedElement.width)">
                        </label>
                        <label>
                            <span>Line height</span>
                            <input type="number" step="1" x-model.number="selectedElement.height" x-on:change="updateSelected('height', selectedElement.height)">
                        </label>
                    </div>
                </details>

                <div class="label-format-buttons label-format-buttons--move">
                    <button type="button" x-on:click="nudge(0, -1)">Up</button>
                    <button type="button" x-on:click="nudge(0, 1)">Down</button>
                    <button type="button" x-on:click="nudge(-1, 0)">Left</button>
                    <button type="button" x-on:click="nudge(1, 0)">Right</button>
                </div>

                <div class="label-format-buttons label-format-buttons--size" x-show="['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <button type="button" x-on:click="resizeSelected(2, 0)">Wider</button>
                    <button type="button" x-on:click="resizeSelected(-2, 0)">Narrower</button>
                    <button type="button" x-on:click="resizeSelected(0, 2)">Taller</button>
                    <button type="button" x-on:click="resizeSelected(0, -2)">Shorter</button>
                </div>

                <div class="label-format-buttons">
                    <button type="button" x-on:click="rotateSelected(-5)">Rotate -</button>
                    <button type="button" x-on:click="rotateSelected(5)">Rotate +</button>
                    <button type="button" x-on:click="layerSelected(-1)">Send back</button>
                    <button type="button" x-on:click="layerSelected(1)">Bring front</button>
                </div>

                <label x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <span>Font family</span>
                    <select x-model="selectedElement.style.fontFamily" x-on:change="updateSelected('style.fontFamily', selectedElement.style.fontFamily)">
                        @foreach ($fontFamilies as $family)
                            <option value="{{ $family }}">{{ $family }}</option>
                        @endforeach
                    </select>
                </label>

                <div class="label-format-grid" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <label>
                        <span>Font size</span>
                        <input type="number" min="4" max="72" step="1" x-model.number="selectedElement.style.fontSize" x-on:change="updateSelected('style.fontSize', selectedElement.style.fontSize)">
                    </label>
                    <label>
                        <span>Weight</span>
                        <select x-model="selectedElement.style.fontWeight" x-on:change="updateSelected('style.fontWeight', selectedElement.style.fontWeight)">
                            @foreach ($fontWeights as $value => $label)
                                <option value="{{ $value }}">{{ $label }}</option>
                            @endforeach
                        </select>
                    </label>
                </div>

                <div class="label-format-grid" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <label>
                        <span>Prefix size</span>
                        <input type="number" min="4" max="72" step="1" x-model.number="selectedElement.style.prefixFontSize" x-on:change="updateSelected('style.prefixFontSize', selectedElement.style.prefixFontSize || selectedElement.style.fontSize)">
                    </label>
                    <label>
                        <span>Suffix size</span>
                        <input type="number" min="4" max="72" step="1" x-model.number="selectedElement.style.suffixFontSize" x-on:change="updateSelected('style.suffixFontSize', selectedElement.style.suffixFontSize || selectedElement.style.fontSize)">
                    </label>
                </div>

                <div class="label-format-buttons" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <button type="button" x-on:click="changeFontSize(-1)">Font -</button>
                    <button type="button" x-on:click="changeFontSize(1)">Font +</button>
                    <button type="button" x-on:click="fitText()">Fit text</button>
                    <button type="button" x-on:click="updateSelected('style.fontWeight', '800')">Max bold</button>
                </div>

                <div class="label-format-grid" x-show="!['barcode','image','rectangle','line'].includes(selectedElement?.type)">
                    <label>
                        <span>Style</span>
                        <select x-model="selectedElement.style.fontStyle" x-on:change="updateSelected('style.fontStyle', selectedElement.style.fontStyle)">
                            <option value="normal">Normal</option>
                            <option value="italic">Italic</option>
                        </select>
                    </label>
                    <label>
                        <span>Align</span>
                        <select x-model="selectedElement.style.align" x-on:change="updateSelected('style.align', selectedElement.style.align)">
                            <option value="left">Left</option>
                            <option value="center">Center</option>
                            <option value="right">Right</option>
                            <option value="justify">Justify</option>
                        </select>
                    </label>
                </div>

                <label>
                    <span>Rotation</span>
                    <input type="number" step="1" x-model.number="selectedElement.rotation" x-on:change="updateSelected('rotation', selectedElement.rotation)">
                </label>

                <button type="button" class="label-delete-button" x-on:click="remove()" x-bind:disabled="selectedElement?.type === 'barcode'">
                    Delete selected
                </button>
            </div>
        </aside>
    </div>

    <details class="label-json-details">
        <summary>Developer JSON preview</summary>
        <pre x-text="jsonText"></pre>
    </details>
</div>
