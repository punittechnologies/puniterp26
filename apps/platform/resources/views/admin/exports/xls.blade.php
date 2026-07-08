<table>
    <thead>
        <tr>
            <th colspan="{{ count($columns) }}">{{ strtoupper($report) }} REPORT</th>
        </tr>
        <tr>
            <th colspan="{{ count($columns) }}">Generated {{ now()->format('Y-m-d H:i') }}</th>
        </tr>
        <tr>
            @foreach ($columns as $column)
                <th>{{ str($column)->replace('_', ' ')->title() }}</th>
            @endforeach
        </tr>
    </thead>
    <tbody>
        @foreach ($rows as $row)
            <tr>
                @foreach ($columns as $column)
                    @php($value = data_get($row, $column))
                    <td>{{ is_array($value) ? json_encode($value) : $value }}</td>
                @endforeach
            </tr>
        @endforeach
    </tbody>
</table>
