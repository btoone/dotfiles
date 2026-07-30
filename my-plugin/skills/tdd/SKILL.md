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
- Tests are executable specifications of what the system does for a consumer —
  if they pass, you should feel able to ship
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

Then load **the project's own trap catalogue**, if it has one — the traps this
codebase has already been bitten by. Look in the project's test-guideline doc
(`.claude/tdd_guidelines.md`, `.claude/testing.md`, `docs/testing.md`, or
whatever the project uses) for sections naming a family of traps, and in any
doc split out from it (`test_flakiness.md` and the like). Read it once per
session alongside the framework file. If the project has no such doc, don't
manufacture one — proceed on the universal rules.

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

**Mutation check:** before settling on the example, ask which subtly wrong
implementation it would catch. An example that would still pass against an
inverted comparison, an off-by-one, or a dropped condition is too weak —
prefer boundary values and near-misses. Coverage only proves the code ran;
the example's job is detection.

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
- **The claim decides the boundary.** Every layer has its own public
  interface; test at the one that owns the behavior, and let the test name
  claim only what that boundary proves — a "user creates X" test that calls
  the HTTP endpoint proves an HTTP contract, not a UI flow. Don't re-test
  what another layer already owns; which test fails should tell you which
  boundary broke
- **Fakes over mocks.** A test double is a hand-written implementation of the
  real interface, verified by state ("was it saved?"), not interaction ("was
  `.save()` called?"). Never mock or spy on internal calls of the unit under
  test; if the outside world must be doubled, do it at the outermost edge
  (HTTP/network-level handlers where an unhandled request fails the test).
  Asserting on a collaborator the caller provided through the public surface
  (an injected recorder, an `onSubmit` callback) is behavior, not spying
- **Time is a dependency** — prefer injecting a clock/`now` through an
  existing seam and passing tests a fixed instant; use the framework's
  freeze-time helper when there is no seam (see Flaky tests)
- Never reach into private members (private methods, unexported fields,
  instance variables) from a test
- Never test constants, configuration, or metadata
- Never copy implementation logic into the test
- **Never extract a function just to test it** — a helper is an
  implementation detail of its consumer; prove it through the consumer's
  boundary. There is no 1:1 test-file-to-source-file rule; group test files
  by behavior
- Use the project's factory/fixture helper — builders return **complete,
  valid objects** and accept per-test overrides, and a test overrides only
  what its assertion is about. No shared mutable test data: build fresh per
  test; lifecycle hooks are for booting servers, not building data
- **Assert whole values where the shape is the contract** — equality on the
  full object catches more wrong implementations than plucking single
  fields; assert a partial shape only when only that part is the contract
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

**Trap-catalogue check:** scan the project's catalogue (loaded in Step 0) for
entries whose family touches this behavior — the same kind of write, the same
boundary, the same shared aggregate. Each entry names the example that catches
it; if one applies, write that example now rather than discovering the trap in
review. The catalogue exists because these were missed once by someone reading
the code carefully, so "I checked and it looks right" is not the counterargument.

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

## Step 4 — Refactor (required)

Green is not the end of the cycle. Before you commit, look at what you just
wrote with the tests as a safety net.

The *restructuring* is conditional — often the right answer is that the code is
already clean. The *decision* is not. You must state a verdict:

- **"Refactored: <what and why>"** — you restructured; say what moved.
- **"No refactor: <reason>"** — nothing earned it; say what you considered.

An unstated verdict means the step didn't happen. Do not commit without one.

**What to look at** — the code you touched this cycle, not the whole file:

- Duplication that has now reached its third use (Rule of Three)
- Names that drifted from the domain while you were making the test pass
- A method that grew past one job, or a conditional that wants to be a value
- Comments this cycle added — the default is none, so each one is a decision to
  re-examine. If the diff added any, load **my:comments** and apply it to them
  before you commit; a comment that restates the code goes, and one that exists
  because a name is unclear becomes a rename.
- Anything you'd flag if this arrived as someone else's pull request

**Rules while refactoring:**

- No behavior changes; tests should not change during refactoring
- Extract only when the pattern is clear — three similar uses, not two
- If a refactor breaks a test, the test was testing implementation — fix the
  test first
- If you find a bug, stop and start a new RED → GREEN cycle for it. A bug fix
  is a behavior change, not a refactor.

**Success criteria:** a verdict is stated, all tests still pass, and no
behavior changed.

## Step 5 — Repeat

If the feature has multiple slices, loop back to Step 2. Each slice is one
RED → GREEN → REFACTOR cycle producing one atomic, independently revertable
change.

**Feature rhythm:**
```
Cycle 1 → feat: display transaction list
Cycle 2 → feat: add date range filter
Cycle 3 → refactor: extract query scope
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
| Spying on an internal collaborator to prove a call happened | Fake the real interface; assert the resulting state |
| Extracting a helper only so a test can reach it | Prove it through its consumer's public boundary |
| Example still passes with an inverted comparison or off-by-one | Strengthen it with boundary values and near-misses |
| Reaching into private members from a test | Test through the public interface |
| Test with 10+ assertions | Split into separate test blocks |
| Constructing objects directly when factories exist | Use the project's factory helper |
| Adding features the test didn't ask for | Delete them. Stay GREEN. |
| Extracting an abstraction on first use | Wait for the third use |
| Multiple writes between entry and return, atomicity undecided | Wrap the unit in a transaction; add a rollback test that fails a *later* record |
| Adding a retry to silence a flaky test | Find the cause — a flake is a false negative. See Flaky tests |
| Going green straight into the next failing test | Step 4 is not optional. State a refactor verdict before you commit |
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

## The project's trap catalogue

The universal rules in this skill are what every project needs. A mature project
also accumulates its **own** traps — the misses a review or an incident caught,
where the implementation looked right and no test objected. Those live in the
project's test-guideline doc, grouped by failure family and dated to the review
that produced them, and each entry names the example that catches it.

Read it in Step 0, apply it in Step 2. Two entries in the same family are worth
more than either alone: they show the shape of what this codebase gets wrong.

**Closing the loop.** When a review or a production bug catches something the
tests should have, the generalization outlives the fix — route it into the
catalogue via `my:capture-learnings`, which carries the entry shape and the rule
that a mechanical guard beats a remembered one. A catalogue only compounds if
entries keep landing in it.
