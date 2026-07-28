---
name: trim-context
description: >
  Shrink what loads at session start — an overgrown CLAUDE.md, or a
  plugin's skill-listing frontmatter. Sorts always-on rules from
  task-specific depth, demotes the depth to an on-demand doc, a skill, or
  the SKILL.md body it belongs in, and presents a plan for approval before
  editing. Use when a CLAUDE.md "is getting long", when asked to
  "trim/audit context", when skill descriptions bloat the listing or risk
  truncation, or when a file creeps past ~150 lines. Do NOT use for
  routing fresh session learnings (that's capture-learnings) or for
  auditing auto-memory (that's audit-memory).
---

# Trim context

The metric is **lines loaded at session start**, not how organized the
files feel. Splitting a big CLAUDE.md into `@`-imported modules changes
nothing the model experiences — imports resolve at session start and still
bill the full amount. A trim only counts when demoted content moves to a
file that loads on demand: a linked (non-`@`) doc an agent reads when the
task calls for it, or a skill with a trigger description.

## Procedure

1. **Baseline.** The target is the project `CLAUDE.md` in the current
   directory unless the user explicitly names another one — a different
   file, "global", or a plugin's skill listing (see *Trimming a skill
   listing*). Never widen on your own, even when some other always-loaded
   file looks trimmable. Measure what actually always loads *for the
   target*: for a `CLAUDE.md`, the file itself plus any `@`-imports; for
   a skill listing, the `description` and `when_to_use` frontmatter of
   every `SKILL.md` in the named plugin. Record the total.
2. **Classify each section** with the one test — *does this change how the
   agent should behave on every single turn?*
   - **Stays**: philosophy and hard rules that apply to all work
     (TDD non-negotiable, security constraints, commit conventions), plus
     routing lines pointing at on-demand depth.
   - **Stays, compressed**: quick reference used most turns but currently
     stated with rationale and examples. Keep the rule, demote the why.
   - **Demote to on-demand doc**: per-area depth — style guides, catalogs,
     worked examples, long code blocks, tables. Move to the narrowest
     `.claude/<topic>.md` and leave a one-line pointer.
   - **Demote to a skill**: content that is a *procedure for a kind of
     task* (how to write tests here, how to cut a release). Skills earn
     their load by trigger; write a "Do NOT use for..." clause into the
     description so it doesn't over-apply.
   - **Demote to enforcement**: anything a hook, formatter config, linter
     rule, or CI check can enforce mechanically. Wire the tool, delete the
     prose. A rule enforced by a hook costs zero context.
   - **Route out**: decisions with tradeoffs belong in an ADR; personal
     preferences and cross-session state in auto-memory; anything stale or
     no longer true gets deleted, shown in the plan first.
3. **Present the plan and end the turn.** The plan is the deliverable
   of this step, delivered as the final text message of the turn: a
   markdown table of section → verdict → destination → lines saved,
   plus the projected before/after totals, ending with a one-line ask
   ("Reply to approve, or name the verdicts to change"). No tool calls
   after the table — do NOT use AskUserQuestion for this approval.
   Ending the turn on the plan text is what guarantees the user can
   read it; an approval prompt lets the turn end without the plan ever
   appearing, which is the observed failure mode (the plan stays in
   private reasoning or gets compressed into an option label like
   "All 18 verdicts: 381 → ~140 lines", and the user is asked to
   approve a plan they were never shown). Wait for the user's reply
   before touching anything.
4. **Apply.** Content moves substantially verbatim; the only new prose is
   pointer lines and skill trigger descriptions. Never silently drop a
   rule — every removal is either a demotion with a pointer or a deletion
   the plan called out.
5. **Verify and report.** Confirm every pointer resolves to a real file,
   re-measure the always-loaded total, and report before/after. If the
   file lacks a learnings-routing convention (capture-learnings), suggest
   adding one so the trim doesn't regrow.

## Trimming a skill listing

A `SKILL.md` is already split into the two tiers this skill reasons
about: the frontmatter loads at session start for every session, the body
loads only when the skill fires. An oversized `description` is the same
demotion as an oversized CLAUDE.md section, with the destination one file
closer. Usually the body already says it — grep before cutting, because
that turns the move into a plain delete of a fact billed twice. Grep
under-reports, though: a phrase that wraps across lines in folded YAML or
markdown never matches, so a zero hit on a multi-word phrase means go read
the section, not that it is missing. Twice that nearly turned a delete
into a needless move.

Steps 3–5 are unchanged: plan, approve, apply, verify. Only the
classification test differs, because a description is not content, it is
a routing key. Ask of each clause: **would the skill still fire without
it?**

- **Stays**: what the skill does, in one clause.
- **Stays**: the trigger vocabulary — the literal words a user would
  type. This is the surface routing matches on, so it is the last thing
  to cut, never the first.
- **Stays**: a negative clause addressed to the **router** — one that changes
  whether the skill fires. It either **disambiguates** from a sibling that
  genuinely competes for the same trigger ("do NOT use for X, that's Y"), or
  it **bounds an over-broad trigger** — what stops `capture-learnings`, which
  fires on "remember this", from catching every mid-task scratch note, and
  `bounded-contexts`, which fires before the first failing spec, from
  catching every bug fix. The bounding kind names no rival and is easy to
  mistake for dead weight; a skill whose triggers are common phrases needs
  it more than a disambiguating one, not less. A clause doing neither —
  excluding nothing the triggers would otherwise catch — is what gets cut.
- **Moves to the body**: procedure, traps, worked detail, encoded
  technical knowledge. A description that teaches is paying always-on
  rates for on-demand content.
- **Moves to the body**: a negative clause addressed to the **agent** —
  what not to touch once the skill is already running. Same `do NOT`
  surface as above, opposite verdict. `brain-maintenance`'s "does NOT move
  or rename the note" and `review-triage`'s "does NOT re-run the review"
  change nothing about what fires; they instruct the run, and each was
  already stated in the section that owns it. Ask who the sentence is
  talking to — the router, or the agent mid-run.
- **Deleted**: restatements of the skill's own name, and exhaustive
  trigger lists where three distinctive examples route as well as ten.

Verify differently too. Re-read each trimmed description cold and name
the tasks it should catch; if a real trigger no longer has a word to
match on, put it back.

## Judgment calls

- **When in doubt, it goes on demand.** The cost of a missed always-on
  rule is one extra pointer lookup; the cost of always-on bloat is paid on
  every turn by every future session.
- **For descriptions, the doubt runs the other way.** An over-trimmed
  CLAUDE.md costs one pointer lookup and announces itself. An
  over-trimmed description fails silently — the skill simply never fires,
  and nothing surfaces the miss. When unsure whether a trigger word is
  load-bearing, keep it.
- **Stay scoped to the target.** Other always-loaded files — the global
  CLAUDE.md when trimming a project file, or vice versa — are out of
  scope: don't measure them, don't re-audit them, and don't report on
  their state unless the user asks.
- **When the global CLAUDE.md is the target, it deserves the same test.**
  Philosophy documents accumulate worked examples and reference tables
  that apply at design-tradeoff moments, not every turn; those demote to
  a skill loaded when making design decisions.
- **Don't over-trim the routing layer.** One line per on-demand doc or
  skill is the price of discoverability; a trimmed file with no pointers
  is just a smaller landfill nobody can navigate out of.
