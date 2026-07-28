---
name: capture-learnings
description: >
  Route what a work session taught to its correct durable home, instead of
  letting everything default into CLAUDE.md or evaporate. Files each answer by
  KIND: repo rules to a .claude/ doc or CLAUDE.md, decisions with tradeoffs to
  an ADR, personal preferences and project state to auto-memory, knowledge
  valuable beyond the project to the Obsidian vault, runbook facts to docs/.
  Use when wrapping up a feature, fix, migration, or investigation; when the
  user says "remember this", "capture what we learned", or "wrap up"; or
  whenever about to append anything to a CLAUDE.md. Do NOT use for mid-task
  scratch notes, commit messages, or re-documenting what the code, tests, or
  docs already say.
---

# Capture learnings

At the end of significant work, ask: **"What do I wish I'd known at the
start?"** Every answer worth keeping gets exactly one home, chosen by what
kind of knowledge it is. Appending to CLAUDE.md is the last resort, not the
default — always-loaded lines are a tax on every future turn.

## Routing table

| The learning is... | It goes to... |
|---|---|
| A durable rule for working in this repo (command, convention, gotcha any contributor will hit) | The narrowest existing `.claude/` guideline doc; project CLAUDE.md only if it applies to every session and no linked doc fits |
| A decision with tradeoffs someone might revisit or relitigate | An ADR in `docs/adr/` (or the project's decision-record convention; create `docs/` note if none) |
| About the user: preferences, corrections, how they like to work | Auto-memory (`type: user` or `feedback`) |
| Cross-session project state not derivable from code or git (goals, in-flight threads, external constraints) | Auto-memory (`type: project`), relative dates made absolute |
| Valuable beyond this project: a technique, a research finding, a worldview, reusable playbook | Obsidian vault via `/my:vault` (Developer Brain for craft/tooling) |
| An operational fact the team needs (runbook step, deploy gotcha, credential location pointer) | `docs/` or README, wherever the project keeps runbooks |
| Content the project serves or publishes to others | The project's content directory, through its review path |
| A written plan for work still in flight | `.claude/plans/<feature>.md` at the repo root, committed. Temporary — when its last phase lands mark it `status: shipped`, route its durable parts through this table, then delete the file. Never archive it; git history is the archive |
| Only relevant to this conversation | Nowhere. Let it die. Delete scratch files and finished plans. |

## Rules

- **One fact, one home.** If it's already recorded somewhere, update or link
  that entry; never write a second copy that can drift (DRY applies to
  knowledge, not just code).
- **Check before writing.** Read the destination for an existing entry
  covering the same ground; prefer editing it.
- **Guard the always-loaded budget.** Before adding to any CLAUDE.md, ask
  "does this apply to every single turn in this repo?" If not, it belongs in
  an on-demand doc or skill, with at most a one-line pointer from CLAUDE.md.
- **Route, then report.** Tell the user what was captured and where, in one
  or two lines per item, so misfiled knowledge gets caught immediately.
- **Don't capture what's already recorded** by the code, the tests, git
  history, or existing docs. A learning is what the *next* session couldn't
  reconstruct from those.

## Gotcha shape

Entries that record a trap follow this shape, graspable in under ten
seconds:

```
**<Name the trap>** — <context where it bites>. <What goes wrong>.
<The fix or rule>, so <consequence avoided>.
```

Example: **Docker named-volume mountpoints are created root-owned** — first
`just setup` on a fresh clone. Non-root containers then can't write.
`just setup` chowns the volume once, so composer cache works without manual
intervention.
