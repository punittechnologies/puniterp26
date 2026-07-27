<?php

namespace App\Http\Controllers\Web;

use App\Domain\Operations\Services\OperationsSyncService;
use App\Http\Controllers\Controller;
use App\Http\Controllers\Web\Concerns\AdminDataExchange;
use App\Models\AuditLog;
use App\Models\BarcodeRecord;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Dispatch;
use App\Models\DispatchItem;
use App\Models\InventoryTransaction;
use App\Models\InwardSession;
use App\Models\Labeling\LabelTemplate;
use App\Models\Permission;
use App\Models\ProductConfiguration\DynamicFieldDefinition;
use App\Models\ProductConfiguration\Product;
use App\Models\ProductConfiguration\ProductAttribute;
use App\Models\ProductConfiguration\ProductCategory;
use App\Models\ProductConfiguration\ProductDeviceAssignment;
use App\Models\ProductConfiguration\ProductVariant;
use App\Models\ProductionTransaction;
use App\Models\Role;
use App\Models\ScaleProfile;
use App\Models\SyncQueueEntry;
use App\Models\TenantOnboardingInvite;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminPanelController extends Controller
{
    use AdminDataExchange;

    public function dashboard(Request $request): View
    {
        $tenantId = $this->tenantId();
        [$from, $to] = $this->dateRange($request);

        $production = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->whereBetween('captured_at', [$from, $to]);
        $dispatches = Dispatch::query()
            ->where('tenant_id', $tenantId)
            ->whereBetween(DB::raw('coalesce(confirmed_at, created_at)'), [$from, $to]);

        $inventoryTotals = $this->inventoryTotals($tenantId);

        return view('admin.dashboard', [
            'title' => 'Dashboard',
            'filters' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'kpis' => [
                'productionWeight' => (float) (clone $production)->sum('net_weight'),
                'productionEntries' => (clone $production)->count(),
                'productionPieces' => (float) (clone $production)->sum('piece_quantity'),
                'dispatchWeight' => (float) (clone $dispatches)->sum('total_weight'),
                'dispatchPieces' => (float) (clone $dispatches)->sum('total_pieces'),
                'inventoryWeight' => $inventoryTotals['weight'],
                'inventoryPieces' => $inventoryTotals['pieces'],
                'pendingSync' => SyncQueueEntry::query()->where('tenant_id', $tenantId)->where('status', 'pending')->count(),
                'failedSync' => SyncQueueEntry::query()->where('tenant_id', $tenantId)->where('status', 'failed')->count(),
                'activeProducts' => Product::query()->where('tenant_id', $tenantId)->where('is_active', true)->count(),
                'activeDevices' => Device::query()->where('tenant_id', $tenantId)->where('status', 'active')->count(),
            ],
            'productionByDate' => $this->seriesByDate(ProductionTransaction::class, $tenantId, 'captured_at', 'net_weight', $from, $to),
            'dispatchByDate' => $this->seriesByDate(Dispatch::class, $tenantId, 'confirmed_at', 'total_weight', $from, $to),
            'productProduction' => ProductionTransaction::query()
                ->where('tenant_id', $tenantId)
                ->whereBetween('captured_at', [$from, $to])
                ->select('product_id', DB::raw('sum(net_weight) as total_weight'), DB::raw('count(*) as entries'))
                ->groupBy('product_id')
                ->orderByDesc('total_weight')
                ->limit(8)
                ->get(),
            'inventoryByProduct' => InventoryTransaction::query()
                ->where('tenant_id', $tenantId)
                ->select('product_id', DB::raw($this->inventoryWeightExpression().' as weight'), DB::raw($this->inventoryPieceExpression().' as pieces'))
                ->groupBy('product_id')
                ->orderByDesc('weight')
                ->limit(8)
                ->get(),
            'recentProduction' => ProductionTransaction::query()->where('tenant_id', $tenantId)->latest('captured_at')->limit(8)->get(),
            'recentDispatches' => Dispatch::query()->where('tenant_id', $tenantId)->latest('created_at')->limit(8)->get(),
            'recentInwardCards' => InwardSession::query()->where('tenant_id', $tenantId)->latest('started_at')->limit(5)->get(),
            'recentDispatchCards' => Dispatch::query()->where('tenant_id', $tenantId)->latest('created_at')->limit(5)->get(),
            'productNames' => Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id'),
            'customerDispatchAnalysis' => Dispatch::query()
                ->where('tenant_id', $tenantId)
                ->select('customer_id', DB::raw('count(*) as dispatch_count'), DB::raw('sum(total_weight) as total_weight'), DB::raw('sum(total_pieces) as total_pieces'))
                ->groupBy('customer_id')
                ->orderByDesc('total_weight')
                ->limit(6)
                ->get(),
            'customerNames' => Customer::query()->where('tenant_id', $tenantId)->pluck('name', 'id'),
            'failedSync' => SyncQueueEntry::query()->where('tenant_id', $tenantId)->where('status', 'failed')->latest()->limit(8)->get(),
            'recentDevices' => Device::query()->where('tenant_id', $tenantId)->latest('last_seen_at')->limit(8)->get(),
        ]);
    }

    public function resource(string $section, Request $request): View
    {
        return match ($section) {
            'categories' => $this->simpleResource($section, ProductCategory::query(), ['name', 'code', 'is_active', 'updated_at']),
            'attributes' => $this->simpleResource($section, ProductAttribute::query(), ['name', 'internal_key', 'field_type', 'is_active']),
            'dynamic-fields' => $this->simpleResource($section, DynamicFieldDefinition::query(), ['field_label', 'internal_key', 'entity_type', 'data_type', 'is_active']),
            'devices' => $this->simpleResource($section, Device::query(), ['name', 'device_type', 'identifier', 'status', 'last_seen_at']),
            'scale-profiles' => $this->simpleResource($section, ScaleProfile::query(), ['name', 'is_active', 'updated_at']),
            'device-assignments' => $this->simpleResource($section, ProductDeviceAssignment::query(), ['device_id', 'product_id', 'variant_id', 'allowed', 'locked']),
            'label-templates' => $this->simpleResource($section, LabelTemplate::query(), ['name', 'code', 'scope', 'is_active', 'active_version'], tenantOptional: true),
            'users' => $this->simpleResource($section, User::query(), ['name', 'email', 'is_active', 'updated_at']),
            'roles' => $this->simpleResource(
                $section,
                Role::query()
                    ->where('key', 'not like', 'operator-%')
                    ->where('key', 'not like', 'access-%'),
                ['name', 'key', 'updated_at'],
            ),
            'permissions' => $this->simpleResource($section, Permission::query(), ['name', 'key', 'module'], tenantOptional: true),
            default => abort(404),
        };
    }

    public function superAdminOnboarding(): View
    {
        abort_unless(Auth::user()?->isSuperAdmin(), 403);

        return view('admin.superadmin.onboarding', [
            'title' => 'Superadmin Onboarding',
            'invites' => TenantOnboardingInvite::query()->latest()->paginate(25),
        ]);
    }

    public function superAdminOnboardingSave(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->isSuperAdmin(), 403);

        $data = $request->validate([
            'phone' => ['required', 'string', 'max:32'],
            'company_name' => ['nullable', 'string', 'max:255'],
            'admin_limit' => ['required', 'integer', 'min:1', 'max:50'],
            'valid_until' => ['nullable', 'date'],
        ]);
        $phone = preg_replace('/\D+/', '', $data['phone']);
        TenantOnboardingInvite::query()->updateOrCreate(
            ['phone' => $phone, 'status' => 'pending'],
            [
                'company_name' => $data['company_name'] ?? null,
                'admin_limit' => $data['admin_limit'],
                'valid_until' => $data['valid_until'] ?? null,
                'created_by' => Auth::id(),
                'updated_by' => Auth::id(),
            ],
        );

        return back()->with('status', 'Onboarding access created. Customer can now create their admin login.');
    }

    public function appUsers(Request $request): View
    {
        abort_unless(Auth::user()?->hasPermission('users.manage'), 403);

        $tenantId = $this->tenantId();
        $editing = null;
        if ($request->filled('edit')) {
            $editing = User::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query): void {
                    $query->where('app_only', true)
                        ->orWhereNotNull('app_username');
                })
                ->findOrFail($request->string('edit')->toString());
        }

        return view('admin.app-users.index', [
            'title' => 'App Users',
            'editing' => $editing,
            'users' => User::query()
                ->where('tenant_id', $tenantId)
                ->whereNotNull('app_username')
                ->with('roles.permissions')
                ->latest()
                ->paginate(25),
            'roles' => Role::query()
                ->where('tenant_id', $tenantId)
                ->orderBy('name')
                ->get(),
            'accessOptions' => $this->operatorAccessOptions(),
        ]);
    }

    public function appUserStore(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('users.manage'), 403);

        $tenantId = $this->tenantId();
        $access = $request->validate([
            'access_type' => ['required', Rule::in(['app', 'web'])],
        ]);
        $allowedModules = $access['access_type'] === 'app'
            ? ['production', 'dispatch']
            : array_keys($this->operatorAccessOptions());
        $data = [
            ...$access,
            ...$request->validate([
                'name' => ['required', 'string', 'max:255'],
                'app_username' => ['required', 'alpha_dash', 'min:3', 'max:80', Rule::unique('users', 'app_username')],
                'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')],
                'password' => ['required', 'confirmed', Password::min(6)],
                'access_modules' => ['required', 'array', 'min:1'],
                'access_modules.*' => ['required', Rule::in($allowedModules)],
            ]),
        ];

        $user = DB::transaction(function () use ($data, $tenantId): User {
            $user = User::query()->create([
                'tenant_id' => $tenantId,
                'name' => $data['name'],
                'app_username' => strtolower($data['app_username']),
                'email' => strtolower($data['email']),
                'password' => Hash::make($data['password']),
                'app_only' => $data['access_type'] === 'app',
                'is_active' => true,
                'created_by' => Auth::id(),
                'updated_by' => Auth::id(),
            ]);

            $role = Role::query()->create([
                'tenant_id' => $tenantId,
                'name' => $user->name.' '.str($data['access_type'])->upper().' Access',
                'key' => 'operator-'.$user->id,
                'is_system' => false,
                'created_by' => Auth::id(),
                'updated_by' => Auth::id(),
            ]);
            $role->permissions()->sync($this->permissionIdsForOperator(
                $data['access_type'],
                $data['access_modules'],
            ));
            $user->roles()->sync([$role->id]);
            $this->audit('app_user.created', $user, [], $user->only(['name', 'email', 'app_username', 'is_active']));

            return $user;
        });

        return back()->with('status', "Login created for {$user->app_username}.");
    }

    public function appUserStatus(User $user): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('users.manage'), 403);
        $this->ensureTenant($user->tenant_id);
        abort_unless($user->app_username, 404);

        $old = $user->toArray();
        $user->update([
            'is_active' => ! $user->is_active,
            'updated_by' => Auth::id(),
        ]);
        $this->audit('app_user.status_changed', $user, $old, $user->toArray());

        return back()->with('status', $user->is_active ? 'App user activated.' : 'App user deactivated.');
    }

    public function roleStore(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('roles.manage'), 403);

        $tenantId = $this->tenantId();
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
        ]);
        $name = trim($data['name']);
        $key = str($name)->slug('-')->toString();

        if ($key === '' || str_starts_with($key, 'operator-') || str_starts_with($key, 'access-')) {
            return back()->withErrors(['name' => 'Please enter a valid role name.'])->withInput();
        }

        $existing = Role::withTrashed()
            ->where('tenant_id', $tenantId)
            ->where('key', $key)
            ->first();
        if ($existing && ! $existing->trashed()) {
            return back()->withErrors(['name' => 'This role already exists.'])->withInput();
        }

        $old = $existing?->toArray() ?? [];
        $role = $existing ?: new Role(['tenant_id' => $tenantId, 'key' => $key]);
        if ($role->trashed()) {
            $role->restore();
        }
        $role->fill([
            'tenant_id' => $tenantId,
            'name' => $name,
            'key' => $key,
            'is_system' => false,
            'created_by' => $role->created_by ?? Auth::id(),
            'updated_by' => Auth::id(),
        ])->save();

        $this->audit('role.created', $role, $old, $role->fresh()->toArray());

        return back()->with('status', 'Role created successfully.');
    }

    private function operatorAccessOptions(): array
    {
        return [
            'products' => ['label' => 'Products / Product Details', 'permissions' => ['products.view']],
            'production' => ['label' => 'Production Entry / Inward', 'permissions' => ['production.capture', 'products.view']],
            'dispatch' => ['label' => 'Dispatch', 'permissions' => ['dispatch.confirm', 'customers.manage', 'inventory.view']],
            'customers' => ['label' => 'Customers', 'permissions' => ['customers.manage']],
            'inventory' => ['label' => 'Inventory', 'permissions' => ['inventory.view']],
            'reports' => ['label' => 'Reports / Exports', 'permissions' => ['reports.view']],
            'users_roles' => ['label' => 'Users & Roles', 'permissions' => ['users.manage', 'roles.manage']],
            'settings' => ['label' => 'Settings / Report Customiser', 'permissions' => ['configuration.manage', 'configuration.history.view']],
        ];
    }

    private function permissionIdsForOperator(string $accessType, array $modules): array
    {
        $options = $this->operatorAccessOptions();
        $permissionDefinitions = collect([
            ['key' => 'dashboard.view', 'name' => 'View dashboard', 'module' => 'dashboard'],
            ['key' => 'app.login', 'name' => 'Login to tablet app', 'module' => 'app'],
            ['key' => 'products.view', 'name' => 'View products', 'module' => 'products'],
            ['key' => 'customers.manage', 'name' => 'Manage customers', 'module' => 'customers'],
            ['key' => 'inventory.view', 'name' => 'View inventory', 'module' => 'inventory'],
            ['key' => 'production.capture', 'name' => 'Capture production', 'module' => 'production'],
            ['key' => 'dispatch.confirm', 'name' => 'Confirm dispatch', 'module' => 'dispatch'],
            ['key' => 'reports.view', 'name' => 'View reports', 'module' => 'reports'],
            ['key' => 'users.manage', 'name' => 'Manage users', 'module' => 'users'],
            ['key' => 'roles.manage', 'name' => 'Manage roles', 'module' => 'roles'],
            ['key' => 'configuration.manage', 'name' => 'Manage configuration', 'module' => 'configuration'],
            ['key' => 'configuration.history.view', 'name' => 'View configuration history', 'module' => 'configuration'],
        ])->keyBy('key');
        $keys = collect($modules)
            ->flatMap(fn (string $module) => $options[$module]['permissions'] ?? [])
            ->when($accessType === 'app', fn ($keys) => $keys->push('app.login'))
            ->when($accessType === 'web', fn ($keys) => $keys->push('dashboard.view'))
            ->unique()
            ->values();

        return $keys
            ->map(function (string $key) use ($permissionDefinitions) {
                $definition = $permissionDefinitions[$key] ?? [
                    'key' => $key,
                    'name' => str($key)->replace(['.', '_'], ' ')->title()->toString(),
                    'module' => str($key)->before('.')->toString(),
                ];

                return Permission::query()->firstOrCreate(['key' => $key], $definition)->id;
            })
            ->all();
    }

    public function userDestroy(User $user): RedirectResponse
    {
        abort_unless(Auth::user()?->hasPermission('users.manage'), 403);
        $this->ensureTenant($user->tenant_id);
        abort_unless($user->id !== Auth::id(), 422, 'You cannot delete your own logged-in user.');
        abort_unless(! $user->isSuperAdmin() || Auth::user()?->isSuperAdmin(), 403);

        $old = $user->load('roles')->toArray();
        $deletedMarker = 'deleted-'.$user->id.'-'.now()->timestamp;

        DB::transaction(function () use ($user, $old, $deletedMarker): void {
            $user->tokens()->delete();
            $user->roles()->detach();
            $user->forceFill([
                'email' => $deletedMarker.'@deleted.local',
                'app_username' => $user->app_username ? $deletedMarker : null,
                'is_active' => false,
                'updated_by' => Auth::id(),
            ])->save();
            $user->delete();

            $this->audit('user.deleted', $user, $old, [
                'id' => $user->id,
                'name' => $old['name'] ?? null,
                'email_released' => true,
                'app_username_released' => ! empty($old['app_username']),
            ]);
        });

        return back()->with('status', 'User deleted. Their email/app ID can now be reused if needed.');
    }

    public function production(Request $request): View
    {
        $tenantId = $this->tenantId();
        [$from, $to] = $this->dateRange($request, defaultDays: 30);
        $query = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->whereBetween('captured_at', [$from, $to])
            ->when($request->filled('search'), fn ($query) => $query->where(fn ($query) => $query
                ->where('serial_number', 'like', '%'.$request->search.'%')
                ->orWhere('barcode_value', 'like', '%'.$request->search.'%')))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->status))
            ->latest('captured_at');

        return view('admin.production.index', [
            'title' => 'Production',
            'rows' => $query->paginate(25)->withQueryString(),
            'filters' => ['from' => $from->toDateString(), 'to' => $to->toDateString(), 'search' => $request->search, 'status' => $request->status],
            'products' => Product::query()->where('tenant_id', $tenantId)->where('is_active', true)->orderBy('name')->get(),
            'variants' => ProductVariant::query()->where('tenant_id', $tenantId)->where('is_active', true)->orderBy('name')->get(),
            'productDetailFields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $tenantId)
                ->where('entity_type', 'product_variant')
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('field_label')
                ->get(),
        ]);
    }

    public function productionCreate(Request $request, OperationsSyncService $service): RedirectResponse
    {
        $tenantId = $this->tenantId();
        $data = $request->validate([
            'product_id' => ['required', Rule::exists('products', 'id')->where('tenant_id', $tenantId)],
            'variant_id' => ['nullable', Rule::exists('product_variants', 'id')->where('tenant_id', $tenantId)],
            'serial_number' => ['nullable', 'string', 'max:120', Rule::unique('production_transactions', 'serial_number')->where('tenant_id', $tenantId)],
            'barcode_value' => ['nullable', 'string', 'max:120', Rule::unique('production_transactions', 'barcode_value')->where('tenant_id', $tenantId)],
            'gross_weight' => ['required', 'numeric', 'min:0'],
            'tare_weight' => ['nullable', 'numeric', 'min:0'],
            'piece_quantity' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:20'],
            'captured_at' => ['nullable', 'date'],
        ]);

        $product = Product::query()->where('tenant_id', $tenantId)->findOrFail($data['product_id']);
        $tare = (float) ($data['tare_weight'] ?? $product->getRawOriginal('default_tare_weight') ?? 0);
        $gross = (float) $data['gross_weight'];
        $net = max($gross - $tare, 0);
        $serial = $data['serial_number'] ?: 'INW-'.now()->format('Ymd-His');
        $barcode = $data['barcode_value'] ?: $serial;

        $transaction = $service->production([
            ...$data,
            'serial_number' => $serial,
            'barcode_value' => $barcode,
            'tare_weight' => $tare,
            'net_weight' => $net,
            'unit' => $data['unit'] ?: 'kg',
            'product_snapshot' => $product->toArray(),
            'raw_reading' => ['source' => 'web_manual_inward'],
            'captured_at' => $data['captured_at'] ?? now(),
        ], $tenantId, 'web-inward-'.str()->uuid());
        $this->audit('production.web_inward_created', $transaction, [], $transaction->toArray());

        return back()->with('status', 'Inward production transaction saved and inventory added.');
    }

    public function productionShow(ProductionTransaction $production): View
    {
        $this->ensureTenant($production->tenant_id);

        return view('admin.production.show', [
            'title' => 'Production '.$production->serial_number,
            'row' => $production,
            'inventory' => InventoryTransaction::query()
                ->where('tenant_id', $production->tenant_id)
                ->where('reference_id', $production->id)
                ->get(),
            'audit' => AuditLog::query()
                ->where('tenant_id', $production->tenant_id)
                ->where('auditable_id', $production->id)
                ->latest()
                ->get(),
        ]);
    }

    public function productionCancel(Request $request, ProductionTransaction $production): RedirectResponse
    {
        $this->ensureTenant($production->tenant_id);
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        DB::transaction(function () use ($production, $data): void {
            if ($production->status === 'cancelled') {
                return;
            }

            $old = $production->toArray();
            $production->update(['status' => 'cancelled', 'updated_by' => Auth::id()]);
            InventoryTransaction::query()->create([
                'tenant_id' => $production->tenant_id,
                'warehouse_id' => $production->warehouse_id,
                'product_id' => $production->product_id,
                'variant_id' => $production->variant_id,
                'serial_number' => $production->serial_number,
                'barcode_value' => $production->barcode_value,
                'transaction_type' => 'production_cancellation',
                'weight_quantity' => $production->net_weight,
                'piece_quantity' => $production->piece_quantity,
                'reference_type' => 'production',
                'reference_id' => $production->id,
                'reason' => $data['reason'],
                'created_by' => Auth::id(),
                'occurred_at' => now(),
            ]);
            BarcodeRecord::query()->where('tenant_id', $production->tenant_id)->where('barcode_value', $production->barcode_value)->update([
                'inventory_status' => 'cancelled',
                'dispatch_status' => 'cancelled',
            ]);
            $this->audit('production.cancelled', $production, $old, $production->fresh()->toArray(), ['reason' => $data['reason']]);
        });

        return back()->with('status', 'Production entry cancelled and inventory reversed.');
    }

    public function inventory(Request $request): View
    {
        $tenantId = $this->tenantId();
        $filters = $request->validate([
            'product_id' => ['nullable', Rule::exists('products', 'id')->where('tenant_id', $tenantId)],
            'variant_id' => ['nullable', Rule::exists('product_variants', 'id')->where('tenant_id', $tenantId)],
            'transaction_type' => ['nullable', 'string', 'max:100'],
            'search' => ['nullable', 'string', 'max:120'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);
        $filters = [
            'product_id' => $filters['product_id'] ?? '',
            'variant_id' => $filters['variant_id'] ?? '',
            'transaction_type' => $filters['transaction_type'] ?? '',
            'search' => trim($filters['search'] ?? ''),
            'from' => $filters['from'] ?? '',
            'to' => $filters['to'] ?? '',
        ];

        $summary = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->when($filters['product_id'], fn ($query, $id) => $query->where('product_id', $id))
            ->when($filters['variant_id'], fn ($query, $id) => $query->where('variant_id', $id))
            ->select('product_id', 'variant_id', DB::raw($this->inventoryWeightExpression().' as weight'), DB::raw($this->inventoryPieceExpression().' as pieces'), DB::raw('max(occurred_at) as last_movement'))
            ->groupBy('product_id', 'variant_id')
            ->orderByDesc('weight')
            ->paginate(25)
            ->withQueryString();
        $ledger = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->when($filters['product_id'], fn ($query, $id) => $query->where('product_id', $id))
            ->when($filters['variant_id'], fn ($query, $id) => $query->where('variant_id', $id))
            ->when($filters['transaction_type'], fn ($query, $type) => $query->where('transaction_type', $type))
            ->when($filters['from'], fn ($query, $from) => $query->where('occurred_at', '>=', CarbonImmutable::parse($from)->startOfDay()))
            ->when($filters['to'], fn ($query, $to) => $query->where('occurred_at', '<=', CarbonImmutable::parse($to)->endOfDay()))
            ->when($filters['search'], function ($query, string $search) use ($tenantId): void {
                $like = '%'.$search.'%';
                $matchingBarcodes = ProductionTransaction::query()
                    ->select('barcode_value')
                    ->where('tenant_id', $tenantId)
                    ->where(fn ($query) => $query
                        ->where('serial_number', 'like', $like)
                        ->orWhere('barcode_value', 'like', $like));
                $query->where(fn ($query) => $query
                    ->where('barcode_value', 'like', $like)
                    ->orWhereIn('barcode_value', $matchingBarcodes));
            })
            ->latest('occurred_at')
            ->paginate(25, ['*'], 'ledger_page')
            ->withQueryString();

        $detailCards = $this->inventoryDetailCards(
            $tenantId,
            $filters['product_id'] ?: null,
            $filters['variant_id'] ?: null,
        );

        return view('admin.inventory.index', [
            'title' => 'Inventory',
            'totals' => $this->inventoryTotals($tenantId),
            'summary' => $summary,
            'ledger' => $ledger,
            'products' => Product::query()->where('tenant_id', $tenantId)->orderBy('name')->get(),
            'variants' => ProductVariant::query()->where('tenant_id', $tenantId)->orderBy('name')->get(),
            'productNames' => Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id'),
            'variantNames' => ProductVariant::query()->where('tenant_id', $tenantId)->pluck('name', 'id'),
            'detailCards' => $detailCards,
            'transactionTypes' => InventoryTransaction::query()
                ->where('tenant_id', $tenantId)
                ->whereNotNull('transaction_type')
                ->distinct()
                ->orderBy('transaction_type')
                ->pluck('transaction_type'),
            'filters' => $filters,
        ]);
    }

    public function inventoryAdjust(Request $request): RedirectResponse
    {
        $tenantId = $this->tenantId();
        $data = $request->validate([
            'product_id' => ['required', Rule::exists('products', 'id')->where('tenant_id', $tenantId)],
            'variant_id' => ['nullable', Rule::exists('product_variants', 'id')->where('tenant_id', $tenantId)],
            'transaction_type' => ['required', Rule::in(['opening_stock', 'manual_adjustment'])],
            'weight_quantity' => ['required', 'numeric'],
            'piece_quantity' => ['nullable', 'numeric'],
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $txn = InventoryTransaction::query()->create([
            ...$data,
            'tenant_id' => $tenantId,
            'reference_type' => 'manual',
            'reference_id' => (string) str()->uuid(),
            'created_by' => Auth::id(),
            'occurred_at' => now(),
        ]);
        $this->audit('inventory.adjusted', $txn, [], $txn->toArray());

        return back()->with('status', 'Inventory adjustment posted.');
    }

    public function inventoryClear(Request $request): RedirectResponse
    {
        abort_unless(Auth::user()?->isSuperAdmin() || Auth::user()?->hasPermission('users.manage'), 403);

        $tenantId = $this->tenantId();
        $data = $request->validate([
            'confirm' => ['required', 'string', 'in:CLEAR INVENTORY'],
            'password' => ['required', 'string'],
        ]);
        abort_unless(Hash::check($data['password'], Auth::user()?->password ?? ''), 422, 'Admin password is incorrect.');

        DB::transaction(function () use ($tenantId, $data): void {
            $counts = [
                'dispatch_items' => DispatchItem::query()->where('tenant_id', $tenantId)->count(),
                'dispatches' => Dispatch::query()->where('tenant_id', $tenantId)->count(),
                'inventory_transactions' => InventoryTransaction::query()->where('tenant_id', $tenantId)->count(),
                'barcode_records' => BarcodeRecord::query()->where('tenant_id', $tenantId)->count(),
                'production_transactions' => ProductionTransaction::query()->where('tenant_id', $tenantId)->count(),
                'inward_sessions' => InwardSession::query()->where('tenant_id', $tenantId)->count(),
            ];

            DispatchItem::query()->where('tenant_id', $tenantId)->delete();
            Dispatch::query()->where('tenant_id', $tenantId)->delete();
            InventoryTransaction::query()->where('tenant_id', $tenantId)->delete();
            BarcodeRecord::query()->where('tenant_id', $tenantId)->delete();
            ProductionTransaction::query()->where('tenant_id', $tenantId)->delete();
            InwardSession::query()->where('tenant_id', $tenantId)->delete();

            $this->audit('inventory.cleared', Auth::user(), $counts, ['confirm' => $data['confirm']]);
        });

        return back()->with('status', 'Inventory, inward, dispatch and barcode transaction data cleared for this tenant. Products, product details, customers and settings were kept.');
    }

    public function customers(Request $request): View
    {
        $tenantId = $this->tenantId();
        $editing = null;
        if ($request->filled('edit')) {
            $editing = Customer::query()
                ->where('tenant_id', $tenantId)
                ->findOrFail($request->string('edit')->toString());
        }
        $rows = Customer::query()
            ->where('tenant_id', $tenantId)
            ->when($request->filled('search'), fn ($query) => $query->where(fn ($query) => $query
                ->where('name', 'like', '%'.$request->search.'%')
                ->orWhere('code', 'like', '%'.$request->search.'%')
                ->orWhere('phone', 'like', '%'.$request->search.'%')))
            ->latest()
            ->paginate(25);

        return view('admin.customers.index', ['title' => 'Customers', 'rows' => $rows, 'editing' => $editing]);
    }

    public function customerSave(Request $request, ?Customer $customer = null): RedirectResponse
    {
        $tenantId = $this->tenantId();
        if ($customer) {
            $this->ensureTenant($customer->tenant_id);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'code' => ['nullable', 'string', 'max:100', Rule::unique('customers', 'code')->where('tenant_id', $tenantId)->whereNull('deleted_at')->ignore($customer?->id)],
            'contact_person' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'email' => ['nullable', 'email', 'max:255'],
            'billing_address' => ['nullable', 'string'],
            'shipping_address' => ['nullable', 'string'],
            'tax_number' => ['nullable', 'string', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        if (! $customer && filled($data['code'] ?? null)) {
            $customer = Customer::withTrashed()
                ->where('tenant_id', $tenantId)
                ->where('code', $data['code'])
                ->first();

            if ($customer?->trashed()) {
                $customer->restore();
            }
        }

        $old = $customer?->toArray() ?? [];
        $customer = Customer::query()->updateOrCreate(
            ['id' => $customer?->id],
            [...$data, 'tenant_id' => $tenantId, 'is_active' => $request->boolean('is_active'), 'created_by' => $customer?->created_by ?? Auth::id(), 'updated_by' => Auth::id()],
        );
        $this->audit($old ? 'customer.updated' : 'customer.created', $customer, $old, $customer->toArray());

        return redirect()->route('admin.customers')->with('status', 'Customer saved.');
    }

    public function customerDelete(Customer $customer): RedirectResponse
    {
        $this->ensureTenant($customer->tenant_id);
        $old = $customer->toArray();
        $customer->update(['is_active' => false, 'updated_by' => Auth::id()]);
        $customer->delete();
        $this->audit('customer.deleted', $customer, $old, ['deleted_at' => now()->toISOString()]);

        return redirect()->route('admin.customers')->with('status', 'Customer deleted.');
    }

    public function dispatches(Request $request): View
    {
        $tenantId = $this->tenantId();
        [$from, $to] = $this->dateRange($request, defaultDays: 30);
        $query = Dispatch::query()
            ->with('items')
            ->where('tenant_id', $tenantId)
            ->whereBetween(DB::raw('coalesce(confirmed_at, created_at)'), [$from, $to])
            ->when($request->filled('customer_id'), fn ($query) => $query->where('customer_id', $request->string('customer_id')->toString()))
            ->when($request->filled('search'), function ($query) use ($request): void {
                $search = '%'.$request->string('search')->toString().'%';
                $query->where(function ($query) use ($search): void {
                    $query->where('dispatch_number', 'like', $search)
                        ->orWhere('customer_snapshot->name', 'like', $search)
                        ->orWhereHas('items', fn ($query) => $query
                            ->where('barcode_value', 'like', $search)
                            ->orWhere('serial_number', 'like', $search));
                });
            })
            ->latest();

        return view('admin.dispatch.index', [
            'title' => 'Dispatch',
            'rows' => $query->paginate(25)->withQueryString(),
            'filters' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
                'customer_id' => $request->string('customer_id')->toString(),
                'search' => $request->string('search')->toString(),
            ],
            'customers' => Customer::query()->where('tenant_id', $tenantId)->where('is_active', true)->orderBy('name')->get(),
            'recentAvailable' => ProductionTransaction::query()->where('tenant_id', $tenantId)->where('status', 'active')->latest('captured_at')->limit(10)->get(),
        ]);
    }

    public function dispatchCreate(Request $request, OperationsSyncService $service): RedirectResponse
    {
        $tenantId = $this->tenantId();
        $data = $request->validate([
            'customer_id' => ['required', Rule::exists('customers', 'id')->where('tenant_id', $tenantId)],
            'barcodes' => ['required', 'string'],
            'vehicle_number' => ['nullable', 'string', 'max:100'],
            'driver_name' => ['nullable', 'string', 'max:255'],
            'transporter' => ['nullable', 'string', 'max:255'],
            'po_reference' => ['nullable', 'string', 'max:255'],
            'invoice_reference' => ['nullable', 'string', 'max:255'],
        ]);
        $barcodes = collect(preg_split('/[\r\n,]+/', $data['barcodes']))->map(fn ($value) => trim($value))->filter()->values()->all();
        $dispatch = $service->dispatch([...$data, 'barcodes' => $barcodes], $tenantId, 'web-dispatch-'.str()->uuid());
        $this->audit('dispatch.created', $dispatch, [], $dispatch->toArray());

        return redirect()->route('admin.dispatch')->with('status', 'Dispatch confirmed.');
    }

    public function dispatchReverse(Request $request, Dispatch $dispatch): RedirectResponse
    {
        $this->ensureTenant($dispatch->tenant_id);
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        DB::transaction(function () use ($dispatch, $data): void {
            if ($dispatch->status === 'reversed') {
                return;
            }
            $old = $dispatch->toArray();
            $items = $dispatch->items()->get();
            foreach ($items as $item) {
                $production = ProductionTransaction::query()->where('tenant_id', $dispatch->tenant_id)->find($item->production_transaction_id);
                if (! $production) {
                    continue;
                }
                InventoryTransaction::query()->create([
                    'tenant_id' => $dispatch->tenant_id,
                    'warehouse_id' => $production->warehouse_id,
                    'product_id' => $production->product_id,
                    'variant_id' => $production->variant_id,
                    'serial_number' => $production->serial_number,
                    'barcode_value' => $production->barcode_value,
                    'transaction_type' => 'dispatch_reversal',
                    'weight_quantity' => $production->net_weight,
                    'piece_quantity' => $production->piece_quantity,
                    'reference_type' => 'dispatch',
                    'reference_id' => $dispatch->id,
                    'reason' => $data['reason'],
                    'created_by' => Auth::id(),
                    'occurred_at' => now(),
                ]);
                BarcodeRecord::query()->where('tenant_id', $dispatch->tenant_id)->where('barcode_value', $production->barcode_value)->update([
                    'inventory_status' => 'available',
                    'dispatch_status' => 'not_dispatched',
                ]);
            }
            $dispatch->update(['status' => 'reversed', 'updated_by' => Auth::id()]);
            $this->audit('dispatch.reversed', $dispatch, $old, $dispatch->fresh()->toArray(), ['reason' => $data['reason']]);
        });

        return back()->with('status', 'Dispatch reversed and inventory restored.');
    }

    public function dispatchItemDelete(Request $request, Dispatch $dispatch, DispatchItem $item): RedirectResponse
    {
        $this->ensureTenant($dispatch->tenant_id);
        abort_unless($item->tenant_id === $dispatch->tenant_id && $item->dispatch_id === $dispatch->id, 404);
        abort_if($dispatch->status === 'reversed', 422, 'Cannot delete barcode from a reversed dispatch.');

        DB::transaction(function () use ($dispatch, $item): void {
            $oldDispatch = $dispatch->toArray();
            $production = ProductionTransaction::query()
                ->where('tenant_id', $dispatch->tenant_id)
                ->find($item->production_transaction_id);

            InventoryTransaction::query()
                ->where('tenant_id', $dispatch->tenant_id)
                ->where('reference_type', 'dispatch')
                ->where('reference_id', $dispatch->id)
                ->where('barcode_value', $item->barcode_value)
                ->delete();

            BarcodeRecord::query()
                ->where('tenant_id', $dispatch->tenant_id)
                ->where('barcode_value', $item->barcode_value)
                ->update([
                    'inventory_status' => 'available',
                    'dispatch_status' => 'not_dispatched',
                ]);

            $oldItem = $item->toArray();
            $item->delete();

            $totals = DispatchItem::query()
                ->where('tenant_id', $dispatch->tenant_id)
                ->where('dispatch_id', $dispatch->id)
                ->selectRaw('sum(weight_quantity) as total_weight')
                ->selectRaw('sum(coalesce(piece_quantity, 0)) as total_pieces')
                ->first();

            $dispatch->update([
                'total_weight' => $totals->total_weight ?? 0,
                'total_pieces' => $totals->total_pieces ?? 0,
                'updated_by' => Auth::id(),
            ]);

            $this->audit('dispatch.item_deleted', $dispatch, ['dispatch' => $oldDispatch, 'item' => $oldItem], [
                'dispatch' => $dispatch->fresh()->toArray(),
                'barcode_value' => $oldItem['barcode_value'],
                'production_id' => $production?->id,
            ]);
        });

        return back()->with('status', 'Barcode removed from dispatch and restored to available inventory.');
    }

    public function reports(?string $report, Request $request): View
    {
        $report ??= 'inward';

        return $this->reportView($report, $request, 'Reports');
    }

    public function inwardReport(Request $request): View
    {
        return $this->reportView('inward', $request, 'Inward Report');
    }

    public function dispatchReport(Request $request): View
    {
        return $this->reportView('dispatch', $request, 'Dispatch Report / Packing List');
    }

    private function reportView(string $report, Request $request, string $title): View
    {
        $tenantId = $this->tenantId();
        [$from, $to] = $this->dateRange($request, defaultDays: 30);
        $rows = $report === 'inward'
            ? $this->inwardSessionRows($tenantId, $from, $to, $request)
            : $this->reportRows($report, $tenantId, $from, $to, $request);

        return view('admin.reports.index', [
            'title' => $title,
            'report' => $report,
            'filters' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
                'product_id' => $request->string('product_id')->toString(),
                'barcode' => $request->string('barcode')->toString(),
                'detail_key' => $request->string('detail_key')->toString(),
                'detail_value' => $request->string('detail_value')->toString(),
            ],
            'rows' => ($report === 'dispatch' ? $rows->withCount('items') : $rows)->paginate(25)->withQueryString(),
            'columns' => $this->reportColumns($report),
            'showTabs' => $title === 'Reports',
            'products' => Product::query()->where('tenant_id', $tenantId)->orderBy('name')->get(['id', 'name']),
            'productFields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $tenantId)
                ->where('entity_type', 'product_variant')
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->get(['internal_key', 'field_label']),
        ]);
    }

    public function inwardExport(string $session, string $format)
    {
        $tenantId = $this->tenantId();
        $inwardSession = InwardSession::query()
            ->where('tenant_id', $tenantId)
            ->where(fn ($query) => $query->where('id', $session)->orWhere('session_number', $session))
            ->first();
        $date = $inwardSession ? null : CarbonImmutable::parse($session);
        $productions = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->when($inwardSession, fn ($query) => $query->where('inward_session_id', $inwardSession->id))
            ->when(! $inwardSession, fn ($query) => $query->whereBetween('captured_at', [$date->startOfDay(), $date->endOfDay()]))
            ->orderBy('captured_at')
            ->get();

        abort_if($productions->isEmpty(), 404);

        $rows = $this->inwardExportRows($productions, $tenantId);
        $dynamicColumns = $this->dispatchDynamicColumns($rows, $tenantId);
        $selectedColumns = $this->selectedReportColumns('inward', $dynamicColumns, includeTime: true);
        $startedAt = $productions->first()?->captured_at;
        $endedAt = $productions->last()?->captured_at;
        $columns = array_keys($selectedColumns);
        $report = 'inward-'.($inwardSession?->session_number ?? $date->format('Ymd'));

        if ($format === 'pdf') {
            return response($this->inwardPdf($session, $productions, $tenantId, $inwardSession), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$report.'.pdf"',
            ]);
        }

        if ($format === 'xlsx') {
            return response($this->xlsxWorkbook($report, [
                ['Inward No', $inwardSession?->session_number ?? 'INW-'.$date->format('Ymd')],
                ['Started', $startedAt?->format('Y-m-d H:i')],
                ['Ended', $endedAt?->format('Y-m-d H:i')],
                ['Entries', (string) $rows->count()],
                [],
                array_values($selectedColumns),
                ...$rows->map(fn ($row) => $this->reportExportValues($row, array_keys($selectedColumns)))->all(),
                [],
                ['Summary'],
                ['Total Entries', (string) $rows->count()],
                ['Total Gross kg', (string) $rows->sum('gross_weight')],
                ['Total Tare kg', (string) $rows->sum('tare_weight')],
                ['Total Net kg', (string) $rows->sum('net_weight')],
                ['Total Converted Unit', (string) $rows->sum('piece_quantity')],
            ]), 200, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="'.$report.'.xlsx"',
            ]);
        }

        return new StreamedResponse(function () use ($columns, $rows, $selectedColumns): void {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, array_values($selectedColumns));
            foreach ($rows as $row) {
                fputcsv($handle, $this->reportExportValues($row, $columns));
            }
            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="'.$report.'.csv"',
        ]);
    }

    public function dispatchExport(Dispatch $dispatch, string $format)
    {
        $this->ensureTenant($dispatch->tenant_id);
        $dispatch->load('items');
        $rows = $this->dispatchExportRows($dispatch);
        $dynamicColumns = $this->dispatchDynamicColumns($rows, $dispatch->tenant_id);
        $selectedColumns = $this->selectedReportColumns('dispatch', $dynamicColumns);
        $columns = array_keys($selectedColumns);
        $report = 'dispatch-'.$dispatch->dispatch_number;

        if ($format === 'pdf') {
            return response($this->dispatchPdf($dispatch), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$report.'.pdf"',
            ]);
        }

        if ($format === 'xlsx') {
            return response($this->xlsxWorkbook($report, [
                ['Dispatch No', $dispatch->dispatch_number],
                ['Customer', data_get($dispatch->customer_snapshot, 'name', '-')],
                ['Delivery Address', data_get($dispatch->customer_snapshot, 'shipping_address', '-')],
                ['Date', ($dispatch->confirmed_at ?? $dispatch->created_at)?->format('Y-m-d H:i')],
                [],
                array_values($selectedColumns),
                ...$rows->map(fn ($row) => $this->reportExportValues($row, array_keys($selectedColumns)))->all(),
                [],
                ['Summary'],
                ['Total Labels', (string) $rows->count()],
                ['Total Gross kg', (string) $rows->sum('gross_weight')],
                ['Total Tare kg', (string) $rows->sum('tare_weight')],
                ['Total Net kg', (string) $rows->sum('net_weight')],
                ['Total Converted Unit', (string) $rows->sum('piece_quantity')],
            ]), 200, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="'.$report.'.xlsx"',
            ]);
        }

        return new StreamedResponse(function () use ($columns, $rows, $selectedColumns): void {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, array_values($selectedColumns));
            foreach ($rows as $row) {
                fputcsv($handle, $this->reportExportValues($row, $columns));
            }
            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="'.$report.'.csv"',
        ]);
    }

    public function export(string $report, string $format, Request $request)
    {
        abort_unless(Auth::user()?->hasPermission('reports.view'), 403);
        abort_unless(in_array($report, ['inward', 'dispatch', 'inventory', 'inventory-ledger', 'audit'], true), 404);
        abort_unless(in_array($format, ['pdf', 'xlsx', 'csv'], true), 404);
        $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'product_id' => ['nullable', 'string'],
            'variant_id' => ['nullable', 'string'],
            'transaction_type' => ['nullable', 'string', 'max:100'],
            'search' => ['nullable', 'string', 'max:120'],
        ]);
        $tenantId = $this->tenantId();
        [$from, $to] = $this->dateRange($request, defaultDays: 30);
        $rows = $this->reportRows($report, $tenantId, $from, $to, $request)->limit(5000)->get();
        $columns = $this->reportColumns($report);

        if ($format === 'pdf') {
            return response($this->basicPdf($report, $columns, $rows), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$report.'-report.pdf"',
            ]);
        }

        if ($format === 'xlsx') {
            return response($this->xlsxWorkbook($report, [
                array_map(fn (string $column) => str($column)->replace('_', ' ')->title()->toString(), $columns),
                ...$rows->map(fn ($row) => array_map(fn ($column) => data_get($row, $column), $columns))->all(),
            ]), 200, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="'.$report.'-report.xlsx"',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        }

        return new StreamedResponse(function () use ($columns, $rows): void {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, $columns);
            foreach ($rows as $row) {
                fputcsv($handle, array_map(fn ($column) => data_get($row, $column), $columns));
            }
            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="'.$report.'-report.csv"',
        ]);
    }

    public function sync(): View
    {
        $tenantId = $this->tenantId();

        return view('admin.sync.index', [
            'title' => 'Sync Status',
            'rows' => SyncQueueEntry::query()->where('tenant_id', $tenantId)->latest()->paginate(25),
            'summary' => SyncQueueEntry::query()->where('tenant_id', $tenantId)->select('status', DB::raw('count(*) as total'))->groupBy('status')->pluck('total', 'status'),
        ]);
    }

    public function auditLogs(Request $request): View
    {
        return view('admin.audit.index', [
            'title' => 'Audit Logs',
            'rows' => AuditLog::query()
                ->where('tenant_id', $this->tenantId())
                ->when($request->filled('action'), fn ($query) => $query->where('action', 'like', '%'.$request->action.'%'))
                ->latest()
                ->paginate(25),
        ]);
    }

    public function tenantSettings(): View
    {
        return view('admin.settings.tenant', [
            'title' => 'Report Customiser',
            'tenant' => Auth::user()->tenant,
            'productFields' => DynamicFieldDefinition::query()
                ->where('tenant_id', $this->tenantId())
                ->where('entity_type', 'product_variant')
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->get(['internal_key', 'field_label']),
        ]);
    }

    public function tenantSettingsSave(Request $request): RedirectResponse
    {
        $tenant = Auth::user()->tenant;
        $old = $tenant->toArray();
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'settings.companyAddress' => ['nullable', 'string'],
            'settings.taxNumber' => ['nullable', 'string', 'max:100'],
            'settings.logoUrl' => ['nullable', 'string', 'max:500'],
            'logo' => ['nullable', 'image', 'max:2048'],
            'settings.weightPrecision' => ['nullable', 'integer', 'min:0', 'max:6'],
            'settings.dateFormat' => ['nullable', 'string', 'max:50'],
            'settings.numberFormat' => ['nullable', 'string', 'max:50'],
            'settings.reportHeader.phone' => ['nullable', 'string', 'max:100'],
            'settings.reportHeader.email' => ['nullable', 'string', 'max:150'],
            'settings.reportHeader.gst' => ['nullable', 'string', 'max:100'],
            'settings.reportHeader.contact' => ['nullable', 'string', 'max:150'],
            'settings.reportHeader.address' => ['nullable', 'string', 'max:300'],
            'settings.reportHeader.extra1' => ['nullable', 'string', 'max:200'],
            'settings.reportHeader.extra2' => ['nullable', 'string', 'max:200'],
            'settings.reportFooter.0' => ['nullable', 'string', 'max:200'],
            'settings.reportFooter.1' => ['nullable', 'string', 'max:200'],
            'settings.reportFooter.2' => ['nullable', 'string', 'max:200'],
            'settings.reportEmail.to' => ['nullable', 'string', 'max:500'],
            'settings.reportEmail.pdf' => ['nullable', 'boolean'],
            'settings.reportEmail.excel' => ['nullable', 'boolean'],
            'settings.reportColumns.inward' => ['nullable', 'array'],
            'settings.reportColumns.inward.*' => ['string', 'max:100'],
            'settings.reportColumns.dispatch' => ['nullable', 'array'],
            'settings.reportColumns.dispatch.*' => ['string', 'max:100'],
        ]);
        $settings = $data['settings'] ?? [];
        if ($request->hasFile('logo')) {
            $settings['logoPath'] = $request->file('logo')->store('report-logos', 'public');
        } else {
            $settings['logoPath'] = $tenant->settings['logoPath'] ?? null;
        }

        $tenant->update(['name' => $data['name'], 'settings' => $settings, 'updated_by' => Auth::id()]);
        $this->audit('tenant.settings.updated', $tenant, $old, $tenant->fresh()->toArray());

        return back()->with('status', 'Tenant settings saved.');
    }

    private function simpleResource(string $section, $query, array $columns, bool $tenantOptional = false): View
    {
        $tenantId = $this->tenantId();
        $query->when(! $tenantOptional, fn ($query) => $query->where('tenant_id', $tenantId))
            ->when($tenantOptional, fn ($query) => $query->where(fn ($query) => $query->whereNull('tenant_id')->orWhere('tenant_id', $tenantId)))
            ->latest();

        return view('admin.resources.index', [
            'title' => str($section)->replace('-', ' ')->title()->toString(),
            'section' => $section,
            'columns' => $columns,
            'rows' => $query->paginate(25),
        ]);
    }

    private function inwardSessionRows(string $tenantId, CarbonImmutable $from, CarbonImmutable $to, ?Request $request = null)
    {
        $query = ProductionTransaction::query()
            ->from('production_transactions as pt')
            ->leftJoin('inward_sessions as ins', function ($join): void {
                $join->on('ins.id', '=', 'pt.inward_session_id')
                    ->on('ins.tenant_id', '=', 'pt.tenant_id');
            })
            ->where('pt.tenant_id', $tenantId)
            ->whereBetween('pt.captured_at', [$from, $to]);

        $this->applyProductionReportFilters($query, $request, 'pt');

        return $query
            ->selectRaw('coalesce(pt.inward_session_id, date(pt.captured_at)) as session_key')
            ->selectRaw('min(ins.session_number) as session_number')
            ->selectRaw('count(*) as entries_count')
            ->selectRaw('sum(pt.gross_weight) as gross_weight')
            ->selectRaw('sum(pt.tare_weight) as tare_weight')
            ->selectRaw('sum(pt.net_weight) as net_weight')
            ->selectRaw('sum(coalesce(pt.piece_quantity, 0)) as piece_quantity')
            ->selectRaw('min(pt.captured_at) as started_at')
            ->selectRaw('max(pt.captured_at) as ended_at')
            ->groupByRaw('coalesce(pt.inward_session_id, date(pt.captured_at))')
            ->orderByDesc('ended_at');
    }

    private function reportRows(string $report, string $tenantId, CarbonImmutable $from, CarbonImmutable $to, ?Request $request = null)
    {
        return match ($report) {
            'inventory', 'inventory-ledger' => InventoryTransaction::query()
                ->where('tenant_id', $tenantId)
                ->whereBetween('occurred_at', [$from, $to])
                ->when($request?->filled('product_id'), fn ($query) => $query->where('product_id', $request->string('product_id')->toString()))
                ->when($request?->filled('variant_id'), fn ($query) => $query->where('variant_id', $request->string('variant_id')->toString()))
                ->when($request?->filled('transaction_type'), fn ($query) => $query->where('transaction_type', $request->string('transaction_type')->toString()))
                ->when($request?->filled('search'), function ($query) use ($request, $tenantId): void {
                    $search = '%'.$request->string('search')->toString().'%';
                    $query->where(fn ($query) => $query
                        ->where('barcode_value', 'like', $search)
                        ->orWhereIn('barcode_value', ProductionTransaction::query()
                            ->select('barcode_value')
                            ->where('tenant_id', $tenantId)
                            ->where(fn ($production) => $production
                                ->where('serial_number', 'like', $search)
                                ->orWhere('barcode_value', 'like', $search))));
                })
                ->latest('occurred_at'),
            'dispatch', 'customer-dispatch' => Dispatch::query()
                ->where('tenant_id', $tenantId)
                ->where(function ($query) use ($from, $to): void {
                    $query->whereBetween('confirmed_at', [$from, $to])
                        ->orWhere(function ($query) use ($from, $to): void {
                            $query->whereNull('confirmed_at')
                                ->whereBetween('created_at', [$from, $to]);
                        });
                })
                ->when($request?->filled('barcode'), fn ($query) => $query->whereHas('items', fn ($itemQuery) => $itemQuery->where('barcode_value', 'like', '%'.$request->string('barcode')->toString().'%')))
                ->when($request?->filled('product_id'), fn ($query) => $query->whereHas('items', function ($itemQuery) use ($request): void {
                    $itemQuery->whereIn('production_transaction_id', ProductionTransaction::query()
                        ->select('id')
                        ->where('tenant_id', $this->tenantId())
                        ->where('product_id', $request->string('product_id')->toString()));
                }))
                ->when($request?->filled('detail_key') && $request?->filled('detail_value'), fn ($query) => $query->whereHas('items', function ($itemQuery) use ($request): void {
                    $itemQuery->whereIn('production_transaction_id', ProductionTransaction::query()
                        ->select('id')
                        ->where('tenant_id', $this->tenantId())
                        ->where('dynamic_values', 'like', '%"'.$request->string('detail_key')->toString().'"%')
                        ->where('dynamic_values', 'like', '%'.$request->string('detail_value')->toString().'%'));
                }))
                ->latest(),
            'audit' => AuditLog::query()->where('tenant_id', $tenantId)->whereBetween('created_at', [$from, $to])->latest(),
            default => tap(
                ProductionTransaction::query()->where('tenant_id', $tenantId)->whereBetween('captured_at', [$from, $to]),
                fn ($query) => $this->applyProductionReportFilters($query, $request)
            )->latest('captured_at'),
        };
    }

    private function applyProductionReportFilters($query, ?Request $request = null, string $alias = 'production_transactions'): void
    {
        if (! $request) {
            return;
        }

        $query
            ->when($request->filled('product_id'), fn ($query) => $query->where($alias.'.product_id', $request->string('product_id')->toString()))
            ->when($request->filled('barcode'), fn ($query) => $query->where($alias.'.barcode_value', 'like', '%'.$request->string('barcode')->toString().'%'))
            ->when($request->filled('detail_key') && $request->filled('detail_value'), function ($query) use ($request, $alias): void {
                $query->where($alias.'.dynamic_values', 'like', '%"'.$request->string('detail_key')->toString().'"%')
                    ->where($alias.'.dynamic_values', 'like', '%'.$request->string('detail_value')->toString().'%');
            });
    }

    public function reportColumns(string $report): array
    {
        return match ($report) {
            'inventory', 'inventory-ledger' => ['transaction_type', 'product_id', 'variant_id', 'barcode_value', 'weight_quantity', 'piece_quantity', 'reference_type', 'occurred_at'],
            'dispatch', 'customer-dispatch' => ['dispatch_number', 'customer_snapshot.name', 'status', 'vehicle_number', 'driver_name', 'transporter', 'total_weight', 'total_pieces', 'confirmed_at'],
            'audit' => ['action', 'auditable_type', 'auditable_id', 'created_at'],
            default => ['serial_number', 'barcode_value', 'product_id', 'variant_id', 'gross_weight', 'tare_weight', 'net_weight', 'piece_quantity', 'status', 'captured_at'],
        };
    }

    private function seriesByDate(string $model, string $tenantId, string $dateColumn, string $sumColumn, CarbonImmutable $from, CarbonImmutable $to)
    {
        return $model::query()
            ->where('tenant_id', $tenantId)
            ->whereBetween($dateColumn, [$from, $to])
            ->select(DB::raw('date('.$dateColumn.') as day'), DB::raw('sum('.$sumColumn.') as total'))
            ->groupBy('day')
            ->orderBy('day')
            ->get();
    }

    private function inventoryTotals(string $tenantId): array
    {
        $row = InventoryTransaction::query()
            ->where('tenant_id', $tenantId)
            ->select(DB::raw($this->inventoryWeightExpression().' as weight'), DB::raw($this->inventoryPieceExpression().' as pieces'))
            ->first();

        return ['weight' => (float) ($row->weight ?? 0), 'pieces' => (float) ($row->pieces ?? 0)];
    }

    private function inventoryWeightExpression(): string
    {
        return "sum(case when transaction_type in ('dispatch_deduction', 'production_cancellation') then -weight_quantity else weight_quantity end)";
    }

    private function inventoryPieceExpression(): string
    {
        return "sum(case when transaction_type in ('dispatch_deduction', 'production_cancellation') then -coalesce(piece_quantity, 0) else coalesce(piece_quantity, 0) end)";
    }

    private function inventoryDetailCards(
        string $tenantId,
        ?string $productId = null,
        ?string $variantId = null,
    ) {
        $products = Product::query()->where('tenant_id', $tenantId)->pluck('name', 'id');
        $productions = ProductionTransaction::query()
            ->where('tenant_id', $tenantId)
            ->where('status', 'active')
            ->when($productId, fn ($query, $id) => $query->where('product_id', $id))
            ->when($variantId, fn ($query, $id) => $query->where('variant_id', $id))
            ->latest('captured_at')
            ->limit(300)
            ->get(['product_id', 'variant_id', 'dynamic_values', 'net_weight', 'piece_quantity']);

        return $productions
            ->map(function (ProductionTransaction $row) use ($products) {
                $details = collect($row->dynamic_values ?? [])
                    ->filter(fn ($value) => filled($value))
                    ->mapWithKeys(function ($value, $key) {
                        return [
                            str($key)->replace('_', ' ')->title()->toString() => is_array($value)
                                ? implode(', ', $value)
                                : (string) $value,
                        ];
                    })
                    ->all();

                return [
                    'product_id' => $row->product_id,
                    'variant_id' => $row->variant_id,
                    'product' => $products[$row->product_id] ?? 'Product',
                    'details' => $details,
                    'weight' => (float) $row->net_weight,
                    'pieces' => (float) ($row->piece_quantity ?? 0),
                ];
            })
            ->groupBy(fn ($row) => $row['product_id'].'|'.($row['variant_id'] ?? '').'|'.json_encode($row['details']))
            ->map(function ($rows) {
                $first = $rows->first();

                return [
                    'product_id' => $first['product_id'],
                    'variant_id' => $first['variant_id'],
                    'product' => $first['product'],
                    'details' => $first['details'],
                    'weight' => $rows->sum('weight'),
                    'pieces' => $rows->sum('pieces'),
                    'entries' => $rows->count(),
                ];
            })
            ->sortByDesc('weight')
            ->take(16)
            ->values();
    }

    private function dateRange(Request $request, int $defaultDays = 7): array
    {
        $to = $request->filled('to') ? CarbonImmutable::parse($request->to)->endOfDay() : now()->toImmutable()->endOfDay();
        $from = $request->filled('from') ? CarbonImmutable::parse($request->from)->startOfDay() : $to->subDays($defaultDays - 1)->startOfDay();

        return [$from, $to];
    }

    private function tenantId(): string
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);

        return $tenantId;
    }

    private function ensureTenant(?string $tenantId): void
    {
        abort_unless($tenantId === $this->tenantId(), 404);
    }

    private function audit(string $action, $model, array $old, array $new, array $metadata = []): void
    {
        AuditLog::query()->create([
            'tenant_id' => Auth::user()?->tenant_id,
            'user_id' => Auth::id(),
            'action' => $action,
            'auditable_type' => $model::class,
            'auditable_id' => $model->id,
            'old_values' => $old,
            'new_values' => $new,
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }

    private function basicPdf(string $title, array $columns, $rows): string
    {
        $lines = [strtoupper($title).' REPORT', 'Generated: '.now()->format('Y-m-d H:i'), implode(' | ', $columns)];
        foreach ($rows->take(40) as $row) {
            $lines[] = implode(' | ', array_map(fn ($column) => (string) data_get($row, $column), $columns));
        }
        $text = implode('\\n', array_map(fn ($line) => str_replace(['(', ')', '\\'], ['[', ']', '/'], $line), $lines));

        return "%PDF-1.4\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n4 0 obj << /Length ".(strlen($text) + 80)." >> stream\nBT /F1 9 Tf 40 760 Td 12 TL (".$text.") Tj ET\nendstream endobj\n5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\nxref\n0 6\n0000000000 65535 f \ntrailer << /Root 1 0 R /Size 6 >>\nstartxref\n0\n%%EOF";
    }

    private function dispatchPdf(Dispatch $dispatch): string
    {
        $rows = $this->dispatchExportRows($dispatch);
        $dynamicColumns = $this->dispatchDynamicColumns($rows, $dispatch->tenant_id);
        $customer = data_get($dispatch->customer_snapshot, 'name', '-');
        $address = data_get($dispatch->customer_snapshot, 'shipping_address', '-');
        $columns = $this->dispatchPdfColumns(
            $dynamicColumns,
            array_keys($this->selectedReportColumns('dispatch', $dynamicColumns))
        );

        $logo = $this->reportLogo($dispatch->tenant_id);
        $lines = [
            ...$this->pdfHeaderLines($dispatch->tenant_id, 'DISPATCH / MATERIAL ISSUE REPORT'),
            ['Customer: '.$customer, 28, 724, 10],
            ['Dispatch No: '.$dispatch->dispatch_number, 28, 706, 8],
            ['Date: '.(($dispatch->confirmed_at ?? $dispatch->created_at)?->format('d M Y H:i') ?? '-'), 176, 706, 8],
            ['Address: '.$address, 28, 690, 7],
        ];

        $tableTop = 650;
        $rowHeight = 24;
        $headerY = $tableTop - 15;
        foreach ($columns as $column) {
            $lines[] = [$column['label'], $column['x'] + 3, $headerY, 6.8];
        }

        $y = $tableTop - $rowHeight - 14;
        foreach ($rows->take(22) as $index => $row) {
            foreach ($columns as $column) {
                $value = match ($column['key']) {
                    'sr' => (string) ($index + 1),
                    'product_name' => $row['product_name'],
                    'gross_weight' => (string) $row['gross_weight'],
                    'tare_weight' => (string) $row['tare_weight'],
                    'net_weight' => (string) $row['net_weight'],
                    'converted_unit' => $row['converted_unit'],
                    'barcode_value' => $row['barcode_value'],
                    default => (string) data_get($row, 'product_fields.'.$column['key'], '-'),
                };
                $lines[] = [$value, $column['x'] + 3, $y, 6.4];
            }
            $y -= $rowHeight;
        }

        $lines[] = ['SUMMARY', 28, 110, 10];
        $lines[] = ['Total labels: '.$rows->count(), 28, 92, 8];
        $lines[] = ['Gross: '.$rows->sum('gross_weight').' kg', 126, 92, 8];
        $lines[] = ['Tare: '.$rows->sum('tare_weight').' kg', 232, 92, 8];
        $lines[] = ['Net: '.$rows->sum('net_weight').' kg', 338, 92, 8];
        $lines[] = ['Converted: '.$rows->sum('piece_quantity'), 444, 92, 8];
        $lines = [...$lines, ...$this->pdfFooterLines($dispatch->tenant_id)];

        $text = ($logo ? "q 44 0 0 34 28 796 cm /Im1 Do Q\n" : '');
        $text .= "0.2 w 24 734 548 1 re f\n";
        $text .= "24 668 548 1 re f\n";
        $text .= $this->dispatchTableGrid($columns, $tableTop, $rowHeight, 23);
        $text .= "24 122 548 1 re f\n24 58 548 1 re f\n";
        foreach ($lines as [$line, $x, $lineY, $size]) {
            $text .= 'BT /F1 '.$size.' Tf '.$x.' '.$lineY.' Td ('.$this->pdfEscape((string) $line).") Tj ET\n";
        }

        return $this->pdfDocument($text, image: $logo);
    }

    private function inwardPdf(string $session, $productions, string $tenantId, ?InwardSession $inwardSession = null): string
    {
        $rows = $this->inwardExportRows($productions, $tenantId);
        $dynamicColumns = $this->dispatchDynamicColumns($rows, $tenantId);
        $columns = $this->dispatchPdfColumns(
            $dynamicColumns,
            array_keys($this->selectedReportColumns('inward', $dynamicColumns, includeTime: true))
        );
        $date = $inwardSession?->started_at?->toImmutable() ?? CarbonImmutable::parse($session);
        $startedAt = $productions->first()?->captured_at;
        $endedAt = $productions->last()?->captured_at;

        $logo = $this->reportLogo($tenantId);
        $lines = [
            ...$this->pdfHeaderLines($tenantId, 'INWARD / MATERIAL RECEIPT REPORT'),
            ['Inward No: '.($inwardSession?->session_number ?? 'INW-'.$date->format('Ymd')), 28, 724, 9],
            ['Started: '.($startedAt?->format('d M Y H:i') ?? '-'), 28, 706, 8],
            ['Ended: '.($endedAt?->format('d M Y H:i') ?? '-'), 176, 706, 8],
            ['Entries: '.$rows->count(), 310, 706, 8],
            ['Session Date: '.$date->format('d M Y'), 430, 706, 8],
        ];

        $tableTop = 668;
        $rowHeight = 24;
        $headerY = $tableTop - 15;
        foreach ($columns as $column) {
            $lines[] = [$column['label'], $column['x'] + 3, $headerY, 6.8];
        }

        $y = $tableTop - $rowHeight - 14;
        foreach ($rows->take(23) as $index => $row) {
            foreach ($columns as $column) {
                $value = match ($column['key']) {
                    'sr' => (string) ($index + 1),
                    'product_name' => $row['product_name'],
                    'gross_weight' => (string) $row['gross_weight'],
                    'tare_weight' => (string) $row['tare_weight'],
                    'net_weight' => (string) $row['net_weight'],
                    'converted_unit' => $row['converted_unit'],
                    'barcode_value' => $row['barcode_value'],
                    default => (string) data_get($row, 'product_fields.'.$column['key'], '-'),
                };
                $lines[] = [$value, $column['x'] + 3, $y, 6.4];
            }
            $y -= $rowHeight;
        }

        $lines[] = ['SUMMARY', 28, 92, 10];
        $lines[] = ['Total entries: '.$rows->count(), 28, 74, 8];
        $lines[] = ['Gross: '.$rows->sum('gross_weight').' kg', 126, 74, 8];
        $lines[] = ['Tare: '.$rows->sum('tare_weight').' kg', 232, 74, 8];
        $lines[] = ['Net: '.$rows->sum('net_weight').' kg', 338, 74, 8];
        $lines[] = ['Converted: '.$rows->sum('piece_quantity'), 444, 74, 8];
        $lines = [...$lines, ...$this->pdfFooterLines($tenantId)];

        $text = ($logo ? "q 44 0 0 34 28 796 cm /Im1 Do Q\n" : '');
        $text .= "0.2 w 24 734 548 1 re f\n";
        $text .= "24 686 548 1 re f\n";
        $text .= $this->dispatchTableGrid($columns, $tableTop, $rowHeight, 24);
        $text .= "24 104 548 1 re f\n";
        foreach ($lines as [$line, $x, $lineY, $size]) {
            $text .= 'BT /F1 '.$size.' Tf '.$x.' '.$lineY.' Td ('.$this->pdfEscape((string) $line).") Tj ET\n";
        }

        return $this->pdfDocument($text, image: $logo);
    }

    private function dispatchExportRows(Dispatch $dispatch)
    {
        $productions = ProductionTransaction::query()
            ->where('tenant_id', $dispatch->tenant_id)
            ->whereIn('id', $dispatch->items->pluck('production_transaction_id')->filter())
            ->get()
            ->keyBy('id');

        return $dispatch->items->map(function ($item) use ($productions, $dispatch): array {
            $production = $productions->get($item->production_transaction_id);
            $variantFields = ProductVariant::query()
                ->where('tenant_id', $dispatch->tenant_id)
                ->find($production?->variant_id)?->metadata['dynamic_fields'] ?? [];
            $dynamic = collect($variantFields)
                ->merge($production?->dynamic_values ?? [])
                ->mapWithKeys(fn ($value, $key) => [$key => is_array($value) ? implode(',', $value) : $value])
                ->all();

            return [
                'product_name' => $this->productionProductName($production),
                'product_fields' => $dynamic,
                'gross_weight' => (float) ($production?->gross_weight ?? $item->weight_quantity),
                'tare_weight' => (float) ($production?->tare_weight ?? 0),
                'net_weight' => (float) ($production?->net_weight ?? $item->weight_quantity),
                'piece_quantity' => (float) ($production?->piece_quantity ?? $item->piece_quantity ?? 0),
                'converted_unit' => filled($production?->piece_quantity ?? $item->piece_quantity) ? ($production?->piece_quantity ?? $item->piece_quantity).' pcs' : '-',
                'barcode_value' => $item->barcode_value,
            ];
        });
    }

    private function inwardExportRows($productions, string $tenantId)
    {
        $variants = ProductVariant::query()
            ->where('tenant_id', $tenantId)
            ->whereIn('id', $productions->pluck('variant_id')->filter()->unique())
            ->get()
            ->keyBy('id');

        return $productions->map(function (ProductionTransaction $production) use ($variants): array {
            $variantFields = $variants->get($production->variant_id)?->metadata['dynamic_fields'] ?? [];
            $dynamic = collect($variantFields)
                ->merge($production->dynamic_values ?? [])
                ->mapWithKeys(fn ($value, $key) => [$key => is_array($value) ? implode(',', $value) : $value])
                ->all();

            return [
                'product_name' => $this->productionProductName($production),
                'product_fields' => $dynamic,
                'gross_weight' => (float) $production->gross_weight,
                'tare_weight' => (float) $production->tare_weight,
                'net_weight' => (float) $production->net_weight,
                'piece_quantity' => (float) ($production->piece_quantity ?? 0),
                'converted_unit' => filled($production->piece_quantity) ? $production->piece_quantity.' pcs' : '-',
                'barcode_value' => $production->barcode_value,
                'captured_at' => $production->captured_at?->format('Y-m-d H:i'),
            ];
        });
    }

    private function dispatchDynamicColumns($rows, string $tenantId)
    {
        $keys = $rows
            ->flatMap(fn ($row) => array_keys($row['product_fields'] ?? []))
            ->unique()
            ->values();

        $labels = DynamicFieldDefinition::query()
            ->where('tenant_id', $tenantId)
            ->whereIn('internal_key', $keys)
            ->pluck('field_label', 'internal_key');

        return $keys->mapWithKeys(fn ($key) => [$key => $labels[$key] ?? str($key)->replace('_', ' ')->title()->toString()]);
    }

    private function selectedReportColumns(string $report, $dynamicColumns, bool $includeTime = false): array
    {
        $settings = Auth::user()?->tenant?->settings ?? [];
        $configured = data_get($settings, "reportColumns.$report", []);
        $dynamic = collect($dynamicColumns)
            ->merge($this->configuredDynamicColumnLabels(is_array($configured) ? $configured : []))
            ->all();
        $available = [
            'sr' => 'S/R',
            'barcode_value' => 'Barcode',
            'product_name' => 'Product',
            ...$dynamic,
            'gross_weight' => 'Gross kg',
            'tare_weight' => 'Tare kg',
            'net_weight' => 'Net kg',
            'converted_unit' => 'Unit Conv.',
        ];

        if ($includeTime) {
            $available['captured_at'] = 'Time';
        }

        if (! is_array($configured) || $configured === []) {
            return $available;
        }

        $selected = collect($configured)
            ->filter(fn ($key) => array_key_exists($key, $available))
            ->mapWithKeys(fn ($key) => [$key => $available[$key]])
            ->all();

        return $selected === [] ? $available : $selected;
    }

    private function configuredDynamicColumnLabels(array $configured): array
    {
        $reserved = [
            'sr',
            'barcode_value',
            'product_name',
            'gross_weight',
            'tare_weight',
            'net_weight',
            'converted_unit',
            'captured_at',
        ];
        $keys = collect($configured)->diff($reserved)->values();
        if ($keys->isEmpty()) {
            return [];
        }

        return DynamicFieldDefinition::query()
            ->where('tenant_id', $this->tenantId())
            ->whereIn('internal_key', $keys)
            ->pluck('field_label', 'internal_key')
            ->all();
    }

    private function reportExportValues(array $row, array $columns): array
    {
        return array_map(
            fn ($column) => $column === 'product_name'
                ? $row['product_name']
                : ($row['product_fields'][$column] ?? data_get($row, $column, '-')),
            $columns
        );
    }

    private function productionProductName(?ProductionTransaction $production): string
    {
        if (! $production) {
            return '-';
        }

        return data_get($production->product_snapshot, 'name')
            ?? data_get($production->product_snapshot, 'product.name')
            ?? Product::query()
                ->where('tenant_id', $production->tenant_id)
                ->where('id', $production->product_id)
                ->value('name')
            ?? '-';
    }

    private function pdfHeaderLines(string $tenantId, string $title): array
    {
        $tenant = Auth::user()?->tenant;
        $settings = $tenant?->settings ?? [];
        $header = $settings['reportHeader'] ?? [];
        $left = $this->reportLogo($tenantId) ? 82 : 28;
        $lines = [
            [$this->pdfText($tenant?->name ?? 'Company', 52), $left, 812, 13],
            [$this->pdfText($title, 60), $left, 792, 10.5],
        ];

        $parts = array_values(array_filter([
            $header['phone'] ?? null,
            $header['email'] ?? null,
            $header['gst'] ?? ($settings['taxNumber'] ?? null),
            $header['contact'] ?? null,
        ]));
        foreach ($this->pdfWrappedRows(implode(' | ', $parts), 92, 2) as $index => $row) {
            $lines[] = [$row, $left, 776 - ($index * 10), 6.8];
        }
        foreach (array_slice(array_filter([
            $header['address'] ?? ($settings['companyAddress'] ?? null),
            $header['extra1'] ?? null,
            $header['extra2'] ?? null,
        ]), 0, 3) as $index => $line) {
            $lines[] = [$this->pdfText($line, 100), $left, 754 - ($index * 9), 6.8];
        }

        return $lines;
    }

    private function pdfFooterLines(string $tenantId): array
    {
        $settings = Auth::user()?->tenant?->settings ?? [];
        $footer = array_values(array_filter($settings['reportFooter'] ?? [
            'Solution fully built inhouse by engineers of Punit Instrument Pvt Ltd and Punit Technologies using patented tech | 30 years of R & D | proudly 100% made in India',
            'For software training support contact us 9737599004',
        ]));
        $lines = [
            [$this->pdfText($footer[0] ?? 'Solution fully built inhouse by engineers of Punit Instrument Pvt Ltd and Punit Technologies using patented tech | 30 years of R & D | proudly 100% made in India', 122), 28, 38, 6.4],
            [$this->pdfText($footer[1] ?? 'For software training support contact us 9737599004', 122), 28, 26, 6.4],
        ];
        if (isset($footer[2])) {
            $lines[] = [$this->pdfText($footer[2], 122), 28, 14, 6.2];
        }

        return $lines;
    }

    private function pdfText(?string $value, int $limit): string
    {
        return mb_strimwidth(trim((string) $value), 0, $limit, '...');
    }

    private function pdfWrappedRows(string $value, int $limit, int $maxRows): array
    {
        $value = trim(preg_replace('/\s+/', ' ', $value));
        if ($value === '') {
            return [];
        }

        return collect(str_split($value, $limit))
            ->take($maxRows)
            ->map(fn ($row) => $this->pdfText($row, $limit))
            ->all();
    }

    private function dispatchPdfColumns($dynamicColumns, ?array $selectedKeys = null): array
    {
        $columns = [
            ['key' => 'sr', 'label' => 'S/R', 'width' => 24],
            ['key' => 'barcode_value', 'label' => 'Barcode', 'width' => 64],
            ['key' => 'product_name', 'label' => 'Product', 'width' => 88],
        ];

        foreach ($dynamicColumns as $key => $label) {
            $columns[] = ['key' => $key, 'label' => $label, 'width' => 42];
        }

        $columns = [
            ...$columns,
            ['key' => 'gross_weight', 'label' => 'Gross kg', 'width' => 45],
            ['key' => 'tare_weight', 'label' => 'Tare kg', 'width' => 42],
            ['key' => 'net_weight', 'label' => 'Net kg', 'width' => 42],
            ['key' => 'converted_unit', 'label' => 'Unit Conv.', 'width' => 52],
        ];

        if ($selectedKeys !== null && $selectedKeys !== []) {
            $columns = collect($columns)
                ->filter(fn ($column) => in_array($column['key'], $selectedKeys, true))
                ->values()
                ->all();
        }

        $available = 548;
        $total = collect($columns)->sum('width');
        if ($total > $available) {
            $scale = $available / $total;
            $columns = collect($columns)->map(function ($column) use ($scale) {
                $column['width'] = max(25, $column['width'] * $scale);

                return $column;
            })->all();
        }

        $x = 24;
        foreach ($columns as $index => $column) {
            $columns[$index]['x'] = $x;
            $x += $column['width'];
        }

        return $columns;
    }

    private function dispatchTableGrid(array $columns, int $top, int $rowHeight, int $rowCount): string
    {
        $left = 24;
        $right = 572;
        $bottom = $top - ($rowHeight * $rowCount);
        $grid = '';
        for ($i = 0; $i <= $rowCount; $i++) {
            $y = $top - ($i * $rowHeight);
            $grid .= "{$left} {$y} m {$right} {$y} l S\n";
        }
        foreach ($columns as $column) {
            $x = $column['x'];
            $grid .= "{$x} {$top} m {$x} {$bottom} l S\n";
        }
        $grid .= "{$right} {$top} m {$right} {$bottom} l S\n";

        return $grid;
    }

    private function reportLogo(string $tenantId): ?array
    {
        $settings = Auth::user()?->tenant?->settings ?? [];
        $path = $settings['logoPath'] ?? null;
        if (! $path) {
            return null;
        }

        $fullPath = storage_path('app/public/'.$path);
        if (! is_file($fullPath)) {
            return null;
        }

        $bytes = file_get_contents($fullPath);
        $info = @getimagesizefromstring($bytes);
        if (! $info) {
            return null;
        }

        if (($info['mime'] ?? '') === 'image/jpeg') {
            return ['data' => $bytes, 'width' => $info[0], 'height' => $info[1]];
        }

        if (extension_loaded('gd') && in_array($info['mime'] ?? '', ['image/png', 'image/webp'], true)) {
            $source = ($info['mime'] ?? '') === 'image/png' ? @imagecreatefrompng($fullPath) : @imagecreatefromwebp($fullPath);
            if (! $source) {
                return null;
            }
            $canvas = imagecreatetruecolor(imagesx($source), imagesy($source));
            $white = imagecolorallocate($canvas, 255, 255, 255);
            imagefill($canvas, 0, 0, $white);
            imagecopy($canvas, $source, 0, 0, 0, 0, imagesx($source), imagesy($source));
            ob_start();
            imagejpeg($canvas, null, 85);
            $jpg = ob_get_clean();
            imagedestroy($source);
            imagedestroy($canvas);

            return ['data' => $jpg, 'width' => $info[0], 'height' => $info[1]];
        }

        return null;
    }

    private function pdfDocument(string $content, bool $landscape = false, ?array $image = null): string
    {
        $mediaBox = $landscape ? '[0 0 842 595]' : '[0 0 595 842]';
        $resource = '/Font << /F1 5 0 R >>';
        if ($image) {
            $resource .= ' /XObject << /Im1 6 0 R >>';
        }
        $objects = [
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /MediaBox '.$mediaBox.' /Contents 4 0 R /Resources << '.$resource.' >> >>',
            '<< /Length '.strlen($content)." >>\nstream\n".$content.'endstream',
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        ];
        if ($image) {
            $objects[] = "<< /Type /XObject /Subtype /Image /Width {$image['width']} /Height {$image['height']} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ".strlen($image['data'])." >>\nstream\n".$image['data'].'endstream';
        }

        $pdf = "%PDF-1.4\n";
        $offsets = [0];
        foreach ($objects as $index => $object) {
            $offsets[] = strlen($pdf);
            $pdf .= ($index + 1)." 0 obj\n".$object."\nendobj\n";
        }

        $xref = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n0000000000 65535 f \n";
        foreach (array_slice($offsets, 1) as $offset) {
            $pdf .= str_pad((string) $offset, 10, '0', STR_PAD_LEFT)." 00000 n \n";
        }

        return $pdf.'trailer << /Root 1 0 R /Size '.(count($objects) + 1)." >>\nstartxref\n".$xref."\n%%EOF";
    }

    private function pdfEscape(string $text): string
    {
        return str_replace(['\\', '(', ')'], ['\\\\', '\(', '\)'], mb_substr($text, 0, 95));
    }

    private function xlsxWorkbook(string $sheetName, array $rows): string
    {
        $tmp = tempnam(sys_get_temp_dir(), 'xlsx_');
        $zip = new \ZipArchive;
        $zip->open($tmp, \ZipArchive::OVERWRITE);
        $zip->addFromString('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>');
        $zip->addFromString('_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>');
        $zip->addFromString('xl/_rels/workbook.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>');
        $zip->addFromString('xl/workbook.xml', '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="'.$this->xmlEscape(mb_substr($sheetName, 0, 31)).'" sheetId="1" r:id="rId1"/></sheets></workbook>');
        $zip->addFromString('xl/styles.xml', '<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders><cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellXfs></styleSheet>');
        $zip->addFromString('xl/worksheets/sheet1.xml', $this->worksheetXml($rows));
        $zip->close();
        $content = file_get_contents($tmp);
        unlink($tmp);

        return $content;
    }

    private function worksheetXml(array $rows): string
    {
        $xml = '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>';
        foreach ($rows as $rowIndex => $row) {
            $xml .= '<row r="'.($rowIndex + 1).'">';
            foreach (array_values($row) as $columnIndex => $value) {
                $cell = chr(65 + $columnIndex).($rowIndex + 1);
                $xml .= '<c r="'.$cell.'" t="inlineStr"><is><t>'.$this->xmlEscape((string) $value).'</t></is></c>';
            }
            $xml .= '</row>';
        }

        return $xml.'</sheetData></worksheet>';
    }

    private function xmlEscape(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_XML1, 'UTF-8');
    }
}
