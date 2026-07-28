# Update Project Context Files

Use this prompt to sync an existing project's `.claude/` context files with the latest patterns from your dotfiles templates.

---

## The Prompt

```
I need to update this project's AI context files (.claude/ folder) to incorporate the latest patterns from my dotfiles templates.

## Reference Templates

Please read these template files for the latest patterns:
- ~/.claude/project-templates/inserts/tdd-philosophy.md (what the project records vs. what my:tdd already covers)
- ~/.claude/project-templates/inserts/verification-gate.md (the command that proves a change correct)
- ~/.claude/project-templates/inserts/workflow-commands.md (when a project command earns its place)
- ~/.claude/project-templates/structures/document-skeletons.md (document structures)

## Files to Review and Update

Check these project files against the templates and update as needed:

### Context Documents

1. **.claude/tdd_guidelines.md** - Should hold only what's specific to THIS
   repo: traps its own reviews have found, dated and attributed. Flag any
   generic TDD philosophy still in there (red-green-refactor, mock
   anti-patterns, bug-fix cycle) — that's `my:tdd`'s job now, and the copy
   here is the one that drifts.

2. **CLAUDE.md** - Ensure it includes:
   - A Tests section naming the test command, pointing at my:tdd
   - A Verification Gate section (see the insert) naming the one command
     that proves a change correct, and what it does NOT cover

### Workflow Automation

3. **.claude/commands/** - Audit, don't just add. Delete any command
   superseded by a skill or built-in (`/tdd`, `/code-review`, `/plan`,
   `/commit`). Keep only commands specific to this repo.

4. **CHANGELOG.md** - Create if missing:
   - Use Keep a Changelog format
   - Populate [Unreleased] section
   - Add recent history from git log

6. **.claude/settings.local.json** - Update permissions:
   - Pre-approve test runners
   - Pre-approve build commands
   - Pre-approve git operations (status, log, diff, branch)
   - Pre-approve project-specific CLI tools

## How to Proceed

1. Read my dotfiles templates listed above
2. Read this project's existing .claude/ files
3. Identify what's missing or outdated compared to templates
4. Show me a summary of proposed changes
5. After my approval, make the updates while preserving project-specific content

Important:
- Preserve all project-specific examples, terminology, and context
- Only update structural patterns and missing sections
- Adapt code examples to this project's tech stack (don't copy Ruby examples into a JS project)
- Don't overwrite customizations - merge new patterns in
- Commands should reference existing project docs, not duplicate them
```

---

## Quick Version

For a faster update when you know what's changed:

```
Add a Verification Gate section to this project's CLAUDE.md following ~/.claude/project-templates/inserts/verification-gate.md — name the command that proves a change correct, and what it doesn't cover.
```

---

## When to Use

Run this prompt when:
- You've updated your dotfiles templates with new patterns
- You notice a project is missing sections that helped in other projects
- You want to propagate learnings across all your projects

---

## After Running

1. Review the changes for project-specific accuracy
2. Test that examples use the correct syntax for the project's stack
3. Commit the updates with a message like:
   ```
   . d Update AI context files with latest TDD patterns
   ```
