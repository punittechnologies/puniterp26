@extends('layouts.admin')

@section('content')
    <section class="grid two">
        <div class="card">
            <div class="card-head">
                <h2>{{ $editing ? 'Edit Customer' : 'Create Customer' }}</h2>
                @if($editing)
                    <a class="btn" href="{{ route('admin.customers') }}">New Customer</a>
                @endif
            </div>
            <form method="POST" action="{{ route('admin.customers.save', $editing) }}" class="form-grid">
                @csrf
                <label>Name<input name="name" value="{{ old('name', $editing?->name) }}" required></label>
                <label>Code<input name="code" value="{{ old('code', $editing?->code) }}"></label>
                <label>Contact<input name="contact_person" value="{{ old('contact_person', $editing?->contact_person) }}"></label>
                <label>Phone<input name="phone" value="{{ old('phone', $editing?->phone) }}"></label>
                <label>Email<input name="email" type="email" value="{{ old('email', $editing?->email) }}"></label>
                <label>GST / Tax<input name="tax_number" value="{{ old('tax_number', $editing?->tax_number) }}"></label>
                <label class="full">Billing address<textarea name="billing_address">{{ old('billing_address', $editing?->billing_address) }}</textarea></label>
                <label class="full">Shipping address<textarea name="shipping_address">{{ old('shipping_address', $editing?->shipping_address) }}</textarea></label>
                <label class="check"><input type="checkbox" name="is_active" value="1" @checked(old('is_active', $editing?->is_active ?? true))> Active</label>
                <button class="btn primary">{{ $editing ? 'Update customer' : 'Save customer' }}</button>
            </form>
        </div>
        <div class="card">
            <div class="card-head"><h2>Customer List</h2></div>
            <form method="GET" class="filter-bar compact"><input name="search" value="{{ request('search') }}" placeholder="Search customers"><button class="btn">Search</button></form>
            <div class="table-wrap"><table class="data-table"><thead><tr><th>Name</th><th>Code</th><th>Phone</th><th>Status</th><th>Dispatches</th><th>Actions</th></tr></thead><tbody>
                @foreach($rows as $row)
                    <tr>
                        <td>{{ $row->name }}</td>
                        <td>{{ $row->code ?? '-' }}</td>
                        <td>{{ $row->phone ?? '-' }}</td>
                        <td><span class="status-pill">{{ $row->is_active ? 'active' : 'inactive' }}</span></td>
                        <td>{{ \App\Models\Dispatch::query()->where('customer_id', $row->id)->count() }}</td>
                        <td class="actions">
                            <a class="btn small" href="{{ route('admin.customers', ['edit' => $row->id]) }}">Edit</a>
                            <form method="POST" action="{{ route('admin.customers.delete', $row) }}" class="inline-form" onsubmit="return confirm('Delete this customer? Existing dispatch history will remain.');">
                                @csrf
                                @method('DELETE')
                                <button class="btn small destructive">Delete</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
            </tbody></table></div>
            {{ $rows->links() }}
        </div>
    </section>
@endsection
