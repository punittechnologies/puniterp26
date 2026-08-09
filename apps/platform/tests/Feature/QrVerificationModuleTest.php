<?php

namespace Tests\Feature;

use App\Models\Permission;
use App\Models\Role;
use App\Models\Tenant;
use App\Models\User;
use App\Models\Verification\QrComplaint;
use App\Models\Verification\QrPageSetting;
use App\Models\Verification\QrVerification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class QrVerificationModuleTest extends TestCase
{
    use RefreshDatabase;

    public function test_qr_creation_is_disabled_by_default(): void
    {
        [$tenant, $token] = $this->appUserToken();

        $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertUnprocessable()
            ->assertJsonValidationErrors('qr');

        $this->assertDatabaseCount('qr_verifications', 0);
    }

    public function test_web_label_creates_an_immutable_public_verification_snapshot(): void
    {
        [$tenant, $token] = $this->appUserToken();
        QrPageSetting::query()->create([
            'tenant_id' => $tenant->id,
            'is_enabled' => true,
            'company_name' => 'SIMIC Electronics',
            'gst_number' => '24ABCDE1234F1Z5',
            'authenticity_statement' => 'Original product manufactured by SIMIC Electronics.',
            'made_in_text' => 'Made in India',
            'display_fields' => ['product.name', 'serial.number', 'weight.net', 'dynamic.product.tol'],
            'complaints_enabled' => false,
        ]);

        $response = $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertCreated()
            ->assertJsonPath('status', 'authentic');

        $publicUrl = $response->json('publicUrl');
        $tokenValue = basename((string) parse_url($publicUrl, PHP_URL_PATH));
        $this->assertSame(48, strlen($tokenValue));

        $this->get('/verify/'.$tokenValue)
            ->assertOk()
            ->assertSee('SIMIC Electronics')
            ->assertSee('Original product manufactured by SIMIC Electronics.')
            ->assertSee('DM19C3')
            ->assertSee('0.400 kg')
            ->assertSee('5')
            ->assertSee('VERIFIED THROUGH PUNIT ERP')
            ->assertSee('Product record securely verified')
            ->assertSee('Real-time weighing &amp; labelling intelligence', false)
            ->assertSee('https://puniterp.com');

        $same = $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertCreated();

        $this->assertSame($publicUrl, $same->json('publicUrl'));
        $this->assertDatabaseCount('qr_verifications', 1);

        QrPageSetting::query()->where('tenant_id', $tenant->id)->update([
            'company_name' => 'Changed Later',
        ]);
        $this->get('/verify/'.$tokenValue)
            ->assertOk()
            ->assertSee('SIMIC Electronics')
            ->assertDontSee('Changed Later');
    }

    public function test_customer_can_submit_configured_complaint_with_private_photo(): void
    {
        Storage::fake('local');
        [$tenant, $token] = $this->appUserToken();
        QrPageSetting::query()->create([
            'tenant_id' => $tenant->id,
            'is_enabled' => true,
            'company_name' => 'Complaint Company',
            'complaints_enabled' => true,
            'email_notifications_enabled' => false,
            'complaint_fields' => [
                'customer_name' => ['enabled' => true, 'required' => true],
                'phone' => ['enabled' => true, 'required' => true],
                'message' => ['enabled' => true, 'required' => true],
                'photo' => ['enabled' => true, 'required' => false],
            ],
        ]);

        $created = $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertCreated();
        $tokenValue = basename((string) parse_url($created->json('publicUrl'), PHP_URL_PATH));

        $this->post('/verify/'.$tokenValue.'/complaints', [
            'customer_name' => 'Customer One',
            'phone' => '9876543210',
            'message' => 'The package was damaged.',
            'photo' => UploadedFile::fake()->image('damage.jpg'),
        ])->assertRedirect();

        $complaint = QrComplaint::query()->firstOrFail();
        $this->assertSame($tenant->id, $complaint->tenant_id);
        $this->assertSame('new', $complaint->status);
        Storage::disk('local')->assertExists($complaint->photo_path);
    }

    public function test_company_name_can_be_hidden_without_removing_punit_verification_branding(): void
    {
        [$tenant, $token] = $this->appUserToken();
        QrPageSetting::query()->create([
            'tenant_id' => $tenant->id,
            'is_enabled' => true,
            'show_company_name' => false,
            'company_name' => 'Hidden Manufacturer',
            'complaints_enabled' => false,
        ]);

        $created = $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertCreated();
        $tokenValue = basename((string) parse_url($created->json('publicUrl'), PHP_URL_PATH));

        $this->get('/verify/'.$tokenValue)
            ->assertOk()
            ->assertDontSee('Hidden Manufacturer')
            ->assertDontSee('Test Manufacturer')
            ->assertSee('VERIFIED THROUGH PUNIT ERP');
    }

    public function test_public_token_does_not_expose_the_database_identifier(): void
    {
        [$tenant, $token] = $this->appUserToken();
        QrPageSetting::query()->create([
            'tenant_id' => $tenant->id,
            'is_enabled' => true,
        ]);

        $created = $this->withToken($token)
            ->withHeader('X-Tenant-Id', $tenant->id)
            ->postJson('/api/v1/qr/verifications', $this->printPayload())
            ->assertCreated();
        $verification = QrVerification::query()->firstOrFail();

        $this->assertStringNotContainsString($verification->id, $created->json('publicUrl'));
        $this->assertNotSame(
            basename((string) parse_url($created->json('publicUrl'), PHP_URL_PATH)),
            $verification->token_hash,
        );
    }

    private function appUserToken(): array
    {
        $tenant = Tenant::query()->create([
            'name' => 'Test Manufacturer',
            'code' => 'QR-'.str()->upper(str()->random(8)),
            'status' => 'active',
        ]);
        $permission = Permission::query()->firstOrCreate(
            ['key' => 'app.login'],
            ['name' => 'App login', 'module' => 'foundation'],
        );
        $role = Role::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'App User',
            'key' => 'qr-app-user',
        ]);
        $role->permissions()->attach($permission);
        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Tablet Operator',
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'app_only' => true,
            'is_active' => true,
        ]);
        $user->roles()->attach($role);

        return [$tenant, $user->createToken('qr-test')->plainTextToken];
    }

    private function printPayload(): array
    {
        return [
            'source_transaction_id' => 'prod_qr_001',
            'product_name' => 'DM19C3',
            'serial_number' => 'DM1-260727-ABC123',
            'barcode_value' => 'PABC123',
            'gross_weight' => 0.500,
            'tare_weight' => 0.100,
            'net_weight' => 0.400,
            'piece_quantity' => 400,
            'unit' => 'kg',
            'printed_at' => '2026-07-27T14:30:00+05:30',
            'dynamic_values' => ['tol' => '5'],
            'product_raw' => ['product_code' => 'DM19C3'],
        ];
    }
}
