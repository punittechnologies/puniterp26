@extends('layouts.admin')

@section('content')
<style>
    .complaint-head{display:flex;justify-content:space-between;gap:20px;align-items:center;margin-bottom:20px}.complaint-head h2{margin:0 0 5px;color:#10233f}.complaint-head p{margin:0;color:#64748b}.complaint-list{display:grid;gap:14px}.complaint-card{display:grid;grid-template-columns:minmax(180px,.65fr) minmax(260px,1.5fr) minmax(180px,.55fr);gap:18px;padding:20px;border:1px solid #dbe7f5;border-radius:20px;background:#fff;box-shadow:0 10px 30px rgba(15,35,64,.05)}.complaint-meta{display:grid;gap:6px}.complaint-meta small{color:#64748b;text-transform:uppercase;font-weight:800;font-size:10px;letter-spacing:.06em}.complaint-meta strong{color:#10233f;word-break:break-word}.complaint-message{color:#334155;line-height:1.55;white-space:pre-wrap}.complaint-actions{display:grid;align-content:start;gap:10px}.complaint-actions select{width:100%;padding:10px;border:1px solid #cbd8e8;border-radius:11px}.complaint-actions button,.photo-link{display:block;text-align:center;border:0;border-radius:11px;padding:10px;background:#1d4ed8;color:#fff;text-decoration:none;font-weight:800;cursor:pointer}.status-dot{display:inline-flex;padding:6px 10px;border-radius:999px;background:#eff6ff;color:#1d4ed8;font-size:11px;font-weight:900;text-transform:uppercase}.empty-inbox{padding:50px;text-align:center;border:1px dashed #bfd0e4;border-radius:20px;background:#fff;color:#64748b}@media(max-width:900px){.complaint-card{grid-template-columns:1fr}.complaint-head{align-items:flex-start;flex-direction:column}}
</style>
<section class="complaint-head">
    <div><h2>QR Complaint Inbox</h2><p>Customer concerns submitted from secure product verification pages.</p></div>
    <span class="status-dot">{{ $complaints->total() }} total</span>
</section>
<div class="complaint-list">
    @forelse($complaints as $complaint)
        <article class="complaint-card">
            <div class="complaint-meta">
                <small>Customer</small><strong>{{ $complaint->customer_name ?: $complaint->customer_company_name ?: 'Not provided' }}</strong>
                @if($complaint->phone)<small>Phone</small><strong>{{ $complaint->phone }}</strong>@endif
                @if($complaint->email)<small>Email</small><strong>{{ $complaint->email }}</strong>@endif
                @if($complaint->order_reference)<small>Reference</small><strong>{{ $complaint->order_reference }}</strong>@endif
            </div>
            <div>
                <div class="complaint-meta" style="margin-bottom:12px">
                    <small>Product record</small>
                    <strong>Serial: {{ $complaint->verification?->serial_number ?: '-' }} · Barcode: {{ $complaint->verification?->barcode_value ?: '-' }}</strong>
                    <small>Received {{ $complaint->created_at?->format('d M Y, h:i A') }}</small>
                </div>
                <div class="complaint-message">{{ $complaint->message ?: 'No message provided.' }}</div>
            </div>
            <div class="complaint-actions">
                <span class="status-dot">{{ str_replace('_', ' ', $complaint->status) }}</span>
                <form method="POST" action="{{ route('admin.qr-complaints.update', $complaint) }}">
                    @csrf @method('PATCH')
                    <select name="status">
                        <option value="new" @selected($complaint->status === 'new')>New</option>
                        <option value="in_progress" @selected($complaint->status === 'in_progress')>In Progress</option>
                        <option value="resolved" @selected($complaint->status === 'resolved')>Resolved</option>
                    </select>
                    <button type="submit" style="margin-top:8px;width:100%">Update status</button>
                </form>
                @if($complaint->photo_path)<a class="photo-link" href="{{ route('admin.qr-complaints.photo', $complaint) }}" target="_blank">View photo</a>@endif
            </div>
        </article>
    @empty
        <div class="empty-inbox"><strong>No complaints yet.</strong><br>New QR submissions will appear here.</div>
    @endforelse
</div>
<div style="margin-top:18px">{{ $complaints->links() }}</div>
@endsection
