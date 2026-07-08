@extends('layouts.admin')

@section('content')
    <div class="card">
        <div class="card-head">
            <h2>{{ $title }}</h2>
            <span class="status-pill">{{ $rows->total() }} records</span>
        </div>
        <div class="table-wrap">
            <table class="data-table">
                <thead>
                    <tr>
                        @foreach($columns as $column)<th>{{ str($column)->replace('_', ' ')->title() }}</th>@endforeach
                        @if ($section === 'users')
                            <th>Action</th>
                        @endif
                    </tr>
                </thead>
                <tbody>
                    @forelse($rows as $row)
                        <tr>
                            @foreach($columns as $column)
                                <td>{{ str((string) data_get($row, $column, '-'))->limit(120) }}</td>
                            @endforeach
                            @if ($section === 'users')
                                <td>
                                    @if ($row->id !== auth()->id())
                                        <form method="POST" action="{{ route('admin.users.destroy', $row) }}" onsubmit="return confirm('Delete this user? This will block login and free the email for reuse.');">
                                            @csrf
                                            @method('DELETE')
                                            <button class="btn danger">Delete</button>
                                        </form>
                                    @else
                                        <span class="muted">Current user</span>
                                    @endif
                                </td>
                            @endif
                        </tr>
                    @empty
                        <tr><td colspan="{{ count($columns) + ($section === 'users' ? 1 : 0) }}" class="empty">No records yet.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        {{ $rows->links() }}
    </div>
@endsection
