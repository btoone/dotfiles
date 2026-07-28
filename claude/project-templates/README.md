# AI Context Project Templates

Templates for bootstrapping AI context documentation (CLAUDE.md + .claude/ folder) in new projects.

**Location**: `~/.claude/project-templates/`

This folder is separate from Claude Code's internal files. These are user-created templates for project setup.

---

## Quick Start

### Option 1: Copy the prompt into a new Claude Code session

```bash
# Open the full prompt
cat ~/.claude/project-templates/prompts/full-generator.md

# Or the quick-start version
cat ~/.claude/project-templates/prompts/quick-start.md
```

Then paste the prompt into Claude Code when starting a new project.

### Option 2: Reference templates during generation

Tell Claude Code:
```
I have AI context templates at ~/.claude/project-templates/ that show the structure
I want. Please read them and generate similar documents for THIS project, asking
clarifying questions first.
```

---

## What's Included

```
~/.claude/project-templates/
├── README.md                    # This file
├── prompts/
│   ├── full-generator.md        # Comprehensive prompt with full instructions
│   ├── quick-start.md           # Shorter prompt for fast setup
│   └── update-context.md        # Sync existing projects with latest templates
├── structures/
│   └── document-skeletons.md    # Section outlines for each document type
└── inserts/
    ├── tdd-philosophy.md        # What a project records vs. what my:tdd covers
    ├── verification-gate.md     # The one command that proves a change correct
    └── workflow-commands.md     # When a project command earns its place
```

---

## Document Overview

| Document | Purpose |
|----------|---------|
| **CLAUDE.md** | Root-level guide: tech stack, commands, structure, patterns |
| **.claude/project_intent.md** | Strategic boundaries, "what we are/aren't", guardrails |
| **.claude/ux_guidelines.md** | UX principles, terminology, accessibility, anti-patterns |
| **.claude/design_system.md** | Colors, typography, components, spacing |
| **.claude/tdd_guidelines.md** | Testing traps found in THIS repo, dated and attributed (the cycle itself lives in my:tdd) |
| **.claude/plans/** | In-flight plans with a status lifecycle, continued by my:continue-plan |
| **.claude/commands/** | Only commands specific to this repo — not copies of skills or built-ins |
| **CHANGELOG.md** | Track changes using Keep a Changelog format |
| **.claude/settings.local.json** | Pre-approved permissions for common commands |

---

## Usage Tips

### Starting a New Project

1. Navigate to the project directory
2. Start Claude Code: `claude`
3. Paste one of the prompts or reference the templates
4. Answer the clarifying questions about your product
5. Review generated docs, iterate as needed

### Updating Existing Projects

When you update these templates with new patterns (like adding Bug Fix Workflow):

1. Navigate to the project: `cd ~/code/my-project`
2. Start Claude Code: `claude`
3. Paste the update prompt from `~/.claude/project-templates/prompts/update-context.md`
4. Review and approve the changes

This propagates learnings across all your projects without regenerating everything.

### For Different Tech Stacks

The prompts adapt automatically. Optionally add context:

**JavaScript/TypeScript:**
```
This is a React app with Vite, using Vitest for tests and Tailwind for styling.
```

**Rails:**
```
This is a Rails 8 app with Hotwire, Minitest with spec DSL, and Tailwind.
```

**Python:**
```
This is a FastAPI app with pytest and Tailwind (via templates).
```

### Key Principles Encoded

- **One fact, one home**: philosophy that applies everywhere lives in the plugin's skills; a project doc records only what's true of *this* repo
- **Nothing generic gets copied in**: a second copy drifts, and the drifted copy is the one the project reads
- **Verifiability before autonomy**: every project names the command that proves a change correct, and what it doesn't cover
- **"What we are NOT" is as important as "What we are"**: Explicit boundaries prevent scope creep
- **Clarifying questions first**: AI should understand the product before generating

---

## Customizing

Feel free to modify these templates. Common customizations:

- Add your preferred commit convention (if not using Arlo's notation)
- Add company-specific terminology
- Adjust the TDD section for your testing philosophy
- Add framework-specific patterns you always use

---

## Updating

These templates are manually maintained. To update:

```bash
# Edit directly
code ~/.claude/project-templates/

# Or use Claude Code
cd ~/.claude/project-templates && claude
```
