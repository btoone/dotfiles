---
name: tdd
description: Write tests following TDD cycle and BDD conventions with domain-first coding philosophy
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Bash(bin/rspec:*)
  - Bash(bundle exec rspec:*)
  - Bash(bin/rails test:*)
  - Bash(bundle exec rake test:*)
  - Bash(ruby -Itest:*)
  - Bash(npm test:*)
  - Bash(npx vitest:*)
  - Bash(npx jest:*)
  - Bash(yarn test:*)
  - Bash(pnpm test:*)
  - Bash(go test:*)
  - Bash(pytest:*)
  - Bash(python -m pytest:*)
  - Bash(python -m unittest:*)
  - Bash(uv run pytest:*)
  - Bash(poetry run pytest:*)
  - Bash(bats:*)
  - Agent
when_to_use: >
  Use when the user asks to implement a feature, fix a bug, add a spec, or do
  any code change that should follow TDD. This includes when the user says
  'go ahead', 'let's do it', 'start', 'begin', or similar to kick off
  previously discussed implementation work. If you are about to write
  production code or test files, this skill applies. Examples: 'add filtering
  to transactions', 'fix the zero-amount bug', 'write tests for the parser',
  'TDD this', 'implement...', 'go ahead'.
---

# TDD — Test-Driven Development with BDD Conventions

Every code change follows RED → GREEN → REFACTOR. Tests describe behavior in
domain language. Implementation is minimal and domain-first.

## Goal

- Every behavior is proven by a test written first and seen to fail
- Tests read like a behavioral specification a domain expert could follow
- Implementation uses ubiquitous language and avoids premature abstraction

## Step 0 — Detect the framework

Before writing any test, identify the project's test runner and load the
matching reference file from `frameworks/`:

| Signal | Reference |
|--------|-----------|
| `Gemfile` with `rspec-rails`/`rspec` or a `spec/` dir | `frameworks/rspec.md` |
| `Gemfile` with `minitest` or a `test/` dir (Rails default) | `frameworks/minitest.md` |
| `package.json` using `vitest` or `jest` | `frameworks/vitest.md` |
| `go.mod` present | `frameworks/go.md` |
| `pyproject.toml`/`requirements*.txt`/`setup.py`, or `tests/test_*.py`, or a `conftest.py` | `frameworks/python.md` |
| `*.bats` files or a `test/bats/` dir | `frameworks/bats.md` |

If the signal is ambiguous or missing, ask the user which runner to use. Read
the framework file once per session — it supplies the exact run commands,
file paths, idiomatic test syntax, factory conventions, language idioms, and
framework-specific anti-patterns for the universal rules below.

## Step 1 — Understand the change

Read the relevant modules and existing tests. You should be able to
articulate in one sentence, in domain language, what behavior will change.
Check how tests are organized in this repo, and which factory/fixture helpers
already exist.

**Success criteria:** you can name the behavior under test using ubiquitous
language from the domain.

## Step 2 — Write the failing test (RED)

Write one test describing the desired behavior. Run it and confirm it fails
with a meaningful message.

**BDD naming (principle — see the framework file for exact syntax):**
- Describe a **capability or behavior**, never a method — "creating a
  transaction", "resolving a dispute" — NOT "#call" or "resolve()"
- Scenarios name a **condition**, not a judgment — "when amount is zero" —
  NOT "with valid params"
- Outcomes state what is **observable** — "persists the record", "returns
  failure"
- The test output should read like a behavioral specification

**Test quality (universal, non-negotiable):**
- Test **observable outcomes only** — state changes, return values, side
  effects, errors raised
- Mock only at **infrastructure boundaries** (HTTP, Redis, the clock,
  external APIs). Never mock internal calls on the unit under test
- Never reach into private members (private methods, unexported fields,
  instance variables) from a test
- Never test constants, configuration, or metadata
- Never copy implementation logic into the test
- Use the project's factory/fixture helper — not raw constructors
- One behavior per test block — no god tests with 20 assertions

**Multi-write unit check:** if the behavior under test writes more than one
record — a loop of saves, a service touching several rows, or "X and Y" /
"as a unit" / "whole cloth" in the test name — the unit needs an explicit
atomicity decision (usually a transaction) and the test list needs a
rollback test. Raising on failure is not atomicity: an exception mid-way
rolls back nothing already committed. Write the rollback test to fail a
*later* record so an earlier record's committed write proves the rollback
(fail-on-first is vacuous — it passes even without a transaction).
Framework-specific traps live in the matching `frameworks/*.md`.

**Success criteria:** the test fails with a message that clearly shows what
behavior is missing.

## Step 3 — Implement the minimum (GREEN)

Write the simplest code that makes the failing test pass. Run the test.

**Rules (universal):**
- Write only what the test requires — no gold-plating
- No premature abstractions — three similar lines beat the wrong abstraction
- Domain-first: ubiquitous language from the business domain
- Favor declarative style in domain code (what things *are*), imperative in
  orchestration (what to *do*)
- Don't add error handling for scenarios that can't happen
- For language-specific idioms (plain objects vs framework types, zero
  values, etc.) see the framework file

**Success criteria:** the new test passes, no other tests break, the
implementation is the simplest thing that works.

## Step 4 — Refactor (optional)

If the code benefits from restructuring, do it now. Tests are the safety net.

- No behavior changes; tests should not change during refactoring
- Extract only when the pattern is clear (Rule of Three)
- If a refactor breaks a test, the test was testing implementation — fix the
  test first

**Success criteria:** all tests still pass, code is cleaner, no behavior
changed.

## Step 5 — Repeat

If the feature has multiple slices, loop back to Step 2. Each slice is one
RED → GREEN → REFACTOR cycle producing one atomic, independently revertable
change.

**Feature rhythm:**
```
Cycle 1 → feat: display transaction list
Cycle 2 → feat: add date range filter
Cycle 3 → refactor: extract query scope (optional)
Cycle 4 → feat: add pagination
```

**Bug fix rhythm:**
```
Cycle 1 → fix: handle zero-amount fee calculation
           (regression test + fix in one commit)
```

**Commit as each cycle closes** — same working session, no waiting to be asked.
Don't stack up green cycles and split them into commits afterward.

The boundary is **what can stand alone green**, not how many files changed. If
one new fixture or test forces changes in two units, that is ONE cycle and one
commit: they ship together because neither passes without the other.

Committing per cycle makes each commit green *by construction* — the suite ran
when that commit's content existed. Splitting a finished blob afterward inverts
that: you assert green states you never executed, and a commit whose test is
only fixed by a later commit is red no matter how green the tip is.

**Escape hatch — this is a means, not the goal.** Real work doesn't always
separate cleanly: interleaved fixes, a refactor that touches every call site, a
change that only makes sense whole. When it doesn't separate, write ONE commit
with the entire suite green and say so in the message. A single honest green
commit beats a tidy series that was never run. The property being protected is
"every commit I present as green actually ran green" — not "many small commits."
Never fabricate a boundary to look disciplined.

If you do batch and split anyway, check out each reconstructed commit and run
the suite before pushing. Never infer an intermediate commit is green from the
tip being green.

**Success criteria:** every commit you present as green has actually been run
green; commit history reads like a changelog.

## Anti-patterns

If you catch yourself doing any of these, stop and correct:

| Smell | Fix |
|-------|-----|
| Writing implementation before the test | Stop. Write the test first. |
| Test name describes a method instead of behavior | Rename to describe the behavior |
| Mocking a method on the unit under test | Test the outcome instead |
| Reaching into private members from a test | Test through the public interface |
| Test with 10+ assertions | Split into separate test blocks |
| Constructing objects directly when factories exist | Use the project's factory helper |
| Adding features the test didn't ask for | Delete them. Stay GREEN. |
| Extracting an abstraction on first use | Wait for the third use |
| Multiple writes between entry and return, atomicity undecided | Wrap the unit in a transaction; add a rollback test that fails a *later* record |
| Adding a retry to silence a flaky test | Find the cause — a flake is a false negative. See Flaky tests |
| Several green cycles stacked up uncommitted | Commit each as it closes |
| Splitting a finished blob into commits you never ran | Run each boundary, or write one honest green commit |

Framework-specific anti-patterns live in the matching `frameworks/*.md`.

## Flaky tests

A flaky test passes or fails on the same code. It's a false negative that makes
every red ambiguous, so fix the cause — never paper over it with a retry. Almost
all flakes fall into two families:

- **Time-dependent** — the result depends on *when* the test runs. Anything
  asserting over a relative or bounded window ("this month", "last 30 days", "the
  next 14 days") flakes at a date/time boundary. Freeze the clock at a fixed,
  mid-window instant for the assertion, and don't date fixtures relative to today.
- **Async / ordering** — the test reads state before an asynchronous change has
  settled (a UI update, a background job, a goroutine, a timer). Wait for the
  expected condition; never snapshot-read state right after triggering async work.

See the matching `frameworks/*.md` for the exact freeze-time and wait helpers.
