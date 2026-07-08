<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Onboarding | Punit ERP</title>
    <meta name="description" content="Punit ERP">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="auth-body">
    <main class="auth-card wide">
        <div class="brand auth-brand">
            <img src="{{ asset('brand/punit-logo.png') }}" alt="Punit Instrument" class="brand-logo">
            <span><strong>Punit ERP</strong><small>Company onboarding</small></span>
        </div>
        <h1>Create company admin</h1>
        <p class="muted">Enter the phone number approved by Punit, then set your company and admin login.</p>
        @if ($errors->any())
            <div class="notice error">{{ $errors->first() }}</div>
        @endif
        <form method="POST" action="{{ route('onboarding.store') }}" class="form-grid">
            @csrf
            <label>Approved phone <input name="phone" value="{{ old('phone') }}" required></label>
            <label>Company name <input name="company_name" value="{{ old('company_name') }}" required></label>
            <label>Admin name <input name="name" value="{{ old('name') }}" required></label>
            <label>Email <input type="email" name="email" value="{{ old('email') }}" required></label>
            <label>Password <input type="password" name="password" required></label>
            <label>Confirm password <input type="password" name="password_confirmation" required></label>
            <button class="btn primary">Create account</button>
            <a class="btn" href="{{ route('login') }}">Back to login</a>
        </form>
    </main>
</body>
</html>
