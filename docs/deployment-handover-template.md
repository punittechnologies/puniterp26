# Punit ERP Deployment Handover

Use this document to hand over PHP/Laravel web-panel access, editing instructions, and deployment instructions to the deployment developer.

## 1. Project Summary

Project name:

```text
Punit ERP
```

Live website:

```text
https://erp.puniterp.com
```

Main technology:

```text
Laravel PHP web panel
Flutter Android app
MySQL database
Hostinger hosting
```

Laravel web panel folder:

```text
apps/platform
```

Flutter app folder:

```text
apps/tablet
```

## 2. Source Code

Source code will be provided by:

```text
GitHub / ZIP / direct folder transfer
```

Repository, if using GitHub:

```text
https://github.com/punittechnologies/puniterp26
```

Main branch:

```text
main
```

## 3. Laravel Web Panel Editing Areas

For PHP/web-panel work, edit mainly:

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

## 4. Main Web Modules

The web panel contains:

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

## 5. Server Access Details

Fill these before deployment:

```text
SSH host/IP:

SSH port:

SSH username:

SSH password:

Hosting panel URL:

Hosting panel username/email:

Hosting panel password:
```

Known current server paths:

```text
Laravel live app path:
/home/u407989482/domains/erp.puniterp.com/punit_erp_app

Public HTML path:
/home/u407989482/domains/erp.puniterp.com/public_html

PHP binary:
/opt/alt/php84/usr/bin/php
```

## 6. Database Details

Fill these from Hostinger/MySQL panel:

```text
DB_CONNECTION=mysql
DB_HOST=
DB_PORT=3306
DB_DATABASE=
DB_USERNAME=
DB_PASSWORD=
```

## 7. Mail / SMTP Details

Fill these from email/SMTP provider:

```text
MAIL_MAILER=smtp
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME="Punit ERP"
```

## 8. Live `.env` File

Do not paste the live `.env` into this document, GitHub, a pull request, issue,
commit, chat or task prompt. Transfer production configuration only through the
owner's approved secret-sharing method and keep it on the production server.

Never commit or share this file publicly.

The `.env` file must be placed at:

```text
apps/platform/.env
```

For live server, the `.env` file must be placed at:

```text
/home/u407989482/domains/erp.puniterp.com/punit_erp_app/.env
```



## 9. Local Setup For Developer

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

Open locally:

```text
http://127.0.0.1:8000
```

## 10. Backup Before Deployment

Before deploying, take a backup:

```bash
mkdir -p /home/u407989482/deploy_backups
cp -a /home/u407989482/domains/erp.puniterp.com/punit_erp_app /home/u407989482/deploy_backups/punit_erp_app_$(date +%Y%m%d%H%M%S)
cp -a /home/u407989482/domains/erp.puniterp.com/public_html /home/u407989482/deploy_backups/public_html_$(date +%Y%m%d%H%M%S)
```

## 11. Deployment Steps

SSH into server:

```bash
ssh -p SSH_PORT SSH_USERNAME@SSH_HOST
```

Go to Laravel app folder:

```bash
cd /home/u407989482/domains/erp.puniterp.com/punit_erp_app
```

Install dependencies:

```bash
composer install --no-dev --optimize-autoloader
```

If frontend assets changed:

```bash
npm install
npm run build
```

Run Laravel commands:

```bash
/opt/alt/php84/usr/bin/php artisan migrate --force
/opt/alt/php84/usr/bin/php artisan storage:link
/opt/alt/php84/usr/bin/php artisan optimize:clear
/opt/alt/php84/usr/bin/php artisan config:cache
/opt/alt/php84/usr/bin/php artisan view:cache
/opt/alt/php84/usr/bin/php artisan route:cache
```

## 12. Public HTML Setup

The Laravel `public` folder contents should be served from:

```text
/home/u407989482/domains/erp.puniterp.com/public_html
```

In `public_html/index.php`, paths must point to:

```php
require __DIR__.'/../punit_erp_app/vendor/autoload.php';
$app = require_once __DIR__.'/../punit_erp_app/bootstrap/app.php';
```

Maintenance path should point to:

```php
__DIR__.'/../punit_erp_app/storage/framework/maintenance.php'
```

## 13. Verify After Deployment

Check:

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

```text
Login
Add product
Delete product
Recreate same product
Add product details
Create app user
Inward report
Dispatch report
Inventory
PDF export
Excel export
Flutter app sync API
```

## 14. API Base URL

Flutter app API:

```text
https://erp.puniterp.com/api/v1
```

Important API groups:

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

## 15. Error Checking

Check Laravel log:

```bash
cd /home/u407989482/domains/erp.puniterp.com/punit_erp_app
tail -100 storage/logs/laravel.log
```

Clear cache:

```bash
/opt/alt/php84/usr/bin/php artisan optimize:clear
```

## 16. Do Not Commit Or Share Publicly

Never commit or publicly share:

```text
.env
APP_KEY
DB password
SMTP password
SSH password
GitHub token
database backups
storage/logs
```

## 17. Final Checklist

Before saying deployment is complete:

```text
Website opens
Login works
Dashboard opens
Products work
Product details work
Inward report works
Dispatch report works
Inventory works
App users work
PDF/Excel export works
Flutter app login sync works
No 500 error
Laravel log has no new fatal errors
```
## 18. Environment Template

APP_NAME="Punit ERP"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://erp.puniterp.com
ASSET_URL=https://erp.puniterp.com
LOG_CHANNEL=stack
LOG_LEVEL=error
DB_CONNECTION=mysql
DB_DATABASE=
SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=.erp.puniterp.com
CACHE_STORE=file
QUEUE_CONNECTION=sync
FILESYSTEM_DISK=local
SANCTUM_STATEFUL_DOMAINS=erp.puniterp.com

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USERNAME=
DB_PASSWORD=
