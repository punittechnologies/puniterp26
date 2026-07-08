# Phase 1 Architecture

## Folder Structure

- `apps/platform`: Laravel modular monolith for web admin, REST API, auth, tenancy, RBAC, configuration, sync and audit.
- `apps/tablet`: Flutter Android tablet app, landscape-first.
- `docs`: concise implementation notes.

## Laravel Module Boundaries

- `app/Domain`: business contracts and data objects.
- `app/Http`: controllers, requests, resources and middleware.
- `app/Models`: Eloquent models for Phase 1 entities.
- `database/migrations`: MySQL-compatible schema.

Phase 1 includes only foundation modules: auth, tenancy, users, roles, permissions, devices, sync, configuration versioning and audit.

## Flutter Module Boundaries

- `lib/core`: theme, routing and API conventions.
- `lib/features`: feature shells.
- `lib/services`: local sync and device adapter interfaces.

Operational weighing, printing, inventory and dispatch screens are deferred to later phases.

## Tenant Isolation

- Shared MySQL database.
- Tenant-owned tables include `tenant_id`.
- Authenticated API requests resolve tenant context from `X-Tenant-Id` or the authenticated user.
- Services and policies must scope tenant-owned data by tenant before returning records.

## Authentication

- Laravel Sanctum token auth for app/API clients.
- Permission checks are middleware/policy driven.
- Roles are tenant-scoped; permissions are stable system keys.

## Hostinger Constraints

- No Docker, Redis, PostgreSQL, custom daemons, permanent workers or WebSockets required.
- Uses MySQL, database sessions, database cache and database queues.
- Queues can be drained by cron with `php artisan queue:work --stop-when-empty`.

## Offline Sync And Idempotency

- Tablet creates local UUID idempotency keys for writes.
- Server stores idempotency records per tenant and key.
- Sync queue entries record operation, payload, retry count, status and last error.

## Device Interfaces

- `ScaleAdapter`: discovery, connect, read, zero and tare.
- `PrinterAdapter`: discovery, connect and print.
- `ScannerAdapter`: connect and parse scanned input.
- Phase 1 defines contracts only.

## Configuration And AI Foundation

- Configuration schemas define allowed structured configuration.
- Configuration versions support draft, approval, activation and rollback later.
- `AiConfigurationProvider` is an interface only; no real AI provider is connected in Phase 1.
