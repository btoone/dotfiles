# Workflow Commands Insert

Reusable patterns for Claude Code custom commands. Reference this when creating project-specific commands.

---

## Core Commands to Create

Every project should have these commands in `.claude/commands/`:

### /tdd - Full TDD Workflow

```markdown
# TDD Workflow

Run the Test-Driven Development workflow for a feature or bug fix.

## Process

### Phase 1: Write Failing Tests

1. Read `.claude/tdd_guidelines.md` for patterns and anti-patterns
2. Write tests that describe the desired behavior through the **public API**
3. Run tests to confirm they **fail** for the right reason
4. Do NOT write any production code yet

### Phase 2: Implement

1. Write the **minimum code** to make tests pass
2. Run tests after each change
3. Do NOT modify the tests (they are the specification)
4. Stop as soon as tests pass

### Phase 3: Refactor

1. Clean up the implementation while keeping tests green
2. Run tests after each refactor step
3. Apply patterns from existing codebase
4. Remove duplication, improve naming

## Rules

- **NEVER** write production code before a failing test
- **NEVER** modify tests to make them pass (fix the code instead)
- Tests must describe **behavior**, not implementation
- Tests must use the **public API**

## Context Clearing (Complex Features)

For complex features (5+ user stories), consider separating test writing from implementation:

1. **Session 1**: `/plan-feature` → create plan
2. **Session 2**: `/test` → write all failing tests (stop here)
3. **Session 3**: Implement to make tests pass

A fresh context forces implementation to treat tests as a black-box specification.

For this workflow, use `/write-tests` instead of `/tdd`.

## Bug Fix Mode

For bug fixes:
1. **REPRODUCE**: Write a test that fails with the same error as the bug
2. **VERIFY**: Confirm the test fails for the right reason
3. **FIX**: Make minimal changes to pass the test
4. **VERIFY**: Confirm the test passes
```

### /write-tests - Tests Only (Context Clearing)

```markdown
# Write Tests

Write failing tests for a planned feature. Do NOT implement any production code.

## Process

1. Read the plan from `.claude/plans/<feature-name>.md`
2. Write tests based on user stories and acceptance criteria
3. Run tests to confirm they **FAIL** for the right reasons
4. **STOP** - do not write any production code

## Rules

- Tests must describe **behavior**, not implementation
- Tests must use the **public API**
- Do NOT create stubs or placeholder implementation code

## Next Steps

After this command:
1. Commit the failing tests
2. Start a new session
3. Implement to make tests pass
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

### /plan-feature - Feature Planning

```markdown
# Plan Feature

Structured feature planning with multi-phase validation.

## Planning Phases

### Phase 1: Understanding
**Goal**: Clearly define what we're building and why.

- What user problem does this solve?
- Who is the user?
- What does success look like from the user's perspective?
- What's the minimum viable version?

Deliverable: One-paragraph problem statement

### Phase 2: Validation
**Goal**: Ensure alignment with project constraints.

Check against project_intent.md:
- [ ] Aligns with "What We Are"
- [ ] Doesn't conflict with "What We Are NOT"
- [ ] Passes feature guardrail questions

Deliverable: Pass/fail on each guardrail with reasoning

### Phase 3: Design
**Goal**: Define the user journey and technical approach.

User journey:
1. Entry point (how do they start?)
2. Steps (what do they do?)
3. Feedback (what do they see?)
4. Success state
5. Edge cases (errors, empty states)

Technical approach:
- What existing patterns apply?
- What components can be reused?
- What tests will prove this works?

Deliverable: User flow diagram and component list

### Phase 4: Scope
**Goal**: Define boundaries and defer non-essentials.

- What's in scope for v1?
- What can be deferred?
- What are the risks?
- What assumptions are we making?

Deliverable: Explicit scope statement with out-of-scope items

### Phase 5: Plan
**Goal**: Create actionable implementation steps.

Create a plan file in `.claude/plans/` with:
- Problem statement
- User stories with acceptance criteria
- Technical approach
- Step-by-step implementation order (with TDD)
- Out of scope items

## Output

Save the completed plan to `.claude/plans/<feature-name>.md`
```

---

## Project-Specific Commands

Beyond the core commands, identify repetitive workflows that would benefit from automation:

| Workflow | Command | Example |
|----------|---------|---------|
| Database migrations | `/migrate` | Rails migrations, Supabase migrations |
| New feature scaffolding | `/new-<thing>` | `/new-activity`, `/new-api-endpoint` |
| Deployment | `/deploy` | Vercel, Heroku, AWS |
| Data sync/isolation | `/sync-check` | Profile isolation verification |

---

## Command File Format

Commands are markdown files in `.claude/commands/`:

```
.claude/commands/
├── test.md           # TDD workflow
├── review.md         # Code review checklist
├── plan-feature.md   # Feature planning
└── <project-specific>.md
```

Key principles:
- Reference existing project docs (don't duplicate)
- Include project-specific checklists and patterns
- Provide clear step-by-step processes
- Include relevant bash commands

---

## Adapting to Tech Stacks

### Test Commands by Stack

| Stack | Test Command |
|-------|--------------|
| JavaScript/Vitest | `npm run test:run` |
| JavaScript/Jest | `npm test` |
| Python/pytest | `pytest` |
| Ruby/RSpec | `bundle exec rspec` |
| Ruby/Minitest | `rails test` |
| Go | `go test ./...` |

### Review Focus by Stack

| Stack | Additional Review Focus |
|-------|------------------------|
| React | Component re-renders, hook dependencies |
| Rails | N+1 queries, strong params, authorization |
| Next.js | Server vs Client components, data fetching |
| API-only | Request validation, response formats |
