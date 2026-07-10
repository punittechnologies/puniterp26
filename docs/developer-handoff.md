# Punit ERP Developer Handoff

This document gives a developer the practical details needed to edit, test, and deploy the Punit ERP Laravel web panel and Flutter Android tablet/mobile app.

## 1. Source Code

Repository:

```text
https://github.com/punitdev26/puniterp
```

Main branch:

```text
main
```

Clone:

```bash
git clone https://github.com/punitdev26/puniterp.git
cd puniterp
```

## 2. Project Structure

Laravel web panel:

```text
apps/platform
```

Flutter Android app:

```text
apps/tablet
```

Shared documentation:

```text
docs
```

Generated APK/output files are intentionally not committed.

## 3. Laravel Web Panel

Important Laravel folders:

```text
apps/platform/routes/web.php
apps/platform/routes/api.php
apps/platform/app/Http/Controllers
apps/platform/app/Livewire
apps/platform/app/Models
apps/platform/app/Domain
apps/platform/resources/views
apps/platform/database/migrations
apps/platform/database/seeders
apps/platform/config
```

Primary web modules:

```text
Dashboard
Products
Product Details
Label Templates
Inward Report
Dispatch Report / Packing List
Production Entry
Inventory
Customers
Dispatch Entry
Sync Status
Inventory Report
Inventory Ledger
Audit Report
App Users
Users
Roles
Report Customiser
Audit Logs
```

## 4. Local Laravel Setup

Requirements:

```text
PHP 8.4 compatible runtime
Composer
Node.js / npm
MySQL or SQLite for local development
```

Commands:

```bash
cd apps/platform
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
npm run build
php artisan serve
```

Local URL:

```text
http://127.0.0.1:8000
```

## 5. Laravel Environment Variables

Do not commit `.env`.

Live production URL:

```text
APP_URL=https://erp.puniterp.com
ASSET_URL=https://erp.puniterp.com
APP_ENV=production
APP_DEBUG=false
```

Database keys required in `.env`:

```text
DB_CONNECTION=mysql
DB_HOST=
DB_PORT=3306
DB_DATABASE=
DB_USERNAME=
DB_PASSWORD=
```

Mail keys required in `.env`:

```text
MAIL_MAILER=smtp
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=
MAIL_FROM_ADDRESS=punitinstrument@gmail.com
MAIL_FROM_NAME="Punit ERP"
```

Recommended production settings:

```text
SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
FILESYSTEM_DISK=local
SANCTUM_STATEFUL_DOMAINS=erp.puniterp.com
```

Actual production secrets must be copied from the live server `.env` or Hostinger panel. Do not send them through normal chat.

## 6. Live Server Details

Domain:

```text
https://erp.puniterp.com
```

Hostinger SSH:

```text
Host/IP: 93.127.168.78
Port: 65002
User: u407989482
```

Laravel app directory:

```text
/home/u407989482/domains/erp.puniterp.com/punit_erp_app
```

Public document root:

```text
/home/u407989482/domains/erp.puniterp.com/public_html
```

Production PHP binary:

```text
/opt/alt/php84/usr/bin/php
```

Read live `.env` on server:

```bash
ssh -p 65002 u407989482@93.127.168.78
cd /home/u407989482/domains/erp.puniterp.com/punit_erp_app
cat .env
```

Keep `.env` private.

## 7. Deployment Process

Before deployment:

```bash
cd apps/platform
composer install
npm install
npm run build
php artisan test
```

On the live server after pulling/uploading new Laravel code:

```bash
cd /home/u407989482/domains/erp.puniterp.com/punit_erp_app
/opt/alt/php84/usr/bin/php artisan migrate --force
/opt/alt/php84/usr/bin/php artisan optimize:clear
/opt/alt/php84/usr/bin/php artisan config:cache
/opt/alt/php84/usr/bin/php artisan view:cache
/opt/alt/php84/usr/bin/php artisan route:cache
```

If using the included deployment script, review it first:

```text
deploy_erp_remote.sh
```

The script expects a release tarball at:

```text
/home/u407989482/punit_erp_platform_release.tar.gz
```

and deploys to:

```text
/home/u407989482/domains/erp.puniterp.com/punit_erp_app
```

## 8. Laravel Tests and Formatting

Run:

```bash
cd apps/platform
php artisan test
./vendor/bin/pint
npm run build
```

## 9. Flutter App

Flutter app path:

```text
apps/tablet
```

Important Flutter folders:

```text
apps/tablet/lib/core
apps/tablet/lib/features/weighing
apps/tablet/lib/features/labels
apps/tablet/lib/features/dispatch
apps/tablet/lib/features/inventory
apps/tablet/lib/features/products
apps/tablet/lib/features/reports
apps/tablet/lib/services/devices
apps/tablet/android
```

The app includes:

```text
Bluetooth weighing scale connection
Printer connection and TSPL/native label printing support
Product sync
Label-template sync
Inward production transactions
Dispatch scanning
Inventory view
Reports
Offline fallback
```

## 10. Flutter Setup

Requirements:

```text
Flutter stable
Android Studio / Android SDK
Android device or emulator
```

Commands:

```bash
cd apps/tablet
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Generated APK:

```text
apps/tablet/build/app/outputs/flutter-apk/app-debug.apk
```

## 11. Flutter Live API Connection

Production API base URL:

```text
https://erp.puniterp.com/api/v1
```

The app user should be created from the Laravel web panel:

```text
App Users
```

Then login in the Android app using that app-user email/username and password.

## 12. App User and Web User Separation

Web users:

```text
Laravel admin panel login
Used by admins/superadmins on web
```

App users:

```text
Created from web panel under App Users
Used only in Android app
Synced by tenant/user permissions
```

Do not use superadmin credentials inside the app.

## 13. Label Template Storage

Label templates are stored in Laravel database tables:

```text
label_templates
label_template_versions
label_template_elements
```

The Flutter app syncs templates through the Laravel API.

Expected behavior:

```text
Template saved on one device -> uploaded to web server
Login on another device with same tenant/app user -> sync downloads template
Selecting template -> size, fields, layout, logo, barcode, and preview should restore
```

If a device shows stale templates:

```text
Logout should clear account-scoped local template cache.
Login should force template sync from server.
Local templates must be tenant/user scoped.
```

## 14. Production and Dispatch Sync

Expected cloud-first behavior:

```text
Inward/weighing transaction saved -> immediate API sync -> web inward report visible
Dispatch scan/save -> immediate API sync -> web dispatch report visible
If internet fails -> store locally and retry later
```

Important APIs:

```text
/api/v1/auth/login
/api/v1/sync/products
/api/v1/label-templates
/api/v1/sync/production
/api/v1/sync/inward-sessions
/api/v1/sync/dispatches
/api/v1/inventory
/api/v1/reports
```

## 15. Database Notes

Use MySQL for production scale.

Recommended:

```text
InnoDB
tenant_id indexes
created_at indexes
barcode indexes
idempotency key indexes
inventory transaction indexes
dispatch item indexes
production transaction indexes
```

SQLite should only be used for local/simple testing, not high-volume production.

## 16. High-Volume Rules

For thousands of users and high daily entries:

```text
Do not run unbounded report queries.
Paginate all tables.
Use indexed filters.
Keep transaction writes idempotent.
Use tenant-scoped queries everywhere.
Keep app sync payloads incremental.
Archive old transactions if database grows heavily.
Keep report export filters required for large ranges.
```

## 17. What Developers Should Not Do

Do not commit:

```text
.env
database.sqlite
APKs
node_modules
vendor
storage/logs
Android local.properties
```

Do not edit production directly without backup.

Do not change live database schema manually unless migration is impossible.

Do not expose app keys, database passwords, SMTP passwords, or GitHub tokens in chat.

## 18. Recommended Workflow

```bash
git pull
create a feature branch
edit locally
run tests
commit
push
deploy to live
verify web panel
verify Android app sync
```

Example:

```bash
git checkout -b fix-label-template-sync
# edit files
cd apps/platform && php artisan test
cd ../tablet && flutter test
git add .
git commit -m "Fix label template sync"
git push origin fix-label-template-sync
```

