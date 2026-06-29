---
name: comments
description: >
  Write code comments deliberately — sparingly, only when they add real value,
  in plain natural-language prose rather than dense justification. The default
  is no comment: let names and structure speak. A comment earns its place only
  when it tells a future reader something they could NOT infer from the code —
  a non-obvious WHY, a gotcha, a load-bearing decision, or a grep anchor for a
  source-of-truth table. Strips the recurring failure modes: restating the
  method name, narrating mechanics the reader can see, baking in transient
  snapshot facts (row counts, "for V1"), citing planning docs, sprinkling ADR
  refs on routine code, and writing in a verbose PR-description register. Also
  fixes the VOICE — terse, present-tense, stating the noun-fact or the
  gotcha-with-"so". Use BEFORE writing or editing any inline/method/class
  comment, and when reviewing or auditing comments in a changeset. If you are
  about to type a `#` comment in Ruby (or `//`, `/* */`, `<%# %>` elsewhere),
  this applies. Triggers: writing a new method/class and reaching for a doc
  comment; explaining a query object; "this comment is verbose/low-value/not
  useful"; "audit the comments we added"; "let the code speak"; any time you'd
  narrate what the next line does. Can also be invoked manually against a
  target — uncommitted working-copy changes (the default), the current
  branch's diff vs its base, recent commits, or a specific file/path/symbol.
---

# Comments that earn their place

The default is **no comment**. Names and structure carry the meaning; a comment
is the exception you reach for only when the code genuinely can't say it itself.

## The one test

Before writing any comment, ask:

> Could a competent developer reading this code **not** already know this?

If they can infer it from the method name, the variable names, and the body —
**delete the comment.** A comment only earns its place when it carries
information that is *not present in the code*: a non-obvious WHY, a gotcha, a
deliberate decision a future dev would otherwise "fix," or a grep anchor.

If the comment exists because the *name* is unclear — **fix the name instead.**
A clearer name beats a clarifying comment every time.

## When a comment IS worth writing

- **A non-obvious WHY** — why this reads the pre-aggregate and not the source
  table; why a floor/guard exists; why a write is safe to re-run.
- **A gotcha that would bite a future reader** — "summing this double-counts
  because the value repeats across rows."
- **State semantics that aren't visible** — what `null` means vs `0`.
- **A crisp behavioral contrast** — how this branch differs from a sibling.
- **A grep anchor for a source-of-truth table** — naming the table by name so a
  future reader can find what feeds a surface.
- **A short class-level sentence** on what a query/service object *answers*.
  (Durable design detail belongs in an ADR, not a comment.)

## DON'T

- **Don't restate the method/route name or the code.** A method named
  `page_author_names` already says "resolve author names for the page." Don't
  say it again.
- **Don't narrate mechanics the reader can see** — that `where(id:)` is a PK
  lookup, that `.to_h` returns a hash, what shape gets passed to the caller.
- **Don't bake in transient snapshot facts** — row counts ("40M-row"), roadmap
  labels as framing ("for V1"). Name the *table* or the *behavior*, never its
  current size. The comment outlives the snapshot.
- **Don't narrate the collaboration** — "we chose", "per the prototype/mockup",
  "NOTE: intentionally diverges from the plan", reviewer names.
- **Don't cite planning/task docs** — they get deleted; the ref rots. Put the
  reason inline so it stands on its own.
- **Don't sprinkle ADR references on routine code.** Reserve an ADR citation
  for a genuinely significant, non-obvious design decision.
- **Don't write in PR-description register** — dense, comma-spliced,
  parenthetical-stacked, defensive ("…stay untouched"). That's reviewer prose,
  not a note to a maintainer.
- **Don't be verbose.** Condense to what's truly helpful. Four sentences over a
  four-line method is a smell.

## DO — match the file's existing convention

If a file already comments a certain way (e.g. terse `# GET /reports/:id` over
controller actions), follow it. Don't import a heavier style.

## The voice

When a comment earns its place, write it **terse, plain, present-tense, stating
the fact or the gotcha** — not narrating actions.

- **Lead with what it returns/is, as a noun phrase:**
  `# Views, unique visitors, and bounce rate per page for one site over a date range.`
- **State the gotcha as the reason, joined with "so":**
  `# View counts come from the sessions table only — the events table repeats a row per page-load, so summing it double-counts.`
- **Define null-vs-zero / state semantics plainly:**
  `# zero means "measured, none found"; the rate columns stay null until analytics data is imported.`
- **Contrast behavior crisply, caps only on the load-bearing word:**
  `# Admin-only — unlike show?, a regular member does NOT get this for their own account.`
- **Name the source-of-truth table for grep:**
  `# Reads the daily_rollups table (the analytics source of truth).`
- **Prefer a concrete current limitation over a label:**
  `# rate columns stay null until analytics data is imported` (not "null for V1").

A single em-dash inside a comment is fine — the comment voice is more relaxed
than user-facing copy.

## Worked example — the canonical bad comment

```ruby
# Resolve the author display name for the page's posts in one indexed PK
# lookup (users.id), handed to the list as a { author_id => name } map.
# Only the ~page-size rows on screen are resolved, so the 40M-row posts
# table and the paginator's count query stay untouched.
def page_author_names(posts)
  ids = posts.map(&:author_id).compact_blank.uniq
  return {} if ids.empty?

  User.where(id: ids).pluck(:id, :name).to_h
end
```

Four failures in four sentences: (1) the first clause restates the method name;
(2) it narrates mechanics the reader sees (`where(id:)` is obviously a PK lookup,
`.to_h` is obviously the map); (3) it bakes in a snapshot fact ("40M-row"); (4)
the register is defensive PR prose, not a maintainer's note.

The only non-obvious idea is the WHY: resolve per visible page instead of
joining `User` into the listing query, to keep the count query off the big
table. If that earns a line at all:

```ruby
# Resolve author names for the page's rows, not via a join, so the
# count query never touches the posts table.
def page_author_names(posts)
```

Often the honest answer is **no comment** — the method name and body already say
everything, and the perf rationale is visible from mapping over `posts`.

## Before / after (the shape of the edit)

| Before | After |
|--------|-------|
| `# … never the 40M-row events table.` | `# … never the events table.` |
| `# 'all' for V1` | `# currently always all` |
| `# delete in a follow-up PR once the backfill is done per our task lifecycle` | `# delete once it has run successfully` |
| `# so specs can exercise the behavior without seeding a thousand rows` | `# so tests can exercise it with small fixtures` |
| `# GET /reports/:id — admin-only metrics rolled up across the org's subtree… See ADR 0006.` | `# GET /reports/:id` |
| `# …match on the record id and timestamp. See <planning doc>.` | `# …match on the record id and timestamp.` |

## Auditing a target (manual invocation)

When invoked manually, an argument names the **scope** to audit. Resolve it
first, then audit only the comments inside that scope.

| Argument | Scope | How to gather it |
|----------|-------|------------------|
| *(none)*, "working copy", "uncommitted", "staged" | uncommitted changes | `git diff HEAD` (add `--staged` for staged only) |
| "branch" | everything this branch added vs its base | `git diff $(git merge-base HEAD origin/main)...HEAD` — swap `origin/main` for the real base (`develop`, etc.) |
| "last commit", "recent commits", "last N" | the N most recent commits | `git show HEAD` / `git log -p -n N` |
| a path (`app/foo.rb`, `lib/`) | that file or directory | `git diff HEAD -- <path>`, or read the file directly if auditing all of it |
| a symbol (`SomeClass#method`) | that definition | `grep`/`rg` for it, then read the surrounding block |

**Audit only what the scope touched, not the whole file.** For a diff or commit
range, look at the comments on **added/changed lines** (the `+` lines, plus a
comment directly above a changed method). A pre-existing comment elsewhere in
the file is out of scope unless explicitly asked. This keeps the review focused
on what the change introduced.

**Then, for each comment in scope:** read it against the one test. Delete the
ones that restate code; strip snapshot facts, planning-doc citations, and
collaboration narration from the rest; condense survivors to the voice above;
and keep the genuine value-adds (the WHY, the gotcha, the grep anchor) — don't
over-trim those away.

**Output:** by default, report findings as a list (file:line → why it's
low-value → the suggested rewrite, or "delete") and let the user confirm before
editing. If the user said "fix"/"clean up"/"apply", make the edits directly.
