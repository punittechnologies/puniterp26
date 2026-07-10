# Punit ERP Codex Upload Prompt

You are working on the Punit ERP project.

This project contains:

- Laravel/PHP web panel
- Flutter Android tablet/mobile app
- Live Laravel backend APIs
- MySQL/SQLite-compatible Laravel data layer
- Product, product details, label templates, inward reports, dispatch reports, inventory, customers, users, app users, reports and sync modules

## Repository

```text
https://github.com/punitdev26/puniterp
```

## Project Structure

Laravel web panel:

```text
apps/platform
```

Flutter app:

```text
apps/tablet
```

For PHP/web-panel work, edit only `apps/platform` unless the user explicitly asks for Flutter changes.

## Important Laravel Areas

Inspect these before editing:

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

## Current Main Modules

The Laravel web panel includes:

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

## Critical Architecture Rules

Preserve existing:

- Tenant isolation
- Authentication
- Web users
- App users
- Permissions
- Product sync
- Label-template sync
- Inward transaction sync
- Dispatch sync
- Inventory logic
- Report/export logic
- Audit logging
- Existing UI routes
- Existing API behavior used by Flutter

Do not rewrite working modules unnecessarily.

Do not remove existing production data logic.

Do not break Flutter API compatibility.

## Local Laravel Setup

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

## Test Commands

After PHP/Laravel changes, run:

```bash
cd apps/platform
php artisan test
./vendor/bin/pint
npm run build
```

If migrations changed:

```bash
php artisan migrate
```

## Live Server Details

Live domain:

```text
https://erp.puniterp.com
```

SSH:

```text
Host/IP: 93.127.168.78
Port: 65002
Username: u407989482
```

Live Laravel app path:

```text
/home/u407989482/domains/erp.puniterp.com/punit_erp_app
```

Public HTML path:

```text
/home/u407989482/domains/erp.puniterp.com/public_html
```

PHP binary:

```text
/opt/alt/php84/usr/bin/php
```

Live `.env` location:

```text
/home/u407989482/domains/erp.puniterp.com/punit_erp_app/.env
```

Do not commit `.env`.

Do not paste secrets into GitHub.

## Deployment Commands

Before deployment, take backup:

```bash
mkdir -p /home/u407989482/deploy_backups
cp -a /home/u407989482/domains/erp.puniterp.com/punit_erp_app /home/u407989482/deploy_backups/punit_erp_app_$(date +%Y%m%d%H%M%S)
cp -a /home/u407989482/domains/erp.puniterp.com/public_html /home/u407989482/deploy_backups/public_html_$(date +%Y%m%d%H%M%S)
```

Deploy:

```bash
cd /home/u407989482/domains/erp.puniterp.com/punit_erp_app
git pull origin main
composer install --no-dev --optimize-autoloader
npm install
npm run build
/opt/alt/php84/usr/bin/php artisan migrate --force
/opt/alt/php84/usr/bin/php artisan optimize:clear
/opt/alt/php84/usr/bin/php artisan config:cache
/opt/alt/php84/usr/bin/php artisan view:cache
/opt/alt/php84/usr/bin/php artisan route:cache
```

If needed:

```bash
/opt/alt/php84/usr/bin/php artisan storage:link
```

## Verify After Deployment

Check these URLs:

```text
https://erp.puniterp.com/dashboard
https://erp.puniterp.com/products
https://erp.puniterp.com/product-details
https://erp.puniterp.com/inward-report
https://erp.puniterp.com/dispatch
https://erp.puniterp.com/inventory
https://erp.puniterp.com/app-users
https://erp.puniterp.com/report-customiser
```

Test:

- Login
- Product create/delete/recreate
- Product details fields
- Label template sync
- Inward report cards
- Dispatch report cards
- Inventory update
- PDF export
- Excel export
- App user login API
- Flutter sync API compatibility

## Important API Base URL

Flutter app uses:

```text
https://erp.puniterp.com/api/v1
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

## Do Not Commit

Never commit:

```text
.env
database.sqlite
APKs
node_modules
vendor
storage/logs
Android local.properties
GitHub tokens
DB passwords
SMTP passwords
SSH passwords
```

## Development Rules

1. Inspect existing code before editing.
2. Reuse existing models, controllers, Livewire components and services.
3. Keep tenant isolation mandatory.
4. Keep permission checks on backend.
5. Keep API responses compatible with the Flutter app.
6. Use migrations for database changes.
7. Use Laravel validation.
8. Use database transactions for multi-record writes.
9. Do not add static/mock-only screens.
10. Do not make broad unrelated refactors.
11. After changes, run tests/build.
12. Explain exactly what changed, files changed, commands run and test results.

## What To Do When Given A Task

When the user gives a task:

1. Inspect the relevant Laravel files first.
2. Identify the bug or missing workflow.
3. Make targeted changes.
4. Run:

```bash
cd apps/platform
php artisan test
./vendor/bin/pint
npm run build
```

5. If deployment is requested, take backup first and deploy using the deployment commands above.
6. Verify affected web routes and APIs.
7. Return a concise completion report.

## Final Response Format

Return:

```text
Completed work
Files changed
Commands run
Test results
Deployment status
Remaining issues, if any
```

