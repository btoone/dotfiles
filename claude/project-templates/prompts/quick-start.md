# Quick-Start AI Context Prompt

A shorter version for bootstrapping AI documentation in a new project.

---

## The Prompt

```
I need you to create AI context documentation for this project. Please:

1. **Explore the codebase** - Read package.json/Gemfile, README, directory structure, any existing docs

2. **Ask me clarifying questions** about:
   - What this product is and what problem it solves
   - Who the users are
   - What this product is explicitly NOT (boundaries/anti-goals)
   - Design preferences (colors, brand feel, typography)
   - Any terminology conventions

3. **Create these documents**:

   **CLAUDE.md** (root level):
   - Project overview, tech stack
   - Development workflow commands
   - Codebase structure
   - Key domain models
   - Testing conventions (TDD-first, behavior-focused)
   - Git workflow
   - Quick reference

   **.claude/project_intent.md**:
   - One-sentence definition
   - What we ARE vs what we are NOT
   - Feature design guardrails
   - Preferred vs avoided language

   **.claude/ux_guidelines.md**:
   - UX principles aligned to product type
   - Terminology table (correct vs incorrect)
   - Key user flows
   - Accessibility checklist (WCAG 2.1 AA)
   - Anti-patterns to avoid

   **.claude/design_system.md**:
   - Color palette with hex codes
   - Typography scale
   - Component patterns
   - Spacing/layout conventions

   **.claude/planning_guide.md**:
   - Planning workflow (understand → validate → design → implement)
   - User story format with acceptance criteria
   - Questions to ask before building
   - Anti-patterns to avoid
   - Definition of done

   **.claude/tdd_guidelines.md**:
   - Red-Green-Refactor cycle with examples
   - What to test (behavior) vs NOT test (implementation)
   - Anti-patterns and correct patterns
   - Bug fix workflow (REPRODUCE → VERIFY → FIX → VERIFY)
   - Acceptance test requirements for pages
   - TDD checklist

**My philosophy**: TDD is non-negotiable. Red-Green-Refactor for everything. Test behavior not implementation. Every bug fix starts with a failing reproduction test. Every user-facing page needs an acceptance test.

Please start by exploring and asking questions.
```

---

## Stack-Specific Additions

### For JavaScript/TypeScript/Vite:
Add to the prompt:
```
This is a [React/Vue/Svelte] app using [Vite/Next/etc].
Testing: [Vitest/Jest] for unit tests, [Playwright/Cypress] for E2E.
Styling: [Tailwind/styled-components/CSS Modules].
```

### For Rails:
Add to the prompt:
```
This is a Rails app.
Testing: Minitest with spec DSL, Capybara for system tests.
Use fixtures, not factories.
```

### For Python:
Add to the prompt:
```
This is a [Django/FastAPI/Flask] app.
Testing: pytest with [pytest-django/httpx] for integration tests.
```

---

## Optional: Reference Structural Templates

Add this to have the AI read the document skeletons:
```
For reference, read ~/.claude/project-templates/structures/document-skeletons.md
to see the section structure I want for each document.
```
