# Document Structure Templates

Use these as structural references when generating AI context documents. These show WHAT sections to include without project-specific content.

---

## CLAUDE.md Structure

```markdown
# CLAUDE.md - AI Assistant Guide for [Project Name]

## Project Overview
[1-2 paragraph description + tech stack table or list]

## AI Context Documents
[Table linking to .claude/ files with "When to Reference" guidance]

## Tests
[Test command. One line: TDD is non-negotiable, see my:tdd for the cycle,
repo-specific traps in .claude/tdd_guidelines.md]

## Verification Gate
[The single command that proves a change correct, and what it does NOT cover]

## Development Workflow
[Code block with setup, run, test commands]

## Codebase Structure
[Directory tree with brief descriptions]

## Core Domain Models
[Grouped by domain area with key fields and relationships]

## Authorization Patterns
[Pattern description + example code + key classes]

## Testing Conventions
[Framework, example test, key fixtures/helpers]

## Frontend Patterns (if applicable)
[Framework stack, example patterns, link to design system]

## Git Workflow
[Commit conventions, branch strategy]

## Configuration
[Environment variables, credentials]

## Deployment
[Key deploy commands]

## Key Files Reference
[Table of important files by category]

## Common Pitfalls
[Wrong vs Right table]

## Quick Reference Commands
[Code block with common commands]
```

---

## .claude/project_intent.md Structure

```markdown
# Project Intent & Alignment Charter

**AI Context**: [How to use this document]

---

## One-Sentence Product Definition
[Single sentence defining what the product IS]

---

## The Core Problem We Solve
[2-3 paragraphs on pain points this product addresses]

---

## What We Are
[Product name] **is**:
- [Bullet 1]
- [Bullet 2]
- [Bullet 3]
- [Bullet 4]
- [Bullet 5]

---

## What We Are NOT (Explicit Non-Goals)

**AI Guardrail**: These are hard boundaries. Do not suggest features that push toward these areas.

[Product name] is **not**:
- [Bullet 1]
- [Bullet 2]
- [Bullet 3]
- [Bullet 4]
- [Bullet 5]

---

## Strategic Positioning
[How this product fits in the ecosystem, what it complements vs replaces]

---

## Primary Value Propositions

### For [Persona 1]
- [Value point]
- [Value point]

### For [Persona 2]
- [Value point]
- [Value point]

---

## Feature Design Guardrails

**AI Decision Framework**: Before implementing any feature, ask:

> "[Key question that validates feature alignment]"

If the answer is no, the feature is likely out of scope.

All features must:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

---

## Language & Mental Models

### Preferred Language
- [Term 1]
- [Term 2]

### Language to Avoid
- [Anti-term 1]
- [Anti-term 2]

---

## Anchor Statement

> "[Statement that should always remain true about this product]"
```

---

## .claude/ux_guidelines.md Structure

```markdown
# UX Guidelines & Review Criteria

**AI Context**: Reference when implementing UI features or reviewing changes.

---

## Product-Aligned UX Principles

### 1. [Principle Name]
[Description of principle aligned to product purpose]

### 2. [Principle Name]
[Description]

### 3. [Principle Name]
[Description]

---

## Core UX Principles

### 1. [Principle Name]
[Description]

### 2. [Principle Name]
[Description]

---

## Language & Terminology

### Required Vocabulary
| Correct | Incorrect |
|---------|-----------|
| [Term] | [Anti-term] |

### Preferred Phrasing
- "[Preferred]" not "[Avoided]"

### Tone Guidelines
[Guidelines on voice and tone]

---

## Key User Flows

### [Flow Name]
```
[ASCII diagram of flow]
```

**Design Requirements**:
- [Requirement]

---

## Consistency Checklists

### Visual Consistency
- [ ] [Check item]

### Behavioral Consistency
- [ ] [Check item]

---

## Accessibility Standards

### WCAG 2.1 AA Compliance

#### Perceivable
- [ ] [Check item]

#### Operable
- [ ] [Check item]

#### Understandable
- [ ] [Check item]

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong | Better Alternative |
|--------------|----------------|-------------------|
| [Pattern] | [Reason] | [Alternative] |

---

## Review Process

### Before Implementing UI
1. [Step]

### During Implementation
1. [Step]

### After Implementation
1. [Step]
```

---

## .claude/design_system.md Structure

```markdown
# Design System Reference

**AI Context**: Use when creating or modifying UI components.

---

## Brand Identity
**Theme**: [Theme name] - [Adjectives describing the feel]
**Approach**: [Mobile-first/Desktop-first], [key approach notes]

---

## Color Palette

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| primary-500 | #XXXXXX | [Usage] |

### Semantic Colors
| Name | Hex | Usage |
|------|-----|-------|
| success | #XXXXXX | [Usage] |

### Neutrals
| Name | Hex | Usage |
|------|-----|-------|
| neutral-50 | #XXXXXX | [Usage] |

---

## Typography

**Font Stack**:
- Body: [Font family]
- Display: [Font family]

**Scale**:
- Display: [Size range]
- Headings: [Size range]
- Body: [Default size]
- Caption: [Small size]

---

## Component Classes

### Buttons
```html
[Example HTML with classes]
```

### Cards
```html
[Example HTML]
```

### [Other components...]

---

## Layout Patterns

### [Pattern Name]
```html
[Example HTML]
```

---

## Spacing Scale
- [Size]: [Usage]

## Border Radius
- [Element]: [Value]

---

## Quick Reference

| Need | Use |
|------|-----|
| [Need] | [Class/pattern] |
```

---

## .claude/tdd_guidelines.md Structure

Seed this empty on a new project. It collects traps THIS repo's reviews
have hit — nothing that could have been written before the code existed.

```markdown
# Testing Traps in [Project Name]

**AI Context**: Traps found in this codebase's own reviews. The TDD cycle,
BDD conventions, and mock anti-patterns are universal and live in the
my:tdd skill — do not restate them here.

---

## [Trap name] (found in [review], [date])

[Where it bites.] [What goes wrong.] [The rule], so [consequence avoided].

[Minimal code example, only if the trap is subtle]
```

---

## .claude/plans/ Structure

No skeleton. Plan files carry their own format and lifecycle — see the
global CLAUDE.md and the my:continue-plan skill. A project doesn't restate
either; it just holds the directory.

---

## .claude/commands/ Structure

Only commands specific to this repo. Anything already covered by a skill or
built-in (`/tdd`, `/code-review`, `/plan`, `/commit`) does not belong here —
see `inserts/workflow-commands.md`.

```
.claude/commands/
└── <project-specific>.md  # e.g., new-migration.md, deploy.md
```

### Command File Template

Lightweight checklists, not multi-phase procedures. The "study an existing
one" step is what earns the command.

```markdown
# [Command name]

[One line: what this scaffolds or checks]

## 1. Study an existing one
[Paths to the simplest well-structured example]
[What to notice: how it wires up, how its tests are structured]

## 2. Create the files, following that pattern
[File structure]

## Done when
- [ ] Tests written first
- [ ] Matches the studied example's patterns
- [ ] [the project's verification gate] passes
```

---

## CHANGELOG.md Structure

```markdown
# Changelog

All notable changes to [Project Name] are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- [New feature or file]

### Changed
- [Modified behavior]

### Fixed
- [Bug fix]

### Removed
- [Removed feature]

## [YYYY-MM-DD]

### Added
- [Feature added in this release]

### Changed
- [Change in this release]

### Fixed
- [Bug fixed in this release]
```

---

## .claude/settings.local.json Structure

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test:*)",
      "Bash(npm run build:*)",
      "Bash(npm run lint:*)",
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git branch:*)"
    ]
  }
}
```

Adapt permissions to project's tech stack:

| Stack | Common Permissions |
|-------|-------------------|
| Node.js | `npm run *`, `npx *` |
| Python | `pytest`, `python -m *` |
| Ruby | `bundle exec *`, `rails *` |
| Go | `go test *`, `go build *` |
