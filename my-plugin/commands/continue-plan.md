---
description: Pick up the in-flight plan in .claude/plans and continue the work
---

# Continue Plan

Resume work from this repo's plan files. Plans live in `<repo root>/.claude/plans/<feature>.md` and carry frontmatter:

```yaml
---
plan: hoodz-onboarding
status: active        # active | queued | blocked | shipped
created: 2026-06-15
---
```

Current inventory:

!`plan-gate list`

## Choosing which plan to continue

Count the plans whose status is `active`, then follow the matching case exactly. **Never pick a plan by age, recency, file order, or which one looks most interesting.** Choosing silently is the failure this command exists to prevent.

1. **Exactly one `active`** — that's the work. Open it and continue, without asking. This is the common case and it should be quiet.

2. **Zero `active`** — nothing is in flight. List every `queued` and `blocked` plan with its `created` date and its goal line (one line each), then ask which to promote. For a `blocked` plan, say what it's blocked on. Wait for an answer; do not start work.

3. **Two or more `active`** — a state bug, not a choice. Show them, explain that only one plan may be active, and ask which to keep. Demote the others to `queued` before doing any work.

If `.claude/plans/` is empty or missing, say so and stop — don't offer to create a plan unless asked.

## Promoting a plan

When the user picks one: set its `status: active`, and demote any previously active plan to `queued` in the same edit. Say out loud what was demoted — a silent swap is how work gets orphaned.

## Continuing the work

1. Read the plan fully before touching code.
2. If it has no lifecycle footer, add one now (see below). A plan should carry its own termination condition, so an agent reading only the file still knows the thing is disposable.
3. Reconcile it against reality — `git log` since the plan's `created` date, and the code it names. Plans go stale; say what no longer holds rather than implementing a premise that's already been overtaken.
4. Work the next unfinished step under the normal TDD cycle (my:tdd).
5. As steps land, append to the plan's `## Progress` section (create it if absent): a dated one-liner per completed step. This is what the next session reads.
6. After each step, check whether any unfinished phase, part, or PR remains. When none does, the plan is finished — go straight to Finishing in the same session. Don't wait to be asked.

## Orchestrating slices

For a multi-slice plan, this session is the orchestrator; implementers are
ephemeral:

- One fresh implementer subagent per slice, briefed with a pointer at the plan
  file — never resume an implementer across slices; a resumed agent replays
  its whole transcript every turn, and self-contained slices lose nothing
  from a fresh start.
- Give each implementer an explicit verification budget: one full-suite run
  at most, targeted tests otherwise, screenshots captured without self-reading.
- Slices with disjoint file sets may run in parallel, each warned off the
  others' files; serialize the full-suite gate through the orchestrator.
- Review each slice's diff yourself and re-run the project's gates yourself
  before committing — never accept an implementer's "green".

A single-slice plan or a trivial step doesn't need the ceremony — work it
directly.

**The review gate:** after the last slice of a multi-slice plan — before the
push that ships it — run `/code-review` on the accumulated diff, then
`my:review-triage` on its findings; the triage's Handoff spawns fresh
implementers for accepted fixes. Running the review from a fresh session is
hygiene (cheap context, a triage untainted by having defended the slices),
not a requirement — the finders and fixers are fresh agents either way.

## The lifecycle footer

Every plan file ends with this, verbatim. Any plan written or picked up without it gets it added:

```markdown
---

*Temporary artifact. When this plan's last phase lands: set `status: shipped`, route its
durable learnings out (`my:capture-learnings`), then delete this file. Never archive it —
git history is the archive.*
```

## Finishing

A finished plan gets **deleted, not archived**, in this order:

1. **Set `status: shipped` immediately** — the moment the last phase/PR is implemented, before draining anything. This arms the pre-push gate, so if the rest of this is interrupted, the next push fails loudly instead of leaving a finished plan lying around forever.
2. Route its durable parts to their homes with my:capture-learnings (decisions → ADR, working rules → guideline docs, cross-session state → memory).
3. Delete the file.
4. Commit the deletion.

`shipped` is a marker between "feature done" and "plan drained", never a resting state — `plan-gate check` blocks every push while a plan sits in it.

$ARGUMENTS
