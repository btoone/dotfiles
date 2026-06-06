# Rails / ActiveRecord / Postgres — stack reference for data-lineage

Concrete idioms for the generic steps in `SKILL.md`, for a Rails app with
ActiveRecord models, a Postgres database, and Sidekiq or ActiveJob for
background work. Read this once, then apply the phases. The SQL query patterns
(P1–P7) are already Postgres-flavored in the skill — this file covers the
parts that are *code*-specific: tracing writers, proving enqueue, inspecting
schema, and running queries safely.

## Schema inspection (Phases 1–2; grain in Phase 5)

The canonical column/index inventory is in the repo — grep it, don't guess:

```bash
# SQL format (preferred when present) or the Ruby DSL
grep -n -A30 'CREATE TABLE.*\b<table>\b' db/structure.sql
grep -ni 'index.*\b<table>\b'            db/structure.sql   # which columns are indexed
# or, if the repo uses schema.rb:
grep -n -A20 'create_table "<table>"'    db/schema.rb
```

- Migrations live in `db/migrate/*` — `git log -- db/migrate` dates schema changes.
- Live introspection in psql: `\d <table>` (columns + indexes), `\d+ <table>` (sizes).

## Tracing the WRITE path (Phase 2)

ActiveRecord write primitives — grep for these to find the DB-write hop:
`insert_all` / `insert_all!`, `upsert_all`, `create` / `create!`, `new` (+
`save`/`save!`), `update` / `update!`, `update_all`, `.import`
(activerecord-import), and `<<` on a has-many association.

```bash
rg -n 'insert_all!?|upsert_all|create!?\b|update_all|\.import\b' app lib -g '!**/spec/**'
rg -n '<Model>\.(new|create!?|insert_all!?|upsert_all)' app lib
```

Writers usually live in `app/services/**`, `app/jobs/**` (or `app/workers/**`),
`app/models/**` (callbacks/associations), and `lib/**`. The
router/dispatcher hop is often a `*_router.rb`, a `PARSER_MAPPING` /
`HANDLERS` constant, or a `case`/lookup on a file token or event type.

## Proving a worker is (or never was) enqueued — the "is it dead?" test (Phase 4)

Enqueue calls by framework:

- **Sidekiq**: `<Worker>.perform_async`, `.perform_in`, `.perform_at`, `.set(...).perform_async`
- **ActiveJob**: `<Job>.perform_later`, `.set(wait: ...).perform_later`
- **Synchronous** (also a real caller): `<Worker>.new.perform`

```bash
# Every reference to the worker across ALL history; look for an enqueue among them
git log -p --all -S '<Worker>' -- app lib config \
  | grep -nE 'perform_(async|later|in|at)|<Worker>'
```

Scheduled/cron enqueues are the easy miss — a class name as a *string* in config:

- **sidekiq-cron / sidekiq-scheduler**: `config/sidekiq.yml` (`:schedule:` / `:cron:` keys), `config/schedule.yml`, or an initializer calling `Sidekiq::Cron::Job.load_from_*`
- **whenever gem**: `config/schedule.rb` (`runner`/`rake` lines)
- **clockwork**: `clock.rb` / `lib/clock.rb`

```bash
git log -p --all -- config/sidekiq.yml config/schedule.yml config/schedule.rb \
  | grep -niE '<Worker>|<under_scored_worker_name>'
rg -n '<Worker>|<under_scored_worker_name>' config
```

A worker with **no `perform_*` caller in code AND no cron/schedule entry**
anywhere in git history is dead — committed but never connected.

## Tracing READ paths (Phase 3)

```bash
rg -n '<Model>\b|\b<table_name>\b' app lib config -g '!**/spec/**' -g '!**/test/**'
```

Watch for: model scopes/constants that encode the "authoritative" filter
(`scope :chargebacks, ->{ ... }`, `CHARGEBACK_CODES = [...]`); reporting/query
objects under `app/reporting/**`, `app/queries/**`, or `app/<context>/**`;
serializers; and views. A reader reachable only through a controller action
whose index page is backed by a dead table is *stranded* (Phase 3).

## Running queries (Phase 5)

- **Project wrapper**, if present: `just psql`, `bin/psql`, `make db-console` —
  check the repo's `justfile` / `Makefile` / `bin/`.
- **Rails-native**: `bin/rails dbconsole` (uses `config/database.yml`), or
  `bin/rails runner "puts Model.where(...).to_sql"` to see generated SQL.
- **Read replica**: point at the replica endpoint directly, or in app code
  `ActiveRecord::Base.connected_to(role: :reading) { ... }`. Prefer the replica
  for the heavy reconciliation queries (P3/P4/P6).

## Postgres cost & safety (Phase 5 blast radius)

- **`statement_timeout`** is often 30s in app config; a big `COUNT(DISTINCT)`
  or multi-join can hit it. Check with `SHOW statement_timeout;`. For a
  deliberate one-off **on a replica** you may raise it: `SET statement_timeout = '120s';`.
- **Estimate before running the expensive one**: `EXPLAIN <query>` gives the
  plan without executing. Use `EXPLAIN (ANALYZE, BUFFERS)` only when you're
  willing to actually run it.
- **Sargability**: a predicate wrapped in a function (`LTRIM(col)`,
  `LOWER(col)`, `col::date`) can't use that column's index → expect a seq scan.
  The normalize-on-join that P4/P5 rely on is exactly this shape; on a large
  table it's slow, so sample with `LIMIT` while shaping the query.
- **Watch / cancel** a long query: `SELECT pid, query FROM pg_stat_activity
  WHERE state = 'active';` then `SELECT pg_cancel_backend(<pid>);`.
- Confirm your join/filter columns are indexed (`db/structure.sql`) before the
  full-table version.

## Idempotency tells (Phase 2 — what the writer's shape says about the rows)

- `delete_all` + `insert_all!` per file/batch id → **full reload**; rows are
  authoritative snapshots, safe to re-ingest.
- `upsert_all` / `INSERT ... ON CONFLICT` on a natural key → **incremental**,
  last-write-wins.
- Plain `insert_all!` with no dedup → **append-only**; expect duplicates, count
  `DISTINCT <natural_key>`.
