<?php

use App\Http\Controllers\Web\AdminBatchController;
use App\Http\Controllers\Web\AdminPanelController;
use App\Http\Controllers\Web\PublicVerificationController;
use App\Http\Controllers\Web\QrPageController;
use App\Models\Permission;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\TenantOnboardingInvite;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Route;
use Illuminate\Validation\Rules\Password;

Route::get('/', function () {
    if (Auth::check()) {
        return redirect('/dashboard');
    }

    return view('welcome');
});

Route::get('/downloads/latest', fn () => redirect('/downloads/PUNIT-ERP-v1.1.19-build24.apk'))
    ->name('app.download.latest');

Route::get('/login', function () {
    return view('auth.login');
})->name('login');

Route::post('/login', function (Request $request) {
    $data = $request->validate([
        'login' => ['required', 'string', 'max:255'],
        'password' => ['required', 'string'],
    ]);
    $login = trim($data['login']);
    $phone = preg_replace('/\D+/', '', $login);
    $user = User::query()
        ->where(function ($query) use ($login, $phone): void {
            $query->where('email', $login);
            $query->orWhere('app_username', $login);
            if ($phone !== '') {
                $query->orWhere('phone', $phone);
            }
        })
        ->where('is_active', true)
        ->first();

    if (! $user || ! Hash::check($data['password'], $user->password)) {
        return back()->withErrors(['login' => 'Invalid login details.'])->withInput();
    }

    if ($user->app_only) {
        return back()->withErrors(['login' => 'This is an app-only login. Use it in the Punit ERP app.'])->withInput();
    }

    Auth::login($user, true);
    $request->session()->regenerate();

    return redirect()->intended('/dashboard');
})->name('login.store');

Route::post('/logout', function (Request $request) {
    Auth::logout();
    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect()->route('login');
})->name('logout');

Route::get('/verify/{token}', [PublicVerificationController::class, 'show'])
    ->middleware('throttle:120,1')
    ->name('verification.show');
Route::post('/verify/{token}/complaints', [PublicVerificationController::class, 'complaint'])
    ->middleware('throttle:5,10')
    ->name('verification.complaints.store');

Route::get('/onboarding', fn () => view('auth.onboarding'))->name('onboarding.start');
Route::post('/onboarding', function (Request $request) {
    $data = $request->validate([
        'phone' => ['required', 'string', 'max:32'],
        'company_name' => ['required', 'string', 'max:255'],
        'name' => ['required', 'string', 'max:255'],
        'email' => ['required', 'email', 'max:255', 'unique:users,email'],
        'password' => ['required', 'confirmed', Password::min(8)],
    ]);
    $phone = preg_replace('/\D+/', '', $data['phone']);
    $invite = TenantOnboardingInvite::query()
        ->where('phone', $phone)
        ->where('status', 'pending')
        ->latest()
        ->first();

    if (! $invite || ! $invite->isClaimable()) {
        return back()->withErrors(['phone' => 'This phone number is not approved for onboarding or has expired.'])->withInput();
    }

    $user = DB::transaction(function () use ($data, $phone, $invite) {
        $tenant = Tenant::query()->create([
            'name' => $data['company_name'],
            'code' => 'TEN-'.strtoupper(str()->random(8)),
            'status' => 'active',
            'settings' => [
                'adminLimit' => $invite->admin_limit,
                'reportFooter' => [
                    'Solution fully built inhouse by engineers of Punit Instrument Pvt Ltd and Punit Technologies using patented tech | 30 years of R & D | proudly 100% made in India',
                    'For software training support contact us 9737599004',
                ],
            ],
        ]);
        $role = Role::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'key' => 'company-admin'],
            ['name' => 'Company Admin', 'is_system' => true],
        );
        $role->permissions()->syncWithoutDetaching(Permission::query()->pluck('id'));
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $phone,
            'password' => Hash::make($data['password']),
            'is_active' => true,
        ]);
        $user->roles()->syncWithoutDetaching([$role->id]);
        $invite->update([
            'tenant_id' => $tenant->id,
            'status' => 'claimed',
            'claimed_by' => $user->id,
            'claimed_at' => now(),
        ]);

        return $user;
    });

    Auth::login($user, true);
    $request->session()->regenerate();

    return redirect()->route('admin.tenant-settings')->with('status', 'Company admin created. Add report details and logo here.');
})->name('onboarding.store');

Route::middleware('auth')->group(function (): void {
    Route::get('/account/password', [AdminPanelController::class, 'accountPassword'])->name('admin.account.password');
    Route::patch('/account/password', [AdminPanelController::class, 'accountPasswordUpdate'])->name('admin.account.password.update');
    Route::middleware('permission:products.view')->group(function (): void {
        Route::get('/batches', [AdminBatchController::class, 'index'])->name('admin.batches');
        Route::post('/batches', [AdminBatchController::class, 'store'])->name('admin.batches.store');
        Route::delete('/batches/{batch}/items/{itemIndex}/fields/{fieldKey}', [AdminBatchController::class, 'destroyField'])
            ->whereNumber('itemIndex')
            ->name('admin.batches.fields.destroy');
        Route::delete('/batches/{batch}', [AdminBatchController::class, 'destroy'])->name('admin.batches.destroy');
    });
    Route::get('/dashboard', [AdminPanelController::class, 'dashboard'])->name('admin.dashboard');
    Route::get('/production', [AdminPanelController::class, 'production'])->name('admin.production');
    Route::post('/production', [AdminPanelController::class, 'productionCreate'])->name('admin.production.create');
    Route::get('/production/{production}', [AdminPanelController::class, 'productionShow'])->name('admin.production.show');
    Route::post('/production/{production}/cancel', [AdminPanelController::class, 'productionCancel'])->name('admin.production.cancel');
    Route::get('/inventory', [AdminPanelController::class, 'inventory'])->name('admin.inventory');
    Route::get('/inventory/closing-stock/export', [AdminPanelController::class, 'closingStockExport'])->name('admin.inventory.closing-stock.export');
    Route::post('/inventory/adjust', [AdminPanelController::class, 'inventoryAdjust'])->name('admin.inventory.adjust');
    Route::delete('/inventory/clear', [AdminPanelController::class, 'inventoryClear'])->name('admin.inventory.clear');
    Route::get('/customers', [AdminPanelController::class, 'customers'])->name('admin.customers');
    Route::post('/customers/{customer?}', [AdminPanelController::class, 'customerSave'])->name('admin.customers.save');
    Route::delete('/customers/{customer}', [AdminPanelController::class, 'customerDelete'])->name('admin.customers.delete');
    Route::get('/dispatch', [AdminPanelController::class, 'dispatches'])->name('admin.dispatch');
    Route::post('/dispatch', [AdminPanelController::class, 'dispatchCreate'])->name('admin.dispatch.create');
    Route::post('/dispatch/{dispatch}/reverse', [AdminPanelController::class, 'dispatchReverse'])->name('admin.dispatch.reverse');
    Route::delete('/dispatch/{dispatch}/items/{item}', [AdminPanelController::class, 'dispatchItemDelete'])->name('admin.dispatch.items.delete');
    Route::get('/inward-report', [AdminPanelController::class, 'inwardReport'])->name('admin.inward-report');
    Route::get('/dispatch-report', [AdminPanelController::class, 'dispatchReport'])->name('admin.dispatch-report');
    Route::get('/reports/{report?}', [AdminPanelController::class, 'reports'])->name('admin.reports');
    Route::get('/exports/{report}/{format}', [AdminPanelController::class, 'export'])->name('admin.exports');
    Route::get('/import', [AdminPanelController::class, 'imports'])->name('admin.imports');
    Route::get('/import/template/{type}', [AdminPanelController::class, 'importTemplate'])->name('admin.imports.template');
    Route::get('/import/products/export', [AdminPanelController::class, 'exportProducts'])->name('admin.imports.products.export');
    Route::post('/import/products', [AdminPanelController::class, 'importProducts'])->name('admin.imports.products');
    Route::post('/import/product-details', [AdminPanelController::class, 'importProductDetails'])->name('admin.imports.product-details');
    Route::delete('/import/preview/{type}', [AdminPanelController::class, 'clearImportPreview'])->name('admin.imports.preview.clear');
    Route::get('/export', [AdminPanelController::class, 'exportCenter'])->name('admin.export-center');
    Route::get('/inward/{session}/export/{format}', [AdminPanelController::class, 'inwardExport'])->name('admin.inward.export');
    Route::get('/dispatch/{dispatch}/export/{format}', [AdminPanelController::class, 'dispatchExport'])->name('admin.dispatch.export');
    Route::get('/sync-status', [AdminPanelController::class, 'sync'])->name('admin.sync');
    Route::get('/audit-logs', [AdminPanelController::class, 'auditLogs'])->name('admin.audit');
    Route::get('/tenant-settings', [AdminPanelController::class, 'tenantSettings'])->name('admin.tenant-settings');
    Route::post('/tenant-settings', [AdminPanelController::class, 'tenantSettingsSave'])->name('admin.tenant-settings.save');
    Route::middleware('permission:configuration.manage')->group(function (): void {
        Route::get('/qr-page-design', [QrPageController::class, 'edit'])->name('admin.qr-page.edit');
        Route::post('/qr-page-design', [QrPageController::class, 'update'])->name('admin.qr-page.update');
        Route::get('/qr-complaints', [QrPageController::class, 'complaints'])->name('admin.qr-complaints.index');
        Route::patch('/qr-complaints/{complaint}', [QrPageController::class, 'updateComplaint'])->name('admin.qr-complaints.update');
        Route::get('/qr-complaints/{complaint}/photo', [QrPageController::class, 'complaintPhoto'])->name('admin.qr-complaints.photo');
    });
    Route::get('/app-users', [AdminPanelController::class, 'appUsers'])->name('admin.app-users');
    Route::post('/app-users', [AdminPanelController::class, 'appUserStore'])->name('admin.app-users.store');
    Route::patch('/app-users/{user}', [AdminPanelController::class, 'appUserUpdate'])->name('admin.app-users.update');
    Route::patch('/app-users/{user}/status', [AdminPanelController::class, 'appUserStatus'])->name('admin.app-users.status');
    Route::delete('/app-users/{user}', [AdminPanelController::class, 'userDestroy'])->name('admin.app-users.destroy');
    Route::delete('/admin/users/{user}', [AdminPanelController::class, 'userDestroy'])->name('admin.users.destroy');
    Route::post('/admin/roles', [AdminPanelController::class, 'roleStore'])->name('admin.roles.store');
    Route::delete('/products/clear', [AdminPanelController::class, 'productsClear'])->name('admin.products.clear');
    Route::get('/superadmin/onboarding', [AdminPanelController::class, 'superAdminOnboarding'])->name('admin.superadmin.onboarding');
    Route::post('/superadmin/onboarding', [AdminPanelController::class, 'superAdminOnboardingSave'])->name('admin.superadmin.onboarding.save');
    Route::get('/superadmin/admins', [AdminPanelController::class, 'superAdminAdmins'])->name('admin.superadmin.admins');
    Route::patch('/superadmin/admins/{user}/password', [AdminPanelController::class, 'superAdminAdminPasswordUpdate'])
        ->name('admin.superadmin.admins.password');
    Route::get('/admin/{section}', [AdminPanelController::class, 'resource'])->name('admin.resource');

    Route::get('/products', function () {
        return view('products.index', ['title' => 'Products']);
    })->name('admin.products');

    Route::get('/product-details', function () {
        return view('product-details.index', ['title' => 'Product Details']);
    })->name('admin.product-details');

    Route::get('/labels/{template?}', function (?string $template = null) {
        return view('labels.index', ['title' => 'Label Templates', 'template' => $template]);
    })->name('admin.labels');
});
