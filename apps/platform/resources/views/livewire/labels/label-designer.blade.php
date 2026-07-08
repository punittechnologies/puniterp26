<div class="grid gap-6 xl:grid-cols-[300px_1fr_320px]">
    <aside class="rounded-lg border border-slate-200 bg-white p-5">
        <h2 class="text-xl font-bold">Templates</h2>
        <div class="mt-4 space-y-2">
            @foreach ($templates as $template)
                <a class="block rounded-md border border-slate-200 px-3 py-2 text-sm hover:border-blue-300" href="/labels/{{ $template->id }}">
                    <span class="font-semibold">{{ $template->name }}</span>
                    <span class="block text-slate-500">v{{ $template->active_version }} · {{ $template->scope }}</span>
                </a>
            @endforeach
        </div>

        <div class="mt-6 space-y-3">
            <label class="block text-xs font-bold uppercase tracking-wide text-slate-500">Template name</label>
            <input wire:model.live="name" class="w-full rounded-md border border-slate-300 px-3 py-2" placeholder="Template name">

            <label class="block text-xs font-bold uppercase tracking-wide text-slate-500">Template code</label>
            <input wire:model.live="code" class="w-full rounded-md border border-slate-300 px-3 py-2" placeholder="Code">

            <label class="block text-xs font-bold uppercase tracking-wide text-slate-500">Use as</label>
            <select wire:model.live="scope" class="w-full rounded-md border border-slate-300 px-3 py-2">
                <option value="tenant">Tenant default</option>
                <option value="product">Product default</option>
                <option value="variant">Variant default</option>
            </select>

            <label class="block text-xs font-bold uppercase tracking-wide text-slate-500">Label size</label>
            <select wire:model.live="size" class="w-full rounded-md border border-slate-300 px-3 py-2">
                @foreach ($labelSizes as $sizeKey => $sizeLabel)
                    <option value="{{ $sizeKey }}">{{ $sizeLabel }}</option>
                @endforeach
            </select>

            <label class="block text-xs font-bold uppercase tracking-wide text-slate-500">Font size</label>
            <select wire:model.live="fontSize" class="w-full rounded-md border border-slate-300 px-3 py-2">
                @foreach ([7, 8, 9, 10, 11, 12, 14, 16] as $sizeOption)
                    <option value="{{ $sizeOption }}">{{ $sizeOption }} px</option>
                @endforeach
            </select>

            <label class="flex items-center gap-2 text-sm font-semibold">
                <input type="checkbox" wire:model.live="isDefault">
                Default template
            </label>

            <button wire:click="save" class="w-full rounded-md bg-blue-700 px-4 py-3 font-bold text-white">Save Template</button>

            @if ($statusMessage)
                <div class="rounded-md bg-green-50 p-3 text-sm font-semibold text-green-700">{{ $statusMessage }}</div>
            @endif

            @if ($templateId)
                <button wire:click="archive" class="w-full rounded-md border border-red-200 px-4 py-3 font-bold text-red-700">Archive</button>
            @endif
        </div>
    </aside>

    <section class="rounded-lg border border-slate-200 bg-white p-5">
        <div class="flex flex-wrap items-start justify-between gap-4">
            <div>
                <p class="text-sm font-bold uppercase tracking-[0.18em] text-blue-700">Simple label builder</p>
                <h1 class="mt-1 text-2xl font-black text-slate-950">Header · Content · Footer</h1>
                <p class="mt-1 text-sm text-slate-500">No complex drag/drop. Select fields, move them up/down, preview, save, then the app prints this template.</p>
            </div>
            <div class="rounded-md bg-blue-50 px-4 py-3 text-sm font-bold text-blue-800">
                Barcode is fixed at bottom
            </div>
        </div>

        <div class="mt-5 grid gap-5 lg:grid-cols-[1fr_340px]">
            <div class="space-y-5">
                <div class="rounded-lg border border-slate-200 p-4">
                    <h2 class="text-lg font-black">Header</h2>
                    <p class="text-sm text-slate-500">Write company details line by line. Example: company name, phone, email, GST, location.</p>
                    <textarea wire:model.live.debounce.400ms="headerText" rows="4" class="mt-3 w-full rounded-md border border-slate-300 p-3"></textarea>
                </div>

                <div class="rounded-lg border border-slate-200 p-4">
                    <div class="flex items-center justify-between gap-3">
                        <div>
                            <h2 class="text-lg font-black">Content Fields</h2>
                            <p class="text-sm text-slate-500">Choose product name, product detail fields and weight values.</p>
                        </div>
                        <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">{{ count($selectedBindings) }} selected</span>
                    </div>

                    <div class="mt-4 grid gap-2 md:grid-cols-2">
                        @foreach ($bindings as $binding)
                            @continue($binding['key'] !== 'product.name' && ! str($binding['key'])->startsWith('dynamic.'))
                            <label class="flex items-center gap-3 rounded-md border border-slate-200 px-3 py-2 text-sm font-semibold">
                                <input
                                    type="checkbox"
                                    wire:click="toggleBinding('{{ $binding['key'] }}')"
                                    @checked(in_array($binding['key'], $selectedBindings, true))
                                >
                                <span>{{ $binding['label'] }}</span>
                            </label>
                        @endforeach
                    </div>

                    <div class="mt-4 rounded-md bg-slate-50 p-3">
                        <p class="text-xs font-bold uppercase tracking-wide text-slate-500">Print weights</p>
                        <div class="mt-2 grid gap-2 sm:grid-cols-4">
                            <label class="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" wire:model.live="printGross"> Gross</label>
                            <label class="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" wire:model.live="printTare"> Tare</label>
                            <label class="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" wire:model.live="printNet"> Net</label>
                            <label class="flex items-center gap-2 text-sm font-semibold"><input type="checkbox" wire:model.live="printPieces"> Pieces</label>
                        </div>
                    </div>

                    <div class="mt-4">
                        <p class="text-xs font-bold uppercase tracking-wide text-slate-500">Selected order</p>
                        <div class="mt-2 space-y-2">
                            @foreach ($selectedBindings as $bindingKey)
                                <div class="flex items-center gap-2 rounded-md border border-slate-200 bg-white px-3 py-2">
                                    <span class="flex-1 text-sm font-bold">{{ $selectedBindingLabels[$bindingKey] ?? $bindingKey }}</span>
                                    <button type="button" wire:click="moveBinding('{{ $bindingKey }}', -1)" class="rounded-md border px-2 py-1 text-xs font-bold">Up</button>
                                    <button type="button" wire:click="moveBinding('{{ $bindingKey }}', 1)" class="rounded-md border px-2 py-1 text-xs font-bold">Down</button>
                                </div>
                            @endforeach
                        </div>
                    </div>
                </div>

                <div class="rounded-lg border border-slate-200 p-4">
                    <h2 class="text-lg font-black">Footer</h2>
                    <p class="text-sm text-slate-500">Optional note, address line, thank you text or batch footer.</p>
                    <textarea wire:model.live.debounce.400ms="footerText" rows="3" class="mt-3 w-full rounded-md border border-slate-300 p-3"></textarea>
                </div>
            </div>

            <div class="rounded-lg border border-blue-100 bg-blue-50 p-4">
                <h2 class="text-lg font-black text-blue-950">Live Preview</h2>
                <div class="mt-4 overflow-auto rounded-md bg-slate-100 p-4">
                    @php
                        $scale = 3.2;
                        $elements = collect($templateJson['elements'] ?? [])->sortBy('layerOrder');
                    @endphp
                    <div
                        class="relative inline-block bg-white shadow"
                        style="width: {{ (float) $widthMm * $scale }}px; height: {{ (float) $heightMm * $scale }}px; border: 2px solid #2563eb;"
                    >
                        @foreach ($elements as $element)
                            @php
                                $type = $element['type'] ?? 'text';
                                $label = match ($type) {
                                    'barcode' => '||||| BARCODE |||||',
                                    default => ($element['prefix'] ?? '').($element['text'] ?? $selectedBindingLabels[$element['bindingKey'] ?? ''] ?? $element['bindingKey'] ?? 'Text').($element['suffix'] ?? ''),
                                };
                                $fontSize = max(8, (float) data_get($element, 'style.fontSize', 9) * $scale / 2.1);
                            @endphp
                            <div
                                class="absolute box-border overflow-hidden {{ $type === 'barcode' ? 'grid place-items-center border border-slate-900 bg-slate-50 font-mono text-slate-900' : '' }}"
                                style="
                                    left: {{ (float) ($element['x'] ?? 0) * $scale }}px;
                                    top: {{ (float) ($element['y'] ?? 0) * $scale }}px;
                                    width: {{ (float) ($element['width'] ?? 30) * $scale }}px;
                                    height: {{ (float) ($element['height'] ?? 8) * $scale }}px;
                                    font-family: Arial, sans-serif;
                                    font-size: {{ $fontSize }}px;
                                    font-weight: {{ data_get($element, 'style.fontWeight', '600') }};
                                    text-align: {{ data_get($element, 'style.align', 'left') }};
                                    color: #0f172a;
                                    padding: 1px 3px;
                                "
                            >{{ $label }}</div>
                        @endforeach
                    </div>
                </div>

                <h2 class="mt-5 text-lg font-black text-blue-950">Warnings</h2>
                @if (count($warnings) === 0)
                    <p class="mt-2 rounded-md bg-green-50 p-3 text-sm font-bold text-green-700">No warnings.</p>
                @endif
                <ul class="mt-2 space-y-2 text-sm text-amber-700">
                    @foreach ($warnings as $warning)
                        <li class="rounded-md bg-amber-50 p-2">{{ $warning['type'] ?? 'warning' }}</li>
                    @endforeach
                </ul>
            </div>
        </div>
    </section>
</div>
