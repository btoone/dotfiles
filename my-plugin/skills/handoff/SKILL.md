---
name: handoff
description: >
  Decide how much autonomy a piece of work gets, and write the brief that
  makes an unattended run safe. Sorts work into paired (plan mode, small
  steps, read the diff) versus autonomous (brief it, read the summary),
  then requires four fields in the brief — outcome, constraints, file
  scope, and the command that proves it done. Refuses the handoff when the
  repo has no mechanical gate, rather than proceeding on care. Use when
  kicking off work meant to run unattended, when asked to "just go" or
  "don't stop to check in", before spawning implementer subagents, or when
  deciding whether something needs plan mode. Do NOT use for the inner
  red-green-refactor loop (that's tdd), for resuming an existing plan
  (that's continue-plan), or for reviewing work already finished (that's
  code-review and review-triage).
---

# Handoff

The brief is the last cheap moment. While you're writing it, a correction
costs a sentence; once the run is unattended, the same correction costs a
restart. Long-horizon runs don't fail by drifting off task anymore — they
fail by finishing confidently against an under-specified goal. That makes
the goal, not the steering, the thing worth investing in.

## Choosing the mode

| | Paired | Autonomous |
|---|---|---|
| **Applies to** | Core infrastructure, boot and install paths, auth, data migrations, public interfaces, anything the user holds strong opinions about, anything with no gate | Feature work, refactors, docs, tests, tooling, anything the gate genuinely covers |
| **Start** | Plan mode; the plan is approved before any code | A brief (below) |
| **During** | Small steps, each reviewed before continuing | Uninterrupted to the finish condition |
| **After** | Read the diff | Read the gate result, then the summary |

When it's unclear which applies, pair. Loosening later costs one sentence;
unwinding a bad autonomous run costs the whole run.

## The brief

Four fields. All required.

1. **Outcome** — what is true when this is done, stated as a result rather
   than a list of steps. Steps are the agent's job; the finish condition is
   yours. "Transactions can be filtered by date range from the index page"
   — not "add a param, then a scope, then a form".
2. **Constraints** — the architecture and patterns to honor, and what must
   not change. Name the existing thing to imitate; a pointer at real code
   beats a paragraph of description.
3. **Scope** — the files or directories in play, and explicitly what is off
   limits. Unbounded scope is how a long run quietly rewrites config it was
   never asked to touch.
4. **Gate** — the single command that proves the work correct. It must be
   runnable now, and you must know its current state (passing, or failing
   for a reason you can name).

A brief without a gate is not a brief. It's a wish.

## No gate, no handoff

When the repo has no mechanical gate covering the work, stop and say so.
Concretely:

- State plainly that there's no command that would prove this correct.
- Name what a gate would look like here — the suite that doesn't exist, the
  script that isn't wired up, the path no test covers.
- Offer paired mode as the way to proceed today.

Do not improvise a gate mid-run, and do not proceed on "I'll be careful" —
care is not a verification strategy, and an unattended run has nobody to
exercise it. Building the gate is legitimate work, but it is its own task
with its own brief, not a side quest inside this one.

**What counts as a gate:** one command, exits nonzero on failure, needs no
human to read its output to know the answer. `bin/rails test`, `just test`,
`npm test && npm run lint`, a bats suite, a headless UI driver (see
`my:headless-tui` for TUIs, browser automation for web).

**What doesn't:** "I ran it and it looked right", screenshots the agent
grades itself on, or a suite that passes without executing the changed
code. A gate that can't fail isn't measuring anything.

## After the run

Read the gate result before the summary, and the summary before any diff —
in autonomous mode the diff is usually too large to read, which is the
whole reason the gate has to carry the weight.

Re-run the gate yourself. Never accept an agent's own report of green,
including your own subagents' — the report and the work come from the same
place, so it isn't independent evidence.

Then route what the run taught somewhere durable: `my:capture-learnings`
for the general case, or a constraint added to the next brief when the
lesson is narrow enough to belong there.
