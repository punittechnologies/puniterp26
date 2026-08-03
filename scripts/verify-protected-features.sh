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
    'dashboard',
    'products',
    'product-details',
    'batches',
    'labels/{template?}',
    'import',
    'import/products',
    'import/product-details',
    'import/products/export',
    'inventory',
    'inventory/closing-stock/export',
    'inward-report',
    'dispatch-report',
    'reports/{report?}',
    'app-users',
    'tenant-settings',
    'qr-page-design',
    'qr-complaints',
    'verify/{token}',
    'api/v1/sync/bootstrap',
    'api/v1/label-templates',
    'api/v1/inventory/summary',
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

echo "Protected feature baseline is present."
