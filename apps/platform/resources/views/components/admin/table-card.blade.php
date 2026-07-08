@props(['title', 'rows', 'columns'])
<div class="card">
    <div class="card-head"><h2>{{ $title }}</h2></div>
    <div class="table-wrap">
        <table class="data-table">
            <thead>
                <tr>
                    @foreach ($columns as $column)
                        <th>{{ str($column)->replace('_', ' ')->title() }}</th>
                    @endforeach
                </tr>
            </thead>
            <tbody>
                @forelse ($rows as $row)
                    <tr>
                        @foreach ($columns as $column)
                            @php($value = data_get($row, $column, '-'))
                            <td>{{ str(is_array($value) ? json_encode($value) : (string) $value)->limit(80) }}</td>
                        @endforeach
                    </tr>
                @empty
                    <tr><td colspan="{{ count($columns) }}" class="empty">No records found.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
