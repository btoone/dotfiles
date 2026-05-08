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

Brain vaults are often in iCloud, Obsidian Sync, or another cloud-backed directory. A first `ls` may return only the locally-materialized subset — newer/unsynced files can be invisible to a fresh process. **Run `ls -la <vault>` and `find <vault> -type f -name '*.md'` together as your authoritative inventory, and cross-check the counts.** If the two disagree, force a directory stat (`stat <vault>`) and re-list. Treat any discrepancy between scans as a fail-closed signal — re-scan before reporting.

## Checks

Run all checks, then present a single report. Read `index.md` and `log.md` first, then scan all `.md` files in the vault.

### 1. Orphan Notes
Find notes with **no incoming links** from any other note in the vault. Every note should be reachable from at least one other note (usually `index.md`).

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

**Fix:** Either flesh them out with available context or remove them and clean up references.

### 6. Duplicate Coverage
Find notes with very similar titles or content that likely cover the same topic and could be consolidated.

**Report only** — present candidates to user for decision.

### 7. Missing Frontmatter
Find notes outside `_sources/` that are missing the required YAML frontmatter (`created`, `source`, `tags`).

**Fix:** Add frontmatter with best-guess `created` date (from file metadata) and `source: manual`.

### 8. Root Stragglers
Find `*.md` files at the vault root that aren't part of the brain's reserved set: `_Schema.md`, `index.md`, `log.md`, `README.md`. Anything else at root is a straggler — created in Obsidian without a folder, dropped from clipboard, or left behind by a rename. These bypass every other check (no folder = not in any category, often no frontmatter, often "Untitled").

**Fix:** Move each straggler to the correct folder, rename if the title is generic (`Untitled.md`, `Untitled 1.md`), add frontmatter, link from at least one related note, and add to `index.md`.

### 9. Schema Drift
Compare the folder structure defined in `_Schema.md` against what actually exists on the filesystem. Flag:

- **New folders** — directories that exist in the vault but aren't in the schema. These are intentional — the user created them. Offer to update the schema to include them.
- **Missing folders** — directories listed in the schema but missing from the vault. Offer to either create them or remove them from the schema.
- **Overcrowded folders** — categories with significantly more notes than others that might benefit from splitting.
- **Empty folders** — schema-defined categories with zero notes.

**Fix:** Update `_Schema.md` to reflect the current reality. The filesystem wins — the schema describes the brain, not the other way around.

## Lint Policies (defaults)

The lint is **agentic, not interactive**. For each finding, apply a default action without asking. Only escalate to the user when the policy says ASK or when the rule genuinely has no clear answer (e.g., a root straggler whose target folder is ambiguous).

**Vault-specific overrides:** before applying defaults, check `_Schema.md` for a `## Lint Policies` section. Apply those overrides first; fall back to the defaults below for anything the schema doesn't cover.

| Check | Default action | Asks user? |
|---|---|---|
| Orphan notes | Add to `index.md` under the section matching the note's folder; if folder doesn't map to an index section, add under "Other" | Only if folder is unrecognized AND no obvious section |
| Broken links — basename match exists | Repoint to the matching note | No |
| Broken links — no match, target looks like a real concept | Strip the `[[...]]` markers, keep the link text inline | No |
| Broken links — folder/path-only reference (e.g., `[[PBX]]` meaning the project) | Strip markers; preserve text | No |
| Missing index entries | Add to `index.md` under the matching folder section, with a one-line description derived from the note's first heading or paragraph | No |
| Stale content | Report only | Yes — judgment call |
| Empty notes (0 words after frontmatter) | If file mtime >7 days old AND no incoming links → delete. Else flag and skip. | No (delete or flag, no ask) |
| Stub notes (1–49 words) | Report only | Yes — judgment call |
| Duplicate coverage | Report only | Yes — judgment call |
| Missing frontmatter | Add YAML: `created` from file mtime (formatted `YYYY-MM-DD`), `source: manual`, `tags: []` | No |
| Root straggler — `Untitled*.md` | Move to `_sources/conversations/` with name `YYYY-MM-<topic-slug>.md`. Date from frontmatter `created` if present else file mtime. Topic slug derived from first heading, the first sentence, or detectable subject (max 6 words, kebab-cased). | No |
| Root straggler — content clearly maps to a project (e.g., PBX-tagged, mentions a specific project repeatedly) | Move into that `projects/<name>/` folder, add frontmatter, add to `index.md` | No |
| Root straggler — content is ambiguous | Report only | Yes |
| Schema drift — folder exists, not in schema | Add it to `_Schema.md` (filesystem wins) | No |
| Schema drift — folder in schema, missing from filesystem, but notes are referenced under that section name in index | Create the folder and move the matching notes in | No |
| Schema drift — folder in schema, missing from filesystem, no matching notes | Remove from schema | No |
| Schema drift — empty schema-defined folder (zero notes) | Leave alone (folder may be aspirational) | No |

### Destructive-action guardrails

`rm` is the only action that's not reversible from inside the lint. Apply it only for empty notes (0 words after frontmatter) that meet **all** of: no incoming links, mtime older than 7 days, no `tags` indicating draft/wip status. Anything else, even if 100% redundant, gets reported — never deleted.

`mv` is always reversible (the user can move the file back). Apply moves freely under policy without prompting.

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

### Details
(each section with specific files and recommended fixes)

### Auto-fixable
(list items that can be fixed automatically)
```

## Interaction

The lint runs in one shot:
1. Present the full report.
2. Apply all auto-fixes per the Lint Policies (above) without asking. Show what was applied as part of the report.
3. Group any genuinely judgment-dependent findings (stale content, stubs, duplicates, ambiguous-folder stragglers) into a single batched multi-question prompt at the end. Skip this step entirely if there's nothing to ask.
4. After all fixes, append a `[LINT]` entry to `log.md` summarizing what was found, what was auto-fixed, and any user-decided actions.

Do **not** ask "should I auto-fix?" before applying policy-driven fixes. The user invoked `/my:lint-brain` to have it run, not to decide whether it should run.

$ARGUMENTS