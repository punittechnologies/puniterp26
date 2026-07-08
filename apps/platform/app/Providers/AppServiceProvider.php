<?php

namespace App\Providers;

use App\Support\TenantContext;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->scoped(TenantContext::class, fn () => new TenantContext);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (config('database.default') !== 'sqlite') {
            return;
        }

        try {
            DB::statement('PRAGMA busy_timeout = 10000');
            DB::statement('PRAGMA journal_mode = WAL');
            DB::statement('PRAGMA synchronous = NORMAL');
        } catch (\Throwable) {
            // SQLite pragmas are best-effort during CLI/bootstrap.
        }
    }
}
