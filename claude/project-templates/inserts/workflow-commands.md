# Workflow Commands Insert

Reference this when deciding whether a project needs its own command in
`.claude/commands/`.

---

## Commands are checklists, not workflows

An agent already explores the codebase, finds similar implementations,
copies working patterns, and tests first. A command exists to nudge it when
it isn't doing those things — not to replace them with a procedure.

Keep them lightweight. Point at real code to imitate rather than describing
what the code should look like.

## Most projects need no commands at all

Before writing one, check that it isn't already covered:

| Tempting command | Already exists |
|---|---|
| `/tdd` | `my:tdd` skill |
| `/code-review` | built-in `/code-review`, then `my:review-triage` |
| `/plan` | native plan mode; plans live at `.claude/plans/<feature>.md`, continued by `my:continue-plan` |
| `/commit` | `commit-commands` plugin |
| `/handoff`, `/brief` | `my:handoff` skill |

A project-local copy of any of these shadows better tooling with a worse
checklist, and it's a second copy that drifts. Commands earn their place by
being **specific to this repo**: a scaffolding step, a migration ritual, a
verification only this stack needs.

## What a good project command looks like

```markdown
# New <thing>

Scaffold a <thing>. **Study an existing one first.**

## 1. Read a similar implementation end-to-end
<paths to the simplest well-structured example>
Note how it wires up, how its tests are structured, what it owns.

## 2. Create the files, following that pattern
<file structure>

## Done when
- [ ] Tests written first
- [ ] Matches the studied example's patterns
- [ ] <the project's verification gate> passes
```

The "study an existing one" step is the part that earns the command. The
rest is scaffolding an agent would improvise anyway.

## What not to build

**Commands that replace exploration.** A five-phase planning procedure
isolates the agent from the codebase. Native plan mode with back-and-forth
refinement works better, and for work spanning sessions a plan file carries
its own lifecycle and gets reconciled against `git log` when resumed.

**Commands that duplicate a skill.** See the table above. If the behavior
should apply across projects, it belongs in the plugin, not in one repo's
`.claude/commands/`.

## Test commands by stack

Useful when filling in the project's verification gate (see
`verification-gate.md`):

| Stack | Command |
|---|---|
| JavaScript / Vitest | `npm run test:run` |
| JavaScript / Jest | `npm test` |
| Python / pytest | `pytest` |
| Ruby / RSpec | `bundle exec rspec` |
| Ruby / Minitest | `bin/rails test` |
| Go | `go test ./...` |
| Shell | `bats test/` |
