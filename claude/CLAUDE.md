# Coding Philosophy

These preferences shape how I think about software. Apply them when writing code, suggesting designs, reviewing PRs, or making tradeoffs.

---

## Domain First, Framework Second

Code should model the business domain. Frameworks, databases, and infrastructure are implementation details that serve the domain — not the other way around.

**Eric Evans' Domain-Driven Design** is the foundation:

- **Ubiquitous Language** — Code uses the same terms the business uses. If the domain says "chargeback," the code says `Chargeback`, not `DisputeTypeThree`. When naming diverges from business language, fix the code.
- **Bounded Contexts** — A `Transaction` in the Visa Draft 256 context is not the same as a `Transaction` in the API context. Respect these boundaries rather than forcing a single model to serve every context.
- **Entities vs Value Objects** — Entities have identity (`Transaction` with an ID). Value objects are defined by their attributes (`Money`, `Address`, `DateRange`) and should be immutable. Default to value objects when identity doesn't matter.
- **Aggregates** — Enforce consistency boundaries. External access goes through the aggregate root. Don't reach into an aggregate's internals.
- **Anti-Corruption Layer** — When integrating external systems (Visa, TSYS, payment processors), translate their model into ours. Their naming and structure should not leak into the domain.
- **Domain Services** — When an operation doesn't belong to an entity or value object, use a service named in domain language. Keep it stateless.

**POROs over framework objects.** If it doesn't need persistence, callbacks, or associations, it shouldn't inherit from `ApplicationRecord`. Service objects, value objects, policy objects, query objects, form objects — these are all plain Ruby classes. POROs are faster to test, easier to understand, and have explicit dependencies.

---

## Behavior-Driven Development

Tests describe what the system does, not how it's built. This comes from Steven R. Baker's RSpec philosophy and Dan North's BDD: specs are living documentation written in domain language.

- `describe` blocks name capabilities, not methods
- `context` blocks describe scenarios, not implementation states
- `it` blocks state expected outcomes, not assertions about internals
- The spec output should read like a behavioral specification a domain expert could follow

The TDD cycle (red/green/refactor) is non-negotiable — it's a design tool, not just a verification tool.

---

## Simplicity Over Cleverness

### Extract after it's clear

Do not create abstractions until you have enough evidence. Sandi Metz: "Duplication is far cheaper than the wrong abstraction." The Rule of Three (Don Roberts, via Fowler's *Refactoring*): first time, just write it; second time, note the similarity; third time, now extract — because now you know what actually varies.

### Patterns when earned

Gang of Four patterns (Strategy, Adapter, Decorator, etc.) are tools, not goals. Apply them when the existing code clearly needs the flexibility they provide. Three similar lines of code is better than a premature abstraction. "Program to an interface, not an implementation" and "favor composition over inheritance" are principles to internalize, not patterns to force.

### Optimize with evidence

Donald Knuth: "Premature optimization is the root of all evil." Kent Beck's ordering applies: **make it work, make it right, make it fast** — and fast comes last, only with profiling evidence. The bottleneck is almost never where you think it is. Write clear, correct code first. Measure. Then optimize the proven bottleneck.

---

## Clean Code Principles

Robert C. Martin's SOLID principles, applied with Ruby pragmatism:

- **Single Responsibility** — A class has one reason to change. One stakeholder, one axis of change.
- **Open/Closed** — Extend behavior without modifying existing code. In Ruby, this often means composition and duck typing over conditionals.
- **Liskov Substitution** — Subtypes must be substitutable for their base types. If it quacks like a duck, it must behave like a duck.
- **Interface Segregation** — Don't force objects to implement methods they don't use. Ruby's duck typing helps here naturally — depend on the methods you call, nothing more.
- **Dependency Inversion** — High-level domain logic should not depend on low-level infrastructure. Inject dependencies; don't hardcode class names.

Functions should be small, do one thing, and have names that reveal intent. If you need a comment to explain what code does, the code isn't clear enough.

### Style Preferences

- **No trailing guards on long lines** — Don't sneak `unless` or `if` onto the end of a complex line. Use an explicit guard clause or block instead. Trailing guards are fine on short, simple lines.
- **Manage dependencies at the boundary** — External dependencies (APIs, workers, services) should be easy to isolate in tests. Prefer designs where collaborators are accessible through simple, stubbable seams — whether that's a wrapped method, a constructor default, or a method argument depends on context. The goal is testability without reaching into internals.
- **Favor declarative style, use imperative when it earns its place** — Default to expressing *what things are* rather than *what to do*. Most code should describe structure, relationships, and rules declaratively. Reserve imperative control flow (guard clauses, early returns, step-by-step sequencing) for the edges — where you're orchestrating actions or handling exceptional cases. When imperative style makes the intent clearer than a declarative alternative would, use it without apology.

  This aligns with how Eric Evans draws the line in DDD: the domain model (entities, value objects, specifications, scopes) should be declarative — describing rules, relationships, and constraints. Application services and orchestration layers are where imperative style lives — coordinating actions, enforcing sequence, handling edge cases. Evans advocates "declarative design" in the domain precisely because it keeps the model readable as a specification of the business. The imperative mechanics belong at the boundaries.

  **Example — declarative domain, imperative orchestration:**
  ```ruby
  # Declarative: describes what a shipping policy is
  class ShippingPolicy
    THRESHOLDS = { standard: 5_00, express: 20_00 }.freeze

    def initialize(order)
      @order = order
    end

    def free?       = @order.total >= THRESHOLDS.fetch(tier)
    def tier        = @order.priority ? :express : :standard
    def estimate    = ShippingCalculator.rate_for(tier, @order.weight)
  end

  # Imperative: orchestrates what to do at checkout
  def finalize_shipment(order)
    policy = ShippingPolicy.new(order)
    return notify_warehouse(order) if policy.free?

    charge = collect_shipping(order, policy.estimate)
    return handle_payment_failure(order) unless charge.success?

    notify_warehouse(order)
  end
  ```
  The policy reads like a specification — what shipping *is* for this order. The method reads like a recipe — guard, act, handle failure, proceed. Both are clear; each uses the style that fits.

---

## Continuous Delivery Mindset

Dave Farley and Jez Humble's *Continuous Delivery*: every commit should be releasable. Nicole Forsgren's *Accelerate* research proved there is no tradeoff between speed and stability — the best teams are both faster and more stable.

The DORA metrics that matter:
1. **Deployment Frequency** — deploy often, in small batches
2. **Lead Time for Changes** — commit to production, fast
3. **Mean Time to Restore** — recover quickly when things break
4. **Change Failure Rate** — keep it low through testing and automation

This means: small commits, fast feedback, automated testing, trunk-based development, and expand-and-contract migrations. Build quality in rather than inspecting it out.

---

## Pragmatic Development

Dave Thomas' *Pragmatic Programmer* principles:

- **DRY** — Every piece of *knowledge* has a single authoritative representation. This is about knowledge duplication, not code deduplication — don't DRY up code that's similar by coincidence.
- **Orthogonality** — Components should be independent. Changing one shouldn't ripple through others.
- **Tracer Bullets** — Build thin end-to-end slices first, then flesh them out. Not prototypes (which you throw away) — real code, skeletal but functional.
- **Reversibility** — Don't commit to decisions you can't undo. Isolate volatile decisions behind abstractions.
- **Good Enough Software** — Know when to stop. Perfection is the enemy of delivery.

---

## Influences

These are the people whose thinking shaped these preferences. When making design tradeoffs, their collective wisdom is the lens:

| Person | Key Contribution |
|--------|-----------------|
| **Eric Evans** | Domain-Driven Design — ubiquitous language, bounded contexts, aggregates |
| **Kent Beck** | TDD, xUnit, Extreme Programming — "make it work, make it right, make it fast" |
| **Martin Fowler** | Refactoring, evolutionary design, code smells, PoEAA |
| **Dave Farley** | Continuous Delivery, deployment pipelines, modern software engineering |
| **Dave Thomas** | The Pragmatic Programmer, DRY, tracer bullets, Ruby advocacy |
| **Robert C. Martin** | Clean Code, SOLID principles, Clean Architecture |
| **Steven R. Baker** | RSpec, behavior-driven development in Ruby |
| **Nicole Forsgren** | Accelerate, DORA metrics — evidence that speed and stability aren't tradeoffs |
| **Gang of Four** | Design Patterns — composition over inheritance, program to interfaces |
| **Thoughtworks (early era)** | CI/CD, evolutionary architecture, agile as practice not process |
