<?php

namespace App\Livewire\Labels;

use App\Domain\Labels\Services\LabelBindingRegistry;
use App\Domain\Labels\Services\LabelTemplateService;
use App\Domain\Labels\Services\LabelTemplateValidator;
use App\Models\Labeling\LabelTemplate;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class LabelDesigner extends Component
{
    public ?string $templateId = null;

    public string $name = 'New Label Template';

    public string $code = 'NEW-LABEL';

    public string $scope = 'tenant';

    public bool $isDefault = false;

    public string $size = '75x75';

    public float $widthMm = 75;

    public float $heightMm = 75;

    public array $templateJson = [];

    public string $templateJsonText = '';

    public array $warnings = [];

    public ?string $selectedElementKey = null;

    public string $selectedBindingKey = 'product.name';

    public ?string $statusMessage = null;

    public string $selectedPreset = 'medium_75_9_fields';

    public string $headerText = "PUNIT ERP\nPhone:\nGST:";

    public string $footerText = '';

    public array $selectedBindings = ['product.name'];

    public bool $printGross = true;

    public bool $printTare = true;

    public bool $printNet = true;

    public bool $printPieces = false;

    public int $fontSize = 9;

    public function mount(?string $template = null): void
    {
        if ($template) {
            $model = LabelTemplate::query()->findOrFail($template);
            abort_unless($model->tenant_id === Auth::user()?->tenant_id, 404);
            $this->templateId = $model->id;
            $this->name = $model->name;
            $this->code = $model->code;
            $this->scope = $model->scope;
            $this->isDefault = $model->is_default;
            $this->widthMm = (float) $model->width_mm;
            $this->heightMm = (float) $model->height_mm;
            $this->templateJson = $model->template_json;
            $this->warnings = $model->warnings ?? [];
            $this->loadStructuredSettings();
        } else {
            $this->templateJson = $this->defaultJson();
        }

        $this->rebuildStructuredTemplate();
        $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
        $this->refreshWarnings();
    }

    public function save(LabelTemplateService $service, LabelTemplateValidator $validator): void
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);
        $this->rebuildStructuredTemplate();
        $this->templateJson['widthMm'] = $this->widthMm;
        $this->templateJson['heightMm'] = $this->heightMm;
        $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
        $this->warnings = $validator->validate($this->templateJson, $tenantId);
        $payload = [
            'name' => $this->name,
            'code' => $this->code,
            'scope' => $this->scope,
            'is_default' => $this->isDefault,
            'is_custom_size' => $this->size === 'custom',
            'template_json' => $this->templateJson,
        ];

        if ($this->templateId) {
            $template = LabelTemplate::query()->findOrFail($this->templateId);
            abort_unless($template->tenant_id === $tenantId, 404);
            $codeExists = LabelTemplate::query()
                ->where('tenant_id', $tenantId)
                ->where('code', $this->code)
                ->where('id', '!=', $template->id)
                ->where('is_archived', false)
                ->exists();

            if ($codeExists) {
                $this->statusMessage = 'This template code already exists. Please change the code or open that template from the list.';

                return;
            }

            $service->update($template, $payload);
        } else {
            $template = LabelTemplate::query()
                ->where('tenant_id', $tenantId)
                ->where('code', $this->code)
                ->where('is_archived', false)
                ->first();

            if ($template) {
                $service->update($template, $payload);
                $this->statusMessage = 'Existing template code found, so I updated that template instead of creating a duplicate.';
            } else {
                $template = $service->create($payload, $tenantId);
                $this->statusMessage = 'Template saved.';
            }

            $this->templateId = $template->id;
        }

        $this->statusMessage ??= 'Template saved.';
        $this->dispatch('label-saved');
    }

    public function archive(LabelTemplateService $service): void
    {
        $template = LabelTemplate::query()->findOrFail($this->templateId);
        abort_unless($template->tenant_id === Auth::user()?->tenant_id, 404);
        $service->archive($template);
        $this->redirect('/labels');
    }

    public function updatedSize(string $size): void
    {
        if ($size === '50x75') {
            $this->widthMm = 50;
            $this->heightMm = 75;
        }

        if ($size === '75x75') {
            $this->widthMm = 75;
            $this->heightMm = 75;
        }

        if ($size === '75x100') {
            $this->widthMm = 75;
            $this->heightMm = 100;
        }

        if ($size === '100x100') {
            $this->widthMm = 100;
            $this->heightMm = 100;
        }

        if ($size === '100x150') {
            $this->widthMm = 100;
            $this->heightMm = 150;
        }

        $this->rebuildStructuredTemplate();
    }

    public function updatedHeaderText(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function updatedFooterText(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function updatedFontSize(): void
    {
        $this->fontSize = max(6, min(18, $this->fontSize));
        $this->rebuildStructuredTemplate();
    }

    public function updatedPrintGross(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function updatedPrintTare(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function updatedPrintNet(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function updatedPrintPieces(): void
    {
        $this->rebuildStructuredTemplate();
    }

    public function toggleBinding(string $bindingKey): void
    {
        if (in_array($bindingKey, $this->selectedBindings, true)) {
            $this->selectedBindings = array_values(array_filter(
                $this->selectedBindings,
                fn (string $key): bool => $key !== $bindingKey
            ));
        } else {
            $this->selectedBindings[] = $bindingKey;
        }

        $this->rebuildStructuredTemplate();
    }

    public function moveBinding(string $bindingKey, int $direction): void
    {
        $index = array_search($bindingKey, $this->selectedBindings, true);

        if ($index === false) {
            return;
        }

        $target = $index + $direction;

        if ($target < 0 || $target >= count($this->selectedBindings)) {
            return;
        }

        $items = $this->selectedBindings;
        [$items[$index], $items[$target]] = [$items[$target], $items[$index]];
        $this->selectedBindings = array_values($items);
        $this->rebuildStructuredTemplate();
    }

    public function applyPreset(): void
    {
        $preset = $this->presetTemplates()[$this->selectedPreset] ?? null;

        if (! $preset) {
            return;
        }

        $this->size = $preset['size'];
        $this->widthMm = $preset['widthMm'];
        $this->heightMm = $preset['heightMm'];
        $this->templateJson = [
            'widthMm' => $this->widthMm,
            'heightMm' => $this->heightMm,
            'gridMm' => 2.5,
            'preset' => $this->selectedPreset,
            'elements' => $preset['elements'],
        ];
        $this->selectedElementKey = null;
        $this->statusMessage = 'Predefined design applied. You can still customize every field.';
        $this->syncTemplateText();
    }

    public function addText(): void
    {
        $this->addElement(['type' => 'text', 'text' => 'Static text', 'width' => 35, 'height' => 8]);
    }

    public function addProductField(): void
    {
        $this->addBindingField();
    }

    public function addBindingField(): void
    {
        $this->addElement(['type' => 'binding_text', 'bindingKey' => $this->selectedBindingKey, 'width' => 42, 'height' => 8]);
    }

    public function addNetWeight(): void
    {
        $this->addElement(['type' => 'binding_text', 'bindingKey' => 'weight.net', 'prefix' => 'Net: ', 'width' => 35, 'height' => 8]);
    }

    public function addBarcode(): void
    {
        $this->syncTemplateFromText();

        if (collect($this->templateJson['elements'])->where('type', 'barcode')->isNotEmpty()) {
            $this->warnings = [['type' => 'single_barcode_only']];

            return;
        }

        $this->addElement(['type' => 'barcode', 'bindingKey' => 'barcode.value', 'width' => 45, 'height' => 16]);
    }

    public function addRectangle(): void
    {
        $this->addElement(['type' => 'rectangle', 'width' => 30, 'height' => 15]);
    }

    public function duplicateLast(): void
    {
        $this->syncTemplateFromText();
        $elements = $this->templateJson['elements'] ?? [];
        $last = end($elements);

        if (! is_array($last)) {
            return;
        }

        if (($last['type'] ?? null) === 'barcode' && collect($elements)->where('type', 'barcode')->isNotEmpty()) {
            $this->warnings = [['type' => 'single_barcode_only']];

            return;
        }

        $last['key'] = 'element_'.now()->timestamp.'_'.count($elements);
        $last['x'] = ((float) ($last['x'] ?? 0)) + 3;
        $last['y'] = ((float) ($last['y'] ?? 0)) + 3;
        $last['layerOrder'] = count($elements) + 1;
        $this->selectedElementKey = $last['key'];
        $this->templateJson['elements'][] = $last;
        $this->syncTemplateText();
    }

    public function deleteLast(): void
    {
        $this->syncTemplateFromText();
        array_pop($this->templateJson['elements']);
        $this->selectedElementKey = null;
        $this->syncTemplateText();
    }

    public function selectElement(string $key): void
    {
        $this->selectedElementKey = $key;
    }

    public function deleteSelected(): void
    {
        if (! $this->selectedElementKey) {
            return;
        }

        $this->syncTemplateFromText();
        $this->templateJson['elements'] = collect($this->templateJson['elements'])
            ->reject(fn (array $element) => ($element['key'] ?? null) === $this->selectedElementKey)
            ->values()
            ->all();
        $this->selectedElementKey = null;
        $this->syncTemplateText();
    }

    public function nudgeSelected(float $x, float $y): void
    {
        $this->mutateSelected(function (array $element) use ($x, $y): array {
            $element['x'] = $this->snap(((float) ($element['x'] ?? 0)) + $x);
            $element['y'] = $this->snap(((float) ($element['y'] ?? 0)) + $y);

            return $element;
        });
    }

    public function resizeSelected(float $width, float $height): void
    {
        $this->mutateSelected(function (array $element) use ($width, $height): array {
            $element['width'] = max(2, $this->snap(((float) ($element['width'] ?? 0)) + $width));
            $element['height'] = max(2, $this->snap(((float) ($element['height'] ?? 0)) + $height));

            return $element;
        });
    }

    public function layerSelected(int $direction): void
    {
        $this->mutateSelected(function (array $element) use ($direction): array {
            $element['layerOrder'] = max(1, ((int) ($element['layerOrder'] ?? 1)) + $direction);

            return $element;
        });
    }

    public function updateSelected(string $field, mixed $value): void
    {
        $allowed = ['x', 'y', 'width', 'height', 'rotation', 'layerOrder', 'text', 'bindingKey', 'prefix', 'suffix', 'fontSize', 'fontFamily', 'fontWeight', 'align'];

        if (! in_array($field, $allowed, true)) {
            return;
        }

        $this->mutateSelected(function (array $element) use ($field, $value): array {
            if (in_array($field, ['x', 'y', 'width', 'height', 'rotation'], true)) {
                $element[$field] = $field === 'rotation' ? (float) $value : $this->snap((float) $value);
            } elseif ($field === 'layerOrder') {
                $element[$field] = max(1, (int) $value);
            } elseif (in_array($field, ['fontSize', 'fontFamily', 'fontWeight', 'align'], true)) {
                $element['style'] ??= [];
                $element['style'][$field] = $field === 'fontSize' ? max(4, (float) $value) : (string) $value;
            } else {
                $element[$field] = (string) $value;
            }

            return $element;
        });
    }

    public function render(): mixed
    {
        $tenantId = Auth::user()?->tenant_id;

        return view('livewire.labels.label-designer', [
            'templates' => LabelTemplate::query()
                ->where('tenant_id', $tenantId)
                ->where('is_archived', false)
                ->latest()
                ->get(),
            'bindings' => app(LabelBindingRegistry::class)->bindings((string) $tenantId),
            'fontFamilies' => $this->fontFamilies(),
            'fontWeights' => $this->fontWeights(),
            'presetTemplates' => $this->presetTemplates(),
            'selectedElement' => $this->selectedElement(),
            'labelSizes' => $this->labelSizes(),
            'selectedBindingLabels' => collect(app(LabelBindingRegistry::class)->bindings((string) $tenantId))
                ->pluck('label', 'key')
                ->all(),
        ]);
    }

    private function defaultJson(): array
    {
        return [
            'widthMm' => $this->widthMm,
            'heightMm' => $this->heightMm,
            'gridMm' => 2.5,
            'elements' => [
                ['key' => 'product_name', 'type' => 'binding_text', 'bindingKey' => 'product.name', 'x' => 5, 'y' => 5, 'width' => 60, 'height' => 10, 'layerOrder' => 1, 'style' => ['fontSize' => 12, 'fontFamily' => 'Arial', 'fontWeight' => 'bold']],
                ['key' => 'net_weight', 'type' => 'binding_text', 'bindingKey' => 'weight.net', 'x' => 5, 'y' => 20, 'width' => 40, 'height' => 10, 'layerOrder' => 2, 'prefix' => 'Net: ', 'style' => ['fontSize' => 10, 'fontFamily' => 'Arial', 'fontWeight' => 'normal']],
                ['key' => 'barcode', 'type' => 'barcode', 'bindingKey' => 'barcode.value', 'x' => 5, 'y' => 40, 'width' => 55, 'height' => 20, 'layerOrder' => 3],
            ],
        ];
    }

    private function addElement(array $partial): void
    {
        $this->syncTemplateFromText();
        $elements = $this->templateJson['elements'] ?? [];
        $index = count($elements) + 1;
        $element = array_merge([
            'key' => 'element_'.now()->timestamp.'_'.$index,
            'x' => 5,
            'y' => 5 + ($index * 6),
            'width' => 35,
            'height' => 8,
            'rotation' => 0,
            'layerOrder' => $index,
            'style' => ['fontSize' => 10, 'fontFamily' => 'Arial', 'fontWeight' => 'normal'],
        ], $partial);

        $this->selectedElementKey = $element['key'];
        $this->templateJson['elements'][] = $element;
        $this->syncTemplateText();
    }

    private function mutateSelected(callable $callback): void
    {
        if (! $this->selectedElementKey) {
            return;
        }

        $this->syncTemplateFromText();

        foreach ($this->templateJson['elements'] as $index => $element) {
            if (($element['key'] ?? null) === $this->selectedElementKey) {
                $this->templateJson['elements'][$index] = $callback($element);
                break;
            }
        }

        $this->syncTemplateText();
    }

    private function syncTemplateFromText(): void
    {
        $decoded = json_decode($this->templateJsonText, true);

        if (is_array($decoded)) {
            $this->templateJson = $decoded;
        }

        $this->templateJson['elements'] ??= [];
    }

    private function syncTemplateText(): void
    {
        $this->templateJson['widthMm'] = $this->widthMm;
        $this->templateJson['heightMm'] = $this->heightMm;
        $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
        $this->refreshWarnings();
    }

    private function loadStructuredSettings(): void
    {
        $structured = $this->templateJson['structured'] ?? [];

        if (! is_array($structured)) {
            return;
        }

        $this->headerText = (string) ($structured['headerText'] ?? $this->headerText);
        $this->footerText = (string) ($structured['footerText'] ?? $this->footerText);
        $this->selectedBindings = array_values(array_filter(
            (array) ($structured['selectedBindings'] ?? $this->selectedBindings),
            fn ($key): bool => is_string($key) && $key !== ''
        ));
        $weights = (array) ($structured['weights'] ?? []);
        $this->printGross = (bool) ($weights['gross'] ?? $this->printGross);
        $this->printTare = (bool) ($weights['tare'] ?? $this->printTare);
        $this->printNet = (bool) ($weights['net'] ?? $this->printNet);
        $this->printPieces = (bool) ($weights['pieces'] ?? $this->printPieces);
        $this->fontSize = (int) ($structured['fontSize'] ?? $this->fontSize);
    }

    private function rebuildStructuredTemplate(): void
    {
        $this->selectedBindings = array_values(array_unique($this->selectedBindings));
        $bindingLabels = collect(app(LabelBindingRegistry::class)->bindings((string) Auth::user()?->tenant_id))
            ->pluck('label', 'key');
        $contentBindings = collect($this->selectedBindings)
            ->filter(fn (string $key): bool => $key !== 'barcode.value')
            ->take(10)
            ->values();
        $weightBindings = collect([
            $this->printGross ? 'weight.gross' : null,
            $this->printTare ? 'weight.tare' : null,
            $this->printNet ? 'weight.net' : null,
            $this->printPieces ? 'pieces.quantity' : null,
        ])->filter()->values();
        $contentBindings = $contentBindings
            ->merge($weightBindings)
            ->unique()
            ->take(10)
            ->values();

        $elements = [];
        $order = 1;
        $safeFont = max(6, min(18, $this->fontSize));
        $y = 3.0;

        foreach ($this->lines($this->headerText, 4) as $line) {
            $elements[] = $this->textElement('header_'.$order, $line, 3, $y, $this->widthMm - 6, 5.5, $order++, $safeFont, '700', 'center');
            $y += 6;
        }

        $contentTop = max($y + 1, $this->heightMm * 0.22);
        $barcodeHeight = min(22, max(16, $this->heightMm * 0.18));
        $barcodeY = $this->heightMm - $barcodeHeight - 5;
        $footerLines = $this->lines($this->footerText, 3);
        $footerHeight = count($footerLines) * 5.5;
        $contentBottom = $barcodeY - $footerHeight - 2;
        $rowHeight = max(5.5, min(8, ($contentBottom - $contentTop) / max(1, count($contentBindings))));

        foreach ($contentBindings as $bindingKey) {
            $label = (string) ($bindingLabels[$bindingKey] ?? str($bindingKey)->replace('.', ' ')->title());
            $elements[] = $this->bindingElement(
                str($bindingKey)->replace('.', '_')->toString(),
                $bindingKey,
                4,
                $contentTop,
                $this->widthMm - 8,
                $rowHeight,
                $order++,
                $label.': ',
                in_array($bindingKey, ['weight.gross', 'weight.tare', 'weight.net'], true) ? ' kg' : '',
                $bindingKey === 'weight.net' ? $safeFont + 2 : $safeFont,
                $bindingKey === 'weight.net' ? '800' : '600',
                'left'
            );
            $contentTop += $rowHeight;
        }

        $footerY = max($contentTop + 1, $barcodeY - $footerHeight - 1);
        foreach ($footerLines as $line) {
            $elements[] = $this->textElement('footer_'.$order, $line, 3, $footerY, $this->widthMm - 6, 5, $order++, max(6, $safeFont - 1), '500', 'center');
            $footerY += 5.5;
        }

        $elements[] = $this->barcodeElement(5, $barcodeY, $this->widthMm - 10, $barcodeHeight, $order);

        $this->templateJson = [
            'widthMm' => $this->widthMm,
            'heightMm' => $this->heightMm,
            'gridMm' => 2.5,
            'mode' => 'structured',
            'structured' => [
                'headerText' => $this->headerText,
                'footerText' => $this->footerText,
                'selectedBindings' => $this->selectedBindings,
                'weights' => [
                    'gross' => $this->printGross,
                    'tare' => $this->printTare,
                    'net' => $this->printNet,
                    'pieces' => $this->printPieces,
                ],
                'fontSize' => $safeFont,
            ],
            'elements' => $elements,
        ];
        $this->syncTemplateText();
    }

    private function lines(string $value, int $limit): array
    {
        return collect(preg_split('/\R/', $value) ?: [])
            ->map(fn (string $line): string => trim($line))
            ->filter()
            ->take($limit)
            ->values()
            ->all();
    }

    private function selectedElement(): ?array
    {
        if (! $this->selectedElementKey) {
            return null;
        }

        return collect($this->templateJson['elements'] ?? [])
            ->first(fn (array $element) => ($element['key'] ?? null) === $this->selectedElementKey);
    }

    private function refreshWarnings(): void
    {
        $tenantId = Auth::user()?->tenant_id;

        if (! $tenantId) {
            return;
        }

        $this->warnings = app(LabelTemplateValidator::class)->warnings($this->templateJson, $tenantId);
    }

    private function snap(float $value): float
    {
        $grid = (float) ($this->templateJson['gridMm'] ?? 2.5);

        return round($value / $grid) * $grid;
    }

    private function fontFamilies(): array
    {
        return [
            'Arial',
            'Helvetica',
            'Verdana',
            'Tahoma',
            'Times New Roman',
            'Georgia',
            'Courier New',
            'monospace',
            'sans-serif',
        ];
    }

    private function fontWeights(): array
    {
        return [
            '300' => 'Light',
            '400' => 'Normal',
            '500' => 'Medium',
            '600' => 'Semi Bold',
            '700' => 'Bold',
            '800' => 'Extra Bold',
        ];
    }

    private function presetTemplates(): array
    {
        return [
            'small_50_essential' => [
                'label' => 'Small 50x75 - Essential 5 fields',
                'size' => '50x75',
                'widthMm' => 50,
                'heightMm' => 75,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 3, 3, 44, 6, 1, '', '', 9, '700', 'center'),
                    $this->bindingElement('product_name', 'product.name', 3, 11, 44, 10, 2, '', '', 12, '700', 'center'),
                    $this->bindingElement('net_weight', 'weight.net', 3, 24, 44, 11, 3, 'Net: ', ' kg', 13, '800', 'center'),
                    $this->bindingElement('serial_number', 'serial.number', 3, 39, 44, 6, 4, 'Sr: ', '', 8, '500', 'center'),
                    $this->barcodeElement(5, 49, 40, 20, 5),
                ],
            ],
            'medium_75_5_fields' => [
                'label' => 'Medium 75x75 - 5 large fields + barcode',
                'size' => '75x75',
                'widthMm' => 75,
                'heightMm' => 75,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 8, 1, '', '', 11, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 4, 14, 67, 10, 2, 'Product: ', '', 12, '800', 'center'),
                    $this->bindingElement('net_weight', 'weight.net', 4, 28, 32, 11, 3, 'Net: ', ' kg', 13, '800', 'center'),
                    $this->bindingElement('piece_quantity', 'pieces.quantity', 39, 28, 32, 11, 4, 'PCS: ', '', 12, '700', 'center'),
                    $this->bindingElement('serial_number', 'serial.number', 4, 42, 67, 7, 5, 'Sr: ', '', 8, '600', 'center'),
                    $this->barcodeElement(8, 53, 59, 18, 6),
                ],
            ],
            'medium_75_7_fields' => [
                'label' => 'Medium 75x75 - 7 balanced fields + barcode',
                'size' => '75x75',
                'widthMm' => 75,
                'heightMm' => 75,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 7, 1, '', '', 10, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 4, 12, 43, 9, 2, 'Product: ', '', 11, '700'),
                    $this->bindingElement('variant_name', 'variant.name', 49, 12, 22, 9, 3, 'Var: ', '', 9, '600'),
                    $this->bindingElement('net_weight', 'weight.net', 4, 24, 32, 10, 4, 'Net: ', ' kg', 12, '800', 'center'),
                    $this->bindingElement('piece_quantity', 'pieces.quantity', 39, 24, 32, 10, 5, 'PCS: ', '', 11, '700', 'center'),
                    $this->bindingElement('serial_number', 'serial.number', 4, 37, 43, 7, 6, 'Sr: ', '', 8, '600'),
                    $this->bindingElement('date_current', 'date.current', 49, 37, 22, 7, 7, '', '', 8, '500'),
                    $this->barcodeElement(8, 49, 59, 20, 8),
                ],
            ],
            'medium_75_9_fields' => [
                'label' => 'Medium 75x75 - 9 fields + company + barcode',
                'size' => '75x75',
                'widthMm' => 75,
                'heightMm' => 75,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 6, 1, '', '', 9, '700', 'center'),
                    $this->bindingElement('product_name', 'product.name', 4, 11, 42, 8, 2, 'Product: ', '', 10, '700'),
                    $this->bindingElement('variant_name', 'variant.name', 47, 11, 24, 8, 3, 'Var: ', '', 8, '600'),
                    $this->bindingElement('gross_weight', 'weight.gross', 4, 21, 21, 7, 4, 'Gross: ', ' kg', 8, '500'),
                    $this->bindingElement('tare_weight', 'weight.tare', 27, 21, 20, 7, 5, 'Tare: ', ' kg', 8, '500'),
                    $this->bindingElement('net_weight', 'weight.net', 49, 21, 22, 7, 6, 'Net: ', ' kg', 9, '800'),
                    $this->bindingElement('piece_quantity', 'pieces.quantity', 4, 30, 21, 7, 7, 'PCS: ', '', 8, '600'),
                    $this->bindingElement('serial_number', 'serial.number', 27, 30, 44, 7, 8, 'Sr: ', '', 8, '500'),
                    $this->bindingElement('date_current', 'date.current', 4, 39, 21, 6, 9, '', '', 7, '500'),
                    $this->bindingElement('operator_name', 'operator.name', 27, 39, 44, 6, 10, 'Op: ', '', 7, '500'),
                    $this->barcodeElement(8, 48, 59, 21, 11),
                ],
            ],
            'large_100_detail' => [
                'label' => 'Large 100x100 - Detailed industrial',
                'size' => '100x100',
                'widthMm' => 100,
                'heightMm' => 100,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 5, 4, 90, 8, 1, '', '', 12, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 5, 16, 58, 10, 2, 'Product: ', '', 12, '700'),
                    $this->bindingElement('variant_name', 'variant.name', 65, 16, 30, 10, 3, 'Variant: ', '', 10, '600'),
                    $this->bindingElement('product_code', 'product.code', 5, 30, 43, 8, 4, 'Code: ', '', 9, '500'),
                    $this->bindingElement('variant_code', 'variant.code', 52, 30, 43, 8, 5, 'V.Code: ', '', 9, '500'),
                    $this->bindingElement('gross_weight', 'weight.gross', 5, 42, 28, 9, 6, 'Gross: ', ' kg', 10, '600'),
                    $this->bindingElement('tare_weight', 'weight.tare', 36, 42, 28, 9, 7, 'Tare: ', ' kg', 10, '600'),
                    $this->bindingElement('net_weight', 'weight.net', 67, 42, 28, 9, 8, 'Net: ', ' kg', 11, '800'),
                    $this->bindingElement('piece_quantity', 'pieces.quantity', 5, 55, 28, 8, 9, 'PCS: ', '', 10, '600'),
                    $this->bindingElement('serial_number', 'serial.number', 36, 55, 59, 8, 10, 'Serial: ', '', 9, '500'),
                    $this->bindingElement('date_current', 'date.current', 5, 67, 28, 7, 11, 'Date: ', '', 8, '500'),
                    $this->bindingElement('operator_name', 'operator.name', 36, 67, 59, 7, 12, 'Operator: ', '', 8, '500'),
                    $this->barcodeElement(12, 78, 76, 17, 13),
                ],
            ],
            'medium_75_100' => [
                'label' => '75x100 - More product details',
                'size' => '75x100',
                'widthMm' => 75,
                'heightMm' => 100,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 4, 67, 7, 1, '', '', 10, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 4, 15, 67, 9, 2, 'Product: ', '', 11, '800'),
                    $this->bindingElement('gross_weight', 'weight.gross', 4, 29, 30, 8, 3, 'Gross: ', ' kg', 9, '600'),
                    $this->bindingElement('tare_weight', 'weight.tare', 39, 29, 32, 8, 4, 'Tare: ', ' kg', 9, '600'),
                    $this->bindingElement('net_weight', 'weight.net', 4, 42, 67, 10, 5, 'Net: ', ' kg', 13, '800', 'center'),
                    $this->bindingElement('serial_number', 'serial.number', 4, 57, 67, 7, 6, 'Sr: ', '', 8, '600'),
                    $this->barcodeElement(8, 73, 59, 21, 7),
                ],
            ],
            'large_100_150' => [
                'label' => '100x150 - Maximum detail',
                'size' => '100x150',
                'widthMm' => 100,
                'heightMm' => 150,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 5, 5, 90, 9, 1, '', '', 13, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 5, 20, 90, 10, 2, 'Product: ', '', 12, '800'),
                    $this->bindingElement('gross_weight', 'weight.gross', 5, 36, 28, 9, 3, 'Gross: ', ' kg', 10, '600'),
                    $this->bindingElement('tare_weight', 'weight.tare', 36, 36, 28, 9, 4, 'Tare: ', ' kg', 10, '600'),
                    $this->bindingElement('net_weight', 'weight.net', 67, 36, 28, 9, 5, 'Net: ', ' kg', 11, '800'),
                    $this->bindingElement('piece_quantity', 'pieces.quantity', 5, 51, 28, 8, 6, 'PCS: ', '', 10, '600'),
                    $this->bindingElement('serial_number', 'serial.number', 36, 51, 59, 8, 7, 'Serial: ', '', 9, '600'),
                    $this->bindingElement('date_current', 'date.current', 5, 66, 90, 7, 8, 'Date: ', '', 8, '500'),
                    $this->barcodeElement(12, 118, 76, 24, 9),
                ],
            ],
        ];
    }

    private function labelSizes(): array
    {
        return [
            '75x75' => '75 x 75 mm',
            '100x100' => '100 x 100 mm',
            '75x100' => '75 x 100 mm',
            '50x75' => '50 x 75 mm',
            '100x150' => '100 x 150 mm',
        ];
    }

    private function textElement(string $key, string $text, float $x, float $y, float $width, float $height, int $layerOrder, float $fontSize = 9, string $fontWeight = '500', string $align = 'left'): array
    {
        return [
            'key' => $key,
            'type' => 'text',
            'text' => $text,
            'x' => $x,
            'y' => $y,
            'width' => $width,
            'height' => $height,
            'layerOrder' => $layerOrder,
            'style' => [
                'fontSize' => $fontSize,
                'fontFamily' => 'Arial',
                'fontWeight' => $fontWeight,
                'align' => $align,
            ],
        ];
    }

    private function bindingElement(string $key, string $bindingKey, float $x, float $y, float $width, float $height, int $layerOrder, string $prefix = '', string $suffix = '', float $fontSize = 9, string $fontWeight = '500', string $align = 'left'): array
    {
        return [
            'key' => $key,
            'type' => 'binding_text',
            'bindingKey' => $bindingKey,
            'x' => $x,
            'y' => $y,
            'width' => $width,
            'height' => $height,
            'layerOrder' => $layerOrder,
            'prefix' => $prefix,
            'suffix' => $suffix,
            'style' => [
                'fontSize' => $fontSize,
                'fontFamily' => 'Arial',
                'fontWeight' => $fontWeight,
                'align' => $align,
            ],
        ];
    }

    private function barcodeElement(float $x, float $y, float $width, float $height, int $layerOrder): array
    {
        return [
            'key' => 'barcode',
            'type' => 'barcode',
            'bindingKey' => 'barcode.value',
            'x' => $x,
            'y' => $y,
            'width' => $width,
            'height' => $height,
            'layerOrder' => $layerOrder,
        ];
    }
}
