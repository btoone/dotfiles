# Save to Obsidian Vault

Save a well-structured markdown note to a user's Obsidian vault under `~/Vaults/`, then run brain maintenance if the vault has a `_Schema.md`.

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

### Folder Shorthand

Map these shorthand names to actual folder paths within the vault:

| Shorthand | Folder |
|-----------|--------|
| `pbx` | `PBX` |
| `glow` | `Glow app` |
| `sales` | `Sales Board Vibe Coding` |
| `fleetio` | `Fleetio Code Challenge` |

If the folder doesn't match a known shorthand, use the argument as-is (title-cased). Create the folder if it doesn't exist.

## What to Save

Look at the **most recent substantive response** in the conversation -- the information the user wants to capture. Then:

1. Write it as a clean, standalone markdown note (not a conversation transcript)
2. Add a YAML frontmatter block with `created` date and `source: claude-code`
3. Use clear headings, bullet points, and code blocks as appropriate
4. Make it useful for future reference -- someone reading this note months later should understand the context without the conversation

## File Naming

- Use the title (provided or generated) as the filename
- Replace spaces with spaces (Obsidian handles this fine)
- Example: `~/Vaults/Developer/PBX/Sentry Plugin Workflow.md`

## Examples

| Command | Vault | File |
|---------|-------|------|
| `/my:vault pbx/Sentry Workflow` | Developer (default) | `~/Vaults/Developer/PBX/Sentry Workflow.md` |
| `/my:vault brain pbx/Sentry Workflow` | Brain | `~/Vaults/Brain/PBX/Sentry Workflow.md` |
| `/my:vault pbx` | Developer (default) | `~/Vaults/Developer/PBX/<generated title>.md` |

## Important

- Do NOT overwrite existing files. If a file with the same name exists, append a number: `Title 2.md`
- Confirm to the user what was saved and where

---

## Brain Maintenance

After saving the note, check if the target vault has a `_Schema.md` file at its root. If it does, this vault follows the brain pattern and you **must** run maintenance:

### 1. Categorize

If the note was saved to a folder that doesn't match the schema's folder structure (e.g., saved to a shorthand folder), consider whether it belongs in one of the schema-defined categories (`ai/`, `business/`, `career/`, `personal/`, `_sources/`). If so, move it there. If the shorthand folder is intentional (project-specific), leave it.

### 2. Cross-reference

Scan the new note for concepts, names, and topics that overlap with existing notes in the vault. For each match:
- Add a `[[wiki link]]` in the new note pointing to the existing note
- Add a `[[wiki link]]` in the existing note pointing back to the new note (place it contextually near related content, not dumped at the bottom)

Read the `index.md` to understand what already exists before linking.

### 3. Update Index

Add the new note to `index.md` under the appropriate category. Include a brief `—` description. If no existing category fits, create a new subsection.

### 4. Update Log

Append an entry to `log.md`:
```
[INGEST] YYYY-MM-DD — Brief description of what was added and where it was filed
```

### 5. Source Separation

If the saved content is raw material (a conversation transcript, article clip, chat dump), file it in `_sources/` under the appropriate subfolder (`conversations/`, `clippings/`, `transcripts/`). Then create or update a distilled note in the brain layer that references the source with a link.

### 6. Report

After maintenance, briefly tell the user:
- Where the note was filed
- What cross-references were added
- Any other notes that were updated

$ARGUMENTS