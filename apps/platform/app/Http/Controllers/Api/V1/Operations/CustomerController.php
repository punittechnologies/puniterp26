<?php

namespace App\Http\Controllers\Api\V1\Operations;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Validation\Rule;

class CustomerController extends Controller
{
    public function index(TenantContext $tenantContext)
    {
        $customers = Customer::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->when(request('search'), function ($query, $search): void {
                $query->where(fn ($query) => $query
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%"));
            })
            ->where('is_active', request()->boolean('active', true))
            ->orderBy('name')
            ->paginate((int) request('per_page', 25));

        return JsonResource::collection($customers);
    }

    public function store(Request $request, TenantContext $tenantContext): JsonResponse
    {
        $data = $this->validated($request);
        $customer = Customer::query()->create([
            ...$data,
            'tenant_id' => $tenantContext->tenantId(),
            'created_by' => $request->user()->id,
        ]);

        return response()->json(['data' => $customer], 201);
    }

    public function show(Customer $customer, TenantContext $tenantContext): JsonResponse
    {
        $this->ensureTenant($customer, $tenantContext);

        return response()->json(['data' => $customer]);
    }

    public function update(Request $request, Customer $customer, TenantContext $tenantContext): JsonResponse
    {
        $this->ensureTenant($customer, $tenantContext);
        $customer->fill([
            ...$this->validated($request, $customer->id),
            'updated_by' => $request->user()->id,
        ])->save();

        return response()->json(['data' => $customer->fresh()]);
    }

    private function validated(Request $request, ?string $ignoreId = null): array
    {
        $tenantId = app(TenantContext::class)->tenantId();
        $codeRule = Rule::unique('customers', 'code')
            ->where(fn ($query) => $query->where('tenant_id', $tenantId));
        if ($ignoreId) {
            $codeRule->ignore($ignoreId);
        }

        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'code' => ['nullable', 'string', 'max:100', $codeRule],
            'contact_person' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'email' => ['nullable', 'email', 'max:255'],
            'billing_address' => ['nullable', 'string'],
            'shipping_address' => ['nullable', 'string'],
            'tax_number' => ['nullable', 'string', 'max:100'],
            'is_active' => ['sometimes', 'boolean'],
            'metadata' => ['nullable', 'array'],
        ]);
    }

    private function ensureTenant(Customer $customer, TenantContext $tenantContext): void
    {
        abort_unless($customer->tenant_id === $tenantContext->tenantId(), 404);
    }
}
