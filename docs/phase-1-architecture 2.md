# Phase 1 Architecture

## Folder Structure

- `apps/api`: NestJS modular monolith backend.
- `apps/admin`: Next.js web admin shell.
- `apps/tablet`: Flutter Android tablet app.
- `packages/shared`: shared TypeScript contracts and constants.
- `prisma`: PostgreSQL schema and seed data.

## Boundaries

- Backend owns authentication, tenancy, RBAC, persistence, OpenAPI, sync contracts, idempotency and audit writes.
- Web admin calls backend REST APIs only.
- Tablet app stores local state, queues offline writes and syncs with idempotency keys.
- Device integrations are behind interfaces. Phase 1 includes simulated adapters only.

## Tenant Isolation

- Tenant-owned tables include `tenantId`.
- JWT payloads include `tenantId`.
- Request context is resolved by auth and tenant guards before services execute.
- Services must scope all tenant-owned reads and writes by `tenantId`.

## Offline Sync And Idempotency

- Tablet writes use client-generated UUID idempotency keys.
- Server stores processed idempotency keys per tenant, user, endpoint and key.
- Retried requests return the original result where applicable instead of creating duplicates.

## Device Adapter Interfaces

- Scale: discover, connect, disconnect, read continuous weight, zero, tare, status.
- Printer: discover, connect, print, status.
- Scanner: start, stop, scan stream, status.
