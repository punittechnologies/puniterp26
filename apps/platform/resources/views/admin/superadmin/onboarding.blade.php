@extends('layouts.admin')

@section('content')
    <section class="grid two">
        <form class="card form-grid" method="POST" action="{{ route('admin.superadmin.onboarding.save') }}">
            @csrf
            <div class="card-head full">
                <div>
                    <h2>Approve New Customer</h2>
                    <p>Add a customer phone number. They can then create their own company admin login.</p>
                </div>
            </div>
            <label>Mobile number <input name="phone" required placeholder="9737599004"></label>
            <label>Company name optional <input name="company_name" placeholder="Customer company"></label>
            <label>Allowed admins <input type="number" min="1" max="50" name="admin_limit" value="1"></label>
            <label>Validity date <input type="date" name="valid_until"></label>
            <button class="btn primary">Create onboarding access</button>
        </form>

        <div class="card">
            <div class="card-head"><h2>How it works</h2></div>
            <div class="stack-list">
                <div><b>1. Superadmin approves phone</b><span>Only approved numbers can onboard.</span></div>
                <div><b>2. Customer opens onboarding</b><span>They enter company, email and password.</span></div>
                <div><b>3. App login works</b><span>The same email or phone and password works in Flutter.</span></div>
            </div>
        </div>
    </section>

    <section class="card">
        <div class="card-head"><h2>Onboarding Access List</h2></div>
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Phone</th><th>Company</th><th>Admins</th><th>Valid until</th><th>Status</th><th>Created</th></tr></thead>
                <tbody>
                @forelse($invites as $invite)
                    <tr>
                        <td>{{ $invite->phone }}</td>
                        <td>{{ $invite->company_name ?? '-' }}</td>
                        <td>{{ $invite->admin_limit }}</td>
                        <td>{{ $invite->valid_until?->format('d M Y') ?? 'No expiry' }}</td>
                        <td><span class="status-pill {{ $invite->status === 'pending' ? 'warning' : 'success' }}">{{ $invite->status }}</span></td>
                        <td>{{ $invite->created_at?->format('d M Y H:i') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="empty">No onboarding access created yet.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        {{ $invites->links() }}
    </section>
@endsection
