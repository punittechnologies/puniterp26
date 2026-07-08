<?php

namespace App\Http\Controllers\Api\V1\Operations;

use App\Domain\Operations\Services\OperationsSyncService;
use App\Http\Controllers\Controller;
use App\Models\Dispatch;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SyncController extends Controller
{
    public function inwardSession(Request $request, TenantContext $tenantContext, OperationsSyncService $service): JsonResponse
    {
        $payload = $this->payload($request);
        Validator::make($payload, [
            'id' => ['nullable', 'uuid'],
            'session_number' => ['required', 'string', 'max:120'],
            'status' => ['required', 'string', 'max:40'],
            'entry_count' => ['nullable', 'integer', 'min:0'],
            'total_gross_weight' => ['nullable', 'numeric', 'min:0'],
            'total_tare_weight' => ['nullable', 'numeric', 'min:0'],
            'total_net_weight' => ['nullable', 'numeric', 'min:0'],
            'total_piece_quantity' => ['nullable', 'numeric', 'min:0'],
            'started_at' => ['nullable', 'date'],
            'ended_at' => ['nullable', 'date'],
            'metadata' => ['nullable', 'array'],
        ])->validate();
        $session = $service->inwardSession($payload, $tenantContext->tenantId());

        return response()->json(['status' => 'synced', 'id' => $session->id, 'session_number' => $session->session_number]);
    }

    public function production(Request $request, TenantContext $tenantContext, OperationsSyncService $service): JsonResponse
    {
        $payload = $this->payload($request);
        Validator::make($payload, [
            'product_id' => ['required', 'uuid'],
            'variant_id' => ['nullable', 'uuid'],
            'inward_session_id' => ['nullable', 'uuid'],
            'inward_session_number' => ['nullable', 'string', 'max:120'],
            'inward_session_status' => ['nullable', 'string', 'max:40'],
            'inward_session_started_at' => ['nullable', 'date'],
            'inward_session_ended_at' => ['nullable', 'date'],
            'inward_session_metadata' => ['nullable', 'array'],
            'warehouse_id' => ['nullable', 'uuid'],
            'serial_number' => ['required', 'string', 'max:255'],
            'barcode_value' => ['required', 'string', 'max:255'],
            'product_snapshot' => ['nullable', 'array'],
            'dynamic_values' => ['nullable', 'array'],
            'gross_weight' => ['required', 'numeric', 'min:0'],
            'tare_weight' => ['nullable', 'numeric', 'min:0'],
            'net_weight' => ['required', 'numeric', 'min:0'],
            'piece_quantity' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:20'],
            'raw_reading' => ['nullable', 'array'],
            'id' => ['nullable', 'string', 'max:255'],
            'captured_at' => ['nullable', 'date'],
        ])->validate();
        $transaction = $service->production($payload, $tenantContext->tenantId(), $request->header('Idempotency-Key'));

        return response()->json(['status' => 'synced', 'id' => $transaction->id, 'serial_number' => $transaction->serial_number]);
    }

    public function deleteProduction(string $clientId, TenantContext $tenantContext, OperationsSyncService $service): JsonResponse
    {
        $service->deleteProduction($clientId, $tenantContext->tenantId());

        return response()->json(['status' => 'deleted']);
    }

    public function barcode(string $barcode, TenantContext $tenantContext, OperationsSyncService $service): JsonResponse
    {
        return response()->json([
            'status' => 'available',
            'data' => $service->barcodeForDispatch($barcode, $tenantContext->tenantId()),
        ]);
    }

    public function dispatches(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $dispatches = Dispatch::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->orderByDesc('confirmed_at')
            ->orderByDesc('created_at')
            ->limit((int) $request->integer('limit', 50))
            ->get()
            ->map(fn (Dispatch $dispatch): array => [
                'id' => $dispatch->id,
                'dispatch_number' => $dispatch->dispatch_number,
                'customer_id' => $dispatch->customer_id,
                'customer_snapshot' => $dispatch->customer_snapshot ?? [],
                'status' => $dispatch->status,
                'total_weight' => (float) $dispatch->total_weight,
                'total_pieces' => $dispatch->total_pieces === null ? null : (float) $dispatch->total_pieces,
                'created_at' => optional($dispatch->created_at)->toISOString(),
                'confirmed_at' => optional($dispatch->confirmed_at)->toISOString(),
            ]);

        return response()->json(['data' => $dispatches]);
    }

    public function dispatch(Request $request, TenantContext $tenantContext, OperationsSyncService $service): JsonResponse
    {
        $payload = $this->payload($request);
        Validator::make($payload, [
            'customer_id' => ['required', 'uuid'],
            'dispatch_number' => ['nullable', 'string', 'max:255'],
            'barcodes' => ['required', 'array', 'min:1'],
            'barcodes.*' => ['required', 'string', 'max:255'],
            'vehicle_number' => ['nullable', 'string', 'max:100'],
            'driver_name' => ['nullable', 'string', 'max:255'],
            'transporter' => ['nullable', 'string', 'max:255'],
            'po_reference' => ['nullable', 'string', 'max:255'],
            'invoice_reference' => ['nullable', 'string', 'max:255'],
            'metadata' => ['nullable', 'array'],
            'id' => ['nullable', 'string', 'max:255'],
            'confirmed_at' => ['nullable', 'date'],
        ])->validate();
        $dispatch = $service->dispatch($payload, $tenantContext->tenantId(), $request->header('Idempotency-Key'));

        return response()->json(['status' => 'synced', 'id' => $dispatch->id, 'dispatch_number' => $dispatch->dispatch_number]);
    }

    private function payload(Request $request): array
    {
        $data = $request->all();

        if ($data === [] && $request->getContent() !== '') {
            $decoded = json_decode($request->getContent(), true);

            return is_array($decoded) ? $decoded : [];
        }

        if (is_string($data)) {
            $decoded = json_decode($data, true);

            return is_array($decoded) ? $decoded : [];
        }

        if (count($data) === 1 && array_key_first($data) === 0 && is_string($data[0])) {
            $decoded = json_decode($data[0], true);

            return is_array($decoded) ? $decoded : [];
        }

        return $data;
    }
}
