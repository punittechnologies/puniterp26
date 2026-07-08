<?php

namespace App\Domain\Operations\Services;

use App\Models\BarcodeRecord;
use App\Models\Customer;
use App\Models\Dispatch;
use App\Models\DispatchItem;
use App\Models\InventoryTransaction;
use App\Models\InwardSession;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductionTransaction;
use App\Models\Tenant;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class OperationsSyncService
{
    public function inwardSession(array $payload, string $tenantId): InwardSession
    {
        $session = DB::transaction(function () use ($payload, $tenantId): InwardSession {
            $session = $this->upsertInwardSession([
                'id' => $payload['id'] ?? null,
                'session_number' => $payload['session_number'],
                'status' => $payload['status'] ?? 'saved',
                'started_at' => $payload['started_at'] ?? now(),
                'ended_at' => $payload['ended_at'] ?? null,
                'metadata' => $payload['metadata'] ?? [],
            ], $tenantId);

            $this->refreshInwardSessionTotals($session, [
                'status' => $payload['status'] ?? null,
                'entry_count' => $payload['entry_count'] ?? null,
                'total_gross_weight' => $payload['total_gross_weight'] ?? null,
                'total_tare_weight' => $payload['total_tare_weight'] ?? null,
                'total_net_weight' => $payload['total_net_weight'] ?? null,
                'total_piece_quantity' => $payload['total_piece_quantity'] ?? null,
                'ended_at' => $payload['ended_at'] ?? null,
            ]);

            return $session->refresh();
        });

        if (in_array($session->status, ['saved', 'synced', 'closed'], true)) {
            $this->deferReportEmail($tenantId, 'inward', $session);
        }

        return $session;
    }

    public function production(array $payload, string $tenantId, ?string $idempotencyKey = null): ProductionTransaction
    {
        if ($idempotencyKey) {
            $existing = ProductionTransaction::query()
                ->where('tenant_id', $tenantId)
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existing) {
                return $existing;
            }
        }

        try {
            return DB::transaction(function () use ($payload, $tenantId, $idempotencyKey): ProductionTransaction {
                if ($idempotencyKey) {
                    $existing = ProductionTransaction::query()
                        ->where('tenant_id', $tenantId)
                        ->where('idempotency_key', $idempotencyKey)
                        ->lockForUpdate()
                        ->first();

                    if ($existing) {
                        return $existing;
                    }
                }

                Product::query()
                    ->where('tenant_id', $tenantId)
                    ->findOrFail($payload['product_id']);

                if (! empty($payload['variant_id'])) {
                    ProductVariant::query()
                        ->where('tenant_id', $tenantId)
                        ->where('product_id', $payload['product_id'])
                        ->findOrFail($payload['variant_id']);
                }

                $session = $this->resolveInwardSession($payload, $tenantId);

                $transaction = ProductionTransaction::query()->create([
                    'tenant_id' => $tenantId,
                    'warehouse_id' => $payload['warehouse_id'] ?? null,
                    'product_id' => $payload['product_id'],
                    'variant_id' => $payload['variant_id'] ?? null,
                    'inward_session_id' => $session?->id,
                    'serial_number' => $payload['serial_number'],
                    'barcode_value' => $payload['barcode_value'],
                    'product_snapshot' => $payload['product_snapshot'] ?? [],
                    'dynamic_values' => $payload['dynamic_values'] ?? [],
                    'gross_weight' => $payload['gross_weight'],
                    'tare_weight' => $payload['tare_weight'] ?? 0,
                    'net_weight' => $payload['net_weight'],
                    'piece_quantity' => $payload['piece_quantity'] ?? null,
                    'unit' => $payload['unit'] ?? 'kg',
                    'raw_reading' => $payload['raw_reading'] ?? null,
                    'client_id' => $payload['id'] ?? null,
                    'idempotency_key' => $idempotencyKey,
                    'captured_at' => $payload['captured_at'] ?? now(),
                    'created_by' => Auth::id(),
                ]);

                if ($session) {
                    $this->refreshInwardSessionTotals($session);
                }

                BarcodeRecord::query()->create([
                    'tenant_id' => $tenantId,
                    'production_transaction_id' => $transaction->id,
                    'serial_number' => $transaction->serial_number,
                    'barcode_value' => $transaction->barcode_value,
                    'inventory_status' => 'available',
                    'dispatch_status' => 'not_dispatched',
                ]);

                InventoryTransaction::query()->create([
                    'tenant_id' => $tenantId,
                    'warehouse_id' => $transaction->warehouse_id,
                    'product_id' => $transaction->product_id,
                    'variant_id' => $transaction->variant_id,
                    'serial_number' => $transaction->serial_number,
                    'barcode_value' => $transaction->barcode_value,
                    'transaction_type' => 'production_addition',
                    'weight_quantity' => $transaction->net_weight,
                    'piece_quantity' => $transaction->piece_quantity,
                    'reference_type' => 'production',
                    'reference_id' => $transaction->id,
                    'created_by' => Auth::id(),
                    'occurred_at' => $transaction->captured_at,
                ]);

                return $transaction;
            });
        } catch (QueryException $exception) {
            if ($this->isDuplicateWrite($exception)) {
                $existing = $this->findExistingProduction($payload, $tenantId, $idempotencyKey);

                if ($existing) {
                    return $existing;
                }
            }

            throw $exception;
        }
    }

    public function deleteProduction(string $clientOrServerId, string $tenantId): void
    {
        DB::transaction(function () use ($clientOrServerId, $tenantId): void {
            $transaction = ProductionTransaction::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query) use ($clientOrServerId): void {
                    $query->where('id', $clientOrServerId)
                        ->orWhere('client_id', $clientOrServerId);
                })
                ->firstOrFail();

            InventoryTransaction::query()
                ->where('tenant_id', $tenantId)
                ->where('reference_type', 'production')
                ->where('reference_id', $transaction->id)
                ->delete();

            BarcodeRecord::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query) use ($transaction): void {
                    $query->where('production_transaction_id', $transaction->id)
                        ->orWhere('barcode_value', $transaction->barcode_value);
                })
                ->delete();

            $session = $transaction->inward_session_id
                ? InwardSession::query()
                    ->where('tenant_id', $tenantId)
                    ->find($transaction->inward_session_id)
                : null;

            $transaction->delete();

            if ($session) {
                $this->refreshInwardSessionTotals($session);
            }
        });
    }

    private function resolveInwardSession(array $payload, string $tenantId): ?InwardSession
    {
        $sessionId = $payload['inward_session_id'] ?? null;
        $sessionNumber = $payload['inward_session_number'] ?? null;

        if (! $sessionId && ! $sessionNumber) {
            return null;
        }

        return $this->upsertInwardSession([
            'id' => $sessionId,
            'session_number' => $sessionNumber ?: 'INW-'.now()->format('Ymd-His'),
            'status' => $payload['inward_session_status'] ?? 'open',
            'started_at' => $payload['inward_session_started_at'] ?? ($payload['captured_at'] ?? now()),
            'ended_at' => $payload['inward_session_ended_at'] ?? null,
            'metadata' => $payload['inward_session_metadata'] ?? [],
        ], $tenantId);
    }

    private function upsertInwardSession(array $payload, string $tenantId): InwardSession
    {
        $session = InwardSession::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($payload): void {
                $query->where('session_number', $payload['session_number']);

                if ($payload['id']) {
                    $query->orWhere('id', $payload['id']);
                }
            })
            ->first();

        $values = [
            'session_number' => $payload['session_number'],
            'status' => $payload['status'] ?? 'open',
            'started_at' => $payload['started_at'] ?? now(),
            'ended_at' => $payload['ended_at'] ?? null,
            'metadata' => $payload['metadata'] ?? [],
            'updated_by' => Auth::id(),
        ];

        if ($session) {
            $session->update($values);

            return $session;
        }

        try {
            return InwardSession::query()->create([
                ...$values,
                'id' => $payload['id'] ?: null,
                'tenant_id' => $tenantId,
                'created_by' => Auth::id(),
            ]);
        } catch (QueryException $exception) {
            if (! $this->isDuplicateWrite($exception)) {
                throw $exception;
            }

            return InwardSession::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query) use ($payload): void {
                    $query->where('session_number', $payload['session_number']);

                    if ($payload['id']) {
                        $query->orWhere('id', $payload['id']);
                    }
                })
                ->firstOrFail();
        }
    }

    private function refreshInwardSessionTotals(InwardSession $session, array $fallback = []): void
    {
        $totals = ProductionTransaction::query()
            ->where('tenant_id', $session->tenant_id)
            ->where('inward_session_id', $session->id)
            ->selectRaw('count(*) as entry_count')
            ->selectRaw('sum(gross_weight) as gross_weight')
            ->selectRaw('sum(tare_weight) as tare_weight')
            ->selectRaw('sum(net_weight) as net_weight')
            ->selectRaw('sum(coalesce(piece_quantity, 0)) as piece_quantity')
            ->selectRaw('max(captured_at) as ended_at')
            ->first();

        $entryCount = (int) ($totals->entry_count ?? 0);
        $hasServerEntries = $entryCount > 0;

        $session->update([
            'status' => $fallback['status'] ?? $session->status,
            'entry_count' => $hasServerEntries ? $entryCount : (int) ($fallback['entry_count'] ?? 0),
            'total_gross_weight' => $hasServerEntries ? ($totals->gross_weight ?? 0) : ($fallback['total_gross_weight'] ?? 0),
            'total_tare_weight' => $hasServerEntries ? ($totals->tare_weight ?? 0) : ($fallback['total_tare_weight'] ?? 0),
            'total_net_weight' => $hasServerEntries ? ($totals->net_weight ?? 0) : ($fallback['total_net_weight'] ?? 0),
            'total_piece_quantity' => $hasServerEntries ? ($totals->piece_quantity ?? null) : ($fallback['total_piece_quantity'] ?? null),
            'ended_at' => $fallback['ended_at'] ?? $totals->ended_at ?? $session->ended_at,
        ]);
    }

    public function dispatch(array $payload, string $tenantId, ?string $idempotencyKey = null): Dispatch
    {
        if ($idempotencyKey) {
            $existing = Dispatch::query()
                ->where('tenant_id', $tenantId)
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existing) {
                return $existing;
            }
        }

        try {
            $dispatch = DB::transaction(function () use ($payload, $tenantId, $idempotencyKey): Dispatch {
                $customer = Customer::query()
                    ->where('tenant_id', $tenantId)
                    ->findOrFail($payload['customer_id']);
                $scannedBarcodes = collect($payload['barcodes'] ?? [])
                    ->map(fn ($barcode): string => $this->normalizeBarcodeInput((string) $barcode))
                    ->filter()
                    ->unique()
                    ->values();

                if ($scannedBarcodes->isEmpty()) {
                    throw ValidationException::withMessages(['barcodes' => 'At least one barcode is required.']);
                }

                $resolvedRecords = $scannedBarcodes
                    ->map(fn (string $barcode) => $this->barcodeRecordForDispatch($barcode, $tenantId, true));
                $barcodes = $resolvedRecords
                    ->pluck('barcode_value')
                    ->unique()
                    ->values();

                if ($barcodes->count() !== $scannedBarcodes->count()) {
                    throw ValidationException::withMessages(['barcodes' => 'Duplicate barcode found in this dispatch.']);
                }

                $productions = ProductionTransaction::query()
                    ->where('tenant_id', $tenantId)
                    ->whereIn('barcode_value', $barcodes)
                    ->lockForUpdate()
                    ->get()
                    ->keyBy('barcode_value');

                if ($productions->count() !== $barcodes->count()) {
                    throw ValidationException::withMessages(['barcodes' => 'Unknown barcode found.']);
                }

                $totalWeight = $productions->sum(fn (ProductionTransaction $item) => (float) $item->net_weight);
                $totalPieces = $productions->sum(fn (ProductionTransaction $item) => (float) ($item->piece_quantity ?? 0));
                $number = $payload['dispatch_number'] ?? $this->nextDispatchNumber();

                $dispatch = Dispatch::query()->create([
                    'tenant_id' => $tenantId,
                    'customer_id' => $customer->id,
                    'dispatch_number' => $number,
                    'customer_snapshot' => $customer->toArray(),
                    'status' => 'confirmed',
                    'vehicle_number' => $payload['vehicle_number'] ?? null,
                    'driver_name' => $payload['driver_name'] ?? null,
                    'transporter' => $payload['transporter'] ?? null,
                    'po_reference' => $payload['po_reference'] ?? null,
                    'invoice_reference' => $payload['invoice_reference'] ?? null,
                    'total_weight' => $totalWeight,
                    'total_pieces' => $totalPieces,
                    'metadata' => $payload['metadata'] ?? [],
                    'client_id' => $payload['id'] ?? null,
                    'idempotency_key' => $idempotencyKey,
                    'created_by' => Auth::id(),
                    'confirmed_at' => $payload['confirmed_at'] ?? now(),
                ]);

                foreach ($barcodes as $barcode) {
                    $production = $productions[$barcode];
                    DispatchItem::query()->create([
                        'tenant_id' => $tenantId,
                        'dispatch_id' => $dispatch->id,
                        'production_transaction_id' => $production->id,
                        'barcode_value' => $barcode,
                        'weight_quantity' => $production->net_weight,
                        'piece_quantity' => $production->piece_quantity,
                    ]);
                    BarcodeRecord::query()
                        ->where('tenant_id', $tenantId)
                        ->where('barcode_value', $barcode)
                        ->update(['inventory_status' => 'dispatched', 'dispatch_status' => 'dispatched']);
                    InventoryTransaction::query()->create([
                        'tenant_id' => $tenantId,
                        'warehouse_id' => $production->warehouse_id,
                        'product_id' => $production->product_id,
                        'variant_id' => $production->variant_id,
                        'serial_number' => $production->serial_number,
                        'barcode_value' => $production->barcode_value,
                        'transaction_type' => 'dispatch_deduction',
                        'weight_quantity' => $production->net_weight,
                        'piece_quantity' => $production->piece_quantity,
                        'reference_type' => 'dispatch',
                        'reference_id' => $dispatch->id,
                        'created_by' => Auth::id(),
                        'occurred_at' => $dispatch->confirmed_at ?? now(),
                    ]);
                }

                return $dispatch;
            }, 3);
        } catch (QueryException $exception) {
            if (! $this->isDuplicateWrite($exception)) {
                throw $exception;
            }

            $existing = $this->findExistingDispatch($payload, $tenantId, $idempotencyKey);
            if ($existing) {
                return $existing;
            }

            throw ValidationException::withMessages([
                'barcodes' => 'One or more barcodes are already dispatched. Refresh and scan again.',
            ]);
        }

        $this->deferReportEmail($tenantId, 'dispatch', $dispatch);

        return $dispatch;
    }

    public function barcodeForDispatch(string $barcode, string $tenantId): array
    {
        $record = $this->barcodeRecordForDispatch($barcode, $tenantId);
        $production = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('barcode_value', $record->barcode_value)
            ->firstOrFail();

        return [
            'id' => $production->id,
            'serial_number' => $production->serial_number,
            'barcode_value' => $production->barcode_value,
            'product_id' => $production->product_id,
            'variant_id' => $production->variant_id,
            'inward_session_id' => $production->inward_session_id,
            'product_snapshot' => $production->product_snapshot ?? [],
            'dynamic_values' => $production->dynamic_values ?? [],
            'gross_weight' => (float) $production->gross_weight,
            'tare_weight' => (float) $production->tare_weight,
            'net_weight' => (float) $production->net_weight,
            'piece_quantity' => $production->piece_quantity === null ? null : (float) $production->piece_quantity,
            'unit' => $production->unit,
            'captured_at' => optional($production->captured_at)->toISOString(),
        ];
    }

    private function barcodeRecordForDispatch(string $barcode, string $tenantId, bool $lock = false): BarcodeRecord
    {
        $barcode = $this->normalizeBarcodeInput($barcode);
        $query = BarcodeRecord::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($barcode): void {
                $query->where('barcode_value', $barcode)
                    ->orWhere('serial_number', $barcode);
            });

        if ($lock) {
            $query->lockForUpdate();
        }

        $record = $query->first();

        if (! $record && strlen($barcode) >= 8) {
            $prefixQuery = BarcodeRecord::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query) use ($barcode): void {
                    $query->where('barcode_value', 'like', $barcode.'%')
                        ->orWhere('serial_number', 'like', $barcode.'%');
                });

            if ($lock) {
                $prefixQuery->lockForUpdate();
            }

            $matches = $prefixQuery->limit(2)->get();
            if ($matches->count() === 1) {
                $record = $matches->first();
            } elseif ($matches->count() > 1) {
                throw ValidationException::withMessages(['barcode' => 'Scanned barcode matches multiple records. Please type the full barcode.']);
            }
        }

        if (! $record) {
            $record = $this->repairBarcodeRecordFromProduction($barcode, $tenantId);
        }

        if (! $record) {
            throw ValidationException::withMessages(['barcode' => 'Unknown barcode.']);
        }

        $alreadyDispatched = DispatchItem::query()
            ->where('tenant_id', $tenantId)
            ->where('barcode_value', $record->barcode_value)
            ->exists();

        if ($alreadyDispatched) {
            $record->forceFill([
                'inventory_status' => 'dispatched',
                'dispatch_status' => 'dispatched',
            ])->save();
        }

        if ($record->inventory_status !== 'available' || $record->dispatch_status !== 'not_dispatched') {
            throw ValidationException::withMessages(['barcode' => 'Barcode is not available for dispatch.']);
        }

        return $record;
    }

    private function repairBarcodeRecordFromProduction(string $barcode, string $tenantId): ?BarcodeRecord
    {
        $production = $this->productionForBarcode($barcode, $tenantId);

        if (! $production || $production->status !== 'active') {
            return null;
        }

        $alreadyDispatched = DispatchItem::query()
            ->where('tenant_id', $tenantId)
            ->where('production_transaction_id', $production->id)
            ->exists();

        return BarcodeRecord::query()->firstOrCreate(
            [
                'tenant_id' => $tenantId,
                'barcode_value' => $production->barcode_value,
            ],
            [
                'production_transaction_id' => $production->id,
                'serial_number' => $production->serial_number,
                'inventory_status' => $alreadyDispatched ? 'dispatched' : 'available',
                'dispatch_status' => $alreadyDispatched ? 'dispatched' : 'not_dispatched',
            ]
        );
    }

    private function productionForBarcode(string $barcode, string $tenantId): ?ProductionTransaction
    {
        $query = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($barcode): void {
                $query->where('barcode_value', $barcode)
                    ->orWhere('serial_number', $barcode);
            });

        $production = $query->first();
        if ($production || strlen($barcode) < 6) {
            return $production;
        }

        $matches = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($barcode): void {
                $query->where('barcode_value', 'like', $barcode.'%')
                    ->orWhere('serial_number', 'like', $barcode.'%')
                    ->orWhere('barcode_value', 'like', '%'.$barcode.'%')
                    ->orWhere('serial_number', 'like', '%'.$barcode.'%');
            })
            ->limit(2)
            ->get();

        if ($matches->count() > 1) {
            throw ValidationException::withMessages(['barcode' => 'Scanned barcode matches multiple production entries. Please type the full barcode.']);
        }

        return $matches->first();
    }

    private function normalizeBarcodeInput(string $barcode): string
    {
        return strtoupper(preg_replace('/[^A-Za-z0-9_-]+/', '', trim($barcode)) ?: '');
    }

    private function nextDispatchNumber(): string
    {
        return 'DSP-'.now()->format('Ymd-His-u');
    }

    private function findExistingProduction(array $payload, string $tenantId, ?string $idempotencyKey): ?ProductionTransaction
    {
        return ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($payload, $idempotencyKey): void {
                if ($idempotencyKey) {
                    $query->orWhere('idempotency_key', $idempotencyKey);
                }

                if (! empty($payload['id'])) {
                    $query->orWhere('client_id', $payload['id']);
                }

                if (! empty($payload['barcode_value'])) {
                    $query->orWhere('barcode_value', $payload['barcode_value']);
                }

                if (! empty($payload['serial_number'])) {
                    $query->orWhere('serial_number', $payload['serial_number']);
                }
            })
            ->first();
    }

    private function findExistingDispatch(array $payload, string $tenantId, ?string $idempotencyKey): ?Dispatch
    {
        return Dispatch::query()
            ->where('tenant_id', $tenantId)
            ->where(function ($query) use ($payload, $idempotencyKey): void {
                if ($idempotencyKey) {
                    $query->orWhere('idempotency_key', $idempotencyKey);
                }

                if (! empty($payload['id'])) {
                    $query->orWhere('client_id', $payload['id']);
                }
            })
            ->first();
    }

    private function isDuplicateWrite(QueryException $exception): bool
    {
        return (string) $exception->getCode() === '23000'
            || str_contains(strtolower($exception->getMessage()), 'unique constraint')
            || str_contains(strtolower($exception->getMessage()), 'duplicate entry');
    }

    private function deferReportEmail(string $tenantId, string $type, InwardSession|Dispatch $report): void
    {
        app()->terminating(fn () => $this->sendReportEmail($tenantId, $type, $report));
    }

    private function sendReportEmail(string $tenantId, string $type, InwardSession|Dispatch $report): void
    {
        $tenant = Tenant::query()->find($tenantId);
        $settings = $tenant?->settings ?? [];
        $emailSettings = $settings['reportEmail'] ?? [];
        $recipients = collect(explode(',', (string) ($emailSettings['to'] ?? '')))
            ->map(fn ($email) => trim($email))
            ->filter(fn ($email) => filter_var($email, FILTER_VALIDATE_EMAIL))
            ->values();

        if ($recipients->isEmpty()) {
            return;
        }

        $title = $type === 'inward' ? 'Inward Report' : 'Dispatch Report';
        $number = $type === 'inward' ? $report->session_number : $report->dispatch_number;
        $rows = $type === 'inward'
            ? ProductionTransaction::query()->where('tenant_id', $tenantId)->where('inward_session_id', $report->id)->get()
            : ProductionTransaction::query()
                ->where('tenant_id', $tenantId)
                ->whereIn('id', $report->items()->pluck('production_transaction_id')->filter())
                ->get();

        $body = "Please find attached pdf/excel whatever is selected by user.\n\n"
            ."For system sale and support contact\n"
            ."PUNIT INSTRUMENT PVT LTD\n"
            ."+91 9737599004\n"
            ."punitinstrument.com\n"
            .'17, Hariyog Estate, Behind naroda fire station, Omnagar crossing road, Rd, Naroda, Ahmedabad, Gujarat 382345';

        try {
            Mail::raw($body, function ($message) use ($recipients, $emailSettings, $tenant, $title, $number, $rows): void {
                $message->from('punitinstrument@gmail.com', 'Punit Weighing System')
                    ->to($recipients->all())
                    ->subject('report generated from Punit weighing system');

                if (($emailSettings['pdf'] ?? true)) {
                    $message->attachData(
                        $this->plainReportPdf((string) $tenant?->name, $title, $number, $rows),
                        str($number)->slug('-').'.pdf',
                        ['mime' => 'application/pdf']
                    );
                }

                if (($emailSettings['excel'] ?? false)) {
                    $message->attachData(
                        $this->plainReportCsv($rows),
                        str($number)->slug('-').'.csv',
                        ['mime' => 'text/csv']
                    );
                }
            });
        } catch (\Throwable $exception) {
            Log::warning('Report email failed', [
                'tenant_id' => $tenantId,
                'type' => $type,
                'id' => $report->id,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function plainReportCsv($rows): string
    {
        $csv = "Barcode,Product,Gross,Tare,Net,Pieces,Time\n";
        foreach ($rows as $row) {
            $product = data_get($row->product_snapshot, 'product.name')
                ?? data_get($row->product_snapshot, 'name')
                ?? $row->product_id;
            $csv .= implode(',', array_map(fn ($value) => '"'.str_replace('"', '""', (string) $value).'"', [
                $row->barcode_value,
                $product,
                $row->gross_weight,
                $row->tare_weight,
                $row->net_weight,
                $row->piece_quantity,
                $row->captured_at,
            ]))."\n";
        }

        return $csv;
    }

    private function plainReportPdf(string $company, string $title, string $number, $rows): string
    {
        $lines = [
            $company ?: 'Punit ERP',
            strtoupper($title),
            'Report No: '.$number,
            'Generated: '.now()->format('d M Y H:i'),
            '',
            'Barcode | Product | Gross | Tare | Net | Pieces',
        ];
        foreach ($rows->take(34) as $row) {
            $product = data_get($row->product_snapshot, 'product.name')
                ?? data_get($row->product_snapshot, 'name')
                ?? $row->product_id;
            $lines[] = implode(' | ', [
                $row->barcode_value,
                mb_strimwidth((string) $product, 0, 24, ''),
                $row->gross_weight,
                $row->tare_weight,
                $row->net_weight,
                $row->piece_quantity ?? '-',
            ]);
        }

        $content = '';
        $y = 800;
        foreach ($lines as $index => $line) {
            $safe = str_replace(['\\', '(', ')'], ['/', '[', ']'], mb_strimwidth($line, 0, 100, ''));
            $size = $index === 0 ? 13 : 8;
            $content .= "BT /F1 {$size} Tf 28 {$y} Td ({$safe}) Tj ET\n";
            $y -= $index === 0 ? 24 : 15;
        }
        $objects = [
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
            '<< /Length '.strlen($content)." >>\nstream\n".$content.'endstream',
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        ];
        $pdf = "%PDF-1.4\n";
        $offsets = [0];
        foreach ($objects as $index => $object) {
            $offsets[] = strlen($pdf);
            $pdf .= ($index + 1)." 0 obj\n{$object}\nendobj\n";
        }
        $xref = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n0000000000 65535 f \n";
        foreach (array_slice($offsets, 1) as $offset) {
            $pdf .= str_pad((string) $offset, 10, '0', STR_PAD_LEFT)." 00000 n \n";
        }

        return $pdf.'trailer << /Root 1 0 R /Size '.(count($objects) + 1)." >>\nstartxref\n{$xref}\n%%EOF";
    }
}
