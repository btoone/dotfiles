---
name: maintenance-tasks
description: >
  Build or refactor a great Shopify `maintenance_tasks` Task (Rails) — the full
  design, not just batching. Starts from the decision that shapes everything —
  which of the four collection shapes fits: an AR **Relation** (per-record
  `process`), a **`Model.in_batches(of: N)`** batch enumerator (one set-based
  bulk write per batch), a plain **Array** (small finite computed collections
  like catalogs or date ranges), or **`no_collection`** (a single atomic SQL
  statement, no iteration) — then layers on idempotency, large-table timeout
  rules, callback/PaperTrail-aware writes, and the opt-in features (dry-run,
  attributes, throttling, callbacks). Encodes the traps agents hit repeatedly:
  a collection Relation must carry NO `ORDER BY`/`LIMIT` (the cursor adds its
  own PK ordering and it raises at runtime); `find_each` ignores a custom
  `order`; never override `count` for a batch enumerator; prefer the collection
  API over `no_collection` so you get progress + pause/resume; data backfills
  belong in a task, not a migration; use `update_all`/`update_columns` to skip
  callbacks and avoid minting a spurious PaperTrail version; use `.delete` (not
  `.destroy`) when a destroy callback would cascade to a shared external asset;
  disable triggers inside `begin/ensure`; make every write idempotent so
  cancel/re-run is safe; and delete the task once it has run. When the gem's
  behavior is unclear, read the installed source.
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash(bundle show:*)
  - Bash(bin/rspec:*)
  - Bash(bundle exec rspec:*)
  - Bash(bin/rails test:*)
  - Bash(bundle exec rake test:*)
  - Bash(bin/rubocop:*)
  - Bash(bundle exec rubocop:*)
  - Agent
when_to_use: >
  Use when building, refactoring, or reviewing a Shopify `maintenance_tasks`
  Task in a Rails app — a class under `app/tasks/**` that subclasses
  `MaintenanceTasks::Task`. Concrete triggers: "write a maintenance task",
  "backfill this column", "clean up / purge these rows", "re-process these
  records in production", "this task is slow / not batching / shows 1 of 1",
  "this task will take N hours", "the task raised 'cannot use ORDER BY or
  LIMIT'", a data backfill someone wants to put in a migration, or any review
  of `collection` / `process` / `count` / `no_collection` on a task. If you are
  about to define `collection` or `process`, this skill applies — pick the
  collection shape BEFORE writing `process`.
---

# Building a great `maintenance_tasks` Task

Design guidance for Shopify's [`maintenance_tasks`](https://github.com/Shopify/maintenance_tasks)
gem. Tasks live under `app/tasks/**` and run from the `/maintenance_tasks` UI.
This is how to build one that is fast, honest about progress, idempotent,
resumable, and safe to run in production — then delete.

## Goal

A Task that:

- uses the collection shape that fits the work (per-record, batch, array, or none),
- reports honest progress in the UI (no frozen bar, no "1 of 1"),
- is idempotent and resumable — a cancelled or interrupted run re-runs cleanly,
- respects the database statement timeout on large tables,
- writes without tripping callbacks, triggers, or audit trails it shouldn't,
- is proven by a spec written first,
- carries a header explaining what/why/idempotency/lifecycle, and is deleted
  after it runs.

## When a task is the right tool

Reach for a Maintenance Task for anything **operational in production** —
backfills, cleanups, re-processing, re-enqueuing, data fixes. It beats the
alternatives because it runs on the worker (native Redis + prod creds),
commits each unit before its side effects, shows progress/errors/history, and
pauses/resumes/throttles — and it's named, tested, reviewed.

- **Not a migration.** Data backfills do **not** belong in a migration — move
  them to a task. Migrations are for schema; a task is for data, with progress
  and resumability a migration can't give you.
- **Not the Rails console / Kazam / a rake task.** No progress, no audit, and a
  laptop console can't reach prod Redis to enqueue follow-up work.

## Steps

### 1. Choose the collection shape — the decision that drives the design

Pick one **before** writing `process`. This is the single most important choice.

| Shape | `collection` returns | `process` receives | Use when |
|---|---|---|---|
| **Per-record** | an AR `Relation` — `Model.where(...)` | one record | Row-by-row work that can't collapse into one SQL statement: per-row service call, per-row enqueue, non-trivial Ruby per record. **The default.** |
| **Batch** | `Model.in_batches(of: N)` (a `BatchEnumerator`) | a batch **relation** | The write is set-based — `update_all` / `delete_all` / `upsert_all` / `insert_all` over a whole chunk in one statement. Large tables. |
| **Array** | a plain `Array` (`CATALOG.reject{…}`, `(start...finish).to_a`) | one element | A small, finite, computed collection: a seed catalog, a date range replayed through an aggregator, a hand-built work list. |
| **no_collection** | (declare `no_collection`; no `collection` method) | nothing (`def process`) | A single atomic operation — one `UPDATE`/`INSERT … SELECT`, a trigger toggle — that doesn't iterate records. |

**Prefer the collection API over `no_collection` whenever you iterate records.**
`no_collection` shows "1 of 1", no progress, no pause/resume. Only use it for a
genuinely atomic statement. If you're tempted to `find_each` inside a
`no_collection` `process`, you want a Relation or Batch collection instead.

**Success criteria**: you can name the shape and justify it in one sentence,
tied to whether the write is per-record, set-based, a small finite list, or a
single atomic statement.

### 2a. Per-record `process`

```ruby
def collection
  Widget.where(status: nil)          # Relation → process gets one record
end

def process(widget)
  widget.update!(status: "active")
  SomeWorker.perform_later(widget.id)   # per-row side effect, race-free after commit
end
```

- Each `process` commits its row before its side effects — this is why "reset a
  row, then enqueue a worker for it" belongs here (no transactional-enqueue race).
- The gem fetches the relation in batches under the hood; tune the fetch with
  `collection_batch_size(N)` if needed (this affects **only** the per-record
  branch).

**Success criteria**: each call is genuine per-row work that can't be one SQL statement.

### 2b. Batch `process` — the gem's batch DSL

Returning `Model.in_batches(of: N)` **is** the gem's batch DSL — the gem
special-cases `ActiveRecord::Batches::BatchEnumerator` and drives it through
job-iteration's keyset-cursor enumerator (resumable on the PK). It is **not** a
manual loop.

```ruby
def collection
  Widget.where(status: nil).in_batches(of: 5_000)
end

def process(batch)          # batch is an ActiveRecord::Relation
  batch.update_all(status: "active")          # exactly ONE bulk statement
end
```

- **Do exactly one set-based operation per batch.** `update_all`, `delete_all`,
  `upsert_all`, `insert_all` all qualify — the README's "such as `update_all`
  or `delete_all`" is illustrative, **not** an allowlist (`upsert_all` counts).
- **Never loop record-by-record inside `process`.** `batch.each { |r| r.save! }`
  batches the *fetch* but not the *write* — the exact anti-pattern batching
  avoids. A read + one lookup + one bulk write is fine:

  ```ruby
  def process(batch)
    rows   = batch.pluck(:id, :external_id)
    lookup = Related.where(key: rows.map(&:last).uniq).pluck(:key, :value).to_h
    Target.upsert_all(rows.map { |id, ext| { id:, value: lookup[ext] } }, unique_by: :id)
  end
  ```

- **Do NOT override `count`.** The gem auto-derives the total from the
  enumerator's `size` = `ceil(rows / batch_size)` = number of **batches**, and
  ticks once per batch. Overriding `count` to the row total makes per-batch
  ticks crawl against a total that's `batch_size`× too large — the bar looks
  frozen near 0%. Leave it auto: the UI reads "N of ⟨batches⟩".

**Success criteria**: one bulk statement (plus at most one lookup) per batch, no
per-row loop, `count` not overridden.

### 2c. Array and `no_collection`

```ruby
# Array — small finite computed collection
def collection
  ((Date.current - 365)...Date.current).to_a     # or CATALOG.reject { |a| exists?(a) }
end
def process(date)
  DailyAggregator.new(period: date).call          # idempotent per element (upsert)
end

# no_collection — one atomic statement, no iteration
class RestoreThingTask < MaintenanceTasks::Task
  no_collection
  def process
    ApplicationRecord.connection.execute(<<~SQL.squish)
      UPDATE things SET x = src.x FROM (SELECT …) src WHERE things.id = src.id AND things.x IS NULL
    SQL
  end
end
```

**Success criteria**: Array collections are genuinely small/finite; `no_collection`
is one atomic op, not a disguised iteration.

### 3. Make it idempotent and resumable

A run can be cancelled or interrupted (it stops cleanly between records/batches)
and re-run. Design so re-running is safe **and cheap**:

- **Scope the collection to unprocessed rows** — `where(new_column: nil)`,
  `where(status: :internal)`, `reject { |a| Model.exists?(key: a.key) }`. A
  re-run then picks up only what's left, and finished work isn't redone.
- **Guard the write itself**: `upsert_all(..., unique_by: <real unique index/PK>)`,
  `insert … ON CONFLICT (cols) DO NOTHING`, `find_or_create_by!` on the unique
  key. Never `unique_by` an auto-generated `id` that isn't in the insert list —
  it never conflicts and silently duplicates.
- **A `no_collection` statement must be idempotent on its own** — add the
  `WHERE … IS NULL` / `ON CONFLICT` guard so re-running is a no-op.

**Success criteria**: running twice equals running once — proven in the spec.

### 4. Large tables — respect the statement timeout

For any table over a few million rows (production often runs a ~30s statement
timeout):

- **Batch ~5,000 rows.** Larger batches risk the timeout on wide writes; 50k was
  too large in practice.
- **Iterate per parent entity when backfilling a FK**, so per-parent indexes do
  the work and one "whale" parent can't blow the timeout: `collection` returns
  the parents, `process` updates that parent's children in bounded batches.
- **Split SELECT from UPDATE.** Never `UPDATE … WHERE id IN (SELECT …)` on a huge
  table — Postgres can pick a catastrophic plan. SELECT ids into Ruby, UPDATE by
  exact PK. (The Batch shape already hands you a PK-bounded relation, so
  `batch.update_all` is safe; the split matters inside a hand-rolled loop.)
- **Keep predicates sargable** — a function-wrapped indexed column
  (`LTRIM(col,'0')`, `LOWER(col)`, `col::text`) can't use the index.

**Success criteria**: no single statement scans the whole table; batch size is
bounded; the collection predicate is indexed.

### 5. Write without tripping callbacks, triggers, or the audit trail

Backfills often must NOT behave like normal user writes. Decide deliberately:

- **`update_all` / `update_columns` to skip callbacks and validations** — and,
  crucially, to **avoid minting a spurious PaperTrail version**. Use when the
  backfill is correcting data and should not appear as a new user edit in
  history. (`update_columns` for a single loaded record; `Model.where(id:).update_all`
  for a set-based one.)
- **`.delete` vs `.destroy`.** `destroy` fires callbacks — if an `after_commit`
  cascades to a **shared external resource** (e.g. deleting a row triggers a job
  that deletes a file another surviving row still references), use `.delete` to
  skip the callback. Conversely, if children are protected by
  `dependent: :restrict_with_exception`, delete the children first
  (`delete_all`) then `destroy!` the parent.
- **Disable triggers around a bulk backfill** when a per-row trigger would fire
  millions of times — wrap in `begin/ensure` so it's always re-enabled:

  ```ruby
  def process
    connection.execute("ALTER TABLE t DISABLE TRIGGER trigger_x;")
    backfill!
  ensure
    connection.execute("ALTER TABLE t ENABLE TRIGGER trigger_x;")
  end
  ```

**Success criteria**: you've consciously chosen whether each write fires
callbacks / triggers / versions, and documented why in a comment.

### 6. Collection-query constraints — the gotchas that raise or misbehave

- **No `ORDER BY` or `LIMIT` on the collection Relation.** The gem's cursor adds
  its own primary-key ordering; an explicit `.order(...)` or `.limit(...)` raises
  `"The relation cannot use ORDER BY or LIMIT"` at runtime. Remove it.
- **`find_each` ignores a custom `order`** and forces PK order. If inside
  `process` you need newest-first (or any custom order) over a *bounded*
  per-record set, load it with `.order(...).each`, not `find_each`.
- **`collection_batch_size` affects only the per-record Relation branch** — it's
  dead config on a `BatchEnumerator` (that size comes from `in_batches(of:)`).
- **`cursor_columns` defaults to the primary key** (stable, resumable). Override
  only for a different stable order, and know that if the cursor column's values
  change mid-run, rows can be skipped or yielded twice.

**Success criteria**: the collection carries no ORDER BY/LIMIT; any custom
ordering lives in a bounded `.each` inside `process`.

### 7. Opt-in features — reach for these deliberately, not by default

- **Dry-run + CSV report.** The gem has **no built-in dry-run**. Implement it:
  `attribute :dry_run, :boolean, default: true` (preview is safe, mutation is
  opt-in); always compute and write a CSV of what *would* change; `return if
  dry_run` before the write; log the path and mode on the first row. Operators
  diff the preview, then re-run with `dry_run: false`.
- **`attribute :name, :type`** — run-time knobs rendered as form fields:
  `client_id`/tenant scope for a smoke run, `batch_size`, `since`/`until` window,
  `limit` for a sample, `force` to override an idempotency guard. Validate with
  `validates … inclusion:` for dropdowns; `mask_attribute` for secrets.
- **`throttle_on(backoff:) { condition }`** — pauses and retries when a health
  condition holds. Worth it for very large production writes, especially into a
  table published for CDC/logical replication where write volume can outpace
  replication. Skip it unless there's a real signal to gate on.
- **`report_on(SomeError, severity:)`** — rescue, report, continue. For data
  **backfills prefer the default halt-on-error** so you don't silently skip rows;
  use `report_on` only when partial failure is genuinely acceptable.
- **Callbacks** — `after_start` / `after_complete` / `after_error` / `after_pause`
  / `after_interrupt` / `after_cancel`. Use for notifications or a global sweep
  from `after_complete`; don't add empty ones.
- **A raising guard in `collection`** as a safety gate — e.g. refuse to run a
  destructive purge before a retention window elapses:
  `raise "retention window not elapsed" if Date.current < earliest_run`.

**Success criteria**: every feature added has a reason; none are cargo-culted.

### 8. TDD it — spec first

Write the spec before the task, driving `process` directly:

```ruby
def run_task
  task.collection.each { |unit| task.process(unit) }   # unit = record, batch, or element
end
```

Assert **observable outcomes** (persisted rows, not internal calls) and
**idempotency** (run twice → no duplication, stable values). For a **batch**
task, also pin the batching with a query-count assertion so a future edit can't
regress to row-at-a-time:

```ruby
it "issues one lookup per batch regardless of size" do
  3.times { create(:widget) }
  batch = task.collection.first
  queries = count_queries(matching: 'FROM "related"') { task.process(batch) }
  expect(queries).to eq(1)
end
```

For a **dry-run** task assert all three: the live row is unchanged, no
side-effecting record is created (PaperTrail version, enqueued job), and the CSV
captured the would-be change.

**Success criteria**: RED → GREEN with a meaningful first failure; idempotency
(and, for batch tasks, the batching guarantee) is pinned by a test.

### 9. Header + lifecycle

Give every task a header comment: **what** it does, the **idempotency basis**
(what makes re-runs safe), and the **lifecycle** (when to run, when to delete).

1. **Ship the task in the same PR** as the migration/feature it supports.
2. **Run it** from `/maintenance_tasks` after deploy; watch progress.
3. **Delete the task in a follow-up PR** once confirmed in every environment —
   a stale task referencing a dropped table or renamed model is broken code.

**Success criteria**: header present; task removed after it has run.

## When the gem's behavior is unclear, read the source

Don't guess at how the gem treats a collection type, computes progress, or
resumes:

```bash
bundle show maintenance_tasks     # app/models/maintenance_tasks/task.rb (DSL: throttle_on, report_on,
                                  #   collection_batch_size, csv_collection, callbacks, mask_attribute)
                                  # app/jobs/concerns/maintenance_tasks/task_job_concern.rb (build_enumerator:
                                  #   which collection types are supported and how each is driven)
bundle show job-iteration         # enumerator_builder.rb, active_record_batch_enumerator.rb (size = batch
                                  #   count; cursor/each semantics)
```

**Success criteria**: any claim about gem behavior is backed by the source, not memory.

## Anti-patterns to catch in review

```ruby
# 1. Batched fetch, row-by-row write — worst of both worlds
def collection; Widget.in_batches(of: 5_000); end
def process(batch); batch.each { |w| w.update!(status: "active") }; end   # 5k single UPDATEs
#   → batch.update_all(status: "active")

# 2. no_collection hiding an iteration (shows "1 of 1", no resume)
def process; Widget.where(x: nil).find_each { |w| w.update!(...) }; end
#   → collection = Widget.where(x: nil); process(widget)

# 3. ORDER BY on the collection — raises at runtime
def collection; Widget.where(x: nil).order(:created_at); end
#   → drop the .order; put custom ordering in a bounded .each inside process

# 4. Overriding count on a batch enumerator — freezes the progress bar
def count; Widget.count; end   # with collection = Widget.in_batches(of: 5_000)
#   → delete it; the gem counts batches automatically

# 5. destroy that cascades to a shared external asset
def process(dup); dup.destroy; end   # after_commit deletes a file the survivor still needs
#   → dup.delete  (skip the callback)

# 6. A data backfill written as a migration
#   → move it to a task: progress, pause/resume, and it can't block the deploy
```
