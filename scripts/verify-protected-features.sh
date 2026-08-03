#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
platform_root="$repo_root/apps/platform"
tablet_root="$repo_root/apps/tablet"

required_files=(
  "$platform_root/routes/web.php"
  "$platform_root/routes/api.php"
  "$platform_root/app/Livewire/Labels/LabelDesigner.php"
  "$platform_root/app/Livewire/Products/ProductManager.php"
  "$platform_root/app/Http/Controllers/Web/Concerns/AdminDataExchange.php"
  "$tablet_root/lib/services/devices/bluetooth_thermal_printer_adapter.dart"
  "$tablet_root/lib/features/weighing/presentation/weighing_dashboard_screen.dart"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Protected file is missing: $required_file" >&2
    exit 1
  fi
done

route_json="$(cd "$platform_root" && php artisan route:list --json)"

ROUTE_JSON="$route_json" php <<'PHP'
<?php
$routes = json_decode(getenv('ROUTE_JSON'), true, flags: JSON_THROW_ON_ERROR);
$uris = array_column($routes, 'uri');
$required = [
    'account/password',
    'admin/roles',
    'admin/users/{user}',
    'admin/{section}',
    'app-users',
    'app-users/{user}',
    'app-users/{user}/status',
    'audit-logs',
    'batches',
    'batches/{batch}',
    'batches/{batch}/items/{itemIndex}/fields/{fieldKey}',
    'customers',
    'customers/{customer?}',
    'dashboard',
    'dispatch',
    'dispatch-report',
    'dispatch/{dispatch}/export/{format}',
    'dispatch/{dispatch}/items/{item}',
    'dispatch/{dispatch}/reverse',
    'export',
    'exports/{report}/{format}',
    'import',
    'import/preview/{type}',
    'import/product-details',
    'import/products',
    'import/products/export',
    'import/template/{type}',
    'inventory',
    'inventory/adjust',
    'inventory/clear',
    'inventory/closing-stock/export',
    'inward-report',
    'inward/{session}/export/{format}',
    'labels/{template?}',
    'login',
    'logout',
    'onboarding',
    'product-details',
    'production',
    'production/{production}',
    'production/{production}/cancel',
    'products',
    'products/clear',
    'qr-complaints',
    'qr-complaints/{complaint}',
    'qr-complaints/{complaint}/photo',
    'qr-page-design',
    'reports/{report?}',
    'superadmin/admins',
    'superadmin/admins/{user}/password',
    'superadmin/onboarding',
    'sync-status',
    'tenant-settings',
    'verify/{token}',
    'verify/{token}/complaints',
    'api/v1/auth/login',
    'api/v1/auth/logout',
    'api/v1/auth/me',
    'api/v1/batches',
    'api/v1/configuration/products',
    'api/v1/customers',
    'api/v1/customers/{customer}',
    'api/v1/device-product-config',
    'api/v1/dispatch/barcodes/{barcode}',
    'api/v1/dynamic-fields',
    'api/v1/health',
    'api/v1/inventory/ledger',
    'api/v1/sync/bootstrap',
    'api/v1/inventory/summary',
    'api/v1/label-templates',
    'api/v1/label-templates/app-default',
    'api/v1/label-templates/bindings',
    'api/v1/label-templates/effective',
    'api/v1/label-templates/{label_template}',
    'api/v1/label-templates/{label_template}/archive',
    'api/v1/label-templates/{label_template}/duplicate',
    'api/v1/label-templates/{label_template}/rollback',
    'api/v1/label-templates/{label_template}/versions',
    'api/v1/product-attributes',
    'api/v1/product-categories',
    'api/v1/product-categories/{product_category}',
    'api/v1/products',
    'api/v1/products/{product}',
    'api/v1/products/{product}/variants',
    'api/v1/qr/verifications',
    'api/v1/reports/dispatch',
    'api/v1/reports/inventory',
    'api/v1/reports/production',
    'api/v1/sync/batches',
    'api/v1/sync/dispatch',
    'api/v1/sync/dispatches',
    'api/v1/sync/inward_session',
    'api/v1/sync/label-templates',
    'api/v1/sync/production_transaction',
    'api/v1/sync/production_transaction/{clientId}',
    'api/v1/sync/products',
    'api/v1/unit-conversions',
    'api/v1/units',
    'api/v1/weight-rules',
];

$missing = array_values(array_diff($required, $uris));
if ($missing !== []) {
    fwrite(STDERR, "Protected routes are missing:\n- ".implode("\n- ", $missing)."\n");
    exit(1);
}
PHP

grep -q "type == 'line'" "$tablet_root/lib/services/devices/bluetooth_thermal_printer_adapter.dart"
grep -q "type == 'rectangle'" "$tablet_root/lib/services/devices/bluetooth_thermal_printer_adapter.dart"
grep -q "type == 'barcode'" "$tablet_root/lib/services/devices/bluetooth_thermal_printer_adapter.dart"
grep -q "type == 'qr'" "$tablet_root/lib/services/devices/bluetooth_thermal_printer_adapter.dart"

required_markers=(
  "apps/platform/resources/views/layouts/admin.blade.php:::Label Templates"
  "apps/platform/resources/views/layouts/admin.blade.php:::Inventory Report"
  "apps/platform/resources/views/layouts/admin.blade.php:::Inventory Ledger"
  "apps/platform/resources/views/layouts/admin.blade.php:::App Users"
  "apps/platform/resources/views/layouts/admin.blade.php:::Roles"
  "apps/platform/resources/views/layouts/admin.blade.php:::Import"
  "apps/platform/resources/views/layouts/admin.blade.php:::Export"
  "apps/platform/resources/views/layouts/admin.blade.php:::QR Page Design"
  "apps/platform/resources/views/admin/imports/index.blade.php:::Product Spreadsheet Import"
  "apps/platform/resources/views/admin/imports/index.blade.php:::Product Details Spreadsheet Import"
  "apps/platform/resources/views/admin/imports/index.blade.php:::Export Current Products"
  "apps/platform/resources/views/admin/inventory/index.blade.php:::Inventory Filters"
  "apps/platform/resources/views/admin/inventory/index.blade.php:::Product-wise Inventory"
  "apps/platform/resources/views/admin/inventory/index.blade.php:::Product Detail-wise Inventory"
  "apps/platform/resources/views/admin/reports/index.blade.php:::Inventory Ledger"
  "apps/platform/resources/views/livewire/labels/label-designer.blade.php:::Inventory barcode is mandatory"
)

for marker_entry in "${required_markers[@]}"; do
  relative_file="${marker_entry%%:::*}"
  marker="${marker_entry#*:::}"
  if ! grep -Fq "$marker" "$repo_root/$relative_file"; then
    echo "Protected UI marker is missing: $marker ($relative_file)" >&2
    exit 1
  fi
done

echo "Protected feature baseline is present."
