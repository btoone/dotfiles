# Initialize Brain

Set up the brain pattern in an Obsidian vault. This creates a `_Schema.md`, `index.md`, and `log.md` tailored to the vault's existing content.

## Prerequisite

The current working directory (`pwd`) must be the root of an Obsidian vault (should have a `.obsidian/` directory). If not, tell the user to `cd` into a vault first.

If a `_Schema.md` already exists, warn the user and ask if they want to re-initialize (this will overwrite the schema, index, and log).

## Steps

### 1. Survey the vault

Scan the vault to understand what's already here:
- List all folders and their contents
- Read a sampling of notes across different folders to understand topics and themes
- Check for existing organization patterns (MOCs, tags, folder structure)
- Note any raw source material (conversations, transcripts, clippings, imports)

### 2. Propose a schema

Based on the survey, design a folder structure that fits this vault's domain. The structure always includes:

- `_sources/` with appropriate subfolders for raw inputs
- 3-6 domain-specific folders for the brain layer
- `index.md`, `log.md`, `_Schema.md` at the root

Present the proposed folder structure to the user and ask for feedback before proceeding. Explain why you chose each category.

### 3. Create the schema

Write `_Schema.md` following the same format as other brain vaults — it should include:
- Architecture section with the folder structure
- Conventions (file naming, frontmatter, links, sources)
- Operations (ingest, query, lint)
- Keep operations identical across vaults — only the folder structure and domain change

### 4. Reorganize existing notes

Move existing notes into the new folder structure. File raw material into `_sources/`. Remove old organizational structures (MOCs, etc.) that are being replaced.

### 5. Build the index

Create `index.md` cataloging every note in the brain layer, organized by the new categories. Include brief descriptions.

### 6. Create the log

Create `log.md` with an `[INIT]` entry recording the setup.

### 7. Create README

Write a `README.md` tailored to this vault — same style as other brain vaults but with this vault's specific categories and purpose described.

### 8. Report

Tell the user:
- What folder structure was created
- How many notes were moved and where
- Any notes that were ambiguous and where you filed them
- Suggest running `/my:lint-brain` as a follow-up to catch anything missed

$ARGUMENTS