---
name: bounded-contexts
description: >
  Decide WHERE new domain code lives so a codebase organized by bounded
  context stays predictable as contexts get added — the rule a contributor
  (agent or human) follows before introducing a new domain noun. Models the
  domain in two coordinates: which bounded context owns the code (slices by
  meaning) and which layer it sits in (slices by dependency direction), with
  one hard rule — dependencies point down, a lower layer never names a higher
  one. Places behavior by KIND not amount (record / domain / framework),
  namespaces by ownership not reference, names from domain language not one
  customer's vocabulary, and treats boundary purity as a default with an
  evidence-based escape valve, never a tax. The durable rule lives here; each
  project's own contexts table and migration state live in its
  .claude/bounded_contexts.md, which this skill reads (and offers to scaffold
  when missing). Loads a frameworks/<stack>.md appendix for stack-specific
  placement (e.g. Rails directory coupling) and degrades to generic shapes
  when none matches.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(rg:*)
  - Write
  - Edit
when_to_use: >
  Use BEFORE writing the first failing spec for any work that introduces or
  relocates a top-level domain noun. Concrete triggers: a new noun that
  doesn't fit an existing model (introducing Preference, Notification,
  AuditTrail); a new top-level source directory; a new domain service, query
  object, or value object that doesn't obviously belong to an existing
  context; a refactor that surfaces a new noun out of an existing model
  (extracting a resolver out of a persistence class); deciding whether a new
  model should be namespaced under a context; or planning a migration that
  re-homes existing code into a context. If you're only modifying behavior
  inside an existing context, fixing a bug, or adding a column, this rule does
  NOT fire — keep to the conventions already in that context.
---

# Bounded Contexts — where domain code lives

This skill answers one narrow question: **"where does this file go?"** — not
"what is a value object?" It's the rule that keeps a codebase organized by
**bounded context** (Eric Evans' DDD term: a coherent slice of the domain with
its own ubiquitous language and internal boundaries) predictable for the next
person who walks in, agent or human.

The rule is **the default, not a target.** Introducing a new domain noun at the
root namespace without first deciding its bounded context is a code-review
block, not a stylistic preference. Existing code that doesn't match yet is
**migration debt**, not precedent — the project's own
`.claude/bounded_contexts.md` records the state of each context (see *The
project's contexts table* below).

For the *concepts* themselves — ubiquitous language, aggregates, value objects,
anti-corruption layers — see Evans' *Domain-Driven Design*. This skill is
narrower and operational.

## When this rule fires — and when it doesn't

Match the effort to the change. This is a rule that **fires on specific
triggers**, not a checklist to run on every edit.

**It fires** before the first failing spec when you're:

- introducing a new noun that doesn't fit an existing model
  (`Preference`, `Notification`, `AuditTrail`)
- adding a new top-level source directory
- adding a domain service, query object, or value object with no obvious owner
- refactoring a new noun *out* of an existing model (extracting a resolver from
  a persistence class)
- deciding whether a newly-added model gets a context namespace
- planning a migration that re-homes existing code into a context

**It does not fire** when you're modifying behavior inside an existing context,
fixing a bug, or adding a column. Continue with the conventions the existing
context already uses — don't reorganize on the way past.

When it fires, do the cheapest thing that settles placement: name the owning
context, place the file by the rule below, and move on. Reach for the migration
machinery (escape valves, escalation, a re-home plan) only when the work
actually demands it.

## The two coordinates

Every file in a context-organized codebase has **two independent coordinates**.
"Independent" is load-bearing: knowing one tells you *nothing* about the other —
like latitude and longitude, you need both to locate a file.

- **Which context?** (Reporting / Disputes / Identity…) — slices the domain *by
  meaning*. "What does `Transaction` mean *here*?"
- **Which layer?** (UI / Application / Domain / Infrastructure) — slices *by
  dependency direction*. "What is this code allowed to *know about*?"

Two files can share a context but differ in layer (a context's controller vs.
its domain service), or share a layer but differ in context (two contexts' query
objects). You need both coordinates to know where a file lives and what it may
depend on.

```
                  BOUNDED CONTEXTS  →  sliced by MEANING
                  ┌───────────────┬───────────────┬───────────────┐
                  │   Reporting   │   Disputes    │   Identity    │
  ┌───────────────┼───────────────┼───────────────┼───────────────┤
  │ UI            │ render / parse the outside world                │
  ├───────────────┼───────────────┼───────────────┼───────────────┤
  │ Application   │ orchestrate: sequence steps, dispatch work      │
  ├───────────────┼───────────────┼───────────────┼───────────────┤
  │ Domain        │ the business rules — the heart of the context   │
  ├───────────────┼───────────────┼───────────────┼───────────────┤
  │ Infrastructure│ persistence, external systems                   │
  └───────────────┴───────────────┴───────────────┴───────────────┘
   ↑ context walls = different MEANING   dependencies point DOWN ↓
```

The walls between columns are **context** boundaries (different meaning). The
floors between rows are **layer** boundaries (different dependency rights).

### The dependency rule

One rule governs the layers: **dependencies point down. A lower layer never
names a higher one.**

The single test, no philosophy required: **"Does this object know about
something *above* it?"** A domain object that knows about HTTP, request
parameters, sessions, the current user, or a controller is the violation — the
Domain layer reaching up into Application or UI.

What it rules out, concretely:

- A **domain object referencing request/session/params/current-user or a
  controller** — Domain depending on Application/UI. Pass plain values in.
- A **domain object serializing itself for the wire** — Domain → UI. Serialize
  in the web tier.
- A **persistence callback calling an external service synchronously** — Domain
  reaching into Infrastructure. Enqueue work; let the Application layer dispatch.
- A **controller holding business rules** rather than orchestration —
  Application doing Domain's job. Move the rule to a domain object.
- A **domain object hard-wired to a specific HTTP client or queue SDK** — depend
  on a thin seam (the anti-corruption wrapper), not the vendor directly.

## Behavior goes by KIND, not amount

The question is never "is this class too big?" It's "what **kind** of behavior
is this?" Three kinds, three homes:

| Kind | Lives in | Examples |
|------|----------|----------|
| **Record behavior** | the persistence object — *keep it here* | validation, state/predicate over *this* record's own fields, normalization of its own values |
| **Domain behavior** | a context domain object | decisions *across* records, business policy with its own reason to change (pricing, risk, eligibility), calculations beyond own fields, anything calling an external system |
| **Framework behavior** | wherever the framework wants it (controller / job / mailer / authz) | auth, sessions, background dispatch, authorization — don't isolate these; call *into* the domain object from them |

The deciding question you can answer without philosophy: *"If I deleted this
method, what broke — a fact about this one record, or a business rule?"*
Record-fact → stays on the persistence object. Business rule → domain object.

This places behavior by *kind*; the namespace below records *ownership*. They're
separate decisions — a persistence object can be namespaced into a context and
still carry only record behavior.

## Namespacing follows ownership, not reference

Whether a persistence model gets a context namespace depends on **ownership**,
not on who reads it.

- A model **shared across contexts** with no single owner stays **top-level** —
  namespacing it would lie about who owns it.
- A model **one context owns the write rules for** lives **namespaced under that
  context** — the namespace *is* the ownership label.
- A model a context only **reads** (shared/reference data, or another context's
  entity) stays where its owner puts it. Namespace what the context **owns**, not
  what it consumes.

A **read-model context** reads other contexts' facts and owns *no entities of
its own*. Its natural shape is "queries namespaced, models top-level" — that's
correct **by design**, not a shortcut.

The namespace is an *ownership label*; it says nothing about how much logic the
class carries. Keep an owned persistence class **thin** regardless — domain
behavior still moves to the context's domain objects per the three-kind table.

### Don't shadow a model with a namespace

Never name a sub-namespace the same as a top-level model the context reads. A
`Reporting::Mcc` module that shadows a top-level `Mcc` model forces an escape on
every reference, and a stray lookup silently resolves to the module. Pick the
spelled-out domain term (`Reporting::MerchantCategory`) so the model resolves
cleanly without escapes.

## Naming a context (and its internals)

1. **Use ubiquitous language from the *domain*, not from one customer's
   vocabulary.** If a generic tree node maps to "brands" for one customer and
   "regions" for another, naming the context `Company` or `Region` bakes one
   customer's words into the codebase. Prefer structural names that survive any
   customer remapping.
2. **Backend names may be more abstract than UI labels.** Customer-facing copy
   stays marketable ("Western Region"); the module name just needs to be true to
   the domain. View partials, helper labels, and i18n keys carry the marketing
   voice — the namespace carries the domain.

## The pragmatism clause — the escape valve

Boundary purity is a **default, not a tax.** When isolating a piece of behavior
from the framework or the database would cost more than it returns — at a
framework seam (sessions, auth, background jobs, realtime), a library extension
point, or a callback that genuinely maintains a record invariant — **keep it on
the framework object and move on.** Leave a one-line comment naming what couples
it and why it stays. The boundary is *allowed* to be leaky exactly at framework
seams; that's expected, not a violation.

The signal to *then* extract is **evidence, not principle**: the same policy
duplicated a third time (Rule of Three), or a model growing into a god object
several contexts depend on. Extract when it earns it — never preemptively.
Premature extraction, like the wrong abstraction, is more expensive to undo than
to avoid.

This clause cuts both ways: it stops the purist from ceremony, and it stops the
shortcut of dumping cross-context policy into a god model — because the trigger
(duplication / god-object growth) is concrete, not a matter of taste.

## Step 0 — Load your stack's reference

The two coordinates, the dependency rule, and the three-kind split above are
**portable**. What's **stack-specific** is *which directory a file of a given
type lives in* — because frameworks couple certain file types (controllers,
views, persistence models) structurally to specific paths. Detect the stack and
read the matching appendix once before placing files:

| Signal | Reference |
|--------|-----------|
| `Gemfile` + `config/application.rb` (Rails / ActiveRecord) | `frameworks/rails.md` |

If no reference matches your stack, apply the **generic shape**: pure domain
objects (services, query objects, value objects, domain services) have no
framework coupling — put them in a context-owned directory, namespaced under the
context. Framework-coupled file types (anything the framework locates by
convention — request handlers, view templates, persistence models, background
jobs) stay in their framework-conventional directory, namespaced *within* it
under the context. The rule doesn't change; only the directory names do. (Adding
a `frameworks/<stack>.md` is the way to extend this skill to a new stack.)

## The project's contexts table

The durable rule is here; **each project's own state lives in its
`.claude/bounded_contexts.md`** — the list of contexts, their primary surfaces,
and how far each one's on-disk layout has migrated toward the rule. Read it
first when working in a project: it tells you which contexts exist, which carry
migration debt, and which is the project's canonical worked example.

**If the file is missing, offer to scaffold it** with the thin template below —
state only, since the rule lives in this skill. Fill the table from the actual
codebase (grep the top-level source dirs for existing namespaces), don't invent
contexts:

```markdown
# Bounded Contexts — <project>

> The *rule* for where context code lives is the `my:bounded-contexts` skill.
> This file records only THIS project's state: which contexts exist and how far
> each has migrated toward the rule. New work targets the rule regardless of a
> context's current migration state.

## Contexts

| Context | Primary surfaces | Migration state |
|---------|-----------------|-----------------|
| `<Name>::` | <what it does> | <Migrated (canonical example) / Partial / Not started / Out of scope> |

## Canonical example

<Name the one fully-migrated context to copy the shape from, and link its
migration plan if there is one. Until one exists, say "none yet — first
migration sets the pattern.">

## Migration notes

<Per-context debt worth knowing: what's namespaced, what's scattered, any
context that must not be reorganized without coordinating with its owner.>
```

**New work targets the rule, full stop.** When a feature lands in a context that
still carries migration debt, put the *new* code in the right shape rather than
mirroring the legacy layout. Migrating the existing code can follow on its own
schedule, as a focused change with its own safety-net specs.

## When to escalate beyond this rule

The rule above is the steady state. Two heavier options exist for when it starts
straining — don't reach for them preemptively:

- **A module-boundary enforcement tool** (e.g. Packwerk for Rails) — define
  packages with explicit public APIs and declared dependencies, enforced at the
  linter level. Reach for it when contexts start reaching into each other's
  internals and you want *enforcement*, not just discipline. Signal: "what's the
  public API of this context?" isn't answerable at a glance.
- **A separate deployable per context** (e.g. Rails Engines, a service split) —
  real isolation, real ceremony. Generally overkill for one team on one deploy;
  appropriate when contexts are owned by different teams or need independent
  release cadences.

Default: adopt this rule per new context. Revisit enforcement tooling when
coupling becomes a recurring code-review topic. A deployable split stays off the
table unless team structure changes. The stack appendix names the concrete tools
for that stack.

## Checklist when creating or refactoring a bounded context

- [ ] Context name comes from domain language, not a customer's vocabulary
- [ ] Pure domain objects live in the context-owned directory, namespaced
- [ ] Models the context **owns** are namespaced under it; models it only
      *reads* (shared/reference data, another context's entity) stay where their
      owner puts them
- [ ] Persistence classes stay thin (attributes, persistence, record-level
      behavior); domain behavior lives in the context's domain objects
- [ ] Behavior placed by *kind*, not amount — record → model, domain → domain
      object, framework → controller/job/authz
- [ ] Framework-seam leaks are deliberate and commented, not silent
- [ ] Framework-coupled files (handlers, views, jobs, authz) stay in their
      conventional directories, namespaced
- [ ] Cross-context query objects live at the top level, not inside one context
- [ ] Customer-facing copy may use marketing vocabulary; the namespace and class
      names use domain vocabulary
- [ ] Test paths mirror source paths
- [ ] If renaming an existing context, write tripwire/characterization specs
      *before* the rename
- [ ] The project's `.claude/bounded_contexts.md` reflects the new/changed
      context's migration state

## Anti-patterns

If you catch yourself doing any of these, stop and correct.

| Smell | Fix |
|---|---|
| Reorganizing existing code on the way past a bug fix | The rule fires on *new* nouns, not every edit — leave existing context conventions alone |
| Adding a new domain noun at the root namespace | Decide its owning context first; placement at root is a review block |
| Putting all of a context under one directory, fighting the framework | Framework-coupled files stay in their conventional dirs, namespaced — see the stack appendix |
| Namespacing a model because one context reads it | Namespace by *ownership*, not reference — a read model stays where its owner puts it |
| A sub-namespace shadowing a top-level model it reads | Rename the namespace to the spelled-out domain term |
| Naming a context after one customer's vocabulary | Use structural domain language that survives a customer remap |
| Pushing record-level behavior off the model for purity | Behavior by *kind*: record-facts stay on the model; only cross-record rules move |
| Extracting a domain object "to be clean" before evidence | Extract on the Rule of Three or god-object growth, not principle |
| Isolating a framework seam at high cost for purity's sake | Take the escape valve: keep it on the framework object, comment why |
| Mirroring a context's legacy layout for new code | New work targets the rule; the legacy migration follows separately |
| A domain object that names params/session/request/a controller | Dependency-rule violation — pass plain values in |
| Reaching for Packwerk/Engines before coupling actually hurts | Adopt the rule first; escalate only on a concrete trigger |

## Invocation

- Slash command: `/my:bounded-contexts <the noun or directory you're adding>`
- Natural language: just describe the new domain work — "I'm adding chargeback
  dispute tracking" / "where should this new resolver live?" — and this rule
  applies. It reads (or offers to create) the project's
  `.claude/bounded_contexts.md` for the contexts table, and loads the stack
  appendix for concrete placement.

One-line example trigger:

> "I'm introducing a `Notification` concept with a model, a delivery service,
> and a controller — which context owns it and where does each file go?"
