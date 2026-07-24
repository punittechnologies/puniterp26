#!/usr/bin/env bash
set -euo pipefail

DOMAIN_DIR=/home/u407989482/domains/erp.puniterp.com
APP_DIR="$DOMAIN_DIR/punit_erp_app"
PUBLIC_DIR="$DOMAIN_DIR/public_html"
BACKUP_DIR="/home/u407989482/deploy_backups/erp-puniterp-$(date +%Y%m%d%H%M%S)"
PHP_BIN=/opt/alt/php84/usr/bin/php

echo "Backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

if [ -d "$APP_DIR" ]; then
  cp -a "$APP_DIR" "$BACKUP_DIR/punit_erp_app"
fi

if [ -d "$PUBLIC_DIR" ]; then
  cp -a "$PUBLIC_DIR" "$BACKUP_DIR/public_html"
fi

rm -rf "$APP_DIR.new"
mkdir -p "$APP_DIR.new"
tar -xzf /home/u407989482/punit_erp_platform_release.tar.gz -C "$APP_DIR.new"

if [ -f "$APP_DIR/.env" ]; then
  cp "$APP_DIR/.env" "$APP_DIR.new/.env"
else
  echo "Deployment aborted: $APP_DIR/.env does not exist." >&2
  echo "Create the production .env securely on the server before deploying." >&2
  exit 1
fi

mkdir -p \
  "$APP_DIR.new/database" \
  "$APP_DIR.new/storage/framework/cache" \
  "$APP_DIR.new/storage/framework/sessions" \
  "$APP_DIR.new/storage/framework/views" \
  "$APP_DIR.new/storage/logs" \
  "$APP_DIR.new/storage/app/public" \
  "$APP_DIR.new/bootstrap/cache"

touch "$APP_DIR.new/database/database.sqlite"
chmod -R u+rwX "$APP_DIR.new/storage" "$APP_DIR.new/bootstrap/cache" "$APP_DIR.new/database"

rm -rf "$APP_DIR.prev"
if [ -d "$APP_DIR" ]; then
  mv "$APP_DIR" "$APP_DIR.prev"
fi
mv "$APP_DIR.new" "$APP_DIR"

rm -rf "$PUBLIC_DIR"
mkdir -p "$PUBLIC_DIR"
cp -a "$APP_DIR/public/." "$PUBLIC_DIR/"

sed -i "s#__DIR__.'/../storage/framework/maintenance.php'#__DIR__.'/../punit_erp_app/storage/framework/maintenance.php'#" "$PUBLIC_DIR/index.php"
sed -i "s#__DIR__.'/../vendor/autoload.php'#__DIR__.'/../punit_erp_app/vendor/autoload.php'#" "$PUBLIC_DIR/index.php"
sed -i "s#__DIR__.'/../bootstrap/app.php'#__DIR__.'/../punit_erp_app/bootstrap/app.php'#" "$PUBLIC_DIR/index.php"

ln -sfn ../punit_erp_app/storage/app/public "$PUBLIC_DIR/storage"
mkdir -p "$PUBLIC_DIR/downloads"
cp /home/u407989482/punit-erp-tablet.apk "$PUBLIC_DIR/downloads/punit-erp-tablet.apk"

cat >> "$PUBLIC_DIR/.htaccess" <<'HTACCESS'

# Use PHP 8.4 for Laravel 13 runtime on Hostinger/CloudLinux.
<IfModule mime_module>
  AddHandler application/x-httpd-alt-php84___lsphp .php .php8 .phtml
</IfModule>
HTACCESS

cd "$APP_DIR"
"$PHP_BIN" artisan migrate --force
"$PHP_BIN" artisan db:seed --force
"$PHP_BIN" artisan storage:link || true
"$PHP_BIN" artisan optimize:clear
"$PHP_BIN" artisan config:cache
"$PHP_BIN" artisan view:cache
"$PHP_BIN" artisan route:cache || true

echo "DEPLOY_BACKUP=$BACKUP_DIR"
echo "DEPLOY_DONE"
