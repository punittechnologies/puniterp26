@extends('layouts.admin')

@section('content')
    <section class="grid two">
        <form class="card form-grid" method="POST" action="{{ route('admin.account.password.update') }}">
            @csrf
            @method('PATCH')
            <div class="card-head full">
                <div>
                    <h2>Change Your Password</h2>
                    <p>Enter your current password before choosing a new one.</p>
                </div>
            </div>
            <label class="full">Current password
                <input type="password" name="current_password" required autocomplete="current-password">
            </label>
            <label>New password
                <input type="password" name="password" required minlength="8" autocomplete="new-password">
            </label>
            <label>Confirm new password
                <input type="password" name="password_confirmation" required minlength="8" autocomplete="new-password">
            </label>
            <small class="full">Use at least 8 characters containing both letters and numbers.</small>
            <button class="btn primary">Change Password</button>
        </form>

        <div class="card">
            <div class="card-head"><h2>Account Security</h2></div>
            <div class="stack-list">
                <div><b>Admin ID</b><span>{{ auth()->id() }}</span></div>
                <div><b>Login email</b><span>{{ auth()->user()?->email }}</span></div>
                <div><b>Last password update</b><span>{{ auth()->user()?->password_changed_at?->format('d M Y H:i') ?? 'Not recorded yet' }}</span></div>
                <div><b>Privacy</b><span>Your password is encrypted and cannot be displayed to anyone, including the superadmin.</span></div>
            </div>
        </div>
    </section>
@endsection
