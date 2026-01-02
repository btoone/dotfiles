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

## TDD is Non-Negotiable
[Brief statement + link to detailed TDD guidelines]
[Quick Reference: RED-GREEN-REFACTOR summary]

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

## .claude/planning_guide.md Structure

```markdown
# Planning & Story Guide

**AI Context**: Reference this document BEFORE implementing any feature. This guide ensures
work is properly scoped, aligned with project intent, and follows user-centered design.

---

## Planning Workflow

Before writing code for any feature, follow this sequence:

### 1. Understand the Request
- [ ] What user problem does this solve?
- [ ] Which persona is this for?
- [ ] What does success look like from the user's perspective?

### 2. Validate Against Project Intent
- [ ] Does this align with "What We Are"?
- [ ] Does this conflict with "What We Are NOT"?
- [ ] Does it pass the feature design guardrail question?

### 3. Design the User Journey
- [ ] What triggers this flow? (entry point)
- [ ] What steps does the user take?
- [ ] What feedback do they receive?
- [ ] What's the success state?
- [ ] What are the error/edge cases?

### 4. Plan the Implementation
- [ ] What tests will prove this works? (TDD: write these first)
- [ ] What existing patterns apply?
- [ ] What's the minimum viable implementation?

---

## User Story Format

Write stories from the user's perspective, focused on value:

**Format:**
> As a [persona], I want to [action] so that [value/outcome].

**Acceptance Criteria:**
- Given [context], when [action], then [expected result]
- Given [edge case], when [action], then [graceful handling]

**Example:**
> As a rep, I want to see my win rate compared to peers so that I know if I'm performing well.
>
> Acceptance Criteria:
> - Given I'm on my dashboard, I see my win rate with percentile ranking
> - Given insufficient data, I see a message explaining why benchmark isn't available
> - Given I click the metric, I can drill into the details

---

## Questions to Ask Before Building

### Scope Questions
- Is this the smallest version that delivers value?
- What can we defer to a future iteration?
- Are we solving the root problem or a symptom?

### User Questions
- Have we validated users actually want this?
- What's the user's mental model for this task?
- What existing patterns will users expect?

### Technical Questions
- What existing code/patterns can we reuse?
- What are the authorization implications?
- What data model changes are needed?

### Risk Questions
- What could go wrong?
- What's the rollback plan?
- Are there security or privacy implications?

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Feature factory | Building without validating value | Start with user problem, not solution |
| Gold plating | Over-engineering before validating | Build minimum viable, iterate |
| Assumption-driven | Guessing what users want | Validate with real scenarios |
| Big bang | Large changes all at once | Small, incremental deliveries |
| Tech-first thinking | "We should use X technology" | "Users need to accomplish Y" |

---

## Definition of Done

A feature is complete when:
- [ ] Tests pass (written first, TDD)
- [ ] Code reviewed against project intent
- [ ] UX reviewed against ux_guidelines
- [ ] Accessible (keyboard nav, screen reader, contrast)
- [ ] Works for all relevant personas
- [ ] Error states handled gracefully
- [ ] No regressions in existing functionality
```
