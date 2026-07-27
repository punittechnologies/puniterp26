<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Verification\QrComplaint;
use App\Models\Verification\QrVerification;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\View\View;

class PublicVerificationController extends Controller
{
    public function show(string $token): View
    {
        $verification = $this->verification($token);
        $verification->increment('scan_count');
        $verification->forceFill(['last_scanned_at' => now()])->save();

        return view('verification.show', [
            'verification' => $verification,
            'snapshot' => $verification->snapshot,
            'token' => $token,
        ]);
    }

    public function complaint(Request $request, string $token): RedirectResponse
    {
        $verification = $this->verification($token);
        $config = data_get($verification->snapshot, 'complaints', []);
        abort_unless((bool) ($config['enabled'] ?? false), 404);

        if ($request->filled('_company_website')) {
            return back()->with('complaint_status', 'Thank you. Your feedback was received.');
        }

        $fieldConfig = is_array($config['fields'] ?? null) ? $config['fields'] : [];
        $rules = [];
        foreach ($this->complaintFields() as $field => $baseRules) {
            $options = is_array($fieldConfig[$field] ?? null) ? $fieldConfig[$field] : [];
            if (! ($options['enabled'] ?? false)) {
                continue;
            }
            $rules[$field] = [
                ($options['required'] ?? false) ? 'required' : 'nullable',
                ...$baseRules,
            ];
        }
        $validated = $request->validate($rules);
        $photoPath = null;
        if ($request->hasFile('photo') && ($fieldConfig['photo']['enabled'] ?? false)) {
            $photoPath = $request->file('photo')->store(
                'qr-complaints/'.$verification->tenant_id,
                'local',
            );
        }

        $complaint = QrComplaint::query()->create([
            'tenant_id' => $verification->tenant_id,
            'qr_verification_id' => $verification->id,
            'status' => 'new',
            'customer_company_name' => $validated['customer_company_name'] ?? null,
            'customer_name' => $validated['customer_name'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'email' => $validated['email'] ?? null,
            'contact_person' => $validated['contact_person'] ?? null,
            'order_reference' => $validated['order_reference'] ?? null,
            'message' => $validated['message'] ?? null,
            'photo_path' => $photoPath,
            'metadata' => [
                'ip' => $request->ip(),
                'user_agent' => str($request->userAgent())->limit(500)->toString(),
            ],
        ]);

        $this->notifyCompany($complaint, $verification);

        return back()->with('complaint_status', 'Thank you. Your complaint has been submitted securely.');
    }

    private function verification(string $token): QrVerification
    {
        if (! preg_match('/^[A-Za-z0-9]{48}$/', $token)) {
            abort(404);
        }

        return QrVerification::query()
            ->where('token_hash', hash('sha256', $token))
            ->firstOrFail();
    }

    private function notifyCompany(QrComplaint $complaint, QrVerification $verification): void
    {
        $setting = $verification->setting;
        if (! $setting?->email_notifications_enabled) {
            return;
        }
        $recipient = $setting->complaint_email ?: $setting->email;
        if (! $recipient) {
            return;
        }

        try {
            Mail::raw(
                implode("\n", [
                    'A new QR product complaint was submitted.',
                    'Serial: '.($verification->serial_number ?: '-'),
                    'Barcode: '.($verification->barcode_value ?: '-'),
                    'Customer: '.($complaint->customer_name ?: '-'),
                    'Phone: '.($complaint->phone ?: '-'),
                    'Message: '.($complaint->message ?: '-'),
                    'Open the QR Complaint Inbox in Punit ERP for full details.',
                ]),
                fn ($message) => $message
                    ->to($recipient)
                    ->subject('New product complaint - '.($verification->serial_number ?: 'QR verification')),
            );
        } catch (\Throwable $exception) {
            Log::warning('QR complaint email could not be sent.', [
                'complaint_id' => $complaint->id,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function complaintFields(): array
    {
        return [
            'customer_company_name' => ['string', 'max:255'],
            'customer_name' => ['string', 'max:255'],
            'phone' => ['string', 'max:64'],
            'email' => ['email', 'max:255'],
            'contact_person' => ['string', 'max:255'],
            'message' => ['string', 'max:3000'],
            'order_reference' => ['string', 'max:255'],
            'photo' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
    }
}
