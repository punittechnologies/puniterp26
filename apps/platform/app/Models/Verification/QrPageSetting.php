<?php

namespace App\Models\Verification;

use App\Models\Concerns\HasUuidPrimaryKey;
use App\Models\Tenant;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'tenant_id',
    'is_enabled',
    'complaints_enabled',
    'email_notifications_enabled',
    'company_logo_path',
    'company_name',
    'gst_number',
    'phone',
    'email',
    'address',
    'contact_person',
    'website',
    'custom_text',
    'authenticity_statement',
    'made_in_text',
    'complaint_email',
    'theme',
    'display_fields',
    'section_order',
    'complaint_fields',
    'created_by',
    'updated_by',
])]
class QrPageSetting extends Model
{
    use HasUuidPrimaryKey;

    public const DEFAULT_DISPLAY_FIELDS = [
        'product.name',
        'serial.number',
        'barcode.value',
        'weight.net',
        'pieces.quantity',
        'date.printed',
        'time.printed',
    ];

    public const DEFAULT_SECTION_ORDER = [
        'authenticity',
        'product',
        'company',
        'complaint',
    ];

    public const DEFAULT_COMPLAINT_FIELDS = [
        'customer_name' => ['enabled' => true, 'required' => true],
        'phone' => ['enabled' => true, 'required' => true],
        'email' => ['enabled' => true, 'required' => false],
        'message' => ['enabled' => true, 'required' => true],
        'customer_company_name' => ['enabled' => false, 'required' => false],
        'contact_person' => ['enabled' => false, 'required' => false],
        'order_reference' => ['enabled' => false, 'required' => false],
        'photo' => ['enabled' => true, 'required' => false],
    ];

    public const DEFAULT_THEME = [
        'primary' => '#1d4ed8',
        'accent' => '#0f766e',
        'background' => '#f4f7fb',
        'surface' => '#ffffff',
        'text' => '#10233f',
    ];

    protected function casts(): array
    {
        return [
            'is_enabled' => 'boolean',
            'complaints_enabled' => 'boolean',
            'email_notifications_enabled' => 'boolean',
            'theme' => 'array',
            'display_fields' => 'array',
            'section_order' => 'array',
            'complaint_fields' => 'array',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function verifications(): HasMany
    {
        return $this->hasMany(QrVerification::class);
    }

    public function resolvedTheme(): array
    {
        return array_merge(self::DEFAULT_THEME, $this->theme ?? []);
    }

    public function resolvedDisplayFields(): array
    {
        return is_array($this->display_fields)
            ? $this->display_fields
            : self::DEFAULT_DISPLAY_FIELDS;
    }

    public function resolvedSectionOrder(): array
    {
        return $this->section_order ?: self::DEFAULT_SECTION_ORDER;
    }

    public function resolvedComplaintFields(): array
    {
        return array_replace_recursive(self::DEFAULT_COMPLAINT_FIELDS, $this->complaint_fields ?? []);
    }
}
