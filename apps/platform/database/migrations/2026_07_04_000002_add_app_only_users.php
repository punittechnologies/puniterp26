<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'app_username')) {
                $table->string('app_username')->nullable()->unique()->after('phone');
            }

            if (! Schema::hasColumn('users', 'app_only')) {
                $table->boolean('app_only')->default(false)->index()->after('app_username');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'app_username')) {
                $table->dropUnique(['app_username']);
                $table->dropColumn('app_username');
            }

            if (Schema::hasColumn('users', 'app_only')) {
                $table->dropColumn('app_only');
            }
        });
    }
};
