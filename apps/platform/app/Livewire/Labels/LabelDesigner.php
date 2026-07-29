<?php

namespace App\Livewire\Labels;

use App\Domain\Labels\Services\LabelBindingRegistry;
use App\Domain\Labels\Services\LabelTemplateService;
use App\Domain\Labels\Services\LabelTemplateValidator;
use App\Models\Labeling\LabelTemplate;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Livewire\Features\SupportFileUploads\TemporaryUploadedFile;
use Livewire\WithFileUploads;

class LabelDesigner extends Component
{
    use WithFileUploads;

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

    public ?TemporaryUploadedFile $imageUpload = null;

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
            $this->size = $this->inferSize($this->widthMm, $this->heightMm);
            $this->templateJson = $model->template_json;
            $this->warnings = $model->warnings ?? [];
            $this->loadStructuredSettings();
            $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
            $this->refreshWarnings();

            return;
        } else {
            $this->templateJson = $this->defaultJson();
        }

        $this->ensureMandatoryBarcode();
        $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
        $this->refreshWarnings();
    }

    public function save(LabelTemplateService $service, LabelTemplateValidator $validator): void
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);
        $this->syncTemplateFromText();
        $this->ensureMandatoryBarcode();
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
            $this->widthMm = 75;
            $this->heightMm = 50;
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

        $this->resizeCanvas();
    }

    public function updatedWidthMm(): void
    {
        $this->size = 'custom';
        $this->resizeCanvas();
    }

    public function updatedHeightMm(): void
    {
        $this->size = 'custom';
        $this->resizeCanvas();
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
            'gridMm' => 0.125,
            'precision203' => true,
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

    public function addStaticText(string $text = 'Custom text'): void
    {
        $this->addElement(['type' => 'text', 'text' => $text, 'width' => 45, 'height' => 8]);
    }

    public function addProductField(): void
    {
        $this->addBindingField();
    }

    public function addBindingField(): void
    {
        $this->addElement(['type' => 'binding_text', 'bindingKey' => $this->selectedBindingKey, 'width' => 42, 'height' => 8]);
    }

    public function addBinding(string $bindingKey): void
    {
        $this->selectedBindingKey = $bindingKey;
        $this->addElement(['type' => 'binding_text', 'bindingKey' => $bindingKey, 'width' => 46, 'height' => 8]);
    }

    public function addNetWeight(): void
    {
        $this->addElement(['type' => 'binding_text', 'bindingKey' => 'weight.net', 'prefix' => 'Net: ', 'width' => 35, 'height' => 8]);
    }

    public function addBarcode(): void
    {
        $this->syncTemplateFromText();

        if (collect($this->templateJson['elements'])
            ->where('type', 'barcode')
            ->filter(fn (array $element): bool => ($element['bindingKey'] ?? 'barcode.value') === 'barcode.value')
            ->isNotEmpty()) {
            $this->warnings = [['type' => 'single_barcode_only']];

            return;
        }

        $this->addElement(['type' => 'barcode', 'bindingKey' => 'barcode.value', 'width' => 45, 'height' => 16]);
    }

    public function addCustomerBarcode(): void
    {
        $this->syncTemplateFromText();

        if (collect($this->templateJson['elements'])
            ->where('type', 'barcode')
            ->where('bindingKey', 'product.customer_barcode')
            ->isNotEmpty()) {
            $this->warnings = [['type' => 'single_customer_barcode_only']];

            return;
        }

        $this->addElement([
            'type' => 'barcode',
            'bindingKey' => 'product.customer_barcode',
            'caption' => '',
            'captionPosition' => 'top',
            'showValue' => true,
            'width' => 45,
            'height' => 20,
        ]);
    }

    public function addLine(): void
    {
        $this->addElement(['type' => 'line', 'width' => min(45, $this->widthMm - 8), 'height' => 1]);
    }

    public function addRectangle(): void
    {
        $this->addElement(['type' => 'rectangle', 'width' => 30, 'height' => 15]);
    }

    public function addUploadedImage(): void
    {
        $this->validate([
            'imageUpload' => ['required', 'image', 'max:2048'],
        ]);

        $path = $this->imageUpload?->store('label-images', 'public');

        if (! $path) {
            return;
        }

        $mime = $this->imageUpload->getMimeType() ?: 'image/png';
        $encoded = base64_encode((string) file_get_contents($this->imageUpload->getRealPath()));

        $this->addElement([
            'type' => 'image',
            'imagePath' => $path,
            'imageUrl' => asset('storage/'.$path),
            'imageBase64' => $encoded,
            'imageMime' => $mime,
            'imageDataUri' => 'data:'.$mime.';base64,'.$encoded,
            'width' => min(24, $this->widthMm - 8),
            'height' => 14,
            'preserveAspectRatio' => true,
        ]);
        $this->imageUpload = null;
    }

    public function duplicateLast(): void
    {
        $this->syncTemplateFromText();
        $elements = $this->templateJson['elements'] ?? [];
        $last = end($elements);

        if (! is_array($last)) {
            return;
        }

        if (($last['type'] ?? null) === 'barcode') {
            $this->warnings = [['type' => 'single_barcode_source_only']];

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

        $selected = collect($this->templateJson['elements'] ?? [])
            ->firstWhere('key', $this->selectedElementKey);
        if (($selected['type'] ?? null) === 'barcode'
            && ($selected['bindingKey'] ?? 'barcode.value') === 'barcode.value') {
            $this->statusMessage = 'Barcode is mandatory and cannot be deleted. You can move or resize it.';

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
        $allowed = ['x', 'y', 'width', 'height', 'rotation', 'layerOrder', 'text', 'bindingKey', 'prefix', 'suffix', 'caption', 'captionPosition', 'showValue', 'fontSize', 'fontFamily', 'fontWeight', 'fontStyle', 'align'];

        if (! in_array($field, $allowed, true)) {
            return;
        }

        $this->mutateSelected(function (array $element) use ($field, $value): array {
            if (in_array($field, ['x', 'y', 'width', 'height', 'rotation'], true)) {
                $element[$field] = $field === 'rotation' ? (float) $value : $this->snap((float) $value);
            } elseif ($field === 'layerOrder') {
                $element[$field] = max(1, (int) $value);
            } elseif (in_array($field, ['fontSize', 'fontFamily', 'fontWeight', 'fontStyle', 'align'], true)) {
                $element['style'] ??= [];
                $element['style'][$field] = $field === 'fontSize' ? max(4, (float) $value) : (string) $value;
            } elseif ($field === 'showValue') {
                $element[$field] = filter_var($value, FILTER_VALIDATE_BOOL);
            } else {
                $element[$field] = (string) $value;
            }

            return $element;
        });
    }

    public function updateElementPosition(string $key, float $x, float $y): void
    {
        $this->selectedElementKey = $key;
        $this->mutateSelected(function (array $element) use ($x, $y): array {
            $element['x'] = $this->clamp($this->snap($x), 0, max(0, $this->widthMm - (float) ($element['width'] ?? 2)));
            $element['y'] = $this->clamp($this->snap($y), 0, max(0, $this->heightMm - (float) ($element['height'] ?? 2)));

            return $element;
        });
    }

    public function render(): mixed
    {
        $tenantId = Auth::user()?->tenant_id;
        $bindings = app(LabelBindingRegistry::class)->bindings((string) $tenantId);

        return view('livewire.labels.label-designer', [
            'templates' => LabelTemplate::query()
                ->where('tenant_id', $tenantId)
                ->where('is_archived', false)
                ->latest()
                ->get(),
            'bindings' => $bindings,
            'fontFamilies' => $this->fontFamilies(),
            'fontWeights' => $this->fontWeights(),
            'presetTemplates' => $this->presetTemplates(),
            'selectedElement' => $this->selectedElement(),
            'labelSizes' => $this->labelSizes(),
            'previewProducts' => $this->previewProducts((string) $tenantId),
            'selectedBindingLabels' => collect($bindings)
                ->pluck('label', 'key')
                ->all(),
        ]);
    }

    private function defaultJson(): array
    {
        $barcodeHeight = min(18, max(12, $this->heightMm * 0.22));
        $barcodeY = max(3, $this->heightMm - $barcodeHeight - 4);

        return [
            'widthMm' => $this->widthMm,
            'heightMm' => $this->heightMm,
            'gridMm' => 0.125,
            'precision203' => true,
            'elements' => [
                $this->bindingElement('company_name', 'company.name', 4, 3, max(20, $this->widthMm - 8), 8, 1, '', '', 13, '800', 'center'),
                $this->bindingElement('product_name', 'product.name', 4, 14, max(20, $this->widthMm - 8), 10, 2, 'Product: ', '', 12, '800', 'center'),
                $this->bindingElement('net_weight', 'weight.net', 4, 28, max(20, $this->widthMm - 8), 12, 3, 'Net: ', ' kg', 15, '800', 'center'),
                $this->bindingElement('serial_number', 'serial.number', 4, 43, max(20, $this->widthMm - 8), 7, 4, 'Sr: ', '', 8, '600', 'center'),
                $this->barcodeElement(8, $barcodeY, max(20, $this->widthMm - 16), $barcodeHeight, 5),
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
            'multiline' => true,
            'locked' => false,
            'style' => [
                'fontSize' => 10,
                'prefixFontSize' => 10,
                'suffixFontSize' => 10,
                'fontFamily' => 'TVS Auto',
                'fontWeight' => 'normal',
            ],
        ], $partial);

        $element['x'] = $this->clamp((float) $element['x'], 0, max(0, $this->widthMm - (float) $element['width']));
        $element['y'] = $this->clamp((float) $element['y'], 0, max(0, $this->heightMm - (float) $element['height']));
        $this->selectedElementKey = $element['key'];
        $this->templateJson['elements'][] = $element;
        $this->ensureMandatoryBarcode();
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
        $this->ensureMandatoryBarcode();
        $this->templateJsonText = json_encode($this->templateJson, JSON_PRETTY_PRINT);
        $this->refreshWarnings();
    }

    private function resizeCanvas(): void
    {
        $this->widthMm = $this->clamp((float) $this->widthMm, 20, 300);
        $this->heightMm = $this->clamp((float) $this->heightMm, 20, 300);
        $this->syncTemplateFromText();
        $this->templateJson['widthMm'] = $this->widthMm;
        $this->templateJson['heightMm'] = $this->heightMm;

        foreach ($this->templateJson['elements'] as $index => $element) {
            $this->templateJson['elements'][$index]['x'] = $this->clamp((float) ($element['x'] ?? 0), 0, max(0, $this->widthMm - (float) ($element['width'] ?? 2)));
            $this->templateJson['elements'][$index]['y'] = $this->clamp((float) ($element['y'] ?? 0), 0, max(0, $this->heightMm - (float) ($element['height'] ?? 2)));
        }

        $this->ensureMandatoryBarcode();
        $this->syncTemplateText();
    }

    private function ensureMandatoryBarcode(): void
    {
        $this->templateJson['elements'] ??= [];
        $barcodes = collect($this->templateJson['elements'])
            ->filter(fn (array $element): bool => ($element['type'] ?? null) === 'barcode')
            ->values();

        $inventoryBarcode = $barcodes
            ->first(fn (array $element): bool => ($element['bindingKey'] ?? 'barcode.value') === 'barcode.value');
        if (! $inventoryBarcode) {
            $this->templateJson['elements'][] = $this->barcodeElement(
                5,
                max(3, $this->heightMm - 20),
                max(20, $this->widthMm - 10),
                min(16, max(10, $this->heightMm * 0.22)),
                count($this->templateJson['elements']) + 1
            );

            $barcodes = collect($this->templateJson['elements'])
                ->filter(fn (array $element): bool => ($element['type'] ?? null) === 'barcode')
                ->values();
        }

        $seenInventory = false;
        $seenCustomer = false;
        $this->templateJson['elements'] = collect($this->templateJson['elements'])
            ->filter(function (array $element) use (&$seenInventory, &$seenCustomer): bool {
                if (($element['type'] ?? null) !== 'barcode') {
                    return true;
                }
                $binding = $element['bindingKey'] ?? 'barcode.value';
                if ($binding === 'product.customer_barcode') {
                    if ($seenCustomer) {
                        return false;
                    }
                    $seenCustomer = true;

                    return true;
                }
                if ($seenInventory) {
                    return false;
                }
                $seenInventory = true;

                return true;
            })
            ->map(function (array $element): array {
                if (($element['type'] ?? null) === 'barcode') {
                    $isCustomer = ($element['bindingKey'] ?? 'barcode.value') === 'product.customer_barcode';
                    $element['key'] = $isCustomer
                        ? (blank($element['key'] ?? null) || ($element['key'] ?? null) === 'barcode'
                            ? 'customer_barcode'
                            : $element['key'])
                        : 'barcode';
                    $element['bindingKey'] = $isCustomer ? 'product.customer_barcode' : 'barcode.value';
                    $element['width'] = max(18, min((float) ($element['width'] ?? 45), $this->widthMm));
                    $element['height'] = max(8, min((float) ($element['height'] ?? 14), $this->heightMm));
                    $element['x'] = $this->clamp((float) ($element['x'] ?? 0), 0, max(0, $this->widthMm - (float) $element['width']));
                    $element['y'] = $this->clamp((float) ($element['y'] ?? 0), 0, max(0, $this->heightMm - (float) $element['height']));
                }

                return $element;
            })
            ->values()
            ->all();
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
            'gridMm' => 0.125,
            'precision203' => true,
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

    private function clamp(float $value, float $min, float $max): float
    {
        return min($max, max($min, $value));
    }

    private function fontFamilies(): array
    {
        return [
            'TVS Auto',
            'Arial',
            'Sans Serif',
            'Helvetica',
            'Serif',
            'Roman',
            'Typewriter',
            'Mono',
            'Condensed',
            'OCR-B',
            'TSPL Font 1',
            'TSPL Font 2',
            'TSPL Font 3',
            'TSPL Font 4',
            'TSPL 1 - 8x12',
            'TSPL 2 - 12x20',
            'TSPL 3 - 16x24',
            'TSPL 4 - 24x32',
            'TSPL 5 - 32x48',
            'TSPL TSS24.BF2',
            'TSPL TST24.BF2',
            'TSPL K',
            'TSPL OCR-A',
            'TSPL OCR-B',
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
                'label' => 'Small 75x50 - Essential 5 fields',
                'size' => '50x75',
                'widthMm' => 75,
                'heightMm' => 50,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 6, 1, '', '', 11, '800', 'center'),
                    $this->bindingElement('product_name', 'product.name', 4, 10, 43, 8, 2, '', '', 10, '700'),
                    $this->bindingElement('net_weight', 'weight.net', 49, 10, 22, 8, 3, 'Net: ', ' kg', 10, '800'),
                    $this->bindingElement('serial_number', 'serial.number', 4, 20, 67, 5, 4, 'Sr: ', '', 7, '500', 'center'),
                    $this->barcodeElement(10, 28, 55, 16, 5),
                ],
            ],
            'medium_75_5_fields' => [
                'label' => 'Medium 75x75 - 5 large fields + barcode',
                'size' => '75x75',
                'widthMm' => 75,
                'heightMm' => 75,
                'elements' => [
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 8, 1, '', '', 13, '800', 'center'),
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
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 7, 1, '', '', 12, '800', 'center'),
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
                    $this->bindingElement('company_name', 'company.name', 4, 3, 67, 7, 1, '', '', 11, '800', 'center'),
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
                    $this->bindingElement('company_name', 'company.name', 4, 4, 67, 8, 1, '', '', 12, '800', 'center'),
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
            '50x75' => '75 x 50 mm (horizontal)',
            '100x150' => '100 x 150 mm',
            'custom' => 'Custom size',
        ];
    }

    private function inferSize(float $widthMm, float $heightMm): string
    {
        return match (true) {
            abs($widthMm - 75) < 0.5 && abs($heightMm - 75) < 0.5 => '75x75',
            abs($widthMm - 100) < 0.5 && abs($heightMm - 100) < 0.5 => '100x100',
            abs($widthMm - 75) < 0.5 && abs($heightMm - 100) < 0.5 => '75x100',
            abs($widthMm - 75) < 0.5 && abs($heightMm - 50) < 0.5 => '50x75',
            abs($widthMm - 100) < 0.5 && abs($heightMm - 150) < 0.5 => '100x150',
            default => 'custom',
        };
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
            'multiline' => true,
            'locked' => false,
            'style' => [
                'fontSize' => $fontSize,
                'prefixFontSize' => $fontSize,
                'suffixFontSize' => $fontSize,
                'fontFamily' => 'TVS Auto',
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
            'multiline' => true,
            'locked' => false,
            'style' => [
                'fontSize' => $fontSize,
                'prefixFontSize' => $fontSize,
                'suffixFontSize' => $fontSize,
                'fontFamily' => 'TVS Auto',
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
            'locked' => false,
        ];
    }

    private function previewProducts(string $tenantId): array
    {
        if ($tenantId === '') {
            return [];
        }

        $tenant = Auth::user()?->tenant;
        $companyName = trim((string) ($tenant?->name ?: 'Company name'));
        $definitions = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();
        $products = Product::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->with(['variants' => fn ($query) => $query->where('is_active', true)->orderBy('name')])
            ->orderBy('name')
            ->limit(500)
            ->get();
        $date = now()->format('d/m/Y');
        $time = now()->format('H:i');

        $items = $products->map(function (Product $product) use ($companyName, $definitions, $date, $time): array {
            $variant = $product->variants->first();
            $metadata = collect($product->metadata ?? []);
            $customFields = collect($metadata->get('custom_fields', []));
            $tare = (float) ($product->default_tare_weight ?? 0);
            $net = (float) ($product->maximum_weight ?? $product->target_weight ?? 29.700);
            $values = [
                'company.name' => $companyName,
                'product.name' => $product->name,
                'product.code' => $product->product_code ?: 'PRD-001',
                'variant.name' => $variant?->name ?: '-',
                'variant.code' => $variant?->variant_code ?: '-',
                'weight.gross' => number_format($net + $tare, 3, '.', ''),
                'weight.tare' => number_format($tare, 3, '.', ''),
                'weight.net' => number_format($net, 3, '.', ''),
                'pieces.quantity' => '10',
                'batch.number' => 'BATCH-001',
                'serial.number' => 'DEMO-'.strtoupper(substr((string) $product->id, 0, 8)),
                'barcode.value' => $product->product_code ?: 'PHK123456',
                'product.customer_barcode' => $product->customer_barcode_enabled
                    ? (string) $product->customer_barcode_value
                    : '',
                'date.current' => $date,
                'time.current' => $time,
                'operator.name' => Auth::user()?->name ?: 'Operator',
            ];

            foreach ($definitions as $definition) {
                $key = 'dynamic.'.$definition->entity_type.'.'.$definition->internal_key;
                $value = $metadata->get($definition->internal_key)
                    ?? $customFields->get($definition->internal_key)
                    ?? collect($definition->dropdown_options ?? [])
                        ->map(fn ($option) => is_array($option)
                            ? ($option['label'] ?? $option['value'] ?? '')
                            : $option)
                        ->filter()
                        ->first()
                    ?? 'Value';
                $values[$key] = is_scalar($value) ? (string) $value : 'Value';
            }

            return [
                'id' => $product->id,
                'label' => $product->name.($product->product_code ? ' ('.$product->product_code.')' : ''),
                'values' => $values,
            ];
        })->values();

        $longestValues = [];
        foreach ($items as $item) {
            foreach ($item['values'] as $key => $value) {
                if (mb_strlen((string) $value) > mb_strlen((string) ($longestValues[$key] ?? ''))) {
                    $longestValues[$key] = (string) $value;
                }
            }
        }
        foreach ($definitions as $definition) {
            $key = 'dynamic.'.$definition->entity_type.'.'.$definition->internal_key;
            $longestOption = collect($definition->dropdown_options ?? [])
                ->map(fn ($option) => is_array($option)
                    ? ($option['label'] ?? $option['value'] ?? '')
                    : $option)
                ->filter()
                ->sortByDesc(fn ($value) => mb_strlen((string) $value))
                ->first();
            if ($longestOption && mb_strlen((string) $longestOption) > mb_strlen((string) ($longestValues[$key] ?? ''))) {
                $longestValues[$key] = (string) $longestOption;
            }
        }

        $fallback = [
            'company.name' => $companyName,
            'product.name' => 'Longest product name',
            'product.code' => 'PRODUCT-CODE',
            'variant.name' => 'Product detail',
            'variant.code' => 'VARIANT-CODE',
            'weight.gross' => '30.500',
            'weight.tare' => '0.800',
            'weight.net' => '29.700',
            'pieces.quantity' => '10',
            'batch.number' => 'BATCH-001',
            'serial.number' => 'DEMO-12345678',
            'barcode.value' => 'PHK123456',
            'product.customer_barcode' => 'CUSTOMER123',
            'date.current' => $date,
            'time.current' => $time,
            'operator.name' => Auth::user()?->name ?: 'Operator',
        ];

        return collect([[
            'id' => '__longest__',
            'label' => 'Longest values (all products)',
            'values' => array_replace($fallback, $longestValues),
        ]])->merge($items)->all();
    }
}
