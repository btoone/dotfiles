# Save to Obsidian Vault

Save a well-structured markdown note to a user's Obsidian vault under `~/Vaults/`.

## Configuration

- **Vaults root:** `~/Vaults/`
- **Default vault:** Read from `$OBSIDIAN_DEFAULT_VAULT` env var (`echo $OBSIDIAN_DEFAULT_VAULT`). If unset or empty, fall back to the first directory found in `~/Vaults/`.

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

$ARGUMENTS