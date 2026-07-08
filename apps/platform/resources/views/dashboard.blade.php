<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Punit ERP</title>
    <meta name="description" content="Punit ERP">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    @if (! app()->environment('testing'))
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @endif
    @livewireStyles
</head>
<body class="bg-slate-50 text-slate-950 antialiased">
    <main class="mx-auto flex min-h-screen max-w-6xl flex-col justify-center px-6 py-10">
        <section class="rounded-lg border border-blue-100 bg-white p-8 shadow-sm">
            <p class="text-sm font-semibold uppercase tracking-wide text-blue-700">Phase 1 Foundation</p>
            <h1 class="mt-3 text-4xl font-bold">Punit ERP</h1>
            <p class="mt-4 max-w-3xl text-lg text-slate-600">
                Laravel web admin and REST API foundation for tenant-based weighing, label printing,
                inventory and dispatch workflows.
            </p>

            <div class="mt-8 grid gap-4 md:grid-cols-3">
                <div class="rounded-md border border-slate-200 p-5">
                    <h2 class="font-semibold text-slate-900">Hostinger Ready</h2>
                    <p class="mt-2 text-sm text-slate-600">MySQL, database sessions, database cache and database queues.</p>
                </div>
                <div class="rounded-md border border-slate-200 p-5">
                    <h2 class="font-semibold text-slate-900">Tenant Isolated</h2>
                    <p class="mt-2 text-sm text-slate-600">Tenant context, roles, permissions and Sanctum API tokens.</p>
                </div>
                <div class="rounded-md border border-slate-200 p-5">
                    <h2 class="font-semibold text-slate-900">Extension Points</h2>
                    <p class="mt-2 text-sm text-slate-600">Device adapters, sync queue, configuration versions and AI provider interface.</p>
                </div>
            </div>
        </section>
    </main>
    @livewireScripts
</body>
</html>
