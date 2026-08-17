# Punit ERP System Feature Catalogue

This catalogue is the A-to-Z handoff map for the production Punit ERP source.
It complements `AGENTS.md` and `docs/PROTECTED_FEATURE_BASELINE.md`. A developer
must inspect the implementation and tests before changing any listed workflow.
The catalogue is a protection boundary, not permission to redesign a module.

## Source of truth

- Repository: `https://github.com/punittechnologies/puniterp26`
- Approved production baseline: `origin/main`
- Laravel web/API: `apps/platform`
- Flutter Android applications: `apps/tablet`
- Production secrets, `.env`, signing keys and server credentials are outside
  Git and must remain outside Git.

## Accounts, tenancy and security

- Web login, onboarding, logout and account password change.
- Superadmin onboarding and administration.
- Company/tenant isolation on every web query, API query, import, export,
  report, sync payload, public QR record and local Android cache.
- Web users, app-only users, activation/status controls, roles and permissions.
- Audit logs for administrative and operational changes.
- Account-scoped Android logout and user-switch data clearing.
- Passwords are one-way hashed; plaintext passwords must never be stored,
  displayed, logged or committed.

## Product configuration

- Products, product codes/SKUs, images and active status.
- Product-detail definitions, selectable values and product variants.
- Spreadsheet templates, validation preview, product import/export and
  product-detail import with numeric/text preservation and duplicate handling.
- Zero tare, minimum/maximum/target weight and decimal precision.
- Batch and non-batch workflows with product-batch data.
- Optional unit conversion, divided/per-piece weight and pieces calculation.
- Optional product customer barcode: enable flag, symbology, value and caption.
- Default label template and product selection/locking configuration.
- Guarded product/product-detail cleanup independent of historical operations.

## Label design and printing

- Multiple tenant label templates, duplicate, archive, default selection,
  saved versions and rollback.
- Web label designer elements: text, image, line, rectangle, inventory barcode,
  optional product customer barcode and secure QR.
- Dynamic bindings for company, product, product details, serial, date/time,
  gross/tare/net, pieces, divided/per-piece weight and QR verification.
- Prefix/suffix, font family/weight/size, alignment, rotation, line width,
  multiline spacing, overflow guidance, coordinates, dimensions and z-order.
- Existing saved-template JSON compatibility and 203-DPI placement.
- Internal inventory barcode remains mandatory and independent of the optional
  customer barcode.
- Classic app-managed label path remains independent from Web Label printing.
- Web Label rendering supports TVS/TSPL text, lines, rectangles, barcodes, QR
  and images with transport-write acknowledgement.

## Weighing and inward operations

- Bluetooth scale discovery, pairing, reconnect and persistent connection.
- Live stable weight, gross/tare/net calculations and product range status.
- Manual Save & Print and automatic capture/print workflows.
- Product and searchable product-detail selection.
- Inward sessions/transactions, automatic session creation where configured,
  recent weighments, customer-visible label serial and internal trace ID.
- Optional configurable label serial prefix/sequence with protected reset and
  audit history.
- Offline queue, idempotent synchronization and duplicate prevention.
- Cancellation/reversal entries preserve inventory history.

## Printer connectivity

- Bluetooth Classic/native, BLE TSPL and supported USB printer adapters.
- TVS LP 46 Dlite+BT and compatible TSPL command paths.
- Connection state persists across supported Weighing and Dispatch screens.
- Test print/diagnostic paths are separate from production transactions.
- A success message requires a completed printer transport write; saving a
  transaction alone is not print success.
- Retry Last Print does not create a duplicate production transaction.

## Dispatch

- Customer management and customer snapshots.
- Barcode/serial scanning and validation against available inventory.
- Dispatch transaction creation, item list, total kg/PCS and confirmation.
- Dispatch PDF/Excel/packing-list outputs and configurable report columns.
- Remove item, reverse dispatch and return stock to available inventory.
- Customer, product, product-detail, serial/barcode, status and date filters.
- Smaller readable dispatch references remain distinct from internal IDs.

## Inventory

- Tenant-scoped inventory transaction ledger and product/product-detail totals.
- Production additions, dispatch deductions, dispatch reversals, cancellations,
  opening stock and manual adjustments.
- Current stock and historical closing stock.
- Product, product-detail, date, serial, barcode, movement, kg and PCS filters.
- PDF, CSV and Excel exports must match the selected filters.
- Current Stock Excel contains summary and serial-level sheets, dynamic product
  details, customer-visible serial, barcode, kg, PCS and stock dates.
- Guarded inventory cleanup removes operational transactions only and preserves
  products, product details, customers, users, templates and settings.

## Reports and data exchange

- Dashboard metrics and inventory overview.
- Inward, dispatch/material issue, inventory, inventory ledger, customer
  dispatch and audit reports.
- Multi-product and multi-product-detail filtering.
- PDF, CSV and Excel exports reflect the exact active filter set.
- Report Customiser controls tenant-specific columns and optional summaries.
- Product/detail summary rows include kg and PCS where applicable.
- Import and Export navigation and workflows remain available.

## QR verification and complaints

- Admin QR Page Design with feature enablement, visual configuration and field
  visibility controls.
- Secure random verification token and public `/verify/{token}` page.
- Print-time company/product/weight/serial/barcode/date snapshot.
- Authenticity messaging and Punit ERP verification branding.
- Optional complaint form, configurable input fields, photo upload, throttling,
  email notification, admin inbox and status workflow.
- Existing non-QR labels and classic APK behavior remain unchanged.

## Android editions

- `classic`: existing Punit ERP application and app-managed label behavior.
- `webLabel`: separately installable application using the active default web
  label template; package ID remains independent of classic.
- `qrDiagnostic`: temporary printer/QR diagnostic edition; diagnostics do not
  save operational weighments.
- Operator application navigation retains Login, Weighing and Dispatch focus,
  online/offline status, pending sync, last sync, version/build and logout.
- The server must keep existing API fields compatible with installed APKs.
  New API fields must be additive and nullable/default-safe.

## Deployment and release

- Reviewed source reaches `origin/main` before production deployment.
- Database changes use additive, reversible Laravel migrations.
- Web deployment and APK release are separate approval scopes.
- Existing Android package IDs and signing keys must be preserved for updates.
- Never commit `.env`, credentials, tokens, keystores, APK/AAB files,
  dependencies, caches, logs, database files or generated build output.
- Back up affected production files/data, deploy reviewed files only, run
  migrations and cache commands, verify health/login/changed workflows, and
  retain a tested rollback path.

## Mandatory regression boundary

Every task must test the requested behavior plus the nearest unchanged
workflow. Cross-cutting changes require tests for web, API and Android consumers.
Any missing historical detail must be discovered from Git history and current
tests; it must not be reconstructed from screenshots or assumptions.
