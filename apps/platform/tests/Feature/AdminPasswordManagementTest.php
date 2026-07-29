<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminPasswordManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_change_their_own_password_using_the_current_password(): void
    {
        $admin = $this->companyAdmin();

        $this->actingAs($admin)
            ->patch('/account/password', [
                'current_password' => 'oldpass123',
                'password' => 'newpass123',
                'password_confirmation' => 'newpass123',
            ])
            ->assertRedirect()
            ->assertSessionHas('status');

        $admin->refresh();
        $this->assertTrue(Hash::check('newpass123', $admin->password));
        $this->assertNotNull($admin->password_changed_at);
    }

    public function test_admin_cannot_change_password_without_the_correct_current_password(): void
    {
        $admin = $this->companyAdmin();

        $this->actingAs($admin)
            ->patch('/account/password', [
                'current_password' => 'incorrect123',
                'password' => 'newpass123',
                'password_confirmation' => 'newpass123',
            ])
            ->assertSessionHasErrors('current_password');

        $this->assertTrue(Hash::check('oldpass123', $admin->fresh()->password));
    }

    public function test_superadmin_can_view_admin_ids_and_reset_a_company_admin_password(): void
    {
        $superadmin = User::query()->create([
            'name' => 'Superadmin',
            'email' => 'super@punit.test',
            'password' => Hash::make('superpass123'),
            'is_active' => true,
        ]);
        $admin = $this->companyAdmin();

        $this->actingAs($superadmin)
            ->get('/superadmin/admins')
            ->assertOk()
            ->assertSee($admin->id)
            ->assertSee($admin->email)
            ->assertDontSee('oldpass123');

        $this->actingAs($superadmin)
            ->patch("/superadmin/admins/{$admin->id}/password", [
                'password' => 'temporary123',
                'password_confirmation' => 'temporary123',
            ])
            ->assertRedirect()
            ->assertSessionHas('status');

        $admin->refresh();
        $this->assertTrue(Hash::check('temporary123', $admin->password));
        $this->assertNotNull($admin->password_changed_at);
    }

    public function test_company_admin_cannot_open_superadmin_admin_directory(): void
    {
        $admin = $this->companyAdmin();

        $this->actingAs($admin)
            ->get('/superadmin/admins')
            ->assertForbidden();
    }

    private function companyAdmin(): User
    {
        $tenant = Tenant::query()->create([
            'name' => 'Customer Company',
            'code' => 'CUSTOMER',
            'status' => 'active',
        ]);

        return User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Company Admin',
            'email' => 'company-admin@example.test',
            'password' => Hash::make('oldpass123'),
            'is_active' => true,
        ]);
    }
}
