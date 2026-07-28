# Verification Gate Insert

Copy the section below into a project's CLAUDE.md and fill in the command.
One gate per project, named in one place, so any session — yours or an
agent's — can find it without guessing.

Pairs with the `my:handoff` skill, which refuses to start unattended work
in a repo where this section is missing or empty.

---

## Verification Gate

```
<command>
```

This is the command that proves a change correct. Run it before reporting
work complete. Report the actual result — a failing gate is a finding, not
a detail to work around.

Never substitute a self-assessment for a gate run: not "the change looks
correct", not a screenshot read back by the agent that produced it, not a
partial suite chosen because the full one is slow.

**Not covered by the gate:** <the paths, surfaces, or behaviors this
command doesn't exercise>

Work touching anything listed there is reviewed by a human before it
lands, no matter how routine it looks.

---

## Picking the command

Prefer the one a fresh clone can run. If setup is required first, name that
too — a gate nobody can run is not a gate.

| Stack | Typical |
|---|---|
| Rails | `bin/rails test` or `bin/rails test && bin/rubocop` |
| Node | `npm test && npm run lint` |
| Python | `pytest && ruff check` |
| Go | `go test ./... && go vet ./...` |
| Shell / dotfiles | `bats test/` |
| Mixed or task-runner | `just test`, `make check` |

Wrap multiple checks behind a single task-runner target rather than listing
several commands. One name, one exit code, nothing to remember.

Keep the "not covered" line honest and current. It's what decides whether a
change can be handed off unattended, so an aspirational version of it is
worse than none — it converts an unreviewed change into a confident one.
