---
description: Check a project's AI context docs for drift against currently installed skills
---

# Lint Project

Report where a project's `CLAUDE.md` and `.claude/` docs have drifted out of
step with the skills, commands, and conventions actually installed right now.

**This lint checks relationships, never inventory.** It reports that a doc
restates something a skill owns, that a pointer is dead, that two docs claim
the same ground. It never reports that a doc is *missing*, never proposes a
document set, and never resurrects a convention the project moved past. What
docs a project keeps is the project's business — this only checks that what's
there doesn't lie, duplicate, or rot.

## Prerequisite

`pwd` must be a repo root with a `CLAUDE.md` or a `.claude/` directory. If
neither exists, say so and stop — a project with no AI context has nothing to
drift, and offering to create some is exactly the inventory prescription this
command refuses to make.

## Step 0 — Derive the authority list (do this first)

**Never hardcode what the skills cover.** That list is the thing that goes
stale, and a stale copy here would be worse than the drift it's hunting.

Read it fresh, every run:

- Installed plugin skills: the `name` and `description` frontmatter of every
  `SKILL.md` under each installed plugin's `skills/` directory
- Plugin commands: the `description` frontmatter of every `commands/*.md`
- Built-in commands available in this session
- The user-level `CLAUDE.md` that loads in every session

That's the authority. Everything below compares the project against it, so
the checks stay current as the plugin changes without this file being touched.

## Checks

Run all of them, then present one report.

### 1. Restated ownership

A project doc explains something a skill or the global `CLAUDE.md` already
owns — the TDD cycle, mock anti-patterns, commit conventions, design
philosophy, comment style.

The test, applied sentence by sentence:

> **Would this still be true in a different repo?** If yes, something global
> owns it, and the project's copy is the one that will drift.

Report the doc, the section, and which skill owns it. Do not judge whether
the *content* is right — a divergence between the copy and the skill is the
finding, regardless of which one you'd prefer.

Two exceptions, neither of which is drift: the repo is shared with people who
don't have the plugin (self-contained docs are correct there), and content
that reads generic but encodes a decision *this* repo made against the grain.
Note them and move on.

### 2. Superseded commands

For each `.claude/commands/*.md`, check whether an installed skill or built-in
already does the job. A local copy shadows better tooling with a worse
checklist and drifts from it silently.

Report the command, what supersedes it, and whether anything in it is genuinely
repo-specific and worth keeping before deletion.

### 3. Dead references

Every pointer in `CLAUDE.md` and `.claude/**.md` that no longer resolves:

- Paths, directories, and files that don't exist
- Docs referring to sibling docs that were deleted
- Named commands, scripts, or `just`/`make` targets that don't exist
- Skills or plugin commands referenced by a name nothing provides

This is the check that catches retired conventions automatically — when a doc
is deleted, the references that outlive it surface here rather than being
enumerated by name anywhere.

### 4. Verification gate

Whether the project names a single command that proves a change correct
(see the `handoff` skill for why this gates unattended work):

- Is one named at all?
- Does it still exist and run?
- Does the project say what it does **not** cover?

An absent gate is a finding. A gate whose "not covered" line is missing or
aspirational is a worse one — it converts unreviewed changes into confident
ones. Report what the gate command actually is; don't propose its content.

### 5. Duplicate coverage

Two or more project docs claiming the same ground, where a reader can't tell
which is authoritative and an editor will update only one.

Report the overlap and which doc has the stronger claim. Consolidation is the
user's call.

### 6. Always-loaded budget (report only)

Count what loads at session start: the project `CLAUDE.md` plus any
`@`-imports. Report the number.

Do not classify sections or propose demotions — `my:trim-context` owns that
procedure, and duplicating its rules here is the same mistake this command
exists to find. If the count looks heavy, point at that skill.

## What this lint never does

- **Never reports a missing document.** No "you should have a
  `planning_guide.md`" — that doc was deliberately retired, and the same goes
  for anything else the project chose not to keep.
- **Never proposes a document set or a section structure.** The harness's own
  conventions and the project's needs decide that, not this file.
- **Never enforces a convention it can't trace** to an installed skill, the
  global `CLAUDE.md`, or the project's own stated rules. If a check can't cite
  its authority from step 0, it isn't a finding.
- **Never edits.** Report only. Fixes are separate work the user chooses,
  and each one is a judgment call about who owns a piece of knowledge.

## Output

One report, grouped by check, most-consequential first. Per finding:

```
<file>:<line> — <what's wrong>
  Authority: <the skill / doc / built-in it conflicts with>
  Action: <the specific change, one line>
```

Open with the always-loaded count and the gate command (or its absence), since
those two frame everything else. Close with a one-line ask — which findings to
act on — and end the turn there. No edits in the same turn as the report.
