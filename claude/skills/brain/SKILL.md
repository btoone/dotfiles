---
name: brain
description: Save information to the Obsidian vault at ~/brains. Use when the user says "save this to brain", "brain pbx", "save to my vault", or wants to capture a conversation summary for later review.
argument-hint: [folder] [optional-title]
user-invocable: true
allowed-tools: Write, Bash(ls *), Bash(mkdir *)
---

# Save to Obsidian Vault

Save a well-structured markdown note to the user's Obsidian vault at `~/brains/`.

## Arguments

- `$ARGUMENTS[0]` — The subfolder name (case-insensitive, matched to existing folders)
- Remaining arguments — Optional note title. If omitted, generate a concise descriptive title from the content.

## Known Folders

Map these shorthand names to actual folder paths:

| Shorthand | Folder |
|-----------|--------|
| `pbx` | `PBX` |
| `glow` | `Glow app` |
| `sales` | `Sales Board Vibe Coding` |
| `fleetio` | `Fleetio Code Challenge` |

If the folder doesn't match a known shorthand, use the argument as-is (title-cased). Create the folder if it doesn't exist.

## What to Save

Look at the **most recent substantive response** in the conversation — the information the user wants to capture. Then:

1. Write it as a clean, standalone markdown note (not a conversation transcript)
2. Add a YAML frontmatter block with `created` date and `source: claude-code`
3. Use clear headings, bullet points, and code blocks as appropriate
4. Make it useful for future reference — someone reading this note months later should understand the context without the conversation

## File Naming

- Use the title (provided or generated) as the filename
- Replace spaces with spaces (Obsidian handles this fine)
- Example: `~/brains/PBX/Sentry Plugin Workflow.md`

## Example

User runs: `/brain pbx Sentry Workflow`

Creates: `~/brains/PBX/Sentry Workflow.md` containing a well-formatted note based on the recent conversation content.

## Important

- Do NOT overwrite existing files. If a file with the same name exists, append a number: `Title 2.md`
- Confirm to the user what was saved and where
