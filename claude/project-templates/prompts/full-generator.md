# AI Context Documentation Generator

Use this prompt to bootstrap AI context documentation for a new project. Copy and paste this into Claude Code when setting up a new repository.

---

## The Prompt

```
I need help creating AI context documentation for this project. This includes a CLAUDE.md file and supporting documents in a .claude/ folder that will guide AI assistants working on this codebase.

## What I Want to Create

I need these documents tailored to THIS project:

### 1. CLAUDE.md (Root-level AI Guide)
A comprehensive guide covering:
- Project overview and tech stack
- Development workflow (setup, running, testing)
- Codebase structure with key directories
- Core domain models and their relationships
- Authorization/authentication patterns (if applicable)
- Testing conventions and philosophy
- Frontend patterns (if applicable)
- Common development tasks
- Git workflow and commit conventions
- Quick reference commands

### 2. .claude/project_intent.md (Strategic Boundaries)
A charter that defines:
- One-sentence product definition
- Core problem solved
- "What We Are" - explicit list
- "What We Are NOT" - explicit non-goals (AI guardrails)
- Strategic positioning
- Value propositions by user persona
- Feature design guardrails (decision framework)
- Preferred vs avoided language/terminology
- Anchor statement that should always remain true

### 3. .claude/ux_guidelines.md (UX Review Criteria)
Guidelines covering:
- Product-aligned UX principles
- Core UX principles (3-5 key principles)
- Language & terminology (correct vs incorrect terms)
- Key user flows with diagrams
- Consistency checklists (visual, behavioral)
- Accessibility standards (WCAG 2.1 AA minimum)
- Anti-patterns to avoid (specific to this product type)
- Review process for UI changes

### 4. .claude/design_system.md (Visual Reference)
A reference covering:
- Brand identity (theme, approach)
- Color palette (primary, semantic, neutrals with hex codes)
- Typography (fonts, scale)
- Component classes/patterns
- Layout patterns
- Spacing scale, border radius conventions
- Quick reference table

### 5. .claude/tdd_guidelines.md (Traps Found in This Repo)
Seeded empty, or with only what's already been learned here:
- Testing traps this repo's own reviews have hit, each dated and attributed
- Nothing generic — the cycle, mock anti-patterns, and bug-fix flow come
  from the my:tdd skill and must not be copied in

### 6. .claude/commands/ (Workflow Automation)
Only commands specific to this repo — scaffolding steps, migration rituals,
stack-specific verification (e.g. `/new-migration`, `/deploy`).

Do NOT generate `/test`, `/review`, `/plan-feature`, or `/commit`. Each is
superseded by a skill or built-in, and a local copy shadows better tooling
with a worse checklist.

### 7. CHANGELOG.md (Change Tracking)
A changelog using Keep a Changelog format:
- [Unreleased] section for pending changes
- Dated sections with Added/Changed/Fixed/Removed
- Populated with recent history from git log

### 8. .claude/settings.local.json (Permissions)
Pre-approved commands for common operations:
- Test runners (npm test, pytest, rspec, etc.)
- Build commands
- Git operations (status, log, diff, branch)
- Project-specific CLI tools

## My Development Philosophy

TDD is non-negotiable. The whole worldview — the cycle, BDD conventions,
fakes over mocks, effects as ports, factories, the mutation-testing mindset
— lives in the my:tdd skill and my global CLAUDE.md, both already loaded in
this session. Do not restate any of it in the generated docs; a copy there
is the one that drifts, and the drifted copy is what the project reads.

What the generated docs SHOULD capture is this project's own testing
reality: the test command, the frameworks and fixtures actually in use, and
any traps already visible in the existing tests.

## How to Proceed

1. **First, explore this codebase** to understand:
   - What tech stack is used (framework, language, database, frontend approach)
   - What the project does (read README, package.json/Gemfile, existing docs)
   - How the code is organized (directory structure)
   - What testing framework is used and any existing test patterns
   - What UI framework/styling approach is used (if applicable)

2. **Then ask me clarifying questions** about:
   - The product vision and what problem it solves
   - Who the users are and their key goals
   - What this product is NOT (anti-goals/boundaries)
   - Any specific terminology or language conventions
   - Design preferences (colors, typography, brand feel)
   - Any existing patterns I want preserved or changed

3. **Create the documents** one at a time, asking for feedback before moving to the next.

Please start by exploring the codebase and then asking your clarifying questions.
```

---

## Usage Notes

### For Rails Projects
The prompt works well as-is. The AI will detect Rails patterns and adapt accordingly.

### For JavaScript/TypeScript/Vite Projects
The prompt adapts automatically, but you may want to add:
- Mention if using a specific framework (React, Vue, Svelte, etc.)
- Mention your state management approach
- Mention your testing framework (Vitest, Jest, Playwright, etc.)
- Mention your component library or design system if using one

### Customizing the TDD Section
The TDD philosophy section is written generically. If you have specific testing patterns for your stack, you can modify the prompt to include:
- Your preferred testing library and patterns
- Your preferred assertion style (expect vs assert)
- Any specific testing utilities you use

### Adding Structural Examples (Optional)
If you want the AI to see the document structures, tell it:

```
I have structural templates at ~/.claude/project-templates/structures/document-skeletons.md
that show the section headings I want. Please read those for reference.
```

---

## Expected Clarifying Questions

The AI should ask questions like:

**Product & Vision:**
- What does this product do in one sentence?
- What problem does it solve and for whom?
- What is this product explicitly NOT trying to be?
- Are there adjacent products/tools it complements rather than replaces?

**Users & Personas:**
- Who are the primary users?
- What are their key jobs-to-be-done?
- What makes them feel successful using this product?

**Technical:**
- What existing patterns should I preserve?
- Are there any conventions from other projects you want to adopt?
- What testing patterns do you prefer?

**Design:**
- What's the brand personality? (professional, playful, minimal, etc.)
- Do you have existing brand colors or preferences?
- What's the typography preference?
- Mobile-first or desktop-first?

**Boundaries:**
- What features are explicitly out of scope for MVP?
- What anti-patterns should the AI avoid suggesting?
- Are there any "sacred cows" - things that must not change?

---

## After Generation

Once the documents are created:

1. **Review each document** for accuracy and completeness
2. **Add project-specific details** the AI may have missed
3. **Test the instructions** by asking the AI to implement a small feature
4. **Iterate** - these are living documents that improve over time

The documents should be committed to the repository so all AI assistants have context.
