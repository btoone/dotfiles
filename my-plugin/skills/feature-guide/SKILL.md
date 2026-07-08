---
name: feature-guide
description: >
  Produce a shareable, non-technical feature guide as a published Artifact —
  live screenshots of every surface in the feature's story, captured from the
  running dev app with Playwright (including interaction states: open menus,
  drawers, drill-downs), annotated with numbered callout dots and plain-language
  legends, organized around the feature's own mental model (levels, flow, or
  lifecycle), with "reading the numbers", "what it can't show (yet)", and
  "who can see it" sections. Self-contained HTML (base64-embedded images,
  light + dark themes, project brand tokens) published via the Artifact tool
  and iterated in place at the same URL.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Artifact
  - AskUserQuestion
  - ToolSearch
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Bash(npx tsx:*)
  - Bash(npx playwright:*)
  - Bash(sips:*)
  - Bash(cwebp:*)
  - Bash(ruby:*)
  - Bash(node:*)
  - Bash(curl:*)
  # Plus the project's dev-DB access for staging/verifying demo data —
  # an MCP tool (mcp__*__execute_sql), just psql, or rails runner.
  # Discover via ToolSearch; degrade to asking the user if none exists.
when_to_use: >
  Use when the user wants a shareable, screenshot-driven explanation of a
  shipped UI feature for an audience beyond the codebase — teammates,
  stakeholders, non-technical readers. Triggers: "make a report for my team
  showing X", "document the new X feature with screenshots", "create a feature
  walkthrough I can share", "write up the X feature for the team", "make an
  announcement page for X". Applies whenever the deliverable is a standalone
  guide/report with images of the app, not code docs or a README.
argument-hint: "<feature name or short description>"
arguments:
  - feature
---

# Feature Guide — annotated-screenshot walkthrough as a published Artifact

Turn a shipped UI feature into a guide a mixed audience can follow: real
screenshots from the running app, numbered annotations, and copy that
explains what the reader sees — published as a private-by-default Artifact
the user can share and keep iterating at the same URL.

## Inputs

- `$feature`: the feature to document (name or short description). The
  surfaces, audience notes, and any extra sections come from conversation
  context; ask if the story is unclear.

## Goal

A published Artifact URL containing: one annotated screenshot per surface in
the feature's story (including interaction states), non-technical body copy,
a structure that mirrors the feature's own mental model, honest
limitations, an access/permissions section, and a footnote stating the
screenshots use synthetic data. The user can request edits and get them at
the same URL.

## Hard rules

- **Demo data only.** Screenshots must show synthetic/demo records, never
  real customer names or figures. If the dev DB mixes real and demo data,
  choose demo records; if none exist, stop and ask before seeding. The
  guide always footnotes that data is synthetic.
- **Non-technical by default.** Body copy is written for a mixed audience:
  no routes, class names, or schema talk in prose (a `path` chip for
  "where to click" is fine). Explain domain terms on first use.
- **Honest numbers.** If the feature has known data limitations, the guide
  says so plainly (its own section), including what would unlock them.

## Steps

### 1. Scope the story

Identify the surfaces that tell the feature's story: pages, and the
interaction states that don't exist at rest (an open menu, an open drawer, a
hover state, a filled form). Order them by the feature's own mental model —
drill-down levels, a workflow left-to-right, a lifecycle. Check the repo for
plans/ADRs/memory that record what the feature is and any known limitations
or access rules; these feed sections later.

**Human checkpoint**: present the surface list + narrative order and get
confirmation before capturing anything.

**Success criteria**: a confirmed list of screenshots to take, each with its
URL, required state (what's open/clicked), and the 2–4 things to annotate.

### 2. Stage demo data

Find records that make every surface look real and populated — hierarchies
with children, tables with rows, charts with slope. Query the dev DB
(MCP `execute_sql` tool, `just psql`, or `rails runner`) to verify the
records exist and have data in the window the feature displays.

**Artifacts**: the concrete IDs/identifiers each screenshot will use.

**Success criteria**: every surface on the list has a named demo record
that renders non-empty.

### 3. Capture screenshots with Playwright

Write a one-off Playwright script and run it against the local dev server:

- **Put the script inside the repo** (e.g. `tmp/`) — module resolution for
  `@playwright/test` fails from outside; delete it when done.
- **Reuse the project's e2e auth helper** (login URL, selectors, seeded
  credentials — e.g. `e2e/helpers/auth.ts`) rather than inventing a login.
- Viewport ~1600×1000 with `deviceScaleFactor: 2` for crisp retina output.
- For each surface: `goto`, `waitForLoadState('networkidle')`, extra
  `waitForTimeout` for charts/animations, then `screenshot`.
- Interaction states are their own shots: click the menu/row, wait ~400ms,
  screenshot.
- Output PNGs to the session scratchpad.

**Success criteria**: the script exits cleanly and one PNG per confirmed
surface exists.

### 4. Verify every shot and plan annotations

Read each PNG and actually look at it: logged-in state, right record, right
data, nothing embarrassing in view (browser chrome, other tabs, real data).
Retake anything wrong. While viewing, note annotation coordinates for each
callout **as percentages** of width/height — they position the numbered dots.

**Success criteria**: every screenshot verified good; a dot list per image
with `left%`, `top%`, and legend text.

### 5. Build the page

Load the `artifact-design` skill first (required before Artifact), then:

- **Brand tokens**: pull the project's palette/type from its design system
  (variables file, CLAUDE.md brand section). Define tokens on `:root`,
  redefine under `@media (prefers-color-scheme: dark)` and both
  `:root[data-theme="…"]` overrides. Skip webfont CDNs (CSP); use a close
  system stack.
- **Images**: downscale to ~1600px wide JPEG (`sips -Z 1600 -s format jpeg
  -s formatOptions 82`), embed as base64 data URIs (CSP requires
  self-contained). Keep the total page under a few MB.
- **Annotated figures**: each screenshot in a bordered, shadowed frame;
  absolutely-positioned numbered dots at the step-4 coordinates; a legend
  below matching dot numbers to plain-language explanations.
- **Structure**: intro (what + why) → mental-model overview (level map /
  flow strip) → one section per surface with its figure → "reading the
  numbers" (how to interpret) → "what it can't show (yet)" if limitations
  exist → "who can see it" (roles table) → quick reference → synthetic-data
  footnote.
- Write the HTML to the scratchpad; build with placeholder tokens and
  inject base64 via a small script rather than pasting megabytes by hand.

**Success criteria**: a self-contained HTML file, no external requests,
both themes styled, every confirmed surface present with annotations.

### 6. Publish and iterate

Publish with the Artifact tool (stable emoji favicon, one-line description,
short version label). Report the URL and note it's private until shared
from the page's share menu. For any follow-up edit: edit the same file and
republish the same path — same URL, new version label. Delete the temp
Playwright script from the repo.

**Success criteria**: a live Artifact URL delivered to the user; subsequent
edits land at the same URL.
