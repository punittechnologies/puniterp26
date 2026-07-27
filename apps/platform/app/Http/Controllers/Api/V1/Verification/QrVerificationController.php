<?php

namespace App\Http\Controllers\Api\V1\Verification;

use App\Domain\Verification\Services\QrVerificationService;
use App\Http\Controllers\Controller;
use App\Models\Verification\QrPageSetting;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class QrVerificationController extends Controller
{
    public function store(
        Request $request,
        TenantContext $tenantContext,
        QrVerificationService $service,
    ): JsonResponse {
        $payload = $request->validate([
            'source_transaction_id' => ['required', 'string', 'max:120'],
            'product_id' => [
                'nullable',
                'uuid',
                Rule::exists('products', 'id')->where('tenant_id', $tenantContext->tenantId()),
            ],
            'variant_id' => [
                'nullable',
                'uuid',
                Rule::exists('product_variants', 'id')->where('tenant_id', $tenantContext->tenantId()),
            ],
            'product_name' => ['required', 'string', 'max:255'],
            'variant_name' => ['nullable', 'string', 'max:255'],
            'variant_code' => ['nullable', 'string', 'max:255'],
            'serial_number' => ['required', 'string', 'max:255'],
            'barcode_value' => ['required', 'string', 'max:255'],
            'gross_weight' => ['nullable', 'numeric'],
            'tare_weight' => ['nullable', 'numeric'],
            'net_weight' => ['nullable', 'numeric'],
            'piece_quantity' => ['nullable', 'numeric'],
            'unit' => ['nullable', 'string', 'max:24'],
            'printed_at' => ['nullable', 'date'],
            'dynamic_values' => ['nullable', 'array'],
            'product_raw' => ['nullable', 'array'],
        ]);

        $setting = QrPageSetting::query()
            ->with('tenant')
            ->where('tenant_id', $tenantContext->tenantId())
            ->first();

        if (! $setting?->is_enabled) {
            throw ValidationException::withMessages([
                'qr' => 'QR verification is disabled. Enable it in QR Page Design before printing this template.',
            ]);
        }

        $created = $service->create($setting, $payload, $request->user()?->id);
        $publicUrl = route('verification.show', ['token' => $created['token']]);

        return response()->json([
            'id' => $created['verification']->id,
            'publicUrl' => $publicUrl,
            'status' => $created['verification']->status,
        ], 201);
    }
}
