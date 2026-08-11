<?php

namespace App\Http\Controllers\Web\Concerns;

use App\Models\InventoryTransaction;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductConfiguration\Unit;
use App\Models\ProductionTransaction;
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
        $data = [
            ...$this->operationalReportFilters($request, $tenantId),
            ...$request->validate([
                'stock_date' => ['required', 'date'],
                'format' => ['required', Rule::in(['xlsx', 'pdf'])],
            ]),
        ];
        $asOf = CarbonImmutable::parse($data['stock_date'])->endOfDay();
        $query = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('occurred_at', '<=', $asOf);
        $this->applyInventoryFilters($query, $data, $tenantId);
        $rows = $query
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

    public function currentStockExport(Request $request)
    {
        abort_unless(
            Auth::user()?->hasPermission('inventory.view') || Auth::user()?->hasPermission('reports.view'),
            403,
        );
        $tenantId = $this->tenantId();
        $data = [
            ...$this->operationalReportFilters($request, $tenantId),
            ...$request->validate([
                'stock_date' => ['required', 'date'],
                'format' => ['required', Rule::in(['xlsx', 'pdf'])],
            ]),
        ];
        $asOf = CarbonImmutable::parse($data['stock_date'])->endOfDay();
        $query = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('occurred_at', '<=', $asOf);

        // Apply identity/detail filters to the movements, then calculate the balance.
        // Movement type and raw movement quantities must not filter the balance itself.
        $balanceFilters = [
            ...$data,
            'transaction_type' => '',
            'weight_min' => '',
            'weight_max' => '',
            'pieces_min' => '',
            'pieces_max' => '',
        ];
        $this->applyInventoryFilters($query, $balanceFilters, $tenantId);
        $query
            ->when($data['serial'], fn ($query, $serial) => $query->where('label_serial_number', 'like', '%'.$serial.'%'))
            ->when($data['barcode'], fn ($query, $barcode) => $query->where('barcode_value', 'like', '%'.$barcode.'%'));

        $weightExpression = $this->inventoryWeightExpression();
        $pieceExpression = $this->inventoryPieceExpression();
        $query
            ->select('product_id', 'variant_id', 'label_serial_number', 'barcode_value')
            ->selectRaw($weightExpression.' as weight')
            ->selectRaw($pieceExpression.' as pieces')
            ->selectRaw('max(occurred_at) as last_movement')
            ->groupBy('product_id', 'variant_id', 'label_serial_number', 'barcode_value')
            ->havingRaw('('.$weightExpression.') > 0.000001 OR ('.$pieceExpression.') > 0.000001')
            ->when($data['weight_min'] !== '', fn ($query) => $query->havingRaw('('.$weightExpression.') >= ?', [(float) $data['weight_min']]))
            ->when($data['weight_max'] !== '', fn ($query) => $query->havingRaw('('.$weightExpression.') <= ?', [(float) $data['weight_max']]))
            ->when($data['pieces_min'] !== '', fn ($query) => $query->havingRaw('('.$pieceExpression.') >= ?', [(float) $data['pieces_min']]))
            ->when($data['pieces_max'] !== '', fn ($query) => $query->havingRaw('('.$pieceExpression.') <= ?', [(float) $data['pieces_max']]))
            ->orderBy('product_id')
            ->orderBy('variant_id')
            ->orderBy('label_serial_number');

        $balances = $query->get();
        $productNames = Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id');
        $variants = ProductVariant::query()
            ->where('tenant_id', $tenantId)
            ->get(['id', 'name', 'metadata'])
            ->keyBy('id');
        $productions = $balances->isEmpty()
            ? collect()
            : ProductionTransaction::query()
                ->where('tenant_id', $tenantId)
                ->where('captured_at', '<=', $asOf)
                ->where(function ($query) use ($balances): void {
                    $barcodes = $balances->pluck('barcode_value')->filter()->unique()->values();
                    $serials = $balances->pluck('label_serial_number')->filter()->unique()->values();
                    $query->when($barcodes->isNotEmpty(), fn ($query) => $query->whereIn('barcode_value', $barcodes))
                        ->when($serials->isNotEmpty(), fn ($query) => $query->orWhereIn('label_serial_number', $serials));
                })
                ->latest('captured_at')
                ->get(['product_id', 'variant_id', 'label_serial_number', 'barcode_value', 'dynamic_values', 'captured_at']);
        $productionByBarcode = $productions->filter->barcode_value->unique('barcode_value')->keyBy('barcode_value');
        $productionBySerial = $productions->filter->label_serial_number->unique('label_serial_number')->keyBy('label_serial_number');
        $dynamicColumns = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('entity_type', 'product_variant')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->pluck('field_label', 'internal_key');

        $rows = $balances->map(function ($balance) use ($productNames, $variants, $productionByBarcode, $productionBySerial, $dynamicColumns): array {
            $variant = $variants->get($balance->variant_id);
            $production = $productionByBarcode->get($balance->barcode_value)
                ?? $productionBySerial->get($balance->label_serial_number);
            $dynamicValues = collect($variant?->metadata['dynamic_fields'] ?? [])
                ->merge($production?->dynamic_values ?? []);
            $serial = trim((string) $balance->label_serial_number);
            $barcode = trim((string) $balance->barcode_value);
            $row = [
                'product_name' => $productNames[$balance->product_id] ?? 'Unknown product',
                'product_detail' => $variant?->name ?? 'Base product',
                'serial_number' => $serial !== '' ? $serial : 'Not assigned',
                'barcode_value' => $barcode !== '' ? $barcode : 'Not assigned',
                'net_weight' => number_format((float) $balance->weight, 3, '.', ''),
                'pieces' => number_format((float) $balance->pieces, 0, '.', ''),
                'stock_entry' => $production?->captured_at?->format('Y-m-d H:i') ?? 'Not assigned',
                'last_movement' => CarbonImmutable::parse($balance->last_movement)->format('Y-m-d H:i'),
                'status' => $serial !== '' ? 'Available' : 'Manual / Opening stock',
            ];
            foreach ($dynamicColumns as $key => $label) {
                $value = $dynamicValues->get($key);
                $row[$key] = is_array($value) ? implode(', ', $value) : ((string) $value ?: '-');
            }

            return $row;
        });
        $columns = $this->currentStockColumns($dynamicColumns->all());
        $summaryRows = $rows
            ->groupBy(fn ($row) => collect(['product_name', 'product_detail', ...array_keys($dynamicColumns->all())])
                ->map(fn ($key) => (string) ($row[$key] ?? '-'))
                ->implode('|'))
            ->map(function ($group) use ($dynamicColumns): array {
                $first = $group->first();

                return [
                    'product_name' => $first['product_name'],
                    'product_detail' => $first['product_detail'],
                    ...collect(array_keys($dynamicColumns->all()))->mapWithKeys(fn ($key) => [$key => $first[$key] ?? '-'])->all(),
                    'serials' => $group->where('serial_number', '!=', 'Not assigned')->count(),
                    'net_weight' => number_format($group->sum(fn ($row) => (float) $row['net_weight']), 3, '.', ''),
                    'pieces' => number_format($group->sum(fn ($row) => (float) $row['pieces']), 0, '.', ''),
                ];
            })
            ->sortBy('product_name')
            ->values();
        $totalWeight = $rows->sum(fn ($row) => (float) $row['net_weight']);
        $totalPieces = $rows->sum(fn ($row) => (float) $row['pieces']);
        $serialCount = $rows->where('serial_number', '!=', 'Not assigned')->count();
        $summaryColumns = [
            'product_name' => 'Product',
            'product_detail' => 'Product Detail',
            ...$dynamicColumns->all(),
            'serials' => 'Serials',
            'net_weight' => 'Net Stock kg',
            'pieces' => 'PCS',
        ];
        $baseName = 'current-stock-'.$asOf->format('Ymd');

        if ($data['format'] === 'pdf') {
            $pdfRows = collect([
                ['section' => 'AS OF', 'details' => $asOf->format('Y-m-d H:i'), 'weight' => '', 'pieces' => '', 'serials' => ''],
                ['section' => 'TOTAL', 'details' => 'Available current stock', 'weight' => number_format($totalWeight, 3), 'pieces' => number_format($totalPieces, 0), 'serials' => $serialCount],
                ...$summaryRows->map(fn ($row) => [
                    'section' => 'SUMMARY',
                    'details' => collect(array_keys($summaryColumns))->reject(fn ($key) => in_array($key, ['net_weight', 'pieces', 'serials'], true))->map(fn ($key) => $row[$key] ?? '-')->implode(' / '),
                    'weight' => $row['net_weight'],
                    'pieces' => $row['pieces'],
                    'serials' => $row['serials'],
                ])->all(),
                ...$rows->map(fn ($row) => [
                    'section' => 'STOCK',
                    'details' => collect(array_keys($columns))->map(fn ($key) => ($columns[$key] ?? $key).': '.($row[$key] ?? '-'))->implode(' / '),
                    'weight' => $row['net_weight'],
                    'pieces' => $row['pieces'],
                    'serials' => $row['serial_number'],
                ])->all(),
            ]);

            return response($this->basicPdf('Current Stock', ['section', 'serials', 'weight', 'pieces', 'details'], $pdfRows), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$baseName.'.pdf"',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        }

        $summarySheet = [
            ['Current Stock Report'],
            ['As of', $asOf->format('Y-m-d H:i')],
            ['Generated at', now()->format('Y-m-d H:i')],
            ['Total Net Stock kg', number_format($totalWeight, 3, '.', '')],
            ['Total PCS', number_format($totalPieces, 0, '.', '')],
            ['Available Customer Serials', (string) $serialCount],
            [],
            array_values($summaryColumns),
            ...$summaryRows->map(fn ($row) => collect(array_keys($summaryColumns))->map(fn ($key) => $row[$key] ?? '-')->all())->all(),
        ];
        $serialSheet = [
            ['Current Stock Serial Report'],
            ['As of', $asOf->format('Y-m-d H:i')],
            [],
            array_values($columns),
            ...$rows->map(fn ($row) => collect(array_keys($columns))->map(fn ($key) => $row[$key] ?? '-')->all())->all(),
        ];

        return response($this->xlsxWorkbookSheets([
            'Stock Summary' => $summarySheet,
            'Serial Stock' => $serialSheet,
        ]), 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="'.$baseName.'.xlsx"',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    private function currentStockColumns(array $dynamicColumns): array
    {
        $available = [
            'product_name' => 'Product',
            'product_detail' => 'Product Detail',
            ...$dynamicColumns,
            'serial_number' => 'Serial Number',
            'barcode_value' => 'Barcode',
            'net_weight' => 'Net Stock kg',
            'pieces' => 'PCS',
            'stock_entry' => 'Stock Entry',
            'last_movement' => 'Last Movement',
            'status' => 'Status',
        ];
        $configured = data_get(Auth::user()?->tenant?->settings ?? [], 'reportColumns.stock', []);
        if (! is_array($configured) || $configured === []) {
            return $available;
        }
        $selected = collect($configured)
            ->filter(fn ($key) => array_key_exists($key, $available))
            ->mapWithKeys(fn ($key) => [$key => $available[$key]])
            ->all();

        return $selected === [] ? $available : $selected;
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
