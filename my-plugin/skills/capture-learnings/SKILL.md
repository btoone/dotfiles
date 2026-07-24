---
name: capture-learnings
description: >
  Route what a work session taught to its correct durable home, instead of
  letting everything default into CLAUDE.md or evaporate. At the end of
  significant work, ask "what do I wish I'd known at the start?" and file
  each answer by KIND: durable how-to-work-here rules → project CLAUDE.md or
  the narrowest .claude/ guideline doc it links; decisions with tradeoffs →
  an ADR; personal preferences and cross-session project state → auto-memory;
  knowledge valuable beyond the project (techniques, research, worldviews) →
  the Obsidian vault via /my:vault; operational runbook facts → docs/ or
  README per project convention; conversation-scoped context → nowhere,
  deliberately. Guards the always-loaded context budget: nothing lands in
  CLAUDE.md by default, and anything that doesn't apply to every turn belongs
  in an on-demand doc or skill with a one-line pointer. Use when wrapping up
  a feature, fix, migration, or investigation; when the user says "remember
  this", "capture what we learned", "write that down", or "wrap up"; or
  whenever about to append anything to a CLAUDE.md. Do NOT use for mid-task
  scratch notes, for commit messages (git history is its own record), or to
  re-document what the code, tests, or existing docs already say.
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
