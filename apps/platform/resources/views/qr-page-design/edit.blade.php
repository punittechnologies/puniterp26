@extends('layouts.admin')

@section('content')
@php
    $selectedFields = old('display_fields', $setting->resolvedDisplayFields());
    $complaintFields = old('complaint_fields', $setting->resolvedComplaintFields());
    $sectionOrder = old('section_order', array_flip($setting->resolvedSectionOrder()));
    $sectionOrder = collect($sectionLabels)->mapWithKeys(
        fn ($label, $key) => [$key => ((int) ($sectionOrder[$key] ?? array_search($key, $setting->resolvedSectionOrder(), true))) + (old('section_order') ? 0 : 1)]
    )->all();
    $theme = array_merge(\App\Models\Verification\QrPageSetting::DEFAULT_THEME, old('theme', $setting->resolvedTheme()));
@endphp

<style>
    .qr-admin-hero{display:flex;justify-content:space-between;gap:24px;align-items:center;padding:28px;border-radius:24px;background:linear-gradient(135deg,#0d2240,#1d4ed8 62%,#0f766e);color:#fff;box-shadow:0 20px 45px rgba(29,78,216,.18);margin-bottom:24px}
    .qr-admin-hero h2{font-size:30px;margin:5px 0 8px}.qr-admin-hero p{max-width:720px;margin:0;color:#dbeafe;line-height:1.6}.qr-admin-hero__badge{white-space:nowrap;padding:10px 14px;border:1px solid rgba(255,255,255,.32);border-radius:999px;background:rgba(255,255,255,.12);font-weight:800}
    .qr-settings-grid{display:grid;grid-template-columns:minmax(0,1.5fr) minmax(330px,.75fr);gap:22px}.qr-stack{display:grid;gap:20px}.qr-card{background:#fff;border:1px solid #dbe7f5;border-radius:22px;padding:22px;box-shadow:0 12px 35px rgba(15,35,64,.06)}.qr-card h3{margin:0 0 5px;color:#10233f;font-size:20px}.qr-card>p{margin:0 0 18px;color:#64748b;line-height:1.55}.qr-form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.qr-form-grid .wide{grid-column:1/-1}.qr-field{display:grid;gap:7px}.qr-field span{font-size:12px;text-transform:uppercase;letter-spacing:.06em;font-weight:800;color:#52627a}.qr-field input,.qr-field textarea,.qr-field select{width:100%;border:1px solid #cbd8e8;border-radius:12px;padding:11px 12px;background:#fbfdff;color:#10233f}.qr-field textarea{min-height:90px;resize:vertical}.qr-switch-row{display:flex;justify-content:space-between;align-items:center;gap:16px;padding:15px;border-radius:16px;background:#f5f9ff;border:1px solid #dbeafe}.qr-switch-row strong{display:block;color:#10233f}.qr-switch-row small{display:block;margin-top:3px;color:#64748b}.qr-switch-row input{width:22px;height:22px;accent-color:#1d4ed8}.qr-check-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.qr-check{display:flex;align-items:center;gap:10px;padding:11px 12px;border:1px solid #dbe7f5;border-radius:12px;background:#fbfdff;color:#243b5a;font-weight:700}.qr-check input{width:18px;height:18px;accent-color:#1d4ed8}.qr-complaint-row{display:grid;grid-template-columns:minmax(0,1fr) 100px 100px;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #edf2f7}.qr-complaint-row:last-child{border-bottom:0}.qr-complaint-row label{display:flex;align-items:center;gap:7px;color:#475569}.qr-preview{position:sticky;top:18px;overflow:hidden;padding:0}.qr-preview__top{padding:28px;background:linear-gradient(145deg,var(--primary),var(--accent));color:#fff;text-align:center}.qr-preview__logo{width:74px;height:74px;border-radius:20px;object-fit:contain;background:#fff;padding:8px;margin:0 auto 12px;box-shadow:0 12px 28px rgba(0,0,0,.16)}.qr-preview__body{padding:20px;background:var(--background)}.qr-preview__verified{background:var(--surface);border-radius:18px;padding:18px;text-align:center;box-shadow:0 10px 25px rgba(15,35,64,.08)}.qr-preview__seal{width:52px;height:52px;border-radius:50%;display:grid;place-items:center;margin:0 auto 10px;background:#dcfce7;color:#15803d;font-size:26px;font-weight:900}.qr-preview__lines{display:grid;gap:9px;margin-top:14px}.qr-preview__line{height:44px;background:var(--surface);border-radius:12px;border:1px solid #e4ebf4}.qr-save{position:sticky;bottom:12px;display:flex;justify-content:flex-end;margin-top:20px}.qr-save button{border:0;border-radius:14px;padding:14px 22px;background:#1d4ed8;color:#fff;font-weight:900;box-shadow:0 12px 28px rgba(29,78,216,.25);cursor:pointer}.qr-logo-current{max-width:120px;max-height:90px;border-radius:12px;border:1px solid #dbe7f5;padding:6px;background:#fff}
    @media(max-width:1050px){.qr-settings-grid{grid-template-columns:1fr}.qr-preview{position:relative;top:auto}}@media(max-width:700px){.qr-admin-hero{align-items:flex-start;flex-direction:column}.qr-form-grid,.qr-check-grid{grid-template-columns:1fr}.qr-complaint-row{grid-template-columns:1fr 1fr}.qr-complaint-row>strong{grid-column:1/-1}}
</style>

<section class="qr-admin-hero">
    <div>
        <small>Secure product verification</small>
        <h2>Design the customer’s QR experience</h2>
        <p>Create a polished mobile verification page, choose exactly which print-time details appear, and receive structured complaints without exposing your ERP login.</p>
    </div>
    <div class="qr-admin-hero__badge">{{ $setting->is_enabled ? '● Live for new labels' : '○ Disabled by default' }}</div>
</section>

<form class="qr-design-form" method="POST" action="{{ route('admin.qr-page.update') }}" enctype="multipart/form-data">
    @csrf
    <div class="qr-settings-grid">
        <div class="qr-stack">
            <section class="qr-card qr-stack">
                <div class="qr-switch-row">
                    <div><strong>Enable QR verification</strong><small>Only new Web Label prints containing a QR field will create verification pages.</small></div>
                    <input type="hidden" name="is_enabled" value="0">
                    <input type="checkbox" name="is_enabled" value="1" @checked(old('is_enabled', $setting->is_enabled))>
                </div>
                <div class="qr-switch-row">
                    <div><strong>Enable customer complaints</strong><small>Show the complaint form beneath verified product information.</small></div>
                    <input type="hidden" name="complaints_enabled" value="0">
                    <input type="checkbox" name="complaints_enabled" value="1" @checked(old('complaints_enabled', $setting->complaints_enabled))>
                </div>
                <div class="qr-switch-row">
                    <div><strong>Email notifications</strong><small>Also email the configured address when a complaint arrives.</small></div>
                    <input type="hidden" name="email_notifications_enabled" value="0">
                    <input type="checkbox" name="email_notifications_enabled" value="1" @checked(old('email_notifications_enabled', $setting->email_notifications_enabled ?? true))>
                </div>
            </section>

            <section class="qr-card">
                <h3>Company identity</h3>
                <p>These details are copied into every new verification snapshot. Editing them later will not rewrite labels already printed.</p>
                <div class="qr-form-grid">
                    <label class="qr-field wide"><span>Company logo</span><input type="file" name="company_logo" accept="image/png,image/jpeg,image/webp"></label>
                    @if($logoUrl)<div class="wide"><img class="qr-logo-current" src="{{ $logoUrl }}" alt="Current company logo"></div>@endif
                    <label class="qr-field"><span>Company name</span><input name="company_name" value="{{ old('company_name', $setting->company_name) }}"></label>
                    <label class="qr-field"><span>GST number</span><input name="gst_number" value="{{ old('gst_number', $setting->gst_number) }}"></label>
                    <label class="qr-field"><span>Phone</span><input name="phone" value="{{ old('phone', $setting->phone) }}"></label>
                    <label class="qr-field"><span>Email</span><input type="email" name="email" value="{{ old('email', $setting->email) }}"></label>
                    <label class="qr-field"><span>Contact person</span><input name="contact_person" value="{{ old('contact_person', $setting->contact_person) }}"></label>
                    <label class="qr-field"><span>Website</span><input type="url" name="website" placeholder="https://example.com" value="{{ old('website', $setting->website) }}"></label>
                    <label class="qr-field wide"><span>Address</span><textarea name="address">{{ old('address', $setting->address) }}</textarea></label>
                    <label class="qr-field wide"><span>Custom company text</span><textarea name="custom_text" placeholder="Warranty, support or brand statement">{{ old('custom_text', $setting->custom_text) }}</textarea></label>
                </div>
            </section>

            <section class="qr-card">
                <h3>Authenticity message</h3>
                <p>Plain text only keeps the public page safe and consistently formatted.</p>
                <div class="qr-form-grid">
                    <label class="qr-field wide"><span>Authenticity statement</span><textarea name="authenticity_statement" placeholder="Original product manufactured by Company Name.">{{ old('authenticity_statement', $setting->authenticity_statement) }}</textarea></label>
                    <label class="qr-field"><span>Origin line</span><input name="made_in_text" value="{{ old('made_in_text', $setting->made_in_text ?: 'Made in India') }}"></label>
                    <label class="qr-field"><span>Complaint notification email</span><input type="email" name="complaint_email" value="{{ old('complaint_email', $setting->complaint_email) }}"></label>
                </div>
            </section>

            <section class="qr-card">
                <h3>Product information</h3>
                <p>Select the fields customers may see. Values are frozen at label-printing time.</p>
                <div class="qr-check-grid">
                    @foreach($fieldOptions as $key => $label)
                        <label class="qr-check"><input type="checkbox" name="display_fields[]" value="{{ $key }}" @checked(in_array($key, $selectedFields, true))><span>{{ $label }}</span></label>
                    @endforeach
                </div>
            </section>

            <section class="qr-card">
                <h3>Complaint form</h3>
                <p>Enable each input and independently decide whether the customer must complete it.</p>
                @foreach($complaintFieldLabels as $key => $label)
                    @php $field = $complaintFields[$key] ?? ['enabled' => false, 'required' => false]; @endphp
                    <div class="qr-complaint-row">
                        <strong>{{ $label }}</strong>
                        <label><input type="checkbox" name="complaint_fields[{{ $key }}][enabled]" value="1" @checked((bool)($field['enabled'] ?? false))> Show</label>
                        <label><input type="checkbox" name="complaint_fields[{{ $key }}][required]" value="1" @checked((bool)($field['required'] ?? false))> Required</label>
                    </div>
                @endforeach
            </section>

            <section class="qr-card">
                <h3>Brand colours and section order</h3>
                <p>Choose the page palette and the order customers see each section.</p>
                <div class="qr-form-grid">
                    @foreach(['primary' => 'Primary', 'accent' => 'Accent', 'background' => 'Background', 'surface' => 'Cards', 'text' => 'Text'] as $key => $label)
                        <label class="qr-field"><span>{{ $label }}</span><input type="color" name="theme[{{ $key }}]" value="{{ $theme[$key] }}"></label>
                    @endforeach
                    @foreach($sectionLabels as $key => $label)
                        <label class="qr-field"><span>{{ $label }} order</span><select name="section_order[{{ $key }}]">@for($rank=1;$rank<=4;$rank++)<option value="{{ $rank }}" @selected((int)($sectionOrder[$key] ?? 1) === $rank)>{{ $rank }}</option>@endfor</select></label>
                    @endforeach
                </div>
            </section>
        </div>

        <aside>
            <section class="qr-card qr-preview" style="--primary:{{ $theme['primary'] }};--accent:{{ $theme['accent'] }};--background:{{ $theme['background'] }};--surface:{{ $theme['surface'] }};--text:{{ $theme['text'] }}">
                <div class="qr-preview__top">
                    @if($logoUrl)<img class="qr-preview__logo" src="{{ $logoUrl }}" alt="">@endif
                    <small>PRODUCT AUTHENTICITY</small>
                    <h3 style="color:#fff;margin-top:8px">{{ old('company_name', $setting->company_name ?: auth()->user()?->tenant?->name) }}</h3>
                </div>
                <div class="qr-preview__body">
                    <div class="qr-preview__verified">
                        <div class="qr-preview__seal">✓</div>
                        <strong style="color:var(--text)">Verified product record</strong>
                        <p style="color:#64748b;margin:7px 0 0">A secure print-time snapshot will appear here.</p>
                    </div>
                    <div class="qr-preview__lines"><div class="qr-preview__line"></div><div class="qr-preview__line"></div><div class="qr-preview__line"></div></div>
                </div>
            </section>
        </aside>
    </div>
    <div class="qr-save"><button type="submit">Save QR page design</button></div>
</form>
@endsection
