<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login | Punit ERP</title>
    <meta name="description" content="Punit ERP">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="auth-body">
    <main class="auth-card">
        <div class="brand auth-brand">
            <img src="{{ asset('brand/punit-logo.png') }}" alt="Punit Instrument" class="brand-logo">
            <span><strong>Punit ERP</strong><small>Weighing Automation and Softwares</small></span>
        </div>
        <h1>Login</h1>
        <p class="muted">Use your email or registered phone number.</p>
        @if ($errors->any())
            <div class="notice error">{{ $errors->first() }}</div>
        @endif
        <form method="POST" action="{{ route('login.store') }}" class="form-grid single">
            @csrf
            <label>Email or phone <input name="login" value="{{ old('login') }}" required autofocus></label>
            <label>Password <input type="password" name="password" required></label>
            <button class="btn primary">Login</button>
        </form>
        <p class="muted auth-foot">New customer? <a href="{{ route('onboarding.start') }}">Complete onboarding with your approved phone number</a>.</p>
        <a class="auth-app-download" href="{{ route('app.download.latest') }}" download>
            <span aria-hidden="true">↓</span>
            <span><strong>Download Latest PUNIT ERP App</strong><small>Android APK · Version {{ config('punit.android_app.version') }} (Build {{ config('punit.android_app.build') }})</small></span>
        </a>
    </main>
</body>
</html>
