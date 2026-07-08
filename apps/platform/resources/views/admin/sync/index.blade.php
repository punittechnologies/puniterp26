@extends('layouts.admin')

@section('content')
    <section class="metric-grid">
        @foreach(['pending', 'failed', 'synced', 'processed'] as $status)
            <x-admin.metric :label="str($status)->title()" :value="$summary[$status] ?? 0" :tone="$status === 'failed' ? 'error' : ($status === 'pending' ? 'warning' : 'default')" />
        @endforeach
    </section>
    <x-admin.table-card title="Sync Queue" :rows="$rows" :columns="['entity_type', 'operation', 'idempotency_key', 'status', 'attempt_count', 'last_error', 'created_at']" />
    {{ $rows->links() }}
@endsection
