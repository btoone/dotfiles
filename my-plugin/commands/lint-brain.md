---
description: Run health checks on an Obsidian vault with brain pattern
---

# Lint Brain

Run a health check on an Obsidian vault that follows the brain pattern (has a `_Schema.md`).

## Configuration

- **Vaults root:** `~/Vaults/`

## Vault Resolution (in priority order)

1. **Explicit argument** — if the user passes a vault name, case-insensitive match against `ls ~/Vaults/`
2. **Current working directory** — if `pwd` is inside `~/Vaults/<something>/`, use that vault
3. **`$OBSIDIAN_DEFAULT_VAULT`** env var
4. **Fallback** — first directory found in `~/Vaults/`

## Prerequisite

Read the vault's `_Schema.md` AND scan the actual filesystem. The schema is not necessarily the source of truth — the user may have created, renamed, or removed folders directly. The lint should detect divergence and reconcile.

If no `_Schema.md` exists, tell the user this vault doesn't follow the brain pattern and offer to initialize it.

### Enumerate the filesystem completely

Brain vaults are often in iCloud, Obsidian Sync, or another cloud-backed directory. A first `ls` may return only the locally-materialized subset — newer/unsynced files can be invisible to a fresh process. **Run `ls -la <vault>` and `find -L <vault> -type f -name '*.md'` together as your authoritative inventory, and cross-check the counts.** The `-L` is required: vault entries under `~/Vaults/` are frequently symlinks to the real directory, and a bare `find` stops at the symlink and reports zero files — which reads as an empty vault rather than an error. If the two disagree, force a directory stat (`stat <vault>`) and re-list. Treat any discrepancy between scans as a fail-closed signal — re-scan before reporting.

## Checks

Run all checks, then present a single report. Read `index.md` and `log.md` first, then scan all `.md` files in the vault.

### 1. Orphan Notes
Take the definition from the schema's Lint section — both existing vaults define an orphan there as **no incoming or outgoing links**, which is narrower than no-incoming-only and selects a different set of notes. Use **no incoming links** only when the schema is silent.

Notes the schema exempts are not orphans. Every note should otherwise be reachable from at least one other note (usually `index.md`).

**Fix:** Add the orphan to `index.md` under the appropriate category, and add contextual links from related notes.

### 2. Broken Links
Find `[[wiki links]]` that point to notes that don't exist in the vault. These are references to deleted, renamed, or never-created notes.

**Fix:** Either create the missing note (if the concept is worth capturing) or update the link to point to the correct note.

### 3. Missing Index Entries
Find notes that exist in the brain layer (not in `_sources/`) but are not listed in `index.md`.

**Fix:** Add them to `index.md` under the appropriate category with a brief description.

### 4. Stale Content
Flag notes that:
- Have a `created` date older than 1 year and no links to/from recent notes
- Contain temporal references that are now past (e.g., "next quarter", "upcoming")
- Are clearly outdated (old job search notes, expired plans)

**Report only** — don't auto-fix. Present to user for decision.

### 5. Empty or Stub Notes
Find notes with fewer than 50 words of content (excluding frontmatter). These are placeholders that never got filled in.

**Fix:** Flesh them out where there's enough context to work with. Otherwise report only — empty notes go under "Proposed deletions" with their evidence and the user runs the deletion (see guardrails).

### 6. Duplicate Coverage
Find notes with very similar titles or content that likely cover the same topic and could be consolidated.

**Report only** — present candidates to user for decision.

### 7. Missing Frontmatter
Find notes outside `_sources/` that are missing the required YAML frontmatter (`created`, `source`, `tags`).

**Fix:** Add frontmatter with best-guess `created` date (from file metadata) and `source: manual`.

### 8. Root Stragglers
Find `*.md` files at the vault root that aren't reserved. The reserved set is `_Schema.md`, `index.md`, `log.md`, `README.md` **plus every root-level file the schema's Architecture block names** — `Brain/_Schema.md` registers `Scratch.md` there as a "deliberate root scratchpad — no frontmatter, no index entry, not linted for orphan status," and a vault that declares a root file has already answered this check. Treat ` <n>` variants of reserved names as reserved too; those are check #10's business, not stragglers.

Anything else at root is a straggler — created in Obsidian without a folder, dropped from clipboard, or left behind by a rename. These bypass every other check (no folder = not in any category, often no frontmatter, often "Untitled").

**Fix:** Move each straggler to the correct folder, rename if the title is generic (`Untitled.md`, `Untitled 1.md`), add frontmatter, link from at least one related note, and add to `index.md`.

Non-`.md` files at root are attachments, handled by check #12.

### 9. Schema Drift
Compare the folder structure defined in `_Schema.md` against what actually exists on the filesystem. Flag:

- **New folders** — directories that exist in the vault but aren't in the schema. These are intentional — the user created them. Offer to update the schema to include them.
- **Missing folders** — directories listed in the schema but missing from the vault. Offer to either create them or remove them from the schema.
- **Overcrowded folders** — categories with significantly more notes than others that might benefit from splitting.
- **Empty folders** — schema-defined categories with zero notes.

**Fix:** Update `_Schema.md` to reflect the current reality. The filesystem wins — the schema describes the brain, not the other way around.

### 10. Sync Conflict Copies
Find files whose basename is another file's basename plus a trailing ` <n>` (`index 2.md` beside `index.md`, `log 3.md` beside `log.md`). iCloud and Dropbox name a losing write this way instead of failing it, so the copy appears silently and both versions then diverge on their own. `index.md` and `log.md` are the usual victims — every maintenance run touches them.

**The filename is a candidate signal, not a verdict.** A conflict copy is a *fork*: it was the same file seconds before the losing write, so it still carries the original's frontmatter `created` value and most of its prose. A deliberately distinct note that merely landed on a similar name shares neither. Confirm the fork before treating the pair as a conflict:

- Same frontmatter `created` value in both files.
- Substantial prose overlap, not just a shared heading or topic.

If either fails, this is two different notes. Leave them alone and let checks #3 and #8 give the newer one an index entry and a home. Merging is unrecoverable in the direction that matters — it copies one note's links into another and then proposes deleting the source.

Do **not** assume the newer file is complete. Diff the pair on link targets, not on lines:

```
comm -13 <(grep -o '\[\[[^]]*\]\]' index.md | sort -u) \
         <(grep -o '\[\[[^]]*\]\]' 'index 2.md' | sort -u)
```

Content unique to each side is normal — the live file kept accumulating after the fork, and the copy holds whatever the losing write contributed.

**Fix:** Merge each entry the copy uniquely has into the live file, but only after confirming its target note still exists — a conflict copy predates any later deletion, so it can reference notes that are now gone. Report those separately rather than reintroducing a broken link. Deleting the copy is destructive and needs the user (see guardrails).

### 11. Unescaped Pseudo-HTML Tags
Find bare `<placeholder>` text outside backticks and fenced blocks — `<commit>`, `<path>`, `<persona>`. Obsidian parses `<foo>` as an HTML open tag; since it never closes, markdown rendering stops for **the rest of the file**, so `[[wiki links]]` below it render as literal brackets. One unescaped tag in a shell snippet can silently unlink hundreds of lines, which makes this cheap to miss and worth checking on every pass.

The damage comes from the tag never closing, so test that rather than the angle brackets. Three forms are angle-bracketed and render correctly — backticking them is itself the corruption:

- **Void elements** — `<br>`, `<img>`, `<hr>`, `<wbr>`. They close nothing because they have no content. A `Brain` travel note uses `<br>` inside a markdown table for line breaks; backticked, the cell renders the literal text `` `<br>` ``.
- **Balanced pairs** — a `<sup>` with a `</sup>` later in the file, `<a>`, `<td>`, inline SVG. These are HTML the author meant.
- **Markdown autolinks** — `<https://example.com>`, `<user@example.com>`. Obsidian renders these as links.

So flag `<foo>` only when the file contains no matching `</foo>` and `foo` is not a void element or an autolink. That keeps the real targets, which are unclosed by construction: placeholders like `<commit>`, and Ruby inspect output pasted from a console (`<Fleetio::Client>`, `<Affiliates::Commission:0x4e1d8>`).

Skip `_sources/` — those exports are immutable. Scope the scan with `-not -path '*/_sources/*'` on the file list; a `grep -v _sources` over match output filters the matched text, not the path, and silently does nothing.

**Fix:** Wrap the placeholder in backticks. Verify by confirming links below it resolve again.

### 12. Stray and Orphaned Attachments
Check the attachment convention in three places:

1. **The setting.** Read `attachmentFolderPath` in `.obsidian/app.json`. If the key is *absent*, Obsidian silently defaults to the vault root and every paste lands there — the setting existing matters more than its value. It should name the folder `_Schema.md` designates for attachments.
2. **Strays.** Non-`.md` files outside that folder and outside `_sources/`. Vault root is the usual pile.
3. **Orphans.** Files in the attachment folder that no note embeds.

A stray is a file the vault would embed — not merely a file that isn't `.md`. Two filters, both required.

**It has to be embeddable.** Obsidian embeds images (`png` `jpg` `jpeg` `gif` `bmp` `svg` `webp` `avif`), audio (`mp3` `wav` `m4a` `ogg` `flac`), video (`mp4` `webm` `mov` `mkv`), and `pdf`. Nothing else is an attachment. Source files, archives, and configs are content someone deliberately filed, and they usually arrive as a tree — the `Developer` vault holds an unpacked repo under `projects/Code Samples/`, whose `Gemfile`, `bin/`, and `lib/` a flat move would scatter into one folder.

**Something has to embed it.** An embedded file can be moved and the embed re-verified afterward; a file nothing references is a guess about intent. Report those instead of moving them, alongside the check #12 point 3 orphans.

Three kinds of file match "not `.md`" without being an attachment at all, and moving them breaks things:

- **Dot-directories and dotfiles** — `.obsidian/`, `.git/`, `.claude/`, `.DS_Store`. Configuration and OS litter. `.obsidian/app.json` is the file point 1 above reads, so a sweep without this exclusion relocates the setting it just checked. `open-note.md` carries the same `-not -path '*/.obsidian/*'` guard.
- **Obsidian's other note formats** — `.canvas` is a note, not an attachment.
- **`.DS_Store`** — ignore it; don't file it.

```
find -L <vault> -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \
     -o -iname '*.bmp' -o -iname '*.svg' -o -iname '*.webp' -o -iname '*.avif' \
     -o -iname '*.mp3' -o -iname '*.wav' -o -iname '*.m4a' -o -iname '*.ogg' \
     -o -iname '*.flac' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mov' \
     -o -iname '*.mkv' -o -iname '*.pdf' \) \
  ! -path '*/.*/*' ! -name '.*' \
  ! -path '*/_sources/*' ! -path '*/<attachment-folder>/*'
```

Sanity-check the result before acting on it: if this returns nothing, confirm the same command finds an attachment you know is misplaced.

Before moving anything, check which embed form points at it. `![[name.png]]` resolves by filename from anywhere in the vault, so those files move freely. `![](some/path.png)` is position-dependent and breaks — rewrite it to the wikilink form rather than fixing the path, so it survives the next reorganization.

**Fix:** Move strays into the attachment folder, then re-verify every embed resolves. Report orphans rather than deleting them — an unreferenced image is often a paste that was never embedded, and it's the user's call whether the bytes are worth keeping.

Establish "orphan" by building the set of every embedded filename across the vault and subtracting it from the files on disk. Do not decide it per-file with a shell search: a quoting or globbing mistake makes the search return nothing, which is indistinguishable from a genuine zero and reads as "safe to delete." Before trusting any empty result, confirm the same search finds a reference you know exists. Attachments live in `_sources/` too — a clipping note embedding its own screenshots is exactly the case a brain-layer-only scan misses.

Path-based embeds are worth a standalone sweep even when nothing is stray: a folder rename breaks all of them at once, and check #2 only inspects `[[wikilinks]]`, so they can sit broken across many lint passes without ever being reported.

## Lint Policies (defaults)

The lint is **agentic, not interactive**. For each finding, apply a default action without asking. Only escalate to the user when the policy says ASK or when the rule genuinely has no clear answer (e.g., a root straggler whose target folder is ambiguous).

**Vault-specific overrides:** the schema outranks this file wherever it speaks, and it speaks in three places — not just one. Read all three before applying any default:

- **`## Lint Policies`** — per-finding actions. `Developer/_Schema.md` has this section; `Brain/_Schema.md` does not, so a lint that reads only here treats Brain as having declared nothing.
- **The Architecture block** — folder structure and root-level files, including exemptions written as prose beside an entry.
- **The `### Lint` section** — what the vault means by each finding (its orphan definition, for one).

Anything the schema doesn't cover falls back to the defaults below. A declaration the lint doesn't read is worse than no declaration: the vault records a decision, the lint overrides it, and the next run reverses it again. When a schema states something this file contradicts, the schema wins and the contradiction is worth reporting.

**Except the guardrails.** The destructive-action rules below are not overridable — see the note there.

| Check | Default action | Asks user? |
|---|---|---|
| Orphan notes | Add to `index.md` under the section matching the note's folder; if folder doesn't map to an index section, add under "Other" | Only if folder is unrecognized AND no obvious section |
| Broken links — basename match exists | Repoint to the matching note | No |
| Broken links — no match, target looks like a real concept | Strip the `[[...]]` markers, keep the link text inline | No |
| Broken links — folder/path-only reference (e.g., `[[Acme]]` meaning the project) | Strip markers; preserve text | No |
| Missing index entries | Add to `index.md` under the matching folder section, with a one-line description derived from the note's first heading or paragraph | No |
| Stale content | Report only | Yes — judgment call |
| Empty notes (0 words after frontmatter) | Report under "Proposed deletions" with incoming-link count and mtime as the evidence | Yes — the user deletes |
| Stub notes (1–49 words) | Report only | Yes — judgment call |
| Duplicate coverage | Report only | Yes — judgment call |
| Missing frontmatter | Add YAML: `created` from file mtime (formatted `YYYY-MM-DD`), `source: manual`, `tags: []` | No |
| Root straggler — `Untitled*.md` | Move to `_sources/conversations/` with name `YYYY-MM-<topic-slug>.md`. Date from frontmatter `created` if present else file mtime. Topic slug derived from first heading, the first sentence, or detectable subject (max 6 words, kebab-cased). | No |
| Root straggler — content clearly maps to a project (e.g., project-tagged, mentions a specific project repeatedly) | Move into that `projects/<name>/` folder, add frontmatter, add to `index.md` | No |
| Root straggler — content is ambiguous | Report only | Yes |
| Schema drift — folder exists, not in schema | Add it to `_Schema.md` (filesystem wins) | No |
| Schema drift — folder in schema, missing from filesystem, but notes are referenced under that section name in index | Create the folder and move the matching notes in | No |
| Schema drift — folder in schema, missing from filesystem, no matching notes | Remove from schema | No |
| Schema drift — empty schema-defined folder (zero notes) | Leave alone (folder may be aspirational) | No |
| ` <n>` filename pair that fails the fork test (differing `created`, no prose overlap) | Not a conflict copy — two distinct notes; leave both, index the newer | No |
| Sync conflict copy — entries unique to the copy | Merge into the live file (skip any whose target note no longer exists, and report those) | No |
| Sync conflict copy — deleting the copy once merged | Report under "Proposed deletions" once the merge is verified | Yes — the user deletes |
| Unclosed pseudo-HTML tag outside `_sources/` | Wrap the placeholder in backticks | No |
| Angle-bracketed token that is a void element, half of a balanced pair, or an autolink | Renders correctly — leave it alone | No |
| `attachmentFolderPath` missing from `.obsidian/app.json` | Set it to the attachment folder named in `_Schema.md`; warn that Obsidian must restart to pick it up | No |
| Stray attachment outside the attachment folder, embedded by some note | Move it in, then re-verify its embed resolves | No |
| Stray attachment outside the attachment folder, embedded nowhere | Report only — moving it is a guess about intent | Yes |
| Non-embeddable file outside the attachment folder (source, archive, config, `.canvas`, dotfile) | Not an attachment — leave it alone | No |
| Broken `![](path)` embed whose target exists elsewhere | Rewrite as `![[filename]]` rather than repairing the path | No |
| Orphaned attachment (in the folder, embedded nowhere) | Report only — never delete | Yes |

### Destructive-action guardrails

**The lint never deletes anything, and no schema can authorize it to.** This is the one place a vault's `_Schema.md` does not win. `Developer/_Schema.md` currently carries an auto-fix reading "Empty notes → if mtime >7 days old AND no incoming links AND no `draft`/`wip` tag, delete"; treat that as a report-only rule and say so in the report. The user can delete from the proposed list in one step, and cannot un-delete a note the lint was wrong about.

Collect every deletion candidate — empty notes, orphaned attachments, merged conflict copies — into a "Proposed deletions" section of the report: path, one-line reason, and the evidence behind it. The user runs the deletions.

This isn't caution about edge cases, it's about what the lint can actually know. Every deletion rests on a claim the lint derived itself ("no incoming links", "embedded nowhere"), and a search that silently failed produces the same empty result as a genuine zero. The `deletion-guard` hook blocks `rm` outside scratch space, so attempting one fails anyway.

Renaming or moving a file out of the way is not a lighter-weight deletion — it breaks references identically. `mv` is for relocating a file to where it belongs, and the embeds and links pointing at it get re-verified afterward.

Before reporting anything as unreferenced, confirm the search that found nothing does find a reference that exists. State that check in the report.

### When to ask

Even with policies, ask the user when:
- Multiple findings collapse into a single ambiguous decision (e.g., 3 root files all need a home but the destination folder is judgment-dependent — ask once, batched).
- A policy says "Yes — judgment call" (stale, stubs, duplicates).
- The schema-and-defaults combination doesn't cover the case at all — surface it explicitly rather than guessing.

Group all questions into a single multi-question prompt at the end. Don't interleave questions with auto-fixes.

## Output Format

Present findings as a structured report:

```
## Brain Lint Report — {Vault Name}
Date: YYYY-MM-DD

### Summary
- X orphan notes
- X broken links
- X missing index entries
- X stale notes flagged
- X empty/stub notes
- X potential duplicates
- X missing frontmatter
- X root stragglers
- X schema drift issues
- X stray/orphaned attachments

### Details
(each section with specific files and recommended fixes)

### Auto-fixable
(list items that can be fixed automatically)

### Proposed deletions
(nothing was deleted — these are for you to run)
| Path | Why | Evidence |
|---|---|---|
| `path/to/file` | empty note, no incoming links | 0 words after frontmatter; link scan found 0 referrers, same scan finds N for a known-linked note |
```

Leave the "Proposed deletions" table out entirely when there's nothing in it. An empty table reads as a completed cleanup.

## Interaction

The lint runs in one shot:
1. Present the full report.
2. Apply all auto-fixes per the Lint Policies (above) without asking. Show what was applied as part of the report.
3. Group any genuinely judgment-dependent findings (stale content, stubs, duplicates, ambiguous-folder stragglers) into a single batched multi-question prompt at the end. Skip this step entirely if there's nothing to ask.
4. After all fixes, add a `[LINT]` entry to `log.md` summarizing what was found, what was auto-fixed, and any user-decided actions.

Ordering differs by vault, so read `log.md` before writing to it. Its header prose declares which: "newest first" means insert directly above the current top entry; "append-only chronological" means append to the bottom. If the header is silent, compare the dates on the first and last entries. Don't assume a direction — writing an entry against the file's order buries it in the wrong decade of the log.

Do **not** ask "should I auto-fix?" before applying policy-driven fixes. The user invoked `/my:lint-brain` to have it run, not to decide whether it should run.

$ARGUMENTS