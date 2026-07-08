<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('permissions') || ! Schema::hasTable('roles')) {
            return;
        }

        $permissionId = DB::table('permissions')
            ->where('key', 'app.login')
            ->value('id');

        if (! $permissionId) {
            $permissionId = (string) Str::uuid();
            DB::table('permissions')->insert([
                'id' => $permissionId,
                'key' => 'app.login',
                'name' => 'Login to tablet app',
                'module' => 'app',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $roleIds = DB::table('roles')
            ->whereIn('key', ['company-admin', 'operator', 'dispatch-operator'])
            ->pluck('id')
            ->merge(
                DB::table('permission_role')
                    ->join('permissions', 'permissions.id', '=', 'permission_role.permission_id')
                    ->whereIn('permissions.key', ['production.capture', 'dispatch.confirm'])
                    ->pluck('permission_role.role_id')
            )
            ->unique();

        foreach ($roleIds as $roleId) {
            DB::table('permission_role')->updateOrInsert([
                'role_id' => $roleId,
                'permission_id' => $permissionId,
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('permissions')) {
            return;
        }

        $permissionId = DB::table('permissions')->where('key', 'app.login')->value('id');
        if ($permissionId) {
            DB::table('permission_role')->where('permission_id', $permissionId)->delete();
            DB::table('permissions')->where('id', $permissionId)->delete();
        }
    }
};
