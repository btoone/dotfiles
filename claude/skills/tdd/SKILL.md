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
  - Agent
when_to_use: >
  Use when the user asks to implement a feature, fix a bug, add a spec, or do
  any code change that should follow TDD. This includes when the user says
  'go ahead', 'let's do it', 'start', 'begin', or similar to kick off
  previously discussed implementation work. If you are about to write
  production code or spec files, this skill applies. Examples: 'add filtering
  to transactions', 'fix the zero-amount bug', 'write tests for the parser',
  'TDD this', 'implement...', 'go ahead'.
---

# TDD — Test-Driven Development with BDD Conventions

Every code change follows the RED → GREEN → REFACTOR cycle. Tests describe
behavior in domain language. Implementation is minimal and domain-first.

## Goal

Produce working, well-tested code where:
- Every behavior is proven by a test that was written first and seen to fail
- Specs read like a behavioral specification a domain expert could follow
- Implementation uses ubiquitous language and avoids premature abstraction

## Steps

### 1. Understand the Change

Read the relevant code, models, controllers, and existing specs. Understand:
- What behavior needs to be added or fixed
- What domain language applies (check model names, service names, existing specs)
- Where the spec file should live (follow existing test organization)
- What factories already exist in `spec/factories/`

**Success criteria**: You can articulate the behavior to be tested in one sentence using domain language.

### 2. Write the Failing Test (RED)

Write a spec that describes the desired behavior. Then run it and confirm it fails.

```bash
bin/rspec spec/path/file_spec.rb:LINE
```

**BDD naming rules** (non-negotiable):
- `describe` names a **capability or behavior**, never a method: `'creating a transaction'`, `'resolving a dispute'` — NOT `'#call'`, `'#resolve'`
- `context` describes a **scenario or condition**: `'when amount is zero'`, `'with invalid input'` — NOT `'with valid params'`
- `it` states the **expected outcome**: `'persists the record'`, `'returns failure'`
- The spec output should read like a behavioral specification

**Test quality rules** (non-negotiable):
- Test **observable outcomes only** — state changes, return values, side effects, errors
- NEVER use `receive` to test internal method calls (only for isolating infrastructure like Redis, external APIs)
- NEVER use `send(:private_method)` or `instance_variable_get`
- NEVER test class constants, configuration, or metadata
- NEVER copy implementation logic into the test
- Use `FactoryBot.create` / `FactoryBot.build` — NEVER `Model.new` or `Model.create!`
- One behavior per `it` block — no god tests with 20 assertions

**Success criteria**:
- The test is written and runs
- It **fails** with a meaningful failure message (not a random error or syntax issue)
- The failure message clearly shows what behavior is missing

### 3. Implement Minimum Code (GREEN)

Write the minimum code to make the failing test pass. Then run the test.

```bash
bin/rspec spec/path/file_spec.rb:LINE
```

**Implementation rules**:
- Write only what the test requires — no gold-plating, no extra features
- No premature abstractions — three similar lines of code is better than the wrong abstraction
- Domain-first: use ubiquitous language from the business domain
- POROs over framework objects when persistence/callbacks/associations aren't needed
- Favor declarative style in domain code (what things *are*), imperative in orchestration (what to *do*)
- No trailing guards on complex lines — use explicit guard clauses
- Don't add error handling for scenarios that can't happen

**Success criteria**:
- The test passes
- No other existing tests are broken (`bin/rspec` on the relevant file)
- The implementation is the simplest thing that works

### 4. Refactor (Optional)

If the code would benefit from restructuring, do it now. Tests are your safety net.

```bash
bin/rspec spec/path/file_spec.rb
```

**Rules**:
- No behavior changes — tests should not change during refactoring
- Extract only when the pattern is clear (Rule of Three)
- Apply SOLID principles with Ruby pragmatism
- If refactoring breaks tests, the tests were testing implementation — fix the tests first

**Success criteria**: All tests still pass, code is cleaner, no behavior changed.

### 5. Repeat

If the feature has multiple slices, loop back to Step 2. Each slice is one
RED → GREEN → REFACTOR cycle producing one atomic, independently revertable change.

**Feature slice rhythm**:
```
Cycle 1 → feat: display transaction list
Cycle 2 → feat: add date range filter
Cycle 3 → refactor: extract query scope (optional)
Cycle 4 → feat: add pagination
```

**Bug fix rhythm**:
```
Cycle 1 → fix: handle zero-amount fee calculation
           (regression test + fix in one commit)
```

**Success criteria**: Each cycle has a passing test suite. The commit history reads like a changelog.

## Anti-Patterns to Watch For

If you catch yourself doing any of these, stop and correct:

| Smell | Fix |
|-------|-----|
| Writing implementation before the test | Stop. Write the test first. |
| `describe '#method_name'` | Rename to describe the behavior |
| `expect(obj).to receive(:internal_method)` | Test the outcome instead |
| `send(:private_method)` in a test | Test through the public interface |
| Test with 10+ assertions | Split into separate `it` blocks |
| `Model.create!(attrs)` in a spec | Use `create(:factory)` |
| Adding features the test didn't ask for | Delete them. Stay GREEN. |
| Extracting an abstraction on first use | Wait for the third use |
