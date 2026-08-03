# Protected Feature Baseline

This file is the minimum regression contract for Punit ERP. It is intentionally
broader than any single task. A feature may be changed only when the task
explicitly requests that feature; unrelated features must remain available.

## Web administration

- Authentication, onboarding, logout, account password change, tenant settings,
  user status, app-user editing, roles, audit logs, and superadmin management.
- Dashboard, global serial/barcode search, products, product details/variants,
  product batches, customers, production, inward sessions, dispatch, inventory,
  sync status, and reports.
- Product and product-detail spreadsheet templates, validation preview, import,
  export, decimal/text preservation, duplicate detection, zero tare handling,
  minimum/maximum product weight, and closing-stock export.
- Inventory summary, ledger, filters, date/product/customer filters,
  adjustments, closing stock, and guarded cleanup actions.
- Inward, production, inventory, audit, dispatch/packing-list reports and their
  supported exports and filters.
- Role and permission creation/editing must remain usable without removing
  existing permissions.

## Product and labeling

- Dynamic product-detail fields and dropdown options.
- Batch and non-batch product workflows.
- Unit conversion and pieces calculation.
- Optional product-specific customer barcode, barcode type, caption, value, and
  label binding; products without a customer barcode must continue normally.
- Internal inventory barcode remains available and independent of customer
  barcode.
- Label templates, duplication, archive, defaults, bindings, preview, saved
  versions/rollback APIs, image, text, line, rectangle, barcode, customer
  barcode, and QR elements.
- Existing saved templates retain their original rendering behavior.
- Precision templates support 203-DPI placement, real/longest-value preview,
  overflow guidance, multiline text, and multiple fields on one row.

## Flutter/Android application

- Account-scoped login/logout and local data isolation.
- Product, dynamic-field, batch, and label-template synchronization.
- Weighing screen, manual/automatic transaction flow, recent weighments,
  inventory, scanning, dispatch, and offline queue/sync behavior.
- Persistent scale and printer connection behavior across supported screens.
- Classic APK behavior remains independent from the Web Label edition.
- Web Label printing supports text, multiline text, barcode, optional customer
  barcode, QR, image, rectangle, and horizontal/vertical line elements.
- Printer success must represent a completed transport write, not only a saved
  local transaction.
- TVS/BLE/USB printer adapters and weighing-scale adapters remain outside UI
  widgets.

## QR verification

- Secure public verification token and `/verify/{token}` page.
- Admin QR page design and visibility controls.
- Company/product snapshot, authenticity messaging, selected product fields,
  serial/barcode/weight/date/time visibility, complaint configuration, photo
  support, complaint inbox, and complaint status.
- Existing labels without QR and classic app printing remain unaffected.

## Safety checks for every pull request

- No protected route or navigation entry disappeared unintentionally.
- No database column or stored JSON key was removed unintentionally.
- Existing tenant/account scoping remains intact.
- Existing import/export columns remain accepted.
- Existing label templates still parse and print.
- Classic and Web Label edition behavior is tested separately when printing
  changes.
- New UI is additive and does not hide existing controls.
