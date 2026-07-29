@extends('layouts.admin')

@section('content')
    <section class="card">
        <div class="card-head">
            <div>
                <h2>Company Admin Directory</h2>
                <p>View admin IDs and reset forgotten passwords. Existing passwords cannot be viewed.</p>
            </div>
        </div>
        <form method="GET" class="filter-bar">
            <label>Search admin
                <input name="search" value="{{ $search }}" placeholder="ID, company, name, email or phone">
            </label>
            <button class="btn primary">Search</button>
            @if ($search !== '')
                <a class="btn" href="{{ route('admin.superadmin.admins') }}">Clear</a>
            @endif
        </form>
    </section>

    <section class="card">
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Admin ID</th>
                        <th>Company</th>
                        <th>Admin</th>
                        <th>Login</th>
                        <th>Password updated</th>
                        <th>Status</th>
                        <th>Reset password</th>
                    </tr>
                </thead>
                <tbody>
                @forelse ($admins as $admin)
                    <tr>
                        <td><code>{{ $admin->id }}</code></td>
                        <td>
                            <strong>{{ $admin->tenant?->name ?? 'System' }}</strong>
                            <small>{{ $admin->tenant?->code }}</small>
                        </td>
                        <td>
                            <strong>{{ $admin->name }}</strong>
                            <small>{{ $admin->roles->pluck('name')->join(', ') ?: 'No role' }}</small>
                        </td>
                        <td>
                            {{ $admin->email }}
                            <small>{{ $admin->phone ?: '-' }}</small>
                        </td>
                        <td>{{ $admin->password_changed_at?->format('d M Y H:i') ?? 'Not recorded' }}</td>
                        <td><span class="status-pill {{ $admin->is_active ? 'success' : 'warning' }}">{{ $admin->is_active ? 'Active' : 'Disabled' }}</span></td>
                        <td>
                            <form method="POST" action="{{ route('admin.superadmin.admins.password', $admin) }}" class="form-grid">
                                @csrf
                                @method('PATCH')
                                <input type="password" name="password" required minlength="8" placeholder="New temporary password" autocomplete="new-password">
                                <input type="password" name="password_confirmation" required minlength="8" placeholder="Confirm password" autocomplete="new-password">
                                <button class="btn primary">Reset</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="empty">No company admins found.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        {{ $admins->links() }}
    </section>
@endsection
