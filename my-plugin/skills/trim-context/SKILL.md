---
name: trim-context
description: >
  Audit an overgrown CLAUDE.md and shrink what loads at session start.
  Classifies every section by the test "does this apply to every turn?" —
  always-on philosophy and routing stay; task-specific depth (examples,
  catalogs, code blocks, per-area rules) gets demoted to an on-demand
  .claude/ doc or a skill with a one-line pointer left behind; misfiled
  knowledge gets routed out entirely (decisions → ADR, personal → memory,
  stale → deleted); rules a hook, linter, or CI can enforce mechanically
  leave context and get wired into the tool instead. Produces a demotion
  plan (section → verdict → destination → lines saved) for approval BEFORE
  editing, and reports the honest metric: lines loaded at session start,
  before and after. Works on a project CLAUDE.md or the global one. Use
  when a CLAUDE.md "is getting long", when asked to "trim/audit context",
  when a project file creeps past ~150 lines, or after a stretch of
  appending rules without pruning. Do NOT use for routing fresh session
  learnings (that's capture-learnings), for auditing auto-memory (that's
  audit-memory), or for prose style edits to content that's staying.
---

# Trim context

The metric is **lines loaded at session start**, not how organized the
files feel. Splitting a big CLAUDE.md into `@`-imported modules changes
nothing the model experiences — imports resolve at session start and still
bill the full amount. A trim only counts when demoted content moves to a
file that loads on demand: a linked (non-`@`) doc an agent reads when the
task calls for it, or a skill with a trigger description.

## Procedure

1. **Baseline.** Identify the target (project `CLAUDE.md`, or the global
   one) and measure what actually always loads: the file itself plus any
   `@`-imports. Record the total.
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
3. **Present the plan before touching anything**: a table of section →
   verdict → destination → lines saved, plus the projected before/after
   totals. Apply only after approval.
4. **Apply.** Content moves substantially verbatim; the only new prose is
   pointer lines and skill trigger descriptions. Never silently drop a
   rule — every removal is either a demotion with a pointer or a deletion
   the plan called out.
5. **Verify and report.** Confirm every pointer resolves to a real file,
   re-measure the always-loaded total, and report before/after. If the
   file lacks a learnings-routing convention (capture-learnings), suggest
   adding one so the trim doesn't regrow.

## Judgment calls

- **When in doubt, it goes on demand.** The cost of a missed always-on
  rule is one extra pointer lookup; the cost of always-on bloat is paid on
  every turn by every future session.
- **Global CLAUDE.md deserves the same test.** Philosophy documents
  accumulate worked examples and reference tables that apply at
  design-tradeoff moments, not every turn; those demote to a skill loaded
  when making design decisions.
- **Don't over-trim the routing layer.** One line per on-demand doc or
  skill is the price of discoverability; a trimmed file with no pointers
  is just a smaller landfill nobody can navigate out of.
