@php
    $user = auth()->user();
    $tenant = $user?->tenant;
    $nav = [
        'Top' => [
            ['Dashboard', route('admin.dashboard'), 'dashboard.view'],
            ['Products', route('admin.products'), 'products.view'],
            ['Product Details', route('admin.product-details'), 'products.view'],
            ['Inward Report', route('admin.inward-report'), 'reports.view'],
            ['Dispatch Report / Packing List', route('admin.dispatch-report'), 'reports.view'],
        ],
        'Operations' => [
            ['Production Entry', route('admin.production'), 'production.capture'],
            ['Inventory', route('admin.inventory'), 'inventory.view'],
            ['Customers', route('admin.customers'), 'customers.manage'],
            ['Dispatch Entry', route('admin.dispatch'), 'dispatch.confirm'],
            ['Sync Status', route('admin.sync'), 'devices.configure'],
        ],
        'Other Reports' => [
            ['Inventory Report', route('admin.reports', 'inventory'), 'reports.view'],
            ['Inventory Ledger', route('admin.reports', 'inventory-ledger'), 'reports.view'],
            ['Audit Report', route('admin.reports', 'audit'), 'reports.view'],
        ],
        'Administration' => [
            ['Superadmin Onboarding', route('admin.superadmin.onboarding'), 'superadmin.only'],
            ['App Users', route('admin.app-users'), 'users.manage'],
            ['Users', route('admin.resource', 'users'), 'users.manage'],
            ['Roles', route('admin.resource', 'roles'), 'roles.manage'],
            ['Report Customiser', route('admin.tenant-settings'), 'configuration.manage'],
            ['Audit Logs', route('admin.audit'), 'configuration.history.view'],
        ],
    ];
@endphp
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin' }} | Punit ERP</title>
    <meta name="description" content="Punit ERP">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @if (! app()->environment('testing'))
        @vite(['resources/css/app.css', 'resources/js/app.js'])
        @php
            $manifestPath = public_path('build/manifest.json');
            $manifest = is_file($manifestPath) ? json_decode(file_get_contents($manifestPath), true) : [];
            $cssAsset = $manifest['resources/css/app.css']['file'] ?? null;
            $jsAsset = $manifest['resources/js/app.js']['file'] ?? null;
        @endphp
        @if ($cssAsset)
            <link rel="stylesheet" href="{{ asset('build/'.$cssAsset) }}">
        @endif
        @if ($jsAsset)
            <script type="module" src="{{ asset('build/'.$jsAsset) }}"></script>
        @endif
    @endif
    @livewireStyles
</head>
<body class="admin-body">
    <div class="admin-shell">
        <aside class="admin-sidebar">
            <a href="{{ route('admin.dashboard') }}" class="brand">
                <img src="{{ asset('brand/punit-logo.png') }}" alt="Punit Instrument" class="brand-logo">
                <span>
                    <strong>Punit ERP</strong>
                    <small>{{ $tenant?->name ?? 'Weighing Automation and Softwares' }}</small>
                </span>
            </a>
            <nav class="nav-groups">
                @foreach ($nav as $group => $items)
                    <section>
                        <p>{{ $group }}</p>
                        @foreach ($items as [$label, $href, $permission])
                            @if (! $permission || ($permission === 'superadmin.only' ? $user?->isSuperAdmin() : $user?->hasPermission($permission)))
                                <a href="{{ $href }}" @class(['active' => request()->fullUrlIs($href) || request()->is(trim(parse_url($href, PHP_URL_PATH), '/').'*')])>
                                    {{ $label }}
                                </a>
                            @endif
                        @endforeach
                    </section>
                @endforeach
            </nav>
        </aside>

        <div class="admin-main">
            <header class="admin-header">
                <div>
                    <p class="eyebrow">Punit ERP</p>
                    <h1>{{ $title ?? 'Admin Panel' }}</h1>
                </div>
                <div class="header-actions">
                    <form method="GET" action="{{ route('admin.production') }}" class="global-search">
                        <input name="search" placeholder="Search serial or barcode">
                        <span>⌘K</span>
                    </form>
                    <span class="status-pill success">Online</span>
                    <span class="avatar">{{ strtoupper(substr($user?->name ?? 'A', 0, 1)) }}</span>
                    <form method="POST" action="{{ route('logout') }}">@csrf<button class="btn">Logout</button></form>
                </div>
            </header>

            @if (session('status'))
                <div class="notice success">{{ session('status') }}</div>
            @endif
            @if ($errors->any())
                <div class="notice error">{{ $errors->first() }}</div>
            @endif

            <main class="admin-content">
                @yield('content')
            </main>
        </div>
    </div>
    @livewireScripts
</body>
</html>
