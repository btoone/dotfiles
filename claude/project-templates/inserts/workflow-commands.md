# Workflow Commands Insert

Reusable patterns for Claude Code custom commands. Reference this when creating project-specific commands.

---

## Design Philosophy

Commands should be **lightweight checklists that enhance natural workflow**, not structured workflows that replace exploration. The agent naturally:

1. Explores the codebase first
2. Finds similar existing implementations
3. Copies patterns from working code
4. Implements with TDD

Commands exist as **reminders when you notice the agent isn't doing these things**.

---

## Core Commands to Create

Every project should have these commands in `.claude/commands/`:

### /tdd - TDD Checklist

```markdown
# TDD Workflow

A lightweight checklist for Test-Driven Development.

## Before Writing Any Tests

**Read `.claude/tdd_guidelines.md` first.** It contains critical guidance on:

- Testing behavior vs implementation
- Mock anti-patterns to avoid
- What makes a good test

## The Cycle

```
RED    → Write a failing test
GREEN  → Write minimum code to pass
REFACTOR → Clean up while green
```

Run tests after each step.

## Before Writing Production Code

- [ ] I have a failing test that describes the behavior I want
- [ ] The test fails for the right reason (missing functionality, not syntax error)
- [ ] The test name describes WHAT, not HOW

## While Implementing

- [ ] I'm writing the minimum code to make the test pass
- [ ] I'm not modifying tests to make them pass
- [ ] I'm running tests frequently

## After Tests Pass

- [ ] I've removed any duplication
- [ ] The code follows existing patterns in the codebase
- [ ] Tests still pass after refactoring

## Mock Anti-Patterns (Don't Do These)

**Don't mock internal collaborators:**
```typescript
// BAD - testing implementation
const mockParser = vi.fn()
const service = new Service({ parser: mockParser })
expect(mockParser).toHaveBeenCalledWith(data)
```

**Don't test private state:**
```typescript
// BAD - accessing internals
expect((service as any)._cache).toEqual(expectedData)
```

**Don't test order of operations:**
```typescript
// BAD - implementation detail
expect(validateSpy.mock.invocationCallOrder[0])
  .toBeLessThan(saveSpy.mock.invocationCallOrder[0])
```

**What TO mock:**

- External APIs (database clients, third-party services)
- Browser APIs when needed (localStorage, fetch)
- That's mostly it

## Test Smells (You're Doing It Wrong If...)

- Test breaks when you refactor without changing behavior
- Test name describes HOW instead of WHAT
- You're mocking everything except the unit under test
- You need `(obj as any).private` to test something

## Bug Fix Mode

1. Write a test that reproduces the bug (should fail)
2. Verify it fails for the right reason
3. Fix the bug with minimal changes
4. Verify the test passes

## Remember

- Tests describe behavior through the public API
- Study existing test files for patterns before writing new tests
- When in doubt, check `tdd_guidelines.md`
```

### /code-review - Code Review Checklist

```markdown
# Code Review

Perform a structured whitebox code review on recent changes.

## Process

1. Run `git diff main` to see all changes
2. Review each change against the checklist below
3. Report findings with file:line references
4. Suggest specific fixes for any issues found

## Review Checklist

### Security
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation at system boundaries
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities

### Performance
- [ ] No N+1 database queries
- [ ] Appropriate caching where needed
- [ ] No unnecessary computation in loops

### Code Quality
- [ ] Follows existing patterns in the codebase
- [ ] No over-engineering (minimum viable implementation)
- [ ] TypeScript/type annotations are correct
- [ ] Error handling is graceful
- [ ] No dead code or unused imports

### Testing
- [ ] Tests exist for new functionality (TDD)
- [ ] Tests are behavioral, not implementation-coupled
- [ ] Edge cases covered

### Project-Specific
[Add project-specific review items here - e.g., data isolation, authorization patterns]

## Output Format

For each issue found:
```
[SEVERITY] file:line - Description
  Suggestion: How to fix
```

Severity: CRITICAL | HIGH | MEDIUM | LOW
```

---

## What NOT to Create

Based on experience, avoid these command patterns:

### Multi-session workflows

Commands like "write tests, then start a new session to implement" cause problems:
- Context clearing loses valuable codebase understanding
- Plans become "source of truth" instead of the codebase
- Implementation doesn't follow existing patterns

**Use native plan mode instead** for complex feature planning.

### Heavyweight planning commands

The agent explores naturally. A command that says "do 5 phases of planning" creates isolation from the codebase. Native plan mode with back-and-forth refinement works better.

---

## Project-Specific Commands

Beyond the core commands, identify repetitive workflows that would benefit from automation:

| Workflow                | Command         | Example                                  |
| ----------------------- | --------------- | ---------------------------------------- |
| Database migrations     | `/migrate`      | Rails migrations, Supabase migrations    |
| New feature scaffolding | `/new-<thing>`  | `/new-activity`, `/new-api-endpoint`     |
| Data sync/isolation     | `/sync-check`   | Profile isolation verification           |

### Example: /new-activity (from Glow project)

```markdown
# New Activity

Scaffold a new activity with proper sync infrastructure. **Study existing activities first.**

## Step 1: Study an Existing Activity (Required)

Before creating any files, read a similar existing activity end-to-end:

**Recommended to study:** [simplest well-structured example]

- `path/to/activity/page.tsx` - Activity UI
- `path/to/activity/page.test.tsx` - Component tests
- `hooks/useActivitySync.ts` - Sync hook
- `app/api/activity/sync/route.ts` - API route

**Note the patterns:**

- How the page uses hooks
- How tests are structured and mocked
- How sync infrastructure works

## Step 2: Quick Design Check

- [ ] Fits project guidelines?
- [ ] What output does it produce?
- [ ] What data needs to sync?

## Step 3: Create Files (Following the Pattern)

[File structure matching existing patterns]

## Definition of Done

- [ ] Tests written first (TDD)
- [ ] Follows patterns from studied activity
- [ ] Works on target platforms
```

---

## Command File Format

Commands are markdown files in `.claude/commands/`:

```
.claude/commands/
├── tdd.md            # TDD checklist
├── code-review.md    # Code review checklist
└── <project-specific>.md  # e.g., new-migration.md
```

Key principles:

- **Lightweight** - Checklists, not multi-phase workflows
- **Reference existing code** - "Study X before creating Y"
- **Don't replace exploration** - Enhance natural workflow
- **Include anti-patterns** - What NOT to do, inline

---

## Adapting to Tech Stacks

### Test Commands by Stack

| Stack             | Test Command        |
| ----------------- | ------------------- |
| JavaScript/Vitest | `npm run test:run`  |
| JavaScript/Jest   | `npm test`          |
| Python/pytest     | `pytest`            |
| Ruby/RSpec        | `bundle exec rspec` |
| Ruby/Minitest     | `rails test`        |
| Go                | `go test ./...`     |

### Review Focus by Stack

| Stack    | Additional Review Focus                       |
| -------- | --------------------------------------------- |
| React    | Component re-renders, hook dependencies       |
| Rails    | N+1 queries, strong params, authorization     |
| Next.js  | Server vs Client components, data fetching    |
| API-only | Request validation, response formats          |
