---
description: Save conversation content as a note in an Obsidian vault
---

# Save to Obsidian Vault

Save a well-structured markdown note to a user's Obsidian vault under `~/Vaults/`, place it correctly on the first write, then hand the note off to background maintenance.

This command owns **placement**: deciding where the note lives and writing it there. It does not own **enrichment** — backlinks, `index.md`, `log.md` — which belongs to the `my:brain-maintenance` skill and runs detached. The split matters: placement decides the path you report to the user, so it has to be settled before you speak. Enrichment reads and edits a pile of other notes, so it has no business blocking the turn.

## Configuration

- **Vaults root:** `~/Vaults/`

### Vault Resolution (in priority order)

1. **Explicit argument** — if the first argument matches a vault name (case-insensitive against `ls ~/Vaults/`), use it and consume the argument
2. **Current working directory** — if `pwd` is inside `~/Vaults/<something>/`, use that vault
3. **`$OBSIDIAN_DEFAULT_VAULT`** env var (`echo $OBSIDIAN_DEFAULT_VAULT`)
4. **Fallback** — first directory found in `~/Vaults/`

## Argument Parsing

Arguments follow the pattern: `[vault] folder/[title]`

1. **Vault selection** (optional first argument): `ls ~/Vaults/` and case-insensitively match the first argument against vault directory names. If it matches, use that vault and consume the argument. If no match, use the default vault (from `$OBSIDIAN_DEFAULT_VAULT`).
2. **Folder and title**: The next argument is parsed as `folder/title`. If there's no `/`, treat the whole thing as the folder and generate a title from the conversation content.

## Placement

Get this right on the first write. Nothing downstream moves the note, so the path you report is the path it keeps.

**If the vault has a `_Schema.md`,** read it first. Its Architecture block is the authoritative folder map, and it wins over any guess about where a topic goes.

Resolve the folder argument against that map: match it case-insensitively against folder basenames in the Architecture block (cross-checked against the filesystem), including prefix matches, and expand to the full path. `glow` resolves to `projects/Glow app`, `fleetio` to `projects/Fleetio Code Challenge`, `craft` to `craft/`. A shorthand that resolves to a nested folder must be written to the nested path — never to a new top-level folder of the same basename.

If the folder argument doesn't resolve, or none was given, choose the schema category that fits the content. Create a folder only when the content genuinely has no home; say so when you do.

**Source separation.** If the content is raw material — a conversation transcript, an article clip, a chat dump — it belongs in `_sources/` under the matching subfolder (`conversations/`, `clippings/`, `dev-logs/`). Distilled, written-up knowledge belongs in the brain layer. This is a placement decision, so make it here, not later.

**If the vault has no `_Schema.md`,** use the folder argument as given (title-cased), and create it if needed.

## What to Save

Look at the **most recent substantive response** in the conversation — the information the user wants to capture. Then:

1. Write it as a clean, standalone markdown note (not a conversation transcript)
2. Add a YAML frontmatter block matching the vault's schema — at minimum `created` (from `date +%F`) and `source: claude-code`
3. Use clear headings, bullet points, and code blocks as appropriate
4. Make it useful for future reference — someone reading this note months later should understand the context without the conversation

Write the note with no `[[wiki links]]` unless you already know a target exists. Linking is maintenance's job, and a link to a note that isn't there is a broken link the next lint has to clean up.

## File Naming

- Use the title (provided or generated) as the filename
- Natural titles with spaces — Obsidian handles them fine
- Example: `~/Vaults/Developer/projects/Glow app/Sentry Plugin Workflow.md`
- Do NOT overwrite existing files. If a file with the same name exists, append a number: `Title 2.md`

## Examples

| Command | Vault | File |
|---------|-------|------|
| `/my:vault craft/Code Review Gates` | Developer (default) | `~/Vaults/Developer/craft/Code Review Gates.md` |
| `/my:vault glow/Sentry Workflow` | Developer (default) | `~/Vaults/Developer/projects/Glow app/Sentry Workflow.md` |
| `/my:vault brain personal/Reading List` | Brain | `~/Vaults/Brain/personal/Reading List.md` |
| `/my:vault craft` | Developer (default) | `~/Vaults/Developer/craft/<generated title>.md` |

## Hand Off to Maintenance

Once the note is written, check whether the vault has a `_Schema.md`. If it doesn't, you're done — report and stop.

If it does, spawn a **background subagent** to run enrichment, using the Agent tool with `run_in_background: true`:

> Invoke the `my:brain-maintenance` skill for the note at `<absolute note path>` in the vault at `<absolute vault root>`. The note is already placed and its frontmatter is written — do not move, rename, or re-file it.

Give it the absolute paths. The subagent has none of this conversation's context and reads everything it needs from disk.

Do not wait for it. Do not do any of its work yourself first — no backlinks, no index entry, no log line.

Run it synchronously (`run_in_background: false`) only if the user explicitly asks to wait, or asks for the cross-references in this turn.

## Report

Tell the user immediately, without waiting on maintenance:

- The note's title and full path
- Why it landed there, if the folder wasn't the one they named
- That maintenance is running in the background, and that linking, index, and log results will arrive when it finishes

The subagent's own report covers what it linked and updated.

Do not open the note. `/my:open-note` handles that on request, and with no argument it opens the most recently modified note — which is this one.

$ARGUMENTS
