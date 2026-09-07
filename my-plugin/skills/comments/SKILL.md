---
name: comments
description: >
  Write code comments deliberately — sparingly, in plain prose. The default is
  no comment; one earns its place only for a non-obvious WHY or a gotcha the
  code can't show. Use BEFORE writing or editing any inline/method/class
  comment, and when auditing comments in a changeset. If you are about to type
  a `#`, `//`, or `/* */` comment, this applies. Triggers: reaching for a doc
  comment on a new method or class; "this comment is verbose/low-value";
  "audit the comments we added"; "let the code speak". Accepts a target scope,
  defaulting to uncommitted changes.
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

## The substance test

A comment can pass the one test on shape and still say nothing. So, for every
noun the comment keeps, ask:

> Is this a term the code or the domain already has?

A noun that needs defining ("history", "figures", "the numbers") is a vague
idea dressed as a fact, and a frame the class has nothing to do with (a
timeline in a class about scope, a workflow in a class about a calculation)
is a tell that the comment is describing something other than the code. When
a comment fails this test, one of two things is true: there is one concrete
decision hiding inside it, which belongs on the method that embodies it, or
there is nothing, and the comment goes.

## When a comment IS worth writing

- **A non-obvious WHY** — why this reads the pre-aggregate and not the source
  table; why a floor/guard exists; why a write is safe to re-run.
- **A gotcha that would bite a future reader** — "summing this double-counts
  because the value repeats across rows."
- **State semantics that aren't visible** — what `null` means vs `0`.
- **A crisp behavioral contrast** — how this branch differs from a sibling.
- **A grep anchor for a source-of-truth table** — naming the table by name so a
  future reader can find what feeds a surface.
- **A class-level sentence, only when it clears a bar:** the class name and its
  public method names together do not already say what the object answers.
  This is not a default. If they do say it, no class comment. (Durable design
  detail belongs in an ADR, not a comment.)

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
  `# View counts come from the sessions table only: the events table repeats a row per page-load, so summing it double-counts.`
- **Define null-vs-zero / state semantics plainly:**
  `# zero means "measured, none found"; the rate columns stay null until analytics data is imported.`
- **Contrast behavior crisply, caps only on the load-bearing word:**
  `# Admin-only. Unlike show?, a regular member does NOT get this for their own account.`
- **Name the source-of-truth table for grep:**
  `# Reads the daily_rollups table (the analytics source of truth).`
- **Prefer a concrete current limitation over a label:**
  `# rate columns stay null until analytics data is imported` (not "null for V1").

Comment prose is held to the same standard as any other prose: write it
against the `humanizer` skill's patterns, and run that skill over the comments
when auditing. The tells that recur in comments are em and en dashes joining
clauses (use a period, comma, or colon instead), the "X, never Y" punchline,
and stacked short fragments for drama. A comment states its fact plainly.

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

## Worked example — the well-formed vague comment

```ruby
# The accounts whose usage counts toward an invoice. A cancelled account's
# history belongs in last quarter's numbers, so exclusion is a deny-list of
# what was never a customer's, not an allow-list of active accounts.
class BillableAccounts
  def excluded_account_ids
    Account.where(internal: true).or(Account.where(status: :trial)).select(:id)
  end
end
```

This one has the voice right and still fails. The class name and its method
already say it is the billable population defined by exclusion. "History" and
"last quarter's numbers" are nouns the code does not have, and they drag a
timeline into a class that is about scope. The single fact the code cannot
show is that cancelled accounts are deliberately left in, and that belongs on
the method that declares the list:

```ruby
class BillableAccounts
  # Cancelled accounts are not excluded: their usage was a customer's while
  # they were one.
  def excluded_account_ids
```

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

When the work behind a change spans more than one session, audit the **branch**
scope, not the commits of the current session. The comment that escapes is the
one written before the session began.

**Audit only what the scope touched, not the whole file.** For a diff or commit
range, look at the comments on **added/changed lines** (the `+` lines, plus a
comment directly above a changed method). A pre-existing comment elsewhere in
the file is out of scope unless explicitly asked. This keeps the review focused
on what the change introduced.

**Then, for each comment in scope:** read it against the one test and the
substance test. Delete the ones that restate code; strip snapshot facts,
planning-doc citations, and collaboration narration from the rest; condense
survivors to the voice above; and keep the genuine value-adds (the WHY, the
gotcha, the grep anchor) — don't over-trim those away.

**Then re-run both tests on the rewritten text.** Reshaping a comment into the
voice is not an audit; a well-formed sentence with undefined nouns is the
failure mode that survives a structure-only pass. Where a class-level comment
keeps one concrete fact, move that fact onto the method it is about and drop
the class comment.

**Output:** by default, report findings as a list (file:line → why it's
low-value → the suggested rewrite, or "delete") and let the user confirm before
editing. If the user said "fix"/"clean up"/"apply", make the edits directly.
