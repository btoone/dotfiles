---
description: Audit local auto-memory against checked-in project docs and migrate any gaps
---

# Audit Memory

Compare this project's auto-memory files against its checked-in context docs to find gaps — learnings that live only in local auto-memory and haven't been promoted to committed docs.

## Why This Matters

Auto-memory is **local-only**. We work across multiple machines and cloud sessions, so anything stored exclusively in auto-memory is lost the moment we switch environments. Checked-in docs (`CLAUDE.md`, `.claude/*.md`) travel with the repo and persist everywhere. "Syncing" here means **promoting durable learnings from local memory into committed docs** — not pushing to any external store.

## Configuration

Resolve both locations from the current project — nothing is hardcoded.

### Auto-memory directory

The auto-memory dir is `<config>/projects/<slug>/memory/`, where `<config>` is the active Claude config dir and `<slug>` is the project's absolute path with every `/` turned into `-`:

```bash
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
slug="$(pwd | sed 's#/#-#g')"           # /Users/brandon/dotfiles -> -Users-brandon-dotfiles
memory_dir="$config/projects/$slug/memory"
ls -la "$memory_dir" 2>/dev/null
```

If `$memory_dir` doesn't exist or holds only `MEMORY.md` with no real entries, there's nothing to audit — tell the user and stop.

### Project docs

The promotion targets are this repo's checked-in docs. Discover them rather than assuming filenames:

```bash
ls CLAUDE.md 2>/dev/null
find .claude -maxdepth 1 -name '*.md' 2>/dev/null   # e.g. project_intent.md, tdd_guidelines.md, ux_guidelines.md, design_system.md, bounded_contexts.md
```

Read each file's purpose before routing anything into it — the right target depends on the kind of learning (conventions/pitfalls → `CLAUDE.md`; strategy/domain → `project_intent.md`; testing → `tdd_guidelines.md`; etc.).

## Process

1. **Read all auto-memory files** in `$memory_dir` — `MEMORY.md` (the index) and every other `.md`.

2. **For each topic/fact in auto-memory**, search the project docs to check coverage.

3. **Classify each topic**:
   - **COVERED** — already in project docs, no action needed
   - **PARTIALLY COVERED** — some details missing from project docs
   - **NOT COVERED** — only in auto-memory, needs migration

4. **Report findings** as a table:

   ```
   | Topic | Status | Target doc | Gap |
   |-------|--------|-----------|-----|
   ```

5. **For any gaps found**, propose specific edits to migrate the content into the appropriate project doc. Match each doc's existing voice and structure — don't paste raw memory text. After the user approves, apply the edits.

## What to Look For

- Specific implementation details (key shapes, type mappings, mock patterns)
- Architectural decisions and their rationale
- Gotchas and debugging insights
- Patterns that took trial-and-error to discover
- Security constraints

## What's OK to Leave in Auto-Memory Only

- Ephemeral working notes about in-progress tasks
- Stats that change frequently (test count, file count)
- Cross-references to project docs ("see ux_guidelines.md for details")
- `feedback`-type memories about how to work with the user (these are personal, not project knowledge)

$ARGUMENTS
