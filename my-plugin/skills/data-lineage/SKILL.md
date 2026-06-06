---
name: data-lineage
description: >
  Systematically answer "where does this data actually come from?" questions —
  is X the source of truth, why did Y stop updating, which table feeds this
  surface — by combining production-query evidence with code-path and
  git-history tracing, then producing an evidence-grounded results document
  where every claim cites a query result or a file:line. Enforces a strict
  evidence-first discipline: frame competing hypotheses, trace write paths
  before read paths, profile the grain BEFORE filtering, reconcile by a
  globally-unique key, quantify coverage and leaks, and refute your own
  hypotheses out loud. No claim ships without a citation; no number ships
  without the query that produced it. Opportunistically uses any connected
  MCP servers (read-only production DB, hosting/deploy logs, observability) to
  deepen the evidence, and degrades gracefully to local tooling when they
  aren't present.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(rg:*)
  - Bash(psql:*)
  - Bash(just psql:*)
  - Agent
  - ToolSearch
  # When connected, this skill also uses MCP servers for read-only DB queries,
  # hosting/deploy logs, and observability (e.g. mcp__*__query, mcp__*__logs,
  # Sentry/Vercel/Datadog tools). Discover them via ToolSearch — see
  # "Available evidence sources" below. None of them are required.
when_to_use: >
  Use whenever you must establish where data actually comes from, or which of
  several stores is authoritative. Concrete triggers: "is X the source of
  truth?", "why did table Y stop updating?", "which table feeds this
  dashboard/report/API?", "are these two numbers measuring the same thing?",
  "this surface reads A but we were told B is truth — which is right?", "did
  this model ever have a live writer?", a migration or analytics cutover that
  needs to re-point a surface from one table to another, or any reconciliation
  where two stores disagree on a count and you need to know which is correct
  and why. If the answer depends on what the data and code actually do (not on
  a doc or a guess), this skill applies — gather evidence before you conclude.
---

# Data Lineage — source-of-truth audit by evidence, not assertion

Answer lineage questions the way a forensic accountant reconciles books:
every claim is backed by either a **production query result** or a
**`file:line` citation**, and you refute your own best hypothesis out loud
when the data disproves it. The deliverable is a results document, not a
verbal conclusion.

A single running illustration threads through the phases below, marked
`▸ Example:`. It's a generic, made-up scenario — *"which store is the source of
truth for chargebacks: the case feed, the financial-posting feed, or a
rolled-up summary table?"* — used only to show what each phase looks like in
practice. The names in it (`case_actions`, `adjustments`, `rollups`) are
illustrative, not part of the method; your real audit substitutes your own.

## Goal

- Every conclusion cites a query result or a `file:line`. Nothing is asserted
  from memory or from a doc that wasn't verified against code/data.
- The write path of each candidate source is established as **live** or
  **dead** before any read path or production number is trusted.
- Counts are profiled at their true grain BEFORE any filter is applied, so
  rows-vs-events confusion never silently corrupts a number.
- The final document includes an honest "hypotheses refuted" section — the
  arguments you expected to win that the data killed.

## Match the depth to the question — dig progressively

This skill is an **escalation ladder, not a checklist you run top to bottom
every time.** Spend effort in proportion to how much the question resists and
how much rides on the answer. **Do the cheapest thing that could settle it,
then stop the moment you have a confident, cited answer.** Running the full
suite on an obvious question is its own failure mode — it buries the answer and
wastes the dev's time.

Three depths; start at the top and escalate only when a trigger fires:

- **Quick (a grep or two, minutes).** "Which table feeds this dashboard?" /
  "what writes this model?" is often a pure Phase 2/3 question — trace the
  writer and the readers, cite `file:line`, answer. No prod, no git, no doc.
- **Confirm (add one cheap probe).** When the answer hinges on "is it still
  live?" or "did this change recently?", add the *single* relevant check — P1
  recency, or a short git lifecycle (Phase 4) — and stop. Don't run the whole
  query suite to answer a recency question.
- **Full audit (the whole ladder).** Competing hypotheses, both paths traced,
  git archaeology, P1–P7, and the results doc with a refuted-hypotheses
  section. Reserved for when it's earned.

**Escalate a level when** any of these is true: the cheap evidence is ambiguous
or self-contradictory; two sources disagree on a number; the answer will drive
a cutover, a deletion, or anything touching money/correctness; or the dev asks
for rigor. **Otherwise stop, answer, and name your confidence** — offer to go
deeper rather than doing it unprompted.

Two things **never** scale down, because they're cheap and they're the whole
point: every claim still cites a query result or a `file:line`, and you still
say so out loud the moment something you find contradicts the easy answer.
Brevity is fine; an uncited or unchallenged claim is not.

## Step 0 — Load your stack's reference

The SQL query patterns (P1–P7) are portable. Three things are **stack-specific**
and have their own reference file: how you *trace a write path* (the write
primitives and where writers live), how you *prove a worker was never enqueued*
(the job/scheduler framework), and how you *inspect schema and run queries* (the
DB console, timeouts, EXPLAIN). Detect the stack and read the matching reference
once before tracing code:

| Signal | Reference |
|--------|-----------|
| `Gemfile` + `config/application.rb` (Rails / ActiveRecord / Postgres) | `frameworks/rails.md` |

If no reference matches your stack, apply the **generic shapes** in each phase
and substitute your stack's equivalents — the write primitive, the enqueue
call, the schema definition, the DB console. The method doesn't change; only
the idioms do. (Adding a `frameworks/<stack>.md` for a new stack is the way to
extend this skill.)

## Available evidence sources — start local, go to prod when you need it

This is **not** a waterfall where you reach for the heaviest tool available and
work down. It's the opposite: **start local.** The code and schema definition
(Phases 1–4; your stack's schema file — see Step 0) answer a surprising amount
on their own — which writers are live, what the grain *should* be, where each
reader sources. Often that's enough to settle the question, and you never touch
production.

Production data (Phase 5) is what you reach for when the question genuinely
needs live values — recency/volume (is this table still fed?), real grain at
scale, coverage, cross-source reconciliation. **When you hit that point, name
it and decide with the dev:** "I can answer X from the code, but confirming
recency/coverage needs production — do you want me to query prod, or is the
code-and-schema read enough for now?" Don't silently jump to prod, and don't
silently stop short of it when the answer requires it.

Once you and the dev agree prod data is needed, **how** the query runs is a
detail, not a quality tier:

- If a **read-only DB MCP server** is connected, run the query through it — a
  connected read-only MCP is itself the dev's standing consent to read prod.
- If not, **ask the dev to run the query** and paste back the result (see
  "Asking the dev to run prod queries" — secure-credential rules apply).
- A local read replica or prod dump, if one exists, is a convenience for either
  path — use it when it's there, don't manufacture one when it isn't.

None of these is "better evidence" than another — they all return the same prod
rows. Pick whichever the environment makes available; don't pause to ask the
dev to wire up an MCP that isn't connected.

Discover MCP tools with `ToolSearch` (their schemas are deferred — search by
keyword, then call the matches):

| Evidence you want | Look for MCP tools matching | If no MCP is connected |
|---|---|---|
| Run a SQL query against prod | `ToolSearch "database query sql postgres"` — e.g. `mcp__*__query`, `mcp__*__execute_sql`, a Supabase/Neon/Postgres server | run it yourself via your DB console (see Step 0) against a read replica or dump, or ask the dev to run it (see "Asking the dev to run prod queries") |
| Inspect schema / list tables | `ToolSearch "list tables describe schema"` | your stack's schema file + migrations, or `\d` in psql (see Step 0) — usually all you need, no prod required |
| Runtime / deploy logs | `ToolSearch "logs deployments runtime"` — Vercel, Netlify, Fly, Railway, Cloudflare, AWS servers | application log files, `git log` on deploy configs, cron/schedule files |
| Error / job telemetry | `ToolSearch "errors issues events"` — Sentry, Datadog, etc. | your queue/scheduler config in the repo, exception-tracking calls in code (see Step 0) |
| Build/deploy history | `ToolSearch "deployments build history"` — hosting provider | `git log` on `config/`, release tags, CI config |

How each source supercharges the phases:

- **Phase 2/4 (is the writer live or dead?)** — deploy logs and job/queue
  telemetry settle it directly: a writer that's genuinely running shows up in
  runtime logs; one that's dead leaves a silent gap that corroborates the git
  "never enqueued" finding. Hosting deploy history dates *when* a path went
  live or stopped, sharpening the timeline beyond what `git log` alone shows.
- **Phase 5 (production queries)** — run the P1–P7 patterns through the MCP DB
  tool exactly as written; the SQL is identical. An MCP server pointed at real
  prod beats a stale dump for recency/volume (P1) and coverage (P4).
- **Cross-checking recency** — a table whose `max_loaded` looks current in P1
  but whose writer shows no recent runtime activity in logs is a contradiction
  worth chasing (e.g. backfilled once, never fed since).

Rules when using MCP sources:
- **Read-only only.** Never issue writes/DDL/mutations through an MCP server,
  even if the tool allows it. This is an audit, not a change.
- **Cite the source of every number** — note which MCP server (or local tool)
  produced each result in the doc, the same way you cite `file:line`.
- **Cross-check, don't blindly trust.** If an MCP result and the code/git story
  disagree, that disagreement is itself a finding — surface it, don't paper
  over it.
- **Note the source of each number** so a reader can calibrate its weight —
  live MCP, local replica, dump, or dev-run.

### Asking the dev to run prod queries (and never leak a credential)

When you and the dev have agreed prod data is needed and there's no DB MCP
server (and no replica/dump you can reach yourself), hand the dev a
ready-to-run query and ask them to paste the result back. This is a normal,
first-class way to get prod data — not a degraded fallback. Do it **without
ever putting a production credential in the clear.** Concretely:

- **Give them paste-ready, read-only SQL** — the exact P1–P7 query, wrapped so
  it cannot mutate anything:

  ```sql
  BEGIN; SET TRANSACTION READ ONLY;
  -- <the P1–P7 query here>
  ROLLBACK;
  ```

- **Let their environment supply the credential — don't dictate how.** Ask
  them to connect "however you normally reach prod read-only" — their existing
  `just psql` / wrapper, a `~/.pgpass` (chmod 600) entry, a `~/.pg_service.conf`
  service (`psql service=prod_ro`), an already-exported `DATABASE_URL`, or
  psql's own interactive password prompt (run `psql` with **no** password on
  the command line; it prompts and the keystrokes never hit history).
- **NEVER instruct them to inline a secret on the command line.** Do not
  suggest `PGPASSWORD=hunter2 psql …` or a `postgres://user:pass@host` URL
  typed into the shell — both leak into shell history and the process list
  (`ps`), where any other user on the box can read them. If they must use an
  env var, tell them to `export` it on its own line (or better, in a file the
  shell sources), not prefix it onto the psql invocation.
- **Prefer a read-only role.** If the environment offers a read-replica
  endpoint or a read-only DB user, point them at that — defense in depth on top
  of the `READ ONLY` transaction.
- Paste their returned result into the doc and cite it as `via: dev-run (prod
  read replica)` so its provenance is explicit.

## The six phases — in dependency order

You won't always run all six — stop as soon as you have a confident, cited
answer (see "Match the depth"). But the *ordering* is load-bearing whenever you
do reach a phase: don't skip ahead. A production number means nothing until you
know whether the table is still fed (Phase 2) and what one row represents
(Phase 5's grain profile). Read paths (Phase 3) are noise until you know which
writers are live (Phase 2). The cheap phases come first precisely so an obvious
question is settled before you spend on the expensive ones.

### Phase 1 — Frame the question as competing hypotheses

List **every** candidate source (table / model / feed / event stream) and what
each is *claimed* to represent. State the conflict to resolve in one sentence.

- Build a candidate table: `Source | Table/Model | What it's claimed to be |
  Native attribution? | Lifecycle/grain (unknown yet — fill in later)`.
- Name the conflict explicitly: "the UI reads **A**, but we're told **B** is
  truth — which is authoritative, and why?"
- Write each candidate's claim as a **falsifiable hypothesis**, e.g. "H1: B is
  the source of truth", "H2: A is the source of truth", "H3: C is dead". You
  will try to refute each.

**Success criteria:** a reader can see what's competing and what would settle
it, before any evidence is gathered.

> ▸ Example: three candidates — `case_actions` (claimed: the dispute case
> itself), `adjustments` filtered to one transaction code (claimed: the same
> chargebacks, and what the dashboard actually reads), and a `rollups` table
> (claimed: a per-case rolled-up summary). Conflict: "the analytics surface
> reads `adjustments`, but we're told `case_actions` is the source of truth."

### Phase 2 — Trace the WRITE path for each candidate (live vs dead)

For each candidate, trace the chain from the outside world to the DB write,
citing `file:line` at every hop. Then classify the path **live** or **dead**.

The generalizable shape of a write path:

```
external file / API / event
  → router / dispatcher          (decides which handler)
  → worker / job / consumer      (the thing that must be enqueued/triggered)
  → service / parser             (transforms the payload)
  → DB write                     (insert / upsert / bulk insert)
```

- Find the model's writer: `rg` for your stack's write primitives (insert,
  create, upsert, bulk-insert, update) scoped to the source dirs — see Step 0's
  reference for the exact method names and where writers live.
- **A model with no enqueued/triggered writer is DEAD** — built but never
  connected. Prove the negative in Phase 4 (git) — show the worker was never
  enqueued.
- Note idempotency semantics (delete+reload per file? upsert on a key?) — it
  tells you whether re-ingestion is safe and whether rows are authoritative or
  provenance-stamped.

**Success criteria:** for each candidate you can name the exact writer
(`file:line`) and state "live" or "dead — no caller (proven in Phase 4)".

> ▸ Example: case-action file → a filename router maps a token to a parser key
> (`file_router.rb:46`) → an ingest worker dispatches that key to a service
> (`ingest_worker.rb:18`) → the service parses and `insert`s
> (`case_action_service.rb:122`). Live, cited at every hop. The `rollups`
> writer existed as a worker class but was traced as never-enqueued → dead.

### Phase 3 — Trace the READ paths

`rg`/grep the model/table name across your source dirs, excluding tests. For
each reader, decide: does it treat this source as authoritative?

- `rg -n '<Model>|<table_name>' <source dirs> -g '!**/{spec,test,tests}/**'`
  (Step 0's reference names the source dirs and the reader idioms to watch for.)
- Classify each reader: analytics/UI/API/job. Which one is the *surface* the
  question is really about?
- Flag **stranded readers** — a reader that is itself only reachable through a
  dead dependency (e.g. a live `#show` action reached only via a dead index).
  It reads the right source but no live traffic gets there.
- Note where the *surface in question* actually sources its data — that's the
  thing a cutover would change.

**Success criteria:** you can say, per reader, "treats X as truth: yes/no" and
"live/stranded/dead", and you've identified which surface the conflict hinges
on.

> ▸ Example: the write side honored `case_actions`, but every analytics
> surface read `adjustments` instead — the exact gap a cutover would close. The
> one live reader of `case_actions` (a `#show` timeline) was stranded: reachable
> only through an index page backed by the dead `rollups` table.

### Phase 4 — Git archaeology

Build a **dated timeline** of when each table/model was introduced, when its
write path changed, and when (if ever) it died. Prove the negatives.

Git itself is stack-agnostic; the enqueue-call names and scheduler-config paths
are not — get those from Step 0's reference.

```bash
# Prove a writer was/wasn't ever enqueued (the key "is it dead?" test):
# pull every reference to the worker across all history, look for an enqueue call
git log -p --all -S '<Worker>' -- <source dirs> \
  | grep -nE '<enqueue-call-names>|<Worker>'   # enqueue idioms: see Step 0

# Rule out a scheduler/cron enqueue (easy to miss — often a class name as a string)
git log -p --all -- <scheduler-config-paths> | grep -niE '<worker_or_keyword>'

# Lifecycle of each file: introduced, changed, removed
git log --all --format='%h %ad %s' --date=short -- <path/to/model>

# When did the write path move? Search for a distinctive signature that changed
git log --all -S '<DISTINCTIVE_CONSTANT_OR_METHOD>' --format='%h %ad %s' --date=short
```

**The archaeology toolkit — including code that no longer exists.** A retired
source table, a deleted model, or a removed writer is *exactly* what these
audits turn up, so you must be able to search history and removed files, not
just the working tree:

```bash
# PICKAXE — find every commit where a string's occurrence COUNT changed
# (i.e. it was added or removed). -S = literal string, -G = regex.
git log --all --oneline -S '<exact_string>'          -- <paths>   # added/deleted lines
git log --all --oneline -G '<regex>'                 -- <paths>   # any diff line matching
git log --all -p        -S '<exact_string>'          -- <paths>   # see the actual diffs

# FIND WHEN A FILE WAS DELETED (and the commit that did it)
git log --all --full-history --diff-filter=D -- <path/to/model>   # deletions of a known path
git log --all --full-history --diff-filter=D -- '**/*<name>*'     # don't know the exact path
#   --full-history is REQUIRED: without it, history simplification hides commits
#   for paths not on the current tree (deleted/renamed files).

# RECOVER the content of a deleted/old file to read what it actually did
git show <deleting_commit>^:<path/to/model>          # the version just before deletion
git show <any_commit>:<path>                          # any historical version

# FOLLOW a file across renames (a "moved" source is not a "dead" source)
git log --all --follow --format='%h %ad %s' --date=short -- <path>

# GREP across history when you don't have a path or a single ref — search a
# snapshot, or every commit's tree (heavy; scope with a pathspec):
git grep -n '<pattern>' <ref>                         # one historical snapshot
git grep -n '<pattern>' $(git rev-list --all -- <paths>) -- <paths>   # across all history
```

- **`-S` vs `-G`:** `-S` reports commits that change how many times a literal
  string appears (best for "when was `<Constant>` introduced/deleted"); `-G`
  matches a regex anywhere in the diff (best for "any commit touching a line
  like `…perform_async…`"). Reach for `-S` first; `-G` when you need a pattern.
- **A "missing" model isn't necessarily dead — it may have been renamed.** Use
  `--follow` / search the old name before concluding a source disappeared.
- A commit message that says "X has no production callers" is gold — quote it
  with its hash and date.
- Convert every finding to an **absolute date** in the timeline (not "last
  year").
- The narrative you're after: *when* the authoritative source changed and
  *why* the team pointed at the wrong one.
- **If deploy/runtime-log MCP tools are connected, corroborate the git story
  against reality:** deploy history dates when a path actually shipped; the
  presence (or telling *absence*) of a writer's runtime/job activity in logs
  confirms live-vs-dead independently of the code. A worker that git says was
  never enqueued *and* that never appears in runtime logs is doubly dead. If
  no such tools are connected, git + the in-repo cron/schedule config is your
  evidence — that's sufficient.

**Success criteria:** a dated timeline table (`Date | Commit | Event`) that
explains the lifecycle of every candidate, including the proof that a "dead"
writer was never enqueued.

> ▸ Example: the timeline showed the `rollups` writer was committed
> already-orphaned (no enqueue in the same commit), and a later commit message
> explicitly stated it "has no production callers." The team then fell back to
> the `adjustments` feed — while the dedicated `case_actions` feed had been
> ingesting the whole time and was simply overlooked.

### Phase 5 — Production queries

Design and run the query suite (patterns in the next section). **Profile the
grain BEFORE you filter.** Reconcile by a shared, globally-unique key.
Quantify coverage and leaks. Run a totals/headline query before the
per-dimension breakdown.

**First confirm you actually need prod data, and decide with the dev** (see
"Available evidence sources"). If the code and schema already answered the
question, you may be done — say so. When the question genuinely needs live
values (recency, real grain at scale, coverage, reconciliation), name that and
get the dev's go-ahead to query prod. Then run it by whatever method the
environment offers — all return the same rows, none is "better evidence":
through a connected read-only DB MCP, yourself via your DB console (Step 0)
against a read replica/dump, or by asking the dev to run the `READ ONLY`-wrapped
SQL (never instruct them to put a credential in the clear). Note in the doc
which path produced each number. Never issue anything but `SELECT`. If
logs/telemetry MCP tools exist, use them to cross-check recency — a table that
looks current in P1 but shows no recent writer activity in the logs is a
contradiction worth chasing.

**Mind the blast radius — these are reads against live production.** P1 is
cheap (indexed `MAX`/`COUNT`) and tells you the row-count bounds *before* you
fire the expensive ones. `COUNT(DISTINCT …)` and multi-table `LEFT JOIN`s /
`NOT EXISTS` over large tables are heavy: they can trip a statement timeout or
add load to the primary. So: prefer a **read replica**, **sample with `LIMIT`**
while you're still shaping a query, and run the full-table reconciliation only
once the shape is right. A normalize-on-join (`LTRIM(col)`, `LOWER(col)`,
`col::date`) usually can't use an index — expect a slow scan and size it first.
Step 0's reference has the timeout / `EXPLAIN` / cancel specifics for your DB.

Order of operations:

1. **Recency & volume** — which tables are even still fed? (kills dead ones
   immediately)
2. **Grain profile** — what does one row represent? (before any WHERE)
3. **Cross-reference join** — inspect the key format on both sides, then the
   match %.
4. **Coverage / leak** — what does the surface silently drop?
5. **Provenance check** — is that FK ownership or just upload provenance?
6. **Reverse direction** — what does the truth-candidate capture that the
   alternative misses?

**Success criteria:** every headline number is reproducible from a query
pasted into the doc, and you know the grain of every count.

### Phase 6 — Write up the answer (proportional to the depth)

Match the writeup to how deep you went. A **quick/confirm** answer is a few
sentences with the `file:line` (and recency) citations inline — no document.
The full **results-document template** at the end of this skill is for a **full
audit**: a contested source of truth, a cutover, or disagreeing numbers.

For a full audit, use the two-stage structure: **interim findings (revisable)**
→ **final conclusion**. Every claim cites a query result or a `file:line`.
Include the **hypotheses refuted** section.

- When a query disproves an argument you expected to win, say so explicitly and
  re-base the conclusion on what survives.
- Label any number that's pending a cleaner query as **approximate** — never
  launder an estimate into a fact.
- End with a scoped, *separate* follow-up (the cutover/fix) — do not implement
  it inside the audit.

**Success criteria:** a reviewer can audit every claim back to its evidence. In
a full audit, the "refuted" section should be non-empty — if you tested several
hypotheses and refuted none, you probably didn't test hard enough. (A quick
answer that one grep settled needn't manufacture a refutation — just cite it.)

## Reusable production-query patterns (templated)

Postgres-flavored but DB-portable. Replace `<placeholders>`. Run the totals
version of any reconciliation first; drill into per-dimension only after the
headline lands.

### P1 — Recency & volume across candidates (the fastest kill)

The single most decisive first query: which tables are still receiving data?

```sql
SELECT '<source_a>' AS source,
       COUNT(*)              AS rows,
       MAX(<event_date_col>) AS max_event_date,
       MAX(<loaded_at_col>)::date AS max_loaded
FROM <table_a>
UNION ALL
SELECT '<source_b>', COUNT(*), MAX(<event_date_col_b>), MAX(<loaded_at_col_b>)::date
FROM <table_b>
UNION ALL
SELECT '<source_c>', COUNT(*), MAX(<event_date_col_c>), MAX(<loaded_at_col_c>)::date
FROM <table_c>;
```

**Read it:** a `max_loaded` months stale (or `rows = 0`) while siblings are
current → that source is **dead**. Differing `max_event_date` between live
sources hints at different file cadences, not a problem.

### P2 — Grain profile BEFORE filtering (never trust reference codes)

Establish whether one row equals one event. Profile the **actually-stored**
values of every dimension you'll later filter on — never assume the spec's
codes match what's in the column.

```sql
SELECT <dimension_col_1>, <dimension_col_2>, <status_or_type_col>,
       COUNT(*)                          AS rows,
       COUNT(DISTINCT <natural_key>)     AS distinct_entities,
       MIN(<event_date_col>)             AS first_seen,
       MAX(<event_date_col>)             AS last_seen
FROM <table>
GROUP BY 1, 2, 3
ORDER BY rows DESC;
```

**Read it:** if `rows ≫ distinct_entities`, rows are *actions/postings*, not
*events* — every later count must be `COUNT(DISTINCT <natural_key>)` or a
filter that selects one row per entity. Record the **exact stored string** of
each code you'll filter on (e.g. `'01'` vs `' 1'` vs `'1'`), including
leading-zero padding.

### P3 — Cross-reference join (the decisive test)

Reconcile two sources by a shared key. **Inspect the key format on BOTH sides
first** — pick a globally-unique key, never a non-unique sub-key.

```sql
-- Step 1: eyeball the key on each side (length, padding, sentinels)
SELECT <key_col> FROM <table_a> WHERE <key_col> IS NOT NULL LIMIT 20;
SELECT <candidate_key>, <other_keys> FROM <table_b> LIMIT 20;

-- Step 2: match %, joining on the globally-unique key
SELECT
  COUNT(DISTINCT a.<key_col>)                                                       AS a_keys,
  COUNT(DISTINCT a.<key_col>) FILTER (WHERE b.<key_col> IS NOT NULL)                AS matched_in_b,
  ROUND(100.0 * COUNT(DISTINCT a.<key_col>) FILTER (WHERE b.<key_col> IS NOT NULL)
        / NULLIF(COUNT(DISTINCT a.<key_col>), 0), 2)                                AS pct_matched
FROM <table_a> a
LEFT JOIN <table_b> b ON b.<key_col> = a.<key_col>
WHERE a.<filter> 
  AND a.<key_col> <> '<sentinel_value>';   -- exclude junk/sentinel keys
```

**Read it:** a high match % proves one source is a superset of the other (the
financial shadow of a case, etc.). A confident **0%** almost always means you
joined on the wrong column — go back to Step 1. Exclude sentinel keys
(`'0000000000000'`, `0`, `''`) before computing the ratio.

### P4 — Coverage / leak (what the surface silently drops)

How many rows would be invisible to a downstream surface because they don't
resolve through its attribution join?

```sql
SELECT COUNT(*)                                AS total,
       COUNT(<dim>.id)                          AS mapped,
       COUNT(*) - COUNT(<dim>.id)               AS unmapped_dropped,
       ROUND(100.0 * (COUNT(*) - COUNT(<dim>.id)) / NULLIF(COUNT(*), 0), 2) AS pct_dropped
FROM <fact_table> f
LEFT JOIN <attribution_table> <dim>
  ON <normalize>(f.<join_col>) = <dim>.<key>
WHERE f.<filter>;
```

**Read it:** `pct_dropped > 0` means the surface undercounts by silently
dropping unmatched rows. `pct_dropped = 0` **refutes** a coverage-leak
hypothesis — say so and re-base the argument on grain/richness instead.

### P5 — Provenance vs ownership check

A foreign key like `client_id` may record *who uploaded the file*, not *who
owns the business entity*. Test it.

```sql
SELECT COUNT(DISTINCT <fk_col>) AS distinct_fk_values
FROM <table> WHERE <filter>;
-- compare to the count of real owners resolved through the proper lookup:
SELECT COUNT(DISTINCT <owner_col>) AS distinct_real_owners
FROM <table> f
JOIN <lookup> l ON <normalize>(f.<business_key>) = l.<key>;
```

**Read it:** a single (or tiny) `distinct_fk_values` against a large
`distinct_real_owners` means the FK is **upload provenance**, not business
ownership — never group analytics by it; resolve the real owner through the
domain lookup.

### P6 — Reverse direction (what truth captures that the alternative misses)

Use `NOT EXISTS` (not a fan-out `LEFT JOIN ... COUNT(*)`) to count entities in
the truth-candidate with no counterpart in the alternative.

```sql
SELECT
  COUNT(*)                                                  AS truth_entities,
  COUNT(*) FILTER (WHERE NOT EXISTS (
    SELECT 1 FROM <alt_table> alt
    WHERE alt.<key> = t.<key> AND alt.<filter>
  ))                                                        AS missing_from_alt,
  ROUND(100.0 * COUNT(*) FILTER (WHERE NOT EXISTS (
    SELECT 1 FROM <alt_table> alt
    WHERE alt.<key> = t.<key> AND alt.<filter>
  )) / NULLIF(COUNT(*), 0), 2)                              AS pct_missing
FROM <truth_table> t
WHERE t.<filter>;   -- one row per entity (use the grain-correct filter from P2)
```

**Read it:** the share the truth-candidate captures that the alternative can't
see (cases resolved before they ever produced a financial posting, etc.) is the
positive case for the source of truth — not just that it matches, but that it
sees *more of the right thing*.

### P7 — Spot-check one entity end to end (narrative proof)

Aggregate percentages convince the head; one fully-traced entity convinces the
gut. Pick one natural key that you know matched in P3 and show how it surfaces
in *every* candidate — this is the single most persuasive artifact in the doc,
and it catches grain/join errors the aggregates can hide.

```sql
-- 1. The candidate-of-truth: the full lifecycle of one entity
SELECT * FROM <truth_table>
WHERE <natural_key> = '<one_key>'
ORDER BY <event_date_col>;

-- 2. The alternative: how the SAME entity shows up (often N rows, coarser grain)
SELECT * FROM <alt_table>
WHERE <join_key> = '<one_key>';

-- 3. The dead / other candidate: expected empty or stale
SELECT * FROM <other_table>
WHERE <fk_or_key> = '<one_key>';
```

**Read it:** one entity should appear as a single rich lifecycle in the truth
source, as N derived/financial rows in the alternative (proving the grain
difference concretely), and as nothing in the dead source — the same story your
aggregates tell, now made auditable. Paste the three results into the doc as a
worked trace. If the entity does NOT show up where you expected, that's a
finding: your join key or grain assumption is wrong — go back to P2/P3.

## Hard-won traps the skill MUST warn about

Each of these is a documented way a lineage audit produces a wrong number.
Check every one.

| Trap | Why it bites | Defense |
|---|---|---|
| **Date columns mean different things across feeds** | A `transaction_date` is the *event* date in one feed and the *posting* date in another; windowing by the wrong one collapses or inflates counts | `MIN/MAX` every date column on each side; pick the one that matches the question. Reconcile date-free (by key) when possible |
| **An FK is provenance, not ownership** | `client_id` may be the upload account, not the business owner — grouping by it silently collapses to one bucket | Run P5; resolve the real owner through the domain lookup |
| **LEFT JOIN fan-out inflates `COUNT(*)`** | One row matching many fans the denominator out | `COUNT(DISTINCT key)` or `NOT EXISTS` (P6), never a fan-out `LEFT JOIN ... COUNT(*)` |
| **Join keys need format inspection first** | Wrong column / unpadded leading zeros returns a confident **0%** match that looks like a real finding | Inspect `length`/format/sample on both sides (P3 Step 1) before trusting any match % |
| **Reference-data codes drift from stored values** | The spec says `1`, the column stores `'01'` or `' 1'` | Profile the stored values (P2); base every filter on what the DB returns, not the spec table |
| **Rows are actions, not events** | `COUNT(*)` counts postings/openings/reversals, not the entity | Profile grain first (P2); count `DISTINCT <natural_key>` or filter to one-row-per-entity |
| **Confirmation bias** | You expect a coverage leak, find 0%, and bury it | Refute your own hypotheses out loud — when a query kills your favorite argument (the leak was 0%), say so and re-base |
| **Laundering estimates into facts** | "~55k" quietly becomes "55,000" | Label pending/approximate numbers as approximate until a clean query confirms them |

## Results-document template

Write this to the project's plans/docs dir (e.g.
`.claude/plans/<topic>_source_of_truth_<date>.md`). Fill every `<...>`. Keep
the interim section even after the final conclusion lands — the revision trail
is part of the evidence.

```markdown
# <Topic> — Source of Truth Audit

**Created:** <date>   **Owner:** <name>   **Status:** <draft | confirmed>

## The question
<One sentence. Name the conflict: "surface reads A, we're told B is truth.">

## Candidate sources (hypotheses)
| Source | Table/Model | Claimed to represent | Native attribution? | Grain (TBD until P2) |
|---|---|---|---|---|
| <A> | <table_a> | <claim> | <y/n> | <fill after profiling> |
| <B> | <table_b> | <claim> | <y/n> | <...> |

- **H1:** <B is the source of truth>   — to confirm/refute
- **H2:** <A is the source of truth>   — to confirm/refute
- **H3:** <C is dead>                  — to confirm/refute

## Write-path findings (Phase 2)   — every row cites file:line
| Source | Writer | Trigger/enqueue | Live? | Cite |
|---|---|---|---|---|
| <table_a> | <Service#method> | <router/worker route> | live/dead | `file:line` |

## Read-path findings (Phase 3)
| Reader | Treats as truth? | Live / stranded / dead | Cite |
|---|---|---|---|

## Git timeline (Phase 4)
| Date | Commit | Event |
|---|---|---|
| <YYYY-MM-DD> | `<hash>` | <introduced / changed / flagged caller-less> |

## Production query results (Phase 5)
Run via: <MCP server name | `just psql` replica | prod dump>.
For each query: paste the SQL, then the result, then a one-line reading.
- **P1 recency/volume:** <result> → <which sources are live/dead>
- **P2 grain:** <result> → <one row = ? ; the canonical filter is `<...>`>
- **P3 cross-ref join:** key = `<key, format>`; **<pct>%** matched → <reading>
- **P4 coverage/leak:** **<pct>%** dropped → <reading>
- **P5 provenance:** distinct fk = <n> vs real owners = <m> → <reading>
- **P6 reverse:** **<pct>%** of truth missing from alternative → <reading>
- **P7 spot-check:** entity `<one_key>` → <1 lifecycle row in truth, N in alt, none in dead>

## Hypotheses refuted (be honest)
- **<expected-winner argument>** — REFUTED by <query>: <what actually happened>.
  Re-based the conclusion on <what survived>.

## Final conclusion
<Source X is the source of truth.> Evidence, each cited:
1. <claim> (<query/file:line>)
2. ...
**Honest caveat:** <where the alternative is not "wrong" but a different layer.>

## Follow-up (NOT done in this audit)
<The scoped cutover/fix: which surfaces to re-point, the cutover seam, the
correct window column, the grain-correct filter.>
```

## Anti-patterns

If you catch yourself doing any of these, stop and correct.

| Smell | Fix |
|---|---|
| Running the full ladder when a grep already answered it | Match depth to the question; stop at a confident cited answer and offer to go deeper |
| Querying prod / doing git archaeology for a question the code already settles | Escalate only on a trigger (ambiguity, disagreeing numbers, a cutover, high stakes, or the dev asks) |
| Trusting a production number before checking whether the table is still fed | Run P1 first — recency kills dead sources immediately |
| Filtering before profiling the grain | Run P2 first; know what one row is before you `WHERE` |
| `COUNT(*)` on a table whose rows are actions/postings | `COUNT(DISTINCT <key>)` or filter to one row per entity |
| Joining two sources without inspecting the key format on both sides | P3 Step 1 — sample length/padding/sentinels first |
| A confident 0% match treated as a finding | Suspect the join key; re-inspect formats before concluding |
| Grouping analytics by an FK without proving it's ownership | Run P5; resolve the owner through the domain lookup |
| `LEFT JOIN ... COUNT(*)` for "how many missing" | `NOT EXISTS` (P6) — avoid fan-out inflation |
| Citing the spec's codes instead of stored values | Profile stored values; cite the DB, not the doc |
| Concluding a source "never existed" from `git log -- <path>` on the working tree | It may be deleted/renamed — search with `--all --full-history --diff-filter=D` and `--follow`, and recover content via `git show <commit>^:<path>` |
| Concluding without a "hypotheses refuted" section | If you refuted nothing, you didn't test hard enough |
| Stating an estimate as a fact | Label it approximate until a clean query confirms it |
| A claim with no `file:line` or query behind it | Add the citation or delete the claim |
| Implementing the cutover/fix inside the audit | Scope it as a separate follow-up; the audit only proves truth |
| Jumping straight to prod queries before the code + schema are exhausted | Start local; go to prod only when the question needs live values, and decide that with the dev |
| Silently querying prod (or silently stopping short of it) | Name the moment you need live data and get the dev's go-ahead; don't decide it unilaterally either way |
| Treating "ask the dev to run it" as a degraded last resort | It's a first-class way to get prod data — equal to MCP/replica, just a different executor |
| Stopping to ask the dev to wire up an MCP server that isn't connected | Don't — use whatever method the env offers (MCP, replica, or dev-run); its absence isn't a blocker |
| Issuing a write/DDL through an MCP DB tool | Read-only only; this is an audit, never a mutation |
| Trusting an MCP result that contradicts code/git without noting it | Surface the disagreement as a finding; cross-check, don't paper over |
| Handing the dev a query with an inline secret (`PGPASSWORD=… psql`, `postgres://user:pass@host`) | Never — it leaks to shell history and `ps`. Let their env supply the credential (`.pgpass`, service file, interactive prompt) |
| Giving the dev a bare query to run against prod by hand | Wrap it `BEGIN; SET TRANSACTION READ ONLY; … ROLLBACK;` and prefer a read replica / read-only role |

## Invocation

- Slash command: `/my:data-lineage <the lineage question>`
- Natural language: just ask the question — "Is `orders` or `order_events` the
  source of truth for revenue? Which one feeds the finance dashboard?" — and
  this skill's procedure applies.

One-line example trigger:

> "The billing dashboard reads `invoices`, but finance says `ledger_entries` is
> the real source of truth — which is authoritative, and why did `invoices`
> stop matching?"
