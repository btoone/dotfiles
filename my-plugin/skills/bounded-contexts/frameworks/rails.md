# Bounded Contexts — Rails appendix

Stack-specific placement for Rails / ActiveRecord. The two coordinates, the
dependency rule, and the three-kind split live in `SKILL.md`; this file answers
the Rails-only question: **which directory does a file of a given type live in?**

## The rule, in Rails terms

> **The `Context::` namespace is the organizing principle. Where each file lives
> is determined by what Rails type it is.**
>
> - **Pure-PORO domain code** → `app/<context>/foo.rb` as `Context::Foo`
> - **Rails-typed code** (AR models, controllers, jobs, mailers, helpers,
>   policies, channels) → its Rails-conventional directory, namespaced under the
>   context
>
> Namespace what the context **owns**. A model it only *reads* — shared or
> reference data, or another context's entity — stays where its owner puts it.

The namespace tells you the bounded context. The directory tells you what Rails
type the file is. Reading either gives you half the picture; both gives you the
whole thing.

This is the **modular monolith** pattern Shopify, Gusto, and other Rails shops
at scale land on. It works *with* Rails directory conventions rather than against
them, which keeps generators, gem defaults, view template lookup, and every
other Rails-magic mechanism functioning as designed.

## Why not "everything under `app/<context>/`?"

Rails has *structural* coupling — not just convention — to a handful of
directories:

| Rails type | Coupled to | What breaks if you move it |
|------------|------------|----------------------------|
| Controllers | `config/routes.rb` + `app/controllers/` | View template lookup (`render :show` finds `app/views/<controller_path>/show.html.erb`), helper auto-inclusion, generator scaffolding, Pundit policy inference |
| Views | `app/views/<controller_path>/` | Template lookup mirrors the controller's path; not overridable cleanly |
| AR models | `app/models/` by convention | Factory paths, schema annotations, every gem that infers locations from `Model.where`, fixture conventions, every Rails dev's mental model |
| Mailers, jobs, channels | Their respective dirs | Same convention friction as controllers |
| Pundit policies | `app/policies/` by gem default | Pundit's policy resolver |

You can *namespace within* those directories (`app/models/disputes/case.rb` →
`Disputes::Case`), but you can't lift a Rails-typed file out without fighting the
framework. The rule embraces that constraint rather than fighting it.

Pure POROs (services, query objects, value objects, domain services, form
objects, decorators, presenters) have no such coupling. Zeitwerk autoloads them
from wherever you tell it, so they live in the context-owned directory cleanly.

## Working with Rails, not against it

This layout is **pragmatic, Rails-flavored DDD** — not Clean Architecture. We
take Evans (bounded contexts, ubiquitous language, aggregates) and deliberately
*decline* the purism often layered on top: "the framework is a detail, the
database is a detail, keep all behavior out of the model." On a Rails team that
purism has two costs:

- It **fights the framework's grain.** Rails *is* the Active Record pattern
  (Fowler, *PoEAA*): the object that wraps a row is meant to carry behavior about
  that row. Forcing every method off it produces an **Anemic Domain Model** (also
  Fowler — an anti-pattern, not a goal) plus a parallel PORO hierarchy shadowing
  every table. That's ceremony.
- It **isn't always worth it.** Sessions, Devise, Turbo/StimulusReflex,
  ActiveJob, Pundit, gem extension points — that's Rails earning its keep.
  Isolating the domain from them costs more than it returns.

So: embrace Rails as the substrate. Use the bounded context to keep *domain
decisions* from sprawling — not to hide the framework.

### Why an AR model doesn't break the dependency rule

An AR model straddles Domain and Infrastructure — the row-mapping is
Infrastructure, the record behavior is Domain. The classical layered
prescription is to physically split them (the repository pattern). We don't. The
layer boundary *inside* an AR object stays conceptual: keep record behavior on
the model, push only cross-record business decisions to POROs, and the
dependency rule holds without a parallel persistence hierarchy.

### The database is not fully a detail in Rails

We decline the repository pattern that hides ActiveRecord behind pure domain
entities — a tax most Rails shops correctly skip. What we *do* take seriously is
the **schema as a deliberate domain artifact** (expand/contract migrations,
strong_migrations). Query objects and value objects are where DB isolation pays
for itself; everywhere else, AR-coupled-to-the-row is fine.

## Namespacing an owned AR model is nearly free

`Loyalty::PointsLedger` maps to the `points_ledgers` table automatically (Rails
infers from the demodulized name unless you define
`Loyalty.table_name_prefix`), so the schema stays clean and the namespace lives
only in Ruby. The only friction is small:

- cross-context associations need an explicit `class_name:`
- polymorphic / STI `*_type` columns store the full namespaced path

Keep the namespaced AR class **thin** regardless — attributes, associations,
persistence, record-level behavior. Domain behavior moves to the context's POROs
per the three-kind table in `SKILL.md`.

## Concrete shape for a new bounded context

A `Disputes::` context laid out by the rule:

```
app/disputes/                          # pure domain — POROs only
├── chargeback_classifier.rb           # Disputes::ChargebackClassifier (service)
├── case.rb                            # Disputes::Case (value object)
├── case_lifecycle.rb                  # Disputes::CaseLifecycle (domain service)
├── deadline_calculator.rb
└── reconciliation.rb                  # Disputes::Reconciliation (invariant checker)

app/models/disputes/                   # AR models the context OWNS, namespaced
└── case_record.rb                     # Disputes::CaseRecord < ApplicationRecord

app/controllers/disputes/              # controllers, namespaced (URL-bound)
└── cases_controller.rb                # Disputes::CasesController

app/views/disputes/cases/              # view paths follow controller paths
└── show.html.erb

app/jobs/disputes/
└── classify_chargeback_job.rb         # Disputes::ClassifyChargebackJob

app/policies/disputes/
└── case_policy.rb                     # Disputes::CasePolicy
```

Test files mirror the source paths:

```
spec/disputes/                         # PORO specs
spec/models/disputes/                  # AR model specs
spec/requests/disputes/                # controller request specs (Rails convention)
spec/jobs/disputes/
spec/policies/disputes/
```

## A read-model context

A read-model context reads other contexts' facts and owns *no entities of its
own*, so every file in it is a PORO (query objects, value objects, domain
services, config). Its whole body lives cleanly under `app/<context>/`, and the
models it reads stay top-level. "Queries namespaced, models top-level" is its
shape **by design**:

```
app/reporting/
├── kpi_query.rb                       # Reporting::KpiQuery
├── config.rb                          # Reporting::Config
├── subtree/                           # a sub-grouping within the context
│   ├── kpi_query.rb                   # Reporting::Subtree::KpiQuery
│   └── leaderboard_query.rb
└── node/
    ├── kpi_query.rb                   # Reporting::Node::KpiQuery
    └── heatmap_query.rb
```

The controllers, views, and helpers that drive such a context stay in their
Rails-conventional directories (`app/controllers/`, `app/views/<name>/`,
`app/helpers/`) — the web tier orchestrates the domain without belonging to it.

## `app/queries/` is reserved for cross-context queries

A query object that belongs to one bounded context lives **inside** that context
— `app/disputes/case_history_query.rb` as `Disputes::CaseHistoryQuery`, not
`app/queries/disputes/case_history_query.rb`.

`app/queries/` is reserved for *generic*, cross-context query objects consumed by
multiple contexts (e.g. a `PeriodOnPeriodQuery` used by several surfaces). No
single context owns them, so they live at the top level.

When in doubt: does the query make sense outside this context? Yes →
`app/queries/`. No → the context.

## When to escalate (Rails-specific tooling)

- **[Packwerk](https://github.com/Shopify/packwerk)** — Shopify's gem for
  defining packages with explicit public APIs, declared dependencies, and
  boundary enforcement at the linter level. Composes naturally with this rule.
  Reach for it when contexts routinely reach into each other's internals and you
  want enforcement, not just discipline.
- **Rails Engines** — a full mini-Rails-app per context
  (`engines/reporting/app/...`). Heavy commitment, real isolation, real
  ceremony. Generally overkill for a single team on a single deploy; appropriate
  when contexts are owned by different teams or need independent release
  cadences.
