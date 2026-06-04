# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-06-04

### Added

- **Apartment-style switching by a unique field.** `Tenant.switch_by(value)`
  resolves the tenant by a unique column (defaulting to the configured
  `subdomain_field`) and switches context for the block; pass `attribute:` to
  use another column (e.g. `switch_by('acme', attribute: :slug)`). A permanent
  `switch_by!` variant is also available. Both raise `RlsMultiTenant::Error`
  when no tenant matches. Instance-level delegators are provided too.

## [0.3.1] - 2026-06-04

Corrects two bugs in the 0.3.0 security work, both uncovered by a new
real-PostgreSQL integration suite.

### Fixed

- **Security validator no longer rejects valid roles.** 0.3.0 used `pg_has_role`
  to flag BYPASSRLS inherited through role membership, but PostgreSQL does not
  inherit the SUPERUSER or BYPASSRLS role attributes through membership — only
  privileges (GRANTs). A role that merely belongs to a BYPASSRLS group does not
  bypass RLS unless it explicitly `SET ROLE`s to it. The validator now checks
  only `current_user`'s own `rolsuper` / `rolbypassrls`, which is what actually
  governs RLS enforcement. Verified empirically against PostgreSQL 16.
- **Tenant context restore no longer masks an aborted-transaction error.** When
  a `switch` block hit a database error that aborts the transaction (e.g. a
  WITH CHECK policy violation), the ensure clause ran `SET LOCAL` to restore the
  previous tenant and raised `PG::InFailedSqlTransaction`, hiding the original
  error. The restore now ignores `ActiveRecord::StatementInvalid`; the rollback
  clears the `SET LOCAL` anyway.

### Internal

- Added a real-PostgreSQL integration suite (provisions privileged/unprivileged
  roles, schema and the RLS policy) covering tenant isolation, WITH CHECK
  enforcement, context lifecycle and the security validator; the suite
  auto-skips when no database is reachable.
- Replaced mocked-only and tautological specs with behavior-driven unit specs,
  real generator invocations, SimpleCov coverage, per-example configuration
  isolation, randomized order, and a CI Ruby×Rails matrix with a Postgres
  service.

## [0.3.0] - 2026-06-04

Security-focused release. Hardens tenant isolation and SQL handling.

### Breaking Changes

- **`TenantContext.switch` now runs its block inside a database transaction.**
  The block form previously used a session-level `SET`; it now uses `SET LOCAL`
  wrapped in a transaction so PostgreSQL guarantees the tenant context is cleared
  when the transaction ends, preventing it from leaking onto pooled connections.

  Because the subdomain middleware wraps each request in `switch`, the entire
  request now executes within a single transaction. Observable consequences:
  - `after_commit` callbacks fire at the end of the request instead of per-save.
  - An unrescued error inside the block rolls back all of the request's writes.
  - Application-level `transaction` blocks become savepoints (`requires_new`).
  - The connection is held for the duration of the request.

  If you relied on per-save commit semantics, review those code paths. The
  permanent `switch!` (session-level `SET`) still exists for the console and
  single-tenant scripts, but is now documented as unsafe on pooled connections —
  always pair it with `reset!`.

### Security

- **Cross-tenant context leak fixed** — `switch` uses `SET LOCAL` in a
  transaction; the context can no longer survive on a pooled connection if
  cleanup fails (crash, killed thread, lost connection).
- **SUPERUSER and inherited BYPASSRLS now rejected** — `SecurityValidator`
  inspects the actually connected role (`current_user`), rejects `rolsuper`
  (superusers bypass RLS unconditionally), and evaluates the effective
  `BYPASSRLS` privilege across inherited roles via `pg_has_role`.
- **SQL identifier injection hardened** — `RlsHelper` and `TenantContext` quote
  table/column/policy identifiers (`quote_table_name` / `quote_column_name`),
  validate identifiers against a strict pattern, and pass catalog literals and
  `current_setting` arguments through `connection.quote`.
- **Cross-tenant assignment blocked** — `MultiTenant#set_tenant_id` raises when
  an explicit `tenant_id` differs from the active context and always pins the
  value to the current tenant, adding an application-layer guard on top of
  database enforcement.

### Fixed

- `tenant_class` is resolved on every call instead of being memoized, avoiding a
  stale class object across development code reloads and reconfiguration.
- Removed the railtie initializer that reset configuration to defaults on every
  boot and could clobber a host application's settings depending on load order.
- Subdomain extraction now handles IPv6 hosts (`::1`, `[::1]`) and `host:port`
  forms via `IPAddr`, instead of treating them as domains and producing a bogus
  subdomain.
