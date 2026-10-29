---
name: explain-diff
description: >
  Teach me a code change so I understand it, not just approve it: background,
  intuition, a literate walkthrough, and a quiz, published as an Artifact.
when_to_use: >
  Use before review of agent-written code, or when asked to "explain this
  diff", explain a branch/PR/commit, or "quiz me on this change". Not a
  correctness review — that is /code-review.
argument-hint: "[branch | PR number | commit range] (default: current branch)"
arguments:
  - target
---

# Explain Diff — understand the change before it goes to review

Agents can check correctness; what they can't do is put the change in my
head. Understanding is what lets me have the next idea, so a change I can't
explain is cognitive debt even when every gate is green. This skill turns a
diff into a short textbook chapter about it, ending in a quiz I should pass
before anyone else is asked to review.

Adapted from Geoffrey Litt's explain-diff prompts
(<https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524>) and
his talk "Understanding is the new bottleneck".

## Inputs

- `$target`: a branch, PR number, or commit range. Default: the current
  branch against its merge-base with the default branch
  (`git diff $(git merge-base HEAD origin/HEAD)...HEAD`). For a PR number,
  `gh pr diff`. If the diff is empty, say so and stop.

## Hard rules

- **Toy data only.** The Artifact is a published page. Examples, figures, and
  quiz scenarios use invented records — never real customer names, amounts,
  IDs, or credentials, even if they appear in fixtures or logs.
- **Explain, don't review.** Correctness belongs to `/code-review`. If you
  notice a likely bug while reading, tell me in chat — don't bury it in the
  explainer or soften the explanation around it.
- **Explain the code that is there.** Every claim about behavior traces to
  the diff or the surrounding code you read. If the intent is unclear from the
  code, say it's unclear rather than inventing a rationale.

## Steps

### 1. Read past the diff

Read the changed files whole, then the code around them — callers, the model
the change touches, the tests. Read the project's domain docs if present
(`.claude/bounded_contexts.md`, a glossary, CLAUDE.md) so the explainer uses
the project's own terms. You should be able to say in one sentence, in domain
language, what changed for the system's users.

### 2. Write the four sections

One long page with a table of contents and section headers — no tabs.

1. **Background.** First a deep background on the subsystem for a reader new
   to it, visibly marked as skippable. Then a narrow background: exactly the
   state of the world this change starts from.
2. **Intuition.** The essence of the change before any code: what was true
   before, what is true now, and why. Work a concrete example with toy data
   all the way through. Pick one or two diagram families (a data-flow diagram,
   a simplified UI, a before/after state table) and reuse them rather than
   inventing a new picture each time. Add an interactive figure only where
   fiddling with it teaches something a static one can't.
3. **Literate diff.** The code in teaching order, not file order: start where
   the idea starts. Before each excerpt, a paragraph saying what this piece
   does and why it's needed. Quote real hunks; group mechanical changes
   (renames, wiring) into one short note instead of walking each.
4. **Quiz.** Five multiple-choice questions, medium difficulty — answerable
   only by someone who understood the substance, never gotchas or trivia
   about file names. Clicking an answer reveals right/wrong and feedback.

Write in classic style with Martin Kleppmann's clarity: smooth transitions, a
reader you respect, no filler. Use callouts for key definitions and edge
cases.

### 3. Make the quiz detect misunderstanding

Same principle as choosing a test example that a subtly wrong implementation
would fail: each wrong option must be what a reader with a *subtly wrong
mental model* would pick — the plausible misreading, the old behavior, the
edge case handled the other way. Feedback on a wrong option names the
misconception, not just "incorrect". Include at least one "what happens
when…" question about an edge case or failure path.

### 4. Publish

Publish as a private Artifact following the Artifact tool's contract (load
`artifact-design`, and `artifact-diagramming` for figures). Title it after
the change, e.g. "Isometric rendering explained". Give me the link, and offer
a line to paste into the PR description so reviewers start from the
explainer rather than the raw diff.

### 5. Offer the quiz here

Offer to quiz me in the session: ask the five questions one at a time,
without the options visible, and grade my free-text answers. For each miss,
point me to the section that answers it. If a miss reveals a misconception
worth keeping — about the domain or the codebase, not this one diff — hand it
to `my:capture-learnings`. Whether I've passed is my call; the quiz's job is
to make sure I can't fool myself.
