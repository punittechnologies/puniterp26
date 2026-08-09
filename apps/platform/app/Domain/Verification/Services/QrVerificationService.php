<?php

namespace App\Domain\Verification\Services;

use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\Verification\QrPageSetting;
use App\Models\Verification\QrVerification;
use Carbon\CarbonImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class QrVerificationService
{
    public const FIXED_FIELDS = [
        'product.name' => 'Product',
        'product.code' => 'Product code',
        'variant.name' => 'Variant',
        'variant.code' => 'Variant code',
        'serial.number' => 'Serial number',
        'barcode.value' => 'Barcode',
        'weight.gross' => 'Gross weight',
        'weight.tare' => 'Tare weight',
        'weight.net' => 'Net weight',
        'pieces.quantity' => 'Pieces',
        'date.printed' => 'Label date',
        'time.printed' => 'Label time',
    ];

    public function fieldOptions(string $tenantId): array
    {
        $dynamic = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get()
            ->mapWithKeys(fn (DynamicFieldDefinition $field): array => [
                'dynamic.'.$field->entity_type.'.'.$field->internal_key => $field->field_label,
            ])
            ->all();

        return [...self::FIXED_FIELDS, ...$dynamic];
    }

    /**
     * @return array{verification: QrVerification, token: string}
     */
    public function create(QrPageSetting $setting, array $payload, ?string $userId): array
    {
        $existing = QrVerification::query()
            ->where('tenant_id', $setting->tenant_id)
            ->where('source_transaction_id', $payload['source_transaction_id'])
            ->first();

        if ($existing) {
            return [
                'verification' => $existing,
                'token' => Crypt::decryptString($existing->token_encrypted),
            ];
        }

        $token = Str::random(48);
        $printedAt = CarbonImmutable::parse($payload['printed_at'] ?? now());
        $snapshot = $this->snapshot($setting, $payload, $printedAt);

        try {
            $verification = QrVerification::query()->create([
                'tenant_id' => $setting->tenant_id,
                'qr_page_setting_id' => $setting->id,
                'source_transaction_id' => $payload['source_transaction_id'],
                'token_hash' => hash('sha256', $token),
                'token_encrypted' => Crypt::encryptString($token),
                'status' => 'authentic',
                'product_id' => $payload['product_id'] ?? null,
                'variant_id' => $payload['variant_id'] ?? null,
                'serial_number' => $payload['serial_number'] ?? null,
                'barcode_value' => $payload['barcode_value'] ?? null,
                'snapshot' => $snapshot,
                'printed_at' => $printedAt,
                'created_by' => $userId,
            ]);
        } catch (QueryException $exception) {
            $verification = QrVerification::query()
                ->where('tenant_id', $setting->tenant_id)
                ->where('source_transaction_id', $payload['source_transaction_id'])
                ->first();

            if (! $verification) {
                throw $exception;
            }
            $token = Crypt::decryptString($verification->token_encrypted);
        }

        return compact('verification', 'token');
    }

    private function snapshot(QrPageSetting $setting, array $payload, CarbonImmutable $printedAt): array
    {
        $tenant = $setting->tenant;
        $productRaw = is_array($payload['product_raw'] ?? null) ? $payload['product_raw'] : [];
        $dynamicValues = is_array($payload['dynamic_values'] ?? null) ? $payload['dynamic_values'] : [];
        $fieldOptions = $this->fieldOptions($setting->tenant_id);
        $fields = [];

        foreach ($setting->resolvedDisplayFields() as $key) {
            if (! isset($fieldOptions[$key])) {
                continue;
            }
            $value = $this->fieldValue($key, $payload, $productRaw, $dynamicValues, $printedAt);
            if ($value === null || $value === '') {
                continue;
            }
            $fields[] = [
                'key' => $key,
                'label' => $fieldOptions[$key],
                'value' => $value,
            ];
        }

        $showCompanyName = $setting->show_company_name ?? true;
        $resolvedCompanyName = $setting->company_name ?: $tenant?->name;

        return [
            'company' => [
                'logo_url' => $setting->company_logo_path
                    ? url(Storage::disk('public')->url($setting->company_logo_path))
                    : null,
                'name' => $showCompanyName ? $resolvedCompanyName : null,
                'gst_number' => $setting->gst_number,
                'phone' => $setting->phone,
                'email' => $setting->email,
                'address' => $setting->address,
                'contact_person' => $setting->contact_person,
                'website' => $setting->website,
                'custom_text' => $setting->custom_text,
            ],
            'authenticity' => [
                'status' => 'authentic',
                'statement' => $setting->authenticity_statement
                    ?: ($showCompanyName && $resolvedCompanyName
                        ? 'Original product manufactured by '.$resolvedCompanyName.'.'
                        : 'Original product record verified at the time of labelling.'),
                'made_in_text' => $setting->made_in_text,
            ],
            'product' => [
                'name' => $payload['product_name'] ?? null,
                'variant_name' => $payload['variant_name'] ?? null,
                'serial_number' => $payload['serial_number'] ?? null,
                'barcode_value' => $payload['barcode_value'] ?? null,
                'fields' => $fields,
                'printed_at' => $printedAt->toIso8601String(),
            ],
            'page' => [
                'show_company_name' => $showCompanyName,
                'theme' => $setting->resolvedTheme(),
                'section_order' => $setting->resolvedSectionOrder(),
            ],
            'complaints' => [
                'enabled' => $setting->complaints_enabled,
                'fields' => $setting->resolvedComplaintFields(),
            ],
        ];
    }

    private function fieldValue(
        string $key,
        array $payload,
        array $productRaw,
        array $dynamicValues,
        CarbonImmutable $printedAt,
    ): mixed {
        if (str_starts_with($key, 'dynamic.')) {
            $internalKey = str($key)->afterLast('.')->toString();

            return $dynamicValues[$key]
                ?? $dynamicValues[$internalKey]
                ?? data_get($productRaw, $internalKey)
                ?? data_get($productRaw, 'metadata.'.$internalKey)
                ?? data_get($productRaw, 'custom_fields.'.$internalKey);
        }

        return match ($key) {
            'product.name' => $payload['product_name'] ?? data_get($productRaw, 'name'),
            'product.code' => data_get($productRaw, 'product_code') ?? data_get($productRaw, 'productCode'),
            'variant.name' => $payload['variant_name'] ?? null,
            'variant.code' => $payload['variant_code'] ?? null,
            'serial.number' => $payload['serial_number'] ?? null,
            'barcode.value' => $payload['barcode_value'] ?? null,
            'weight.gross' => $this->weight($payload['gross_weight'] ?? null, $payload['unit'] ?? 'kg'),
            'weight.tare' => $this->weight($payload['tare_weight'] ?? null, $payload['unit'] ?? 'kg'),
            'weight.net' => $this->weight($payload['net_weight'] ?? null, $payload['unit'] ?? 'kg'),
            'pieces.quantity' => $payload['piece_quantity'] ?? null,
            'date.printed' => $printedAt->format('d M Y'),
            'time.printed' => $printedAt->format('h:i A'),
            default => null,
        };
    }

    private function weight(mixed $value, string $unit): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return number_format((float) $value, 3, '.', '').' '.$unit;
    }
}
