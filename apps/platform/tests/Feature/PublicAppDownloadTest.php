<?php

namespace Tests\Feature;

use Tests\TestCase;

class PublicAppDownloadTest extends TestCase
{
    public function test_public_home_and_login_show_latest_app_download(): void
    {
        $this->withoutVite();

        $this->get('/')
            ->assertOk()
            ->assertSee('Download Latest PUNIT ERP App')
            ->assertSee(route('app.download.latest'));

        $this->get('/login')
            ->assertOk()
            ->assertSee('Download Latest PUNIT ERP App')
            ->assertSee(route('app.download.latest'));
    }

    public function test_latest_download_route_points_to_production_signed_apk(): void
    {
        $this->get('/downloads/latest')
            ->assertRedirect('/downloads/PUNIT-ERP-v1.1.17-build22.apk');
    }
}
