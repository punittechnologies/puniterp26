<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>PUNIT ERP | Weighing and Labelling</title>
    <meta name="description" content="PUNIT ERP weighing, inventory and intelligent label printing.">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="public-app-body">
    <main class="public-app-card">
        <div class="brand public-app-brand">
            <img src="{{ asset('brand/punit-logo.png') }}" alt="Punit Instrument" class="brand-logo">
            <span><strong>PUNIT ERP</strong><small>Weighing Automation and Softwares</small></span>
        </div>

        <div class="public-app-badge">Official Android application</div>
        <h1>Real-time weighing and intelligent label printing</h1>
        <p>Connect your weighing scale and label printer, capture production entries and use label templates managed from your PUNIT ERP web panel.</p>

        <div class="public-app-actions">
            <a class="public-app-download" href="{{ route('app.download.latest') }}" download>
                <span aria-hidden="true">↓</span>
                <span><strong>Download Latest PUNIT ERP App</strong><small>Android APK · Version 1.1.16</small></span>
            </a>
            <a class="public-app-login" href="{{ route('login') }}">Open ERP Login</a>
        </div>

        <div class="public-app-trust">
            <span>✓ Production signed</span>
            <span>✓ Secure download</span>
            <span>✓ Official PUNIT ERP release</span>
        </div>
    </main>
</body>
</html>
