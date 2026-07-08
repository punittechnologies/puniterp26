@extends('layouts.admin')

@section('content')
    <form class="filter-bar" method="GET">
        <label>Action <input name="action" value="{{ request('action') }}" placeholder="created, updated, reversed"></label>
        <button class="btn primary">Filter</button>
        <a class="btn" href="{{ route('admin.exports', ['audit', 'csv']) }}">Export CSV</a>
    </form>
    <div class="card">
        <div class="card-head"><h2>Audit Trail</h2></div>
        <div class="table-wrap">
            <table class="data-table">
                <thead><tr><th>Action</th><th>Entity</th><th>Before</th><th>After</th><th>Meta</th><th>Date</th></tr></thead>
                <tbody>
                    @foreach($rows as $row)
                        <tr>
                            <td>{{ $row->action }}</td>
                            <td>{{ class_basename($row->auditable_type) }}<br><code>{{ $row->auditable_id }}</code></td>
                            <td><pre>{{ json_encode($row->old_values, JSON_PRETTY_PRINT) }}</pre></td>
                            <td><pre>{{ json_encode($row->new_values, JSON_PRETTY_PRINT) }}</pre></td>
                            <td><pre>{{ json_encode($row->metadata, JSON_PRETTY_PRINT) }}</pre></td>
                            <td>{{ $row->created_at->format('d M Y H:i') }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        {{ $rows->links() }}
    </div>
@endsection
