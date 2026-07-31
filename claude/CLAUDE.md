# Coding Philosophy

These rules shape all code I write, review, or design. Each is stated tersely here; the rationale, worked examples, and reference tables behind them live in the **my:design-philosophy** skill — load it when making design tradeoffs, structuring or naming new code, or reviewing a design.

## Domain first, framework second

- Model the business domain; frameworks, databases, and infrastructure are implementation details that serve it.
- Ubiquitous language: code uses the business's terms (`Chargeback`, not `DisputeTypeThree`); fix naming that diverges.
- Respect bounded contexts — the same noun means different things in different contexts (my:bounded-contexts skill covers placement).
- Default to immutable value objects when identity doesn't matter; external access goes through aggregate roots.
- Translate external systems' models at an anti-corruption layer; their naming must not leak into the domain.
- POROs over framework objects: no persistence, callbacks, or associations → no `ApplicationRecord`.

## Tests

- The TDD cycle (red/green/refactor) is non-negotiable — a design tool and a feedback loop. BDD conventions (describe capabilities, contexts as scenarios, outcomes not internals) live in the my:tdd skill.
- Test at the public boundary that owns the claim; don't test what another layer owns; never extract a function just to test it.
- Fakes over mocks: verify state ("was it saved?"), not interactions ("was `.save()` called?"); never spy on internal collaborators.
- Effects are ports: inject the clock and other effects; introduce a port only when behavior must swap.
- Coverage measures execution, mutation testing measures detection — at RED, pick the example a subtly-wrong implementation would fail.
- Test data via factories: complete valid objects with per-test overrides; no shared mutable setup state.

## Simplicity

- Extract after it's clear: Rule of Three — duplication is cheaper than the wrong abstraction.
- Patterns when earned: three similar lines beat a premature abstraction; composition over inheritance.
- Make it work, make it right, make it fast — optimize last, only with profiling evidence.

## Clean code

- SOLID, applied with Ruby pragmatism. Small functions, one job, intent-revealing names.
- Make illegal states unrepresentable — model with structures that can't hold invalid combinations.
- No trailing guards on long lines — use an explicit guard clause (trailing guards are fine on short, simple lines).
- Manage dependencies at the boundary — collaborators reachable through simple, stubbable seams.
- Declarative domain, imperative orchestration: the model reads as a specification of the business; step-by-step control flow lives at the edges.
- Name with nouns; an "-er" class (`Resolver`, `Manager`, `Processor`) is a prompt to ask what noun or entity behavior it's hiding — not a verdict.
- Default to **no comment** — names and structure carry the meaning. One earns its place only for a non-obvious WHY or a gotcha the code can't show; if the comment exists because a name is unclear, fix the name instead. Never restate what the code already says. The **my:comments** skill holds the full rules — load it when auditing the comments in a changeset.

## Delivery

- Every commit releasable: small commits, trunk-based development, expand-and-contract migrations. Speed and stability aren't a tradeoff.
- Plans are temporary artifacts, not documentation: a written plan lives at `<repo root>/.claude/plans/<feature>.md`, committed, with frontmatter `status: active | queued | blocked | shipped` (at most one `active` **per working tree** — parallel worktrees may each own one; new plans start `queued`). The moment its last phase/PR lands, set `status: shipped` — that arms the pre-push gate — then route anything durable out (my:capture-learnings) and delete the file. Never archive a plan; git history is the archive.

## Pragmatic

- DRY is about knowledge, not code — don't merge coincidental similarity.
- Keep components orthogonal; build tracer bullets (thin end-to-end slices of real code) first; keep decisions reversible; know when good enough ships.
