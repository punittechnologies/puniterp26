<?php

namespace App\Http\Controllers\Web;

use App\Domain\Verification\Services\QrVerificationService;
use App\Http\Controllers\Controller;
use App\Models\Verification\QrComplaint;
use App\Models\Verification\QrPageSetting;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class QrPageController extends Controller
{
    public function edit(Request $request, QrVerificationService $service): View
    {
        $tenantId = $this->tenantId($request);
        $setting = QrPageSetting::query()->firstOrNew(
            ['tenant_id' => $tenantId],
            [
                'company_name' => $request->user()?->tenant?->name,
                'made_in_text' => 'Made in India',
                'theme' => QrPageSetting::DEFAULT_THEME,
                'display_fields' => QrPageSetting::DEFAULT_DISPLAY_FIELDS,
                'section_order' => QrPageSetting::DEFAULT_SECTION_ORDER,
                'complaint_fields' => QrPageSetting::DEFAULT_COMPLAINT_FIELDS,
            ],
        );

        return view('qr-page-design.edit', [
            'title' => 'QR Page Design',
            'setting' => $setting,
            'fieldOptions' => $service->fieldOptions($tenantId),
            'complaintFieldLabels' => $this->complaintFieldLabels(),
            'sectionLabels' => $this->sectionLabels(),
            'logoUrl' => $setting->company_logo_path
                ? Storage::disk('public')->url($setting->company_logo_path)
                : null,
        ]);
    }

    public function update(Request $request, QrVerificationService $service): RedirectResponse
    {
        $tenantId = $this->tenantId($request);
        $fieldOptions = $service->fieldOptions($tenantId);
        $complaintLabels = $this->complaintFieldLabels();
        $sectionLabels = $this->sectionLabels();
        $data = $request->validate([
            'is_enabled' => ['nullable', 'boolean'],
            'complaints_enabled' => ['nullable', 'boolean'],
            'email_notifications_enabled' => ['nullable', 'boolean'],
            'company_logo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'company_name' => ['nullable', 'string', 'max:255'],
            'gst_number' => ['nullable', 'string', 'max:100'],
            'phone' => ['nullable', 'string', 'max:64'],
            'email' => ['nullable', 'email', 'max:255'],
            'address' => ['nullable', 'string', 'max:1500'],
            'contact_person' => ['nullable', 'string', 'max:255'],
            'website' => ['nullable', 'url:http,https', 'max:255'],
            'custom_text' => ['nullable', 'string', 'max:1500'],
            'authenticity_statement' => ['nullable', 'string', 'max:1000'],
            'made_in_text' => ['nullable', 'string', 'max:255'],
            'complaint_email' => ['nullable', 'email', 'max:255'],
            'theme' => ['required', 'array'],
            'theme.*' => ['required', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'display_fields' => ['nullable', 'array'],
            'display_fields.*' => ['string', Rule::in(array_keys($fieldOptions))],
            'section_order' => ['required', 'array'],
            'section_order.*' => ['integer', 'between:1,4', 'distinct'],
            'complaint_fields' => ['nullable', 'array'],
            'complaint_fields.*.enabled' => ['nullable', 'boolean'],
            'complaint_fields.*.required' => ['nullable', 'boolean'],
        ]);

        $setting = QrPageSetting::query()->firstOrNew(['tenant_id' => $tenantId]);
        $setting->fill([
            'is_enabled' => $request->boolean('is_enabled'),
            'complaints_enabled' => $request->boolean('complaints_enabled'),
            'email_notifications_enabled' => $request->boolean('email_notifications_enabled'),
            'company_name' => $data['company_name'] ?? null,
            'gst_number' => $data['gst_number'] ?? null,
            'phone' => $data['phone'] ?? null,
            'email' => $data['email'] ?? null,
            'address' => $data['address'] ?? null,
            'contact_person' => $data['contact_person'] ?? null,
            'website' => $data['website'] ?? null,
            'custom_text' => $data['custom_text'] ?? null,
            'authenticity_statement' => $data['authenticity_statement'] ?? null,
            'made_in_text' => $data['made_in_text'] ?: 'Made in India',
            'complaint_email' => $data['complaint_email'] ?? null,
            'theme' => array_intersect_key($data['theme'], QrPageSetting::DEFAULT_THEME),
            'display_fields' => array_values($data['display_fields'] ?? []),
            'section_order' => collect($data['section_order'])
                ->filter(fn ($rank, $section): bool => isset($sectionLabels[$section]))
                ->sort()
                ->keys()
                ->values()
                ->all(),
            'complaint_fields' => collect($complaintLabels)
                ->mapWithKeys(fn ($label, $key): array => [
                    $key => [
                        'enabled' => $request->boolean("complaint_fields.{$key}.enabled"),
                        'required' => $request->boolean("complaint_fields.{$key}.required")
                            && $request->boolean("complaint_fields.{$key}.enabled"),
                    ],
                ])
                ->all(),
            'updated_by' => $request->user()?->id,
        ]);

        if (! $setting->exists) {
            $setting->created_by = $request->user()?->id;
        }
        if ($request->hasFile('company_logo')) {
            $setting->company_logo_path = $request->file('company_logo')
                ->store("qr-pages/{$tenantId}/logos", 'public');
        }
        $setting->save();

        return back()->with('status', 'QR verification page settings saved. Existing verification snapshots were not changed.');
    }

    public function complaints(Request $request): View
    {
        $complaints = QrComplaint::query()
            ->with('verification')
            ->where('tenant_id', $this->tenantId($request))
            ->latest()
            ->paginate(25);

        return view('qr-complaints.index', [
            'title' => 'QR Complaint Inbox',
            'complaints' => $complaints,
        ]);
    }

    public function updateComplaint(Request $request, QrComplaint $complaint): RedirectResponse
    {
        abort_unless($complaint->tenant_id === $this->tenantId($request), 404);
        $data = $request->validate([
            'status' => ['required', Rule::in(['new', 'in_progress', 'resolved'])],
        ]);
        $complaint->update($data);

        return back()->with('status', 'Complaint status updated.');
    }

    public function complaintPhoto(Request $request, QrComplaint $complaint): BinaryFileResponse
    {
        abort_unless($complaint->tenant_id === $this->tenantId($request), 404);
        abort_unless($complaint->photo_path && Storage::disk('local')->exists($complaint->photo_path), 404);

        return response()->file(Storage::disk('local')->path($complaint->photo_path));
    }

    private function tenantId(Request $request): string
    {
        $tenantId = $request->user()?->tenant_id;
        abort_unless($tenantId, 403);

        return $tenantId;
    }

    private function complaintFieldLabels(): array
    {
        return [
            'customer_company_name' => 'Customer / company name',
            'customer_name' => 'Customer name',
            'phone' => 'Phone number',
            'email' => 'Email address',
            'contact_person' => 'Contact person',
            'message' => 'Complaint message',
            'order_reference' => 'Invoice / order reference',
            'photo' => 'Photo attachment',
        ];
    }

    private function sectionLabels(): array
    {
        return [
            'authenticity' => 'Authenticity result',
            'product' => 'Product details',
            'company' => 'Company details',
            'complaint' => 'Complaint form',
        ];
    }
}
