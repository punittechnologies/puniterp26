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
                <label>
                    App role/access
                    <select name="role_ids[]" multiple required>
                        @foreach ($roles as $role)
                            <option value="{{ $role->id }}" @selected(collect(old('role_ids', []))->contains($role->id))>
                                {{ $role->name }}
                            </option>
                        @endforeach
                    </select>
                    <small>Role permissions decide weighing, dispatch, reports and sync access.</small>
                </label>
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
                <p>{{ $users->total() }} app-only logins configured.</p>
            </div>
        </div>
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>App user ID</th>
                        <th>Email</th>
                        <th>Roles</th>
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
                            <td>{{ $user->roles->pluck('name')->join(', ') ?: '-' }}</td>
                            <td>
                                <span class="status-pill {{ $user->is_active ? 'success' : 'muted' }}">
                                    {{ $user->is_active ? 'Active' : 'Inactive' }}
                                </span>
                            </td>
                            <td>{{ optional($user->updated_at)->format('d M Y H:i') }}</td>
                            <td>
                                <form method="POST" action="{{ route('admin.app-users.status', $user) }}">
                                    @csrf
                                    @method('PATCH')
                                    <button class="btn">{{ $user->is_active ? 'Deactivate' : 'Activate' }}</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7">No app users yet. Create one above for tablet/mobile login.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $users->links() }}
    </section>
@endsection
