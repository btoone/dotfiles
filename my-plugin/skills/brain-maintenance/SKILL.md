---
name: brain-maintenance
description: >
  Wire a note that already exists into the rest of an Obsidian brain vault.
  Adds `[[wiki links]]` and backlinks between it and related notes, an
  `index.md` entry under the right category, and an `[INGEST]` line in
  `log.md`. Works with no conversation history, so it can run in a background
  subagent. Use when a note has been written into a brain vault and needs
  connecting: invoked by `/my:vault` after it saves, or standalone against a
  note you wrote by hand. Triggers: "link this note up", "wire it into the
  index", "run maintenance on <note>". Do NOT use to file or categorize an
  unplaced note (that belongs to the writer), or to sweep the whole vault for
  orphans and broken links (that is `/my:lint-brain`).
---

# Brain Maintenance

Connect one already-placed note to the rest of a brain vault.

## Inputs

- **Note path** — absolute path to the note, already at its final location.
- **Vault root** — the vault directory containing `_Schema.md`.

If invoked without a note path, use the most recently modified `.md` file in the vault outside `_sources/`, and say which one you picked.

## Prerequisite

Read the vault's `_Schema.md`. If there isn't one, this vault doesn't follow the brain pattern — say so and stop. Nothing below applies.

The schema's **Ingest** section is the source of truth. This skill owns steps 3–5 (Link, Index, Log). Steps 1–2 (File, Frontmatter) belong to whoever wrote the note and are already done.

## Scope

**In scope:** adding wiki links inside the note, adding backlinks inside other notes, `index.md`, `log.md`.

**Out of scope — never do these here:**

- Moving, renaming, or deleting the note. Its path has already been reported to the user; changing it makes that report a lie.
- Editing the note's frontmatter.
- Rewriting anyone's prose. You add links into existing sentences; you don't restructure paragraphs.
- Editing anything under `_sources/`. That folder is immutable per the schema.
- Fixing unrelated vault problems you notice along the way. Note them in your report and leave them for `/my:lint-brain`.

## Steps

### 1. Read the landscape

Read the note, then `index.md`. The index is the catalog — it tells you what exists without opening every file. Use it to shortlist candidate notes, then read the handful that actually look related.

Brain vaults often live in iCloud or Obsidian Sync, where a first `ls` can return only the locally-materialized subset. Cross-check `ls` against `find -L <vault> -type f -name '*.md'` and re-scan if the counts disagree. The `-L` is required: vault entries under `~/Vaults/` are frequently symlinks, and a bare `find` stops at the symlink and reports zero files.

### 2. Cross-reference

Find existing notes that overlap the new note's concepts, names, and topics. For each real match:

- Add a `[[wiki link]]` in the new note pointing to the existing note.
- Add a `[[wiki link]]` in the existing note pointing back — **placed contextually**, in or beside the sentence that earns it, not dumped in a "Related" pile at the bottom.

A backlink is worth adding when a reader of the existing note would want the new one at that exact point. Shared vocabulary alone isn't a match. Two or three good links beat a dozen weak ones.

### 3. Update the index

Add the note to `index.md` under the section matching its folder. Include a brief `—` description: the note's first H1 or a ≤80-char summary. Create a subsection only if no existing category fits.

### 4. Update the log

Append to `log.md`:

```
[INGEST] YYYY-MM-DD — Brief description of what was added and where it was filed
```

Get the date from `date +%F` rather than assuming today.

### 5. Report

Return a short summary — where the note is filed, which backlinks you added and into which notes, what else you touched, and anything you deliberately left for lint. When this runs in a background subagent the report is the only thing the user sees, so it carries the whole result.

## Concurrency

`index.md` and `log.md` are shared, and two maintenance runs overlapping on them can clobber each other. Before editing either, re-read it — don't write from a copy you read minutes ago. If you're appending to `log.md`, append; never rewrite the file wholesale.
