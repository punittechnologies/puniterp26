@extends('layouts.admin')

@section('content')
    <div class="grid two-col">
        <section class="panel">
            <div class="panel-header">
                <div>
                    <h2>Create App Login</h2>
                    <p>These credentials work only in the Punit ERP app. They cannot open the Laravel web panel.</p>
                </div>
            </div>

            <form method="POST" action="{{ route('admin.app-users.store') }}" class="form-grid">
                @csrf
                <label>
                    Login type
                    <select name="access_type" required>
                        <option value="app" @selected(old('access_type', 'app') === 'app')>App only</option>
                        <option value="web" @selected(old('access_type') === 'web')>Web panel</option>
                    </select>
                    <small>App only works in the Punit ERP app. Web panel can login at the website.</small>
                </label>
                <label>
                    Operator name
                    <input name="name" value="{{ old('name') }}" placeholder="Example: Dispatch Operator 1" required>
                </label>
                <label>
                    App user ID
                    <input name="app_username" value="{{ old('app_username') }}" placeholder="Example: dispatch01" required>
                    <small>Use letters, numbers, dash or underscore. This is what the operator enters in the app.</small>
                </label>
                <label>
                    Email
                    <input type="email" name="email" value="{{ old('email') }}" placeholder="operator@company.com" required>
                </label>
                <label>
                    Password
                    <input type="password" name="password" required>
                </label>
                <label>
                    Confirm password
                    <input type="password" name="password_confirmation" required>
                </label>
                <div class="access-picker full">
                    @php
                        $accessIcons = [
                            'products' => 'P',
                            'production' => 'IN',
                            'dispatch' => 'D',
                            'customers' => 'C',
                            'inventory' => 'I',
                            'reports' => 'R',
                            'users_roles' => 'U',
                            'settings' => 'S',
                        ];
                        $appOnlyModules = ['production', 'dispatch'];
                    @endphp
                    <div>
                        <strong>Access allowed</strong>
                        <small>Select only the operations this user can use.</small>
                    </div>
                    <div class="choice-stack">
                        @foreach ($accessOptions as $key => $option)
                            <label class="choice-row" data-access-module="{{ $key }}" data-app-only="{{ in_array($key, $appOnlyModules, true) ? 'true' : 'false' }}">
                                <input type="checkbox" name="access_modules[]" value="{{ $key }}" @checked(collect(old('access_modules', []))->contains($key))>
                                <span class="choice-icon">{{ $accessIcons[$key] ?? '-' }}</span>
                                <span>{{ $option['label'] }}</span>
                            </label>
                        @endforeach
                    </div>
                </div>
                <div class="form-actions">
                    <button class="btn primary">Create App User</button>
                </div>
            </form>
        </section>

        <section class="panel">
            <div class="panel-header">
                <div>
                    <h2>How App Login Works</h2>
                    <p>Give the operator only the app user ID/email and password. Keep web admin credentials private.</p>
                </div>
            </div>
            <div class="info-list">
                <div><strong>Web access:</strong> blocked for app-only users.</div>
                <div><strong>App access:</strong> allowed only when the role has tablet app login permission.</div>
                <div><strong>Tenant:</strong> data syncs only inside this company account.</div>
                <div><strong>Disable:</strong> deactivate an operator anytime to stop new app logins.</div>
            </div>
        </section>
    </div>

    <section class="panel mt">
        <div class="panel-header">
            <div>
                <h2>App Users</h2>
                <p>{{ $users->total() }} app/web logins configured.</p>
            </div>
        </div>
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>App user ID</th>
                        <th>Email</th>
                        <th>Type</th>
                        <th>Access</th>
                        <th>Status</th>
                        <th>Updated</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($users as $user)
                        <tr>
                            <td>{{ $user->name }}</td>
                            <td><strong>{{ $user->app_username }}</strong></td>
                            <td>{{ $user->email }}</td>
                            <td>{{ $user->app_only ? 'App' : 'Web' }}</td>
                            <td>{{ $user->roles->flatMap->permissions->pluck('name')->unique()->join(', ') ?: '-' }}</td>
                            <td>
                                <span class="status-pill {{ $user->is_active ? 'success' : 'muted' }}">
                                    {{ $user->is_active ? 'Active' : 'Inactive' }}
                                </span>
                            </td>
                            <td>{{ optional($user->updated_at)->format('d M Y H:i') }}</td>
                            <td>
                                <form method="POST" action="{{ route('admin.app-users.status', $user) }}" class="inline-form">
                                    @csrf
                                    @method('PATCH')
                                    <button class="btn">{{ $user->is_active ? 'Deactivate' : 'Activate' }}</button>
                                </form>
                                <form method="POST" action="{{ route('admin.app-users.destroy', $user) }}" class="inline-form" onsubmit="return confirm('Delete this login? Email and app ID can be reused after delete.');">
                                    @csrf
                                    @method('DELETE')
                                    <button class="btn destructive">Delete</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8">No app users yet. Create one above for tablet/mobile login.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $users->links() }}
    </section>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const loginType = document.querySelector('select[name="access_type"]');
            const rows = Array.from(document.querySelectorAll('[data-access-module]'));
            const syncAccessRows = () => {
                const isApp = loginType?.value === 'app';
                rows.forEach((row) => {
                    const allowedForApp = row.dataset.appOnly === 'true';
                    row.classList.toggle('is-hidden', isApp && !allowedForApp);
                    const checkbox = row.querySelector('input[type="checkbox"]');
                    if (checkbox && isApp && !allowedForApp) {
                        checkbox.checked = false;
                    }
                });
            };

            loginType?.addEventListener('change', syncAccessRows);
            syncAccessRows();
        });
    </script>
@endsection
