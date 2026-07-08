<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        $permissions = collect([
            ['key' => 'app.login', 'name' => 'Login to tablet app', 'module' => 'app'],
            ['key' => 'products.view', 'name' => 'View products', 'module' => 'products'],
            ['key' => 'customers.manage', 'name' => 'Manage customers', 'module' => 'customers'],
            ['key' => 'inventory.view', 'name' => 'View inventory', 'module' => 'inventory'],
            ['key' => 'production.capture', 'name' => 'Capture production', 'module' => 'production'],
            ['key' => 'dispatch.confirm', 'name' => 'Confirm dispatch', 'module' => 'dispatch'],
            ['key' => 'reports.view', 'name' => 'View reports', 'module' => 'reports'],
        ])->map(function (array $permission): object {
            $existing = DB::table('permissions')->where('key', $permission['key'])->first();
            if ($existing) {
                return $existing;
            }

            $id = (string) Str::uuid();
            DB::table('permissions')->insert([
                'id' => $id,
                ...$permission,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return (object) ['id' => $id, ...$permission];
        });

        $roleIds = DB::table('role_user')
            ->join('users', 'users.id', '=', 'role_user.user_id')
            ->where('users.app_only', true)
            ->pluck('role_user.role_id')
            ->unique();

        foreach ($roleIds as $roleId) {
            foreach ($permissions as $permission) {
                DB::table('permission_role')->updateOrInsert([
                    'role_id' => $roleId,
                    'permission_id' => $permission->id,
                ]);
            }
        }
    }

    public function down(): void
    {
        //
    }
};
