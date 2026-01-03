# Update Project Context Files

Use this prompt to sync an existing project's `.claude/` context files with the latest patterns from your dotfiles templates.

---

## The Prompt

```
I need to update this project's AI context files (.claude/ folder) to incorporate the latest patterns from my dotfiles templates.

## Reference Templates

Please read these template files for the latest patterns:
- ~/.claude/project-templates/inserts/tdd-philosophy.md (TDD patterns, bug fix workflow, acceptance tests)
- ~/.claude/project-templates/structures/document-skeletons.md (document structures)

## Files to Review and Update

Check these project files against the templates and update as needed:

1. **.claude/tdd_guidelines.md** - Ensure it includes:
   - Bug Fix Workflow section (REPRODUCE → VERIFY → FIX → VERIFY)
   - Acceptance Test Requirements section with coverage checklist
   - Examples should use THIS project's tech stack

2. **CLAUDE.md** - Ensure TDD section references tdd_guidelines.md

3. **.claude/planning_guide.md** - Ensure Definition of Done includes:
   - Tests pass (written first, TDD)
   - Acceptance test exists for user-facing pages

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
```

---

## Quick Version

For a faster update when you know what's changed:

```
Update this project's .claude/tdd_guidelines.md to include the Bug Fix Workflow and Acceptance Test Requirements sections from ~/.claude/project-templates/inserts/tdd-philosophy.md. Adapt the examples to this project's tech stack.
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
