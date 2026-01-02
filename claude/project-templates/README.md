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
│   └── quick-start.md           # Shorter prompt for fast setup
├── structures/
│   └── document-skeletons.md    # Section outlines for each document type
└── inserts/
    └── tdd-philosophy.md        # Reusable TDD section (multi-language)
```

---

## Document Overview

| Document | Purpose |
|----------|---------|
| **CLAUDE.md** | Root-level guide: tech stack, commands, structure, patterns |
| **.claude/project_intent.md** | Strategic boundaries, "what we are/aren't", guardrails |
| **.claude/ux_guidelines.md** | UX principles, terminology, accessibility, anti-patterns |
| **.claude/design_system.md** | Colors, typography, components, spacing |
| **.claude/planning_guide.md** | How to plan features: workflow, story format, questions, done criteria |

---

## Usage Tips

### Starting a New Project

1. Navigate to the project directory
2. Start Claude Code: `claude`
3. Paste one of the prompts or reference the templates
4. Answer the clarifying questions about your product
5. Review generated docs, iterate as needed

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

- **TDD is non-negotiable**: Red-Green-Refactor for everything
- **Test behavior, not implementation**: Focus on public APIs and outcomes
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
