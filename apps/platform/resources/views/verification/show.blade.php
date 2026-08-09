<!DOCTYPE html>
<html lang="en">
@php
    $company = data_get($snapshot, 'company', []);
    $authenticity = data_get($snapshot, 'authenticity', []);
    $product = data_get($snapshot, 'product', []);
    $theme = array_merge(\App\Models\Verification\QrPageSetting::DEFAULT_THEME, data_get($snapshot, 'page.theme', []));
    $sections = data_get($snapshot, 'page.section_order', \App\Models\Verification\QrPageSetting::DEFAULT_SECTION_ORDER);
    $complaintConfig = data_get($snapshot, 'complaints', []);
    $complaintFields = $complaintConfig['fields'] ?? [];
    $showCompanyName = data_get($snapshot, 'page.show_company_name', true);
    $fieldLabels = [
        'customer_company_name' => 'Company name',
        'customer_name' => 'Your name',
        'phone' => 'Phone number',
        'email' => 'Email address',
        'contact_person' => 'Contact person',
        'message' => 'How can we help?',
        'order_reference' => 'Invoice / order reference',
        'photo' => 'Add a product photo',
    ];
@endphp
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex,nofollow">
    <title>Product Verification | {{ $showCompanyName ? ($company['name'] ?? 'Punit ERP') : 'Punit ERP' }}</title>
    <style>
        :root{--primary:{{ $theme['primary'] }};--accent:{{ $theme['accent'] }};--background:{{ $theme['background'] }};--surface:{{ $theme['surface'] }};--text:{{ $theme['text'] }};--muted:#64748b;--line:#dfe8f2;--success:#15803d}
        *{box-sizing:border-box}body{margin:0;background:radial-gradient(circle at 10% -10%,color-mix(in srgb,var(--primary) 18%,transparent),transparent 34%),var(--background);font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:var(--text);min-height:100vh}.verify-shell{width:min(100%,760px);margin:0 auto;padding:18px 14px 50px}.verify-hero{position:relative;overflow:hidden;padding:34px 24px 74px;border-radius:28px 28px 0 0;background:linear-gradient(145deg,var(--primary),var(--accent));color:#fff;text-align:center;box-shadow:0 24px 60px rgba(15,35,64,.17)}.verify-hero:after{content:"";position:absolute;width:240px;height:240px;border:1px solid rgba(255,255,255,.15);border-radius:50%;right:-110px;top:-100px}.verify-logo{display:block;width:88px;height:88px;object-fit:contain;margin:0 auto 15px;padding:8px;border-radius:22px;background:#fff;box-shadow:0 14px 30px rgba(0,0,0,.2)}.verify-hero small{font-size:11px;letter-spacing:.15em;font-weight:900;color:#dbeafe}.verify-hero h1{font-size:clamp(25px,7vw,38px);line-height:1.08;margin:9px auto 8px}.verify-hero p{margin:0;color:#e7f3ff}.verify-content{position:relative;margin-top:-50px;padding:0 10px;display:grid;gap:16px}.verify-card{background:var(--surface);border:1px solid color-mix(in srgb,var(--primary) 13%,#fff);border-radius:22px;padding:21px;box-shadow:0 13px 35px rgba(15,35,64,.08)}.verify-result{text-align:center;padding:26px}.verify-seal{width:72px;height:72px;border-radius:50%;display:grid;place-items:center;margin:0 auto 13px;background:#dcfce7;color:var(--success);font-size:38px;font-weight:900;box-shadow:0 0 0 8px #f0fdf4}.verify-result h2{margin:7px 0;font-size:23px;color:var(--success)}.verify-result p{margin:7px auto;color:var(--muted);max-width:560px;line-height:1.6}.origin-pill{display:inline-flex;margin-top:8px;padding:7px 12px;border-radius:999px;background:color-mix(in srgb,var(--accent) 10%,#fff);color:var(--accent);font-weight:800}.punit-trust{display:grid;grid-template-columns:auto 1fr auto;align-items:center;gap:13px;margin-top:20px;padding:14px 15px;border:1px solid #bfdbfe;border-radius:17px;background:linear-gradient(135deg,#eff6ff,#f8fbff);text-align:left}.punit-trust-mark{width:43px;height:43px;display:grid;place-items:center;border-radius:13px;background:linear-gradient(145deg,#2563eb,#1d4ed8);color:#fff;font-size:22px;font-weight:950;box-shadow:0 8px 18px rgba(37,99,235,.23)}.punit-trust-copy{display:grid;gap:2px;min-width:0}.punit-trust-copy small{color:#1d4ed8;font-size:9px;font-weight:950;letter-spacing:.1em}.punit-trust-copy strong{color:#0f2e64;font-size:15px;line-height:1.25}.punit-trust-copy span{color:#64748b;font-size:11px}.punit-trust-link{color:#1d4ed8;font-size:12px;font-weight:900;text-decoration:none;white-space:nowrap}.section-title{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:15px}.section-title h2{font-size:19px;margin:0}.section-title span{font-size:10px;font-weight:900;letter-spacing:.1em;color:var(--accent);text-transform:uppercase}.field-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.field{padding:13px;border-radius:14px;background:color-mix(in srgb,var(--background) 75%,#fff);border:1px solid var(--line)}.field small{display:block;color:var(--muted);font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;margin-bottom:5px}.field strong{display:block;word-break:break-word}.company-grid{display:grid;gap:10px}.company-row{display:flex;gap:12px;align-items:flex-start;padding:10px 0;border-bottom:1px solid var(--line)}.company-row:last-child{border-bottom:0}.company-row span{min-width:92px;color:var(--muted);font-size:12px;font-weight:800;text-transform:uppercase}.company-row a{color:var(--primary);word-break:break-all}.complaint-form{display:grid;gap:13px}.complaint-form label{display:grid;gap:6px;color:var(--text);font-weight:800;font-size:13px}.complaint-form input,.complaint-form textarea{width:100%;border:1px solid #cbd8e8;border-radius:13px;padding:12px 13px;background:#fbfdff;color:var(--text);font:inherit}.complaint-form textarea{min-height:115px;resize:vertical}.required{color:#dc2626}.complaint-form button{border:0;border-radius:14px;padding:14px 18px;background:linear-gradient(135deg,var(--primary),var(--accent));color:#fff;font-weight:900;font-size:15px;cursor:pointer}.success-message{padding:13px;border-radius:13px;background:#dcfce7;color:#166534;font-weight:800}.error-message{padding:13px;border-radius:13px;background:#fee2e2;color:#991b1b}.honeypot{position:absolute!important;left:-10000px!important}.verify-footer{text-align:center;padding:22px;color:var(--muted);font-size:12px}.verify-footer a{color:#1d4ed8;font-weight:800;text-decoration:none}.verify-id{font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
        @media(max-width:560px){.verify-shell{padding:0 0 35px}.verify-hero{border-radius:0;padding-top:28px}.verify-content{padding:0 12px}.field-grid{grid-template-columns:1fr}.verify-card{border-radius:19px;padding:18px}.company-row{display:grid;gap:3px}.company-row span{min-width:0}.punit-trust{grid-template-columns:auto 1fr}.punit-trust-link{grid-column:2}}
    </style>
</head>
<body>
<main class="verify-shell">
    <header class="verify-hero">
        @if(!empty($company['logo_url']))<img class="verify-logo" src="{{ $company['logo_url'] }}" alt="{{ $company['name'] ?? 'Company' }} logo">@endif
        <small>SECURE PRODUCT VERIFICATION</small>
        @if($showCompanyName)<h1>{{ $company['name'] ?? 'Verified Manufacturer' }}</h1>@endif
        <p>Traceable product information captured when this label was printed.</p>
    </header>

    <div class="verify-content">
        @foreach($sections as $section)
            @if($section === 'authenticity')
                <section class="verify-card verify-result">
                    <div class="verify-seal">✓</div>
                    <h2>Authentic product record</h2>
                    <p>{{ $authenticity['statement'] ?? 'This product record was generated securely by the manufacturer.' }}</p>
                    @if(!empty($authenticity['made_in_text']))<span class="origin-pill">{{ $authenticity['made_in_text'] }}</span>@endif
                    <div class="punit-trust">
                        <div class="punit-trust-mark" aria-hidden="true">P</div>
                        <div class="punit-trust-copy">
                            <small>VERIFIED THROUGH PUNIT ERP</small>
                            <strong>Product record securely verified</strong>
                            <span>Real-time weighing &amp; labelling intelligence</span>
                        </div>
                        <a class="punit-trust-link" href="https://puniterp.com" rel="noopener">puniterp.com ↗</a>
                    </div>
                </section>
            @elseif($section === 'product')
                <section class="verify-card">
                    <div class="section-title"><h2>Product information</h2><span>Print-time snapshot</span></div>
                    <div class="field-grid">
                        @forelse(($product['fields'] ?? []) as $field)
                            <div class="field"><small>{{ $field['label'] }}</small><strong>{{ $field['value'] }}</strong></div>
                        @empty
                            <p>No public product fields were selected.</p>
                        @endforelse
                    </div>
                </section>
            @elseif($section === 'company')
                <section class="verify-card">
                    <div class="section-title"><h2>Manufacturer details</h2><span>Contact</span></div>
                    <div class="company-grid">
                        @foreach(['gst_number'=>'GST','phone'=>'Phone','email'=>'Email','contact_person'=>'Contact','address'=>'Address'] as $key=>$label)
                            @if(!empty($company[$key]))<div class="company-row"><span>{{ $label }}</span><strong>{{ $company[$key] }}</strong></div>@endif
                        @endforeach
                        @if(!empty($company['website']))<div class="company-row"><span>Website</span><a href="{{ $company['website'] }}" rel="nofollow noopener">{{ $company['website'] }}</a></div>@endif
                        @if(!empty($company['custom_text']))<div class="company-row"><span>Information</span><strong>{{ $company['custom_text'] }}</strong></div>@endif
                    </div>
                </section>
            @elseif($section === 'complaint' && ($complaintConfig['enabled'] ?? false))
                <section class="verify-card">
                    <div class="section-title"><h2>Report a product concern</h2><span>Customer care</span></div>
                    <p style="color:var(--muted);line-height:1.55">Send your concern directly to the manufacturer. Your product serial and barcode are attached automatically.</p>
                    @if(session('complaint_status'))<div class="success-message">{{ session('complaint_status') }}</div>@endif
                    @if($errors->any())<div class="error-message">{{ $errors->first() }}</div>@endif
                    <form class="complaint-form" method="POST" action="{{ route('verification.complaints.store', $token) }}" enctype="multipart/form-data">
                        @csrf
                        <label class="honeypot" aria-hidden="true">Website<input tabindex="-1" autocomplete="off" name="_company_website"></label>
                        @foreach($fieldLabels as $key => $label)
                            @php $options = $complaintFields[$key] ?? []; @endphp
                            @continue(!($options['enabled'] ?? false))
                            <label>{{ $label }} @if($options['required'] ?? false)<span class="required">*</span>@endif
                                @if($key === 'message')
                                    <textarea name="{{ $key }}" @required($options['required'] ?? false)>{{ old($key) }}</textarea>
                                @elseif($key === 'photo')
                                    <input type="file" name="{{ $key }}" accept="image/jpeg,image/png,image/webp" @required($options['required'] ?? false)>
                                @else
                                    <input type="{{ $key === 'email' ? 'email' : ($key === 'phone' ? 'tel' : 'text') }}" name="{{ $key }}" value="{{ old($key) }}" @required($options['required'] ?? false)>
                                @endif
                            </label>
                        @endforeach
                        <button type="submit">Submit complaint securely</button>
                    </form>
                </section>
            @endif
        @endforeach
    </div>
    <footer class="verify-footer">Verification record <span class="verify-id">{{ substr($verification->id, 0, 8) }}</span> · Secured by <a href="https://puniterp.com" rel="noopener">Punit ERP</a></footer>
</main>
</body>
</html>
