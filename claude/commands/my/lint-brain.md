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

### 8. Schema Drift
Compare the folder structure defined in `_Schema.md` against what actually exists on the filesystem. Flag:

- **New folders** — directories that exist in the vault but aren't in the schema. These are intentional — the user created them. Offer to update the schema to include them.
- **Missing folders** — directories listed in the schema but missing from the vault. Offer to either create them or remove them from the schema.
- **Overcrowded folders** — categories with significantly more notes than others that might benefit from splitting.
- **Empty folders** — schema-defined categories with zero notes.

**Fix:** Update `_Schema.md` to reflect the current reality. The filesystem wins — the schema describes the brain, not the other way around.

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
- X schema drift issues

### Details
(each section with specific files and recommended fixes)

### Auto-fixable
(list items that can be fixed automatically)
```

## Interaction

After presenting the report:
1. Ask the user if they want to auto-fix the fixable issues
2. For report-only items, ask what they'd like to do with each
3. After all fixes, append a `[LINT]` entry to `log.md` summarizing what was found and fixed

$ARGUMENTS