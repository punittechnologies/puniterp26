<?php

namespace App\Http\Controllers\Web\Concerns;

use App\Models\InventoryTransaction;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductConfiguration\Unit;
use App\Support\ProductCustomerBarcode;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use ZipArchive;

trait AdminDataExchange
{
    public function imports(): View
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        $tenantId = $this->tenantId();

        return view('admin.imports.index', [
            'title' => 'Import Centre',
            'products' => Product::query()
                ->where('tenant_id', $tenantId)
                ->latest()
                ->limit(8)
                ->get(),
            'productFields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $tenantId)
                ->where('entity_type', 'product_variant')
                ->orderBy('sort_order')
                ->orderBy('field_label')
                ->get(),
            'productPreview' => session($this->importPreviewKey('products')),
            'detailPreview' => session($this->importPreviewKey('product-details')),
            'customerBarcodeTypes' => ProductCustomerBarcode::TYPES,
        ]);
    }

    public function importTemplate(string $type)
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        abort_unless(in_array($type, ['products', 'product-details'], true), 404);

        $fields = DynamicFieldDefinition::query()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->pluck('field_label')
            ->all();

        $rows = $type === 'products'
            ? [
                ['Product Name', 'Product Code', 'Tare Weight', 'Minimum Weight (kg)', 'Maximum Weight (kg)', 'Unit', 'Customer Barcode Enabled', 'Customer Barcode Type', 'Customer Barcode', 'Customer Barcode Caption'],
                ['Printer', 'PRINTER-001', '0.000', '1.000', '25.000', 'kg', 'Yes', 'code128', 'CUSTOMER-PRINTER-001', 'CUSTOMER SKU'],
                ['Scanner', 'SCANNER-001', '0.200', '', '', 'kg', 'No', '', '', ''],
            ]
            : [
                $headers = $fields ?: ['Color', 'Size'],
                array_map(
                    fn (string $field) => match (strtolower($field)) {
                        'color' => 'White',
                        'size' => '10 kg',
                        default => 'Example value',
                    },
                    $headers,
                ),
            ];

        return response($this->xlsxWorkbook($type.' template', $rows), 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="'.$type.'-template.xlsx"',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function exportProducts()
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        $rows = Product::query()
            ->where('tenant_id', $this->tenantId())
            ->with('defaultWeightUnit')
            ->orderBy('name')
            ->get()
            ->map(fn (Product $product) => [
                $product->name,
                $product->product_code ?? '',
                number_format((float) ($product->default_tare_weight ?? 0), 3, '.', ''),
                filled($product->getRawOriginal('minimum_weight'))
                    ? number_format((float) $product->minimum_weight, 3, '.', '')
                    : '',
                filled($product->getRawOriginal('maximum_weight'))
                    ? number_format((float) $product->maximum_weight, 3, '.', '')
                    : '',
                $product->defaultWeightUnit?->symbol ?: 'kg',
                $product->customer_barcode_enabled ? 'Yes' : 'No',
                $product->customer_barcode_type ?? '',
                $product->customer_barcode_value ?? '',
                $product->customer_barcode_caption ?? '',
            ])
            ->all();

        return response($this->xlsxWorkbook('Products', [
            ['Product Name', 'Product Code', 'Tare Weight', 'Minimum Weight (kg)', 'Maximum Weight (kg)', 'Unit', 'Customer Barcode Enabled', 'Customer Barcode Type', 'Customer Barcode', 'Customer Barcode Caption'],
            ...$rows,
        ]), 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="products-export-'.now()->format('Ymd').'.xlsx"',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function importProducts(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        $previewKey = $this->importPreviewKey('products');

        if ($request->boolean('confirm')) {
            $preview = session()->pull($previewKey);
            if (! is_array($preview) || ($preview['type'] ?? null) !== 'products') {
                return back()->withErrors(['file' => 'The product preview expired. Upload the spreadsheet again.']);
            }
            if (($preview['errors'] ?? []) !== []) {
                session()->put($previewKey, $preview);

                return back()->withErrors(['file' => 'Resolve the preview errors before importing.']);
            }

            $tenantId = $this->tenantId();
            $result = DB::transaction(function () use ($preview, $tenantId): array {
                $created = 0;
                $skipped = count($preview['skipped'] ?? []);
                foreach ($preview['records'] as $record) {
                    $alreadyExists = Product::withTrashed()
                        ->where('tenant_id', $tenantId)
                        ->where(fn ($query) => $query
                            ->whereRaw('lower(name) = ?', [mb_strtolower($record['name'])])
                            ->orWhereRaw('lower(product_code) = ?', [mb_strtolower($record['product_code'])]))
                        ->exists();
                    if ($alreadyExists) {
                        $skipped++;

                        continue;
                    }

                    $unit = Unit::query()
                        ->where('symbol', $record['unit'])
                        ->where('category', 'weight')
                        ->where(fn ($query) => $query
                            ->whereNull('tenant_id')
                            ->orWhere('tenant_id', $tenantId))
                        ->first();
                    $unit ??= Unit::query()->create([
                        'tenant_id' => null,
                        'name' => strtoupper($record['unit']),
                        'symbol' => $record['unit'],
                        'category' => 'weight',
                        'conversion_factor_to_base' => 1,
                        'decimal_precision' => 3,
                        'is_system' => true,
                        'is_active' => true,
                    ]);

                    Product::query()->create([
                        'tenant_id' => $tenantId,
                        'name' => $record['name'],
                        'product_code' => $record['product_code'],
                        'default_tare_weight' => $record['tare_weight'],
                        'minimum_weight' => $record['minimum_weight'],
                        'maximum_weight' => $record['maximum_weight'],
                        'default_weight_unit_id' => $unit->id,
                        'customer_barcode_enabled' => $record['customer_barcode_enabled'],
                        'customer_barcode_type' => $record['customer_barcode_type'],
                        'customer_barcode_value' => $record['customer_barcode_value'],
                        'customer_barcode_caption' => $record['customer_barcode_caption'],
                        'is_active' => true,
                        'weight_decimal_precision' => 3,
                        'manual_print_enabled' => true,
                        'duplicate_print_prevention_enabled' => true,
                        'product_selection_mode' => 'operator_can_select',
                        'configuration_activated_at' => now(),
                        'created_by' => Auth::id(),
                        'updated_by' => Auth::id(),
                    ]);
                    $created++;
                }

                return compact('created', 'skipped');
            });

            $this->audit('products.imported', Auth::user(), [], $result);

            return redirect()->route('admin.imports')->with(
                'status',
                "Product import completed. Created {$result['created']} new products; skipped {$result['skipped']} existing or duplicate rows.",
            );
        }

        $data = $request->validate([
            'file' => ['required', 'file', 'max:5120', 'extensions:csv,txt,xlsx'],
        ]);
        [$headers, $rows] = $this->importRowsFromFile($data['file']);
        $preview = $this->buildProductPreview($headers, $rows);
        session()->put($previewKey, $preview);

        $status = match (true) {
            $preview['errors'] !== [] => 'Product spreadsheet checked. Fix the listed new-product rows and upload it again.',
            $preview['records'] === [] => 'No new products found. Existing or duplicate rows were skipped safely.',
            default => 'Product spreadsheet validated. Review the new products and confirm the import.',
        };

        return redirect()->route('admin.imports')->with('status', $status);
    }

    public function importProductDetails(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        $previewKey = $this->importPreviewKey('product-details');

        if ($request->boolean('confirm')) {
            $preview = session()->pull($previewKey);
            if (! is_array($preview) || ($preview['type'] ?? null) !== 'product-details') {
                return back()->withErrors(['file' => 'The product-detail preview expired. Upload the spreadsheet again.']);
            }
            if (($preview['errors'] ?? []) !== []) {
                session()->put($previewKey, $preview);

                return back()->withErrors(['file' => 'Resolve the preview errors before importing.']);
            }

            $tenantId = $this->tenantId();
            $result = DB::transaction(function () use ($preview, $tenantId): array {
                $createdFields = 0;
                $addedOptions = 0;
                foreach ($preview['fields'] as $fieldData) {
                    $field = DynamicFieldDefinition::withTrashed()
                        ->where('tenant_id', $tenantId)
                        ->where('entity_type', 'product_variant')
                        ->where('internal_key', $fieldData['key'])
                        ->first();
                    if (! $field) {
                        $field = new DynamicFieldDefinition([
                            'tenant_id' => $tenantId,
                            'entity_type' => 'product_variant',
                            'internal_key' => $fieldData['key'],
                            'created_by' => Auth::id(),
                        ]);
                        $createdFields++;
                    } elseif ($field->trashed()) {
                        $field->restore();
                    }

                    $existing = collect($field->dropdown_options ?? [])
                        ->map(fn ($option) => $this->normaliseDropdownOption($option))
                        ->filter();
                    $incoming = collect($fieldData['options'])
                        ->map(fn ($option) => $this->normaliseDropdownOption($option))
                        ->filter();
                    $merged = $existing
                        ->merge($incoming)
                        ->unique(fn (array $option) => $option['value'])
                        ->values();
                    $addedOptions += max(0, $merged->count() - $existing->count());

                    $field->forceFill([
                        'field_label' => $fieldData['label'],
                        'data_type' => 'dropdown',
                        'dropdown_options' => $merged->all(),
                        'visible_in_web' => true,
                        'visible_in_flutter' => true,
                        'editable_in_flutter' => true,
                        'printable_on_label' => $field->exists ? ($field->printable_on_label ?? true) : true,
                        'visible_in_reports' => true,
                        'searchable' => true,
                        'filterable' => true,
                        'is_active' => true,
                        'updated_by' => Auth::id(),
                    ])->save();
                }

                return compact('createdFields', 'addedOptions');
            });

            $this->audit('product_details.imported', Auth::user(), [], $result);

            return redirect()->route('admin.imports')->with(
                'status',
                "Product-detail import completed. Created {$result['createdFields']} fields and added {$result['addedOptions']} values.",
            );
        }

        $data = $request->validate([
            'file' => ['required', 'file', 'max:5120', 'extensions:csv,txt,xlsx'],
        ]);
        [$headers, $rows] = $this->importRowsFromFile($data['file']);
        $preview = $this->buildProductDetailPreview($headers, $rows);
        session()->put($previewKey, $preview);

        return redirect()->route('admin.imports')->with(
            'status',
            $preview['errors'] === []
                ? 'Product-detail spreadsheet validated. Review the preview and confirm the import.'
                : 'Product-detail spreadsheet checked. Fix the listed columns and upload it again.',
        );
    }

    public function clearImportPreview(string $type): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('products.view'), 403);
        abort_unless(in_array($type, ['products', 'product-details'], true), 404);
        session()->forget($this->importPreviewKey($type));

        return redirect()->route('admin.imports')->with('status', 'Import preview cleared.');
    }

    public function exportCenter(Request $request): View
    {
        abort_unless(Auth::user()?->hasPermission('reports.view'), 403);

        return view('admin.exports.index', [
            'title' => 'Export Centre',
            'filters' => [
                'report' => $request->string('report', 'inward')->toString(),
                'format' => $request->string('format', 'pdf')->toString(),
                'from' => $request->string('from', now()->subDays(29)->toDateString())->toString(),
                'to' => $request->string('to', now()->toDateString())->toString(),
            ],
        ]);
    }

    public function closingStockExport(Request $request)
    {
        abort_unless(
            Auth::user()?->hasPermission('inventory.view') || Auth::user()?->hasPermission('reports.view'),
            403,
        );
        $tenantId = $this->tenantId();
        $data = $request->validate([
            'stock_date' => ['required', 'date'],
            'format' => ['required', Rule::in(['xlsx', 'pdf'])],
            'product_id' => ['nullable', Rule::exists('products', 'id')->where('tenant_id', $tenantId)],
            'variant_id' => ['nullable', Rule::exists('product_variants', 'id')->where('tenant_id', $tenantId)],
        ]);
        $asOf = CarbonImmutable::parse($data['stock_date'])->endOfDay();
        $rows = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('occurred_at', '<=', $asOf)
            ->when($data['product_id'] ?? null, fn ($query, $id) => $query->where('product_id', $id))
            ->when($data['variant_id'] ?? null, fn ($query, $id) => $query->where('variant_id', $id))
            ->select('product_id', 'variant_id')
            ->selectRaw($this->inventoryWeightExpression().' as weight')
            ->selectRaw($this->inventoryPieceExpression().' as pieces')
            ->selectRaw('max(occurred_at) as last_movement')
            ->groupBy('product_id', 'variant_id')
            ->orderByDesc('weight')
            ->get();
        $productNames = Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id');
        $variantNames = ProductVariant::query()->where('tenant_id', $tenantId)->pluck('name', 'id');
        $detailRows = $rows->map(fn ($row) => [
            'product' => $productNames[$row->product_id] ?? $row->product_id,
            'product_detail' => $variantNames[$row->variant_id] ?? 'All details',
            'weight' => (float) $row->weight,
            'pieces' => (float) $row->pieces,
            'last_movement' => $row->last_movement,
        ]);
        $summaryRows = $detailRows
            ->groupBy('product')
            ->map(fn ($productRows, string $product) => [
                'product' => $product,
                'rows' => $productRows->count(),
                'weight' => $productRows->sum('weight'),
                'pieces' => $productRows->sum('pieces'),
            ])
            ->sortByDesc('weight')
            ->values();
        $baseName = 'closing-stock-'.$asOf->format('Ymd');

        if ($data['format'] === 'pdf') {
            $pdfRows = collect([
                ['product' => 'Closing stock as of', 'product_detail' => $asOf->format('Y-m-d H:i'), 'weight' => '', 'pieces' => '', 'last_movement' => ''],
                ['product' => 'Total', 'product_detail' => '', 'weight' => number_format($detailRows->sum('weight'), 3), 'pieces' => number_format($detailRows->sum('pieces'), 0), 'last_movement' => ''],
                ...$detailRows->map(fn ($row) => [
                    'product' => $row['product'],
                    'product_detail' => $row['product_detail'],
                    'weight' => number_format($row['weight'], 3),
                    'pieces' => number_format($row['pieces'], 0),
                    'last_movement' => $row['last_movement'],
                ])->all(),
            ]);

            return response($this->basicPdf(
                'Closing Stock',
                ['product', 'product_detail', 'weight', 'pieces', 'last_movement'],
                $pdfRows,
            ), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$baseName.'.pdf"',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        }

        return response($this->xlsxWorkbook('Closing Stock', [
            ['Closing Stock Report'],
            ['As of', $asOf->format('Y-m-d H:i')],
            ['Generated at', now()->format('Y-m-d H:i')],
            [],
            ['Stock Details'],
            ['Product', 'Product Detail', 'Weight kg', 'PCS', 'Last Movement'],
            ...$detailRows->map(fn ($row) => [
                $row['product'],
                $row['product_detail'],
                number_format($row['weight'], 3, '.', ''),
                number_format($row['pieces'], 0, '.', ''),
                $row['last_movement'],
            ])->all(),
            [],
            ['Totals'],
            ['Total Weight kg', number_format($detailRows->sum('weight'), 3, '.', '')],
            ['Total PCS', number_format($detailRows->sum('pieces'), 0, '.', '')],
            [],
            ['Product-wise Summary'],
            ['Product', 'Rows', 'Weight kg', 'PCS'],
            ...$summaryRows->map(fn ($row) => [
                $row['product'],
                (string) $row['rows'],
                number_format($row['weight'], 3, '.', ''),
                number_format($row['pieces'], 0, '.', ''),
            ])->all(),
        ]), 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="'.$baseName.'.xlsx"',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    private function buildProductPreview(array $headers, array $rows): array
    {
        $tenantId = $this->tenantId();
        $normalised = array_map(fn ($value) => $this->normaliseImportHeader($value), $headers);
        $required = ['productname'];
        $errors = [];
        foreach ($required as $header) {
            if (! in_array($header, $normalised, true)) {
                $errors[] = 'Missing required column: '.match ($header) {
                    'productname' => 'Product Name',
                    default => $header,
                };
            }
        }
        if ($errors !== []) {
            return ['type' => 'products', 'records' => [], 'skipped' => [], 'errors' => $errors];
        }
        if (count($rows) > 2000) {
            return ['type' => 'products', 'records' => [], 'skipped' => [], 'errors' => ['A maximum of 2,000 data rows is allowed per import.']];
        }

        $existingNames = Product::withTrashed()
            ->where('tenant_id', $tenantId)
            ->pluck('name')
            ->map(fn ($name) => mb_strtolower(trim((string) $name)))
            ->flip();
        $existingCodes = Product::withTrashed()
            ->where('tenant_id', $tenantId)
            ->whereNotNull('product_code')
            ->pluck('product_code')
            ->map(fn ($code) => mb_strtolower(trim((string) $code)))
            ->flip();
        $seenNames = [];
        $seenCodes = [];
        $records = [];
        $skipped = [];

        foreach ($rows as $offset => $row) {
            $line = $offset + 2;
            $row = array_slice(array_pad($row, count($normalised), null), 0, count($normalised));
            $record = array_combine($normalised, $row);
            if (! is_array($record) || collect($record)->filter(fn ($value) => trim((string) $value) !== '')->isEmpty()) {
                continue;
            }
            $name = trim((string) ($record['productname'] ?? ''));
            $code = strtoupper(trim((string) ($record['productcode'] ?? '')));
            $tare = trim((string) ($record['tareweight'] ?? '0'));
            $minimumWeight = trim((string) ($record['minimumweightkg'] ?? $record['minimumweight'] ?? ''));
            $maximumWeight = trim((string) ($record['maximumweightkg'] ?? $record['maximumweight'] ?? ''));
            $unit = strtolower(trim((string) ($record['unit'] ?? 'kg')));
            $customerBarcodeEnabledRaw = strtolower(trim((string) ($record['customerbarcodeenabled'] ?? '')));
            $customerBarcodeValue = trim((string) ($record['customerbarcode'] ?? ''));
            $customerBarcodeEnabled = in_array($customerBarcodeEnabledRaw, ['1', 'yes', 'y', 'true', 'enabled'], true)
                || ($customerBarcodeEnabledRaw === '' && $customerBarcodeValue !== '');
            $customerBarcodeTypeRaw = strtolower(trim((string) ($record['customerbarcodetype'] ?? 'code128')));
            $customerBarcodeType = collect(ProductCustomerBarcode::TYPES)
                ->search(fn (string $label, string $key): bool => in_array(
                    $customerBarcodeTypeRaw,
                    [strtolower($key), strtolower($label)],
                    true,
                ));
            $customerBarcodeType = is_string($customerBarcodeType)
                ? $customerBarcodeType
                : $customerBarcodeTypeRaw;
            $customerBarcodeCaption = trim((string) ($record['customerbarcodecaption'] ?? ''));
            $tare = $tare === '' ? '0' : $tare;
            $unit = $unit === '' ? 'kg' : $unit;
            $rowErrors = [];

            if ($name === '') {
                $rowErrors[] = 'Product Name is required';
            }
            if ($rowErrors !== []) {
                $errors[] = 'Row '.$line.': '.implode('; ', $rowErrors);

                continue;
            }

            $normalisedName = mb_strtolower($name);
            $normalisedCode = mb_strtolower($code);
            $skipReasons = [];
            if (isset($existingNames[$normalisedName])) {
                $skipReasons[] = 'product name already exists';
            }
            if ($code !== '' && isset($existingCodes[$normalisedCode])) {
                $skipReasons[] = 'product code already exists';
            }
            if (isset($seenNames[$normalisedName])) {
                $skipReasons[] = 'duplicate product name in this spreadsheet';
            }
            if ($code !== '' && isset($seenCodes[$normalisedCode])) {
                $skipReasons[] = 'duplicate product code in this spreadsheet';
            }
            if ($skipReasons !== []) {
                $skipped[] = [
                    'line' => $line,
                    'name' => $name,
                    'product_code' => $code,
                    'reason' => implode('; ', array_unique($skipReasons)),
                ];

                continue;
            }

            if (! is_numeric($tare) || (float) $tare < 0) {
                $rowErrors[] = 'Tare Weight must be zero or a positive number';
            }
            if (($minimumWeight === '') !== ($maximumWeight === '')) {
                $rowErrors[] = 'Minimum Weight and Maximum Weight must both be provided';
            } elseif ($minimumWeight !== '' && $maximumWeight !== '') {
                if (! is_numeric($minimumWeight) || (float) $minimumWeight < 0) {
                    $rowErrors[] = 'Minimum Weight must be zero or a positive number';
                }
                if (! is_numeric($maximumWeight) || (float) $maximumWeight < 0) {
                    $rowErrors[] = 'Maximum Weight must be zero or a positive number';
                }
                if (
                    is_numeric($minimumWeight)
                    && is_numeric($maximumWeight)
                    && (float) $maximumWeight < (float) $minimumWeight
                ) {
                    $rowErrors[] = 'Maximum Weight must be greater than or equal to Minimum Weight';
                }
            }
            if (! preg_match('/^[a-z0-9._-]{1,20}$/i', $unit)) {
                $rowErrors[] = 'Unit is invalid';
            }
            if ($customerBarcodeEnabled) {
                $message = ProductCustomerBarcode::validationMessage($customerBarcodeType, $customerBarcodeValue);
                if ($message) {
                    $rowErrors[] = $message;
                }
            }

            if ($rowErrors !== []) {
                $errors[] = 'Row '.$line.': '.implode('; ', $rowErrors);

                continue;
            }

            $code = $code !== '' ? $code : 'PRD-'.strtoupper(str()->random(8));
            $records[] = [
                'name' => $name,
                'product_code' => $code,
                'tare_weight' => round((float) $tare, 6),
                'minimum_weight' => $minimumWeight !== '' ? round((float) $minimumWeight, 6) : null,
                'maximum_weight' => $maximumWeight !== '' ? round((float) $maximumWeight, 6) : null,
                'unit' => $unit,
                'customer_barcode_enabled' => $customerBarcodeEnabled,
                'customer_barcode_type' => $customerBarcodeEnabled ? $customerBarcodeType : null,
                'customer_barcode_value' => $customerBarcodeEnabled ? $customerBarcodeValue : null,
                'customer_barcode_caption' => $customerBarcodeEnabled
                    ? ($customerBarcodeCaption !== '' ? $customerBarcodeCaption : 'CUSTOMER SKU')
                    : null,
            ];
            $seenNames[$normalisedName] = true;
            $seenCodes[mb_strtolower($code)] = true;
        }

        if ($records === [] && $skipped === [] && $errors === []) {
            $errors[] = 'The spreadsheet contains no product rows.';
        }

        return ['type' => 'products', 'records' => $records, 'skipped' => $skipped, 'errors' => $errors];
    }

    private function buildProductDetailPreview(array $headers, array $rows): array
    {
        $errors = [];
        $fields = [];
        $seenKeys = [];

        if ($headers === []) {
            return ['type' => 'product-details', 'fields' => [], 'errors' => ['The spreadsheet has no header row.']];
        }
        if (count($rows) > 5000) {
            return ['type' => 'product-details', 'fields' => [], 'errors' => ['A maximum of 5,000 data rows is allowed per import.']];
        }

        foreach ($headers as $index => $header) {
            $label = trim((string) $header);
            $key = str($label)->slug('_')->toString();
            if ($label === '' || $key === '') {
                $errors[] = 'Column '.($index + 1).' has no valid field name.';

                continue;
            }
            if (isset($seenKeys[$key])) {
                $errors[] = "Duplicate product-detail column: {$label}.";

                continue;
            }
            $options = collect($rows)
                ->map(fn (array $row) => trim((string) ($row[$index] ?? '')))
                ->filter()
                ->unique(fn (string $value) => mb_strtolower($value))
                ->values()
                ->all();
            if ($options === []) {
                $errors[] = "Column {$label} contains no values.";

                continue;
            }
            $fields[] = compact('label', 'key', 'options');
            $seenKeys[$key] = true;
        }

        return ['type' => 'product-details', 'fields' => $fields, 'errors' => $errors];
    }

    private function importPreviewKey(string $type): string
    {
        return 'admin-import-preview.'.$this->tenantId().'.'.Auth::id().'.'.$type;
    }

    private function importRowsFromFile($file): array
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: $file->extension() ?: '');

        return $extension === 'xlsx'
            ? $this->xlsxRows($file->getRealPath())
            : $this->csvRows($file->getRealPath());
    }

    private function csvRows(string $path): array
    {
        $handle = fopen($path, 'r');
        if ($handle === false) {
            return [[], []];
        }
        $headers = fgetcsv($handle) ?: [];
        $rows = [];
        while (($row = fgetcsv($handle)) !== false) {
            if (collect($row)->filter(fn ($value) => trim((string) $value) !== '')->isNotEmpty()) {
                $rows[] = $row;
            }
        }
        fclose($handle);

        return [$headers, $rows];
    }

    private function xlsxRows(string $path): array
    {
        $zip = new ZipArchive;
        if ($zip->open($path) !== true) {
            return [[], []];
        }

        $sharedStrings = [];
        $sharedXml = $zip->getFromName('xl/sharedStrings.xml');
        if ($sharedXml !== false) {
            $shared = simplexml_load_string($sharedXml, 'SimpleXMLElement', LIBXML_NONET | LIBXML_COMPACT);
            $shared?->registerXPathNamespace('main', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main');
            foreach ($shared?->si ?? [] as $si) {
                $si->registerXPathNamespace('main', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main');
                $parts = [];
                foreach ($si->xpath('.//main:t') ?: [] as $textNode) {
                    $parts[] = (string) $textNode;
                }
                $sharedStrings[] = $parts ? implode('', $parts) : (string) ($si->t ?? '');
            }
        }

        $sheetXml = $zip->getFromName('xl/worksheets/sheet1.xml') ?: $this->firstWorksheetXml($zip);
        $zip->close();
        if (! $sheetXml) {
            return [[], []];
        }

        $sheet = simplexml_load_string($sheetXml, 'SimpleXMLElement', LIBXML_NONET | LIBXML_COMPACT);
        if (! $sheet) {
            return [[], []];
        }
        $sheet->registerXPathNamespace('main', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main');
        $rows = [];
        foreach ($sheet->xpath('//main:sheetData/main:row') ?: [] as $rowNode) {
            $rowNode->registerXPathNamespace('main', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main');
            $row = [];
            foreach ($rowNode->xpath('./main:c') ?: [] as $cell) {
                $cell->registerXPathNamespace('main', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main');
                $ref = (string) ($cell['r'] ?? '');
                $index = $this->xlsxColumnIndex((string) preg_replace('/\d+/', '', $ref));
                $type = (string) ($cell['t'] ?? '');
                $valueNodes = $cell->xpath('./main:v') ?: [];
                $value = isset($valueNodes[0]) ? (string) $valueNodes[0] : '';
                if ($type === 's') {
                    $value = $sharedStrings[(int) $value] ?? '';
                } elseif ($type === 'inlineStr') {
                    $textNodes = $cell->xpath('.//main:t') ?: [];
                    $value = implode('', array_map(fn ($node) => (string) $node, $textNodes));
                }
                $row[$index] = $value;
            }
            if ($row !== []) {
                ksort($row);
                $rows[] = array_values(array_replace(
                    array_fill(0, max(array_keys($row)) + 1, ''),
                    $row,
                ));
            }
        }

        return [array_shift($rows) ?: [], $rows];
    }

    private function firstWorksheetXml(ZipArchive $zip): string|false
    {
        for ($index = 0; $index < $zip->numFiles; $index++) {
            $name = $zip->getNameIndex($index);
            if (is_string($name) && str_starts_with($name, 'xl/worksheets/') && str_ends_with($name, '.xml')) {
                return $zip->getFromName($name);
            }
        }

        return false;
    }

    private function xlsxColumnIndex(string $letters): int
    {
        $letters = strtoupper($letters ?: 'A');
        $index = 0;
        foreach (str_split($letters) as $letter) {
            $index = ($index * 26) + (ord($letter) - 64);
        }

        return max($index - 1, 0);
    }

    private function normaliseImportHeader($value): string
    {
        return preg_replace('/[^a-z0-9]+/', '', strtolower(trim((string) $value))) ?? '';
    }

    private function normaliseDropdownOption(mixed $option): ?array
    {
        $label = is_array($option)
            ? trim((string) ($option['label'] ?? $option['value'] ?? ''))
            : trim((string) $option);
        if ($label === '') {
            return null;
        }
        $value = is_array($option) ? trim((string) ($option['value'] ?? '')) : '';

        return [
            'label' => $label,
            'value' => $value !== '' ? $value : str($label)->slug('_')->toString(),
        ];
    }
}
