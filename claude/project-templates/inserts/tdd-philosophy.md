# TDD Insert

The TDD cycle, BDD conventions, and the testing worldview live in the
`my:tdd` skill and the global CLAUDE.md. They load on demand, in every
project, without being copied anywhere.

So a project does not restate them. It records two things this repo can't
get from the skill: how to run its tests, and the traps its own reviews
have already found.

---

## For the project CLAUDE.md

```markdown
## Tests

<test command>

TDD is non-negotiable — see the my:tdd skill for the cycle and conventions.
Traps specific to this repo live in `.claude/tdd_guidelines.md`.
```

That's the whole section. If the project is shared with people who don't
have the plugin, spell the cycle out in `.claude/tdd_guidelines.md` instead
of pointing at a skill they can't load.

---

## For `.claude/tdd_guidelines.md`

This doc exists for what a *general* TDD skill can never know: the ways
tests in **this** codebase have actually lied. Seed it empty and let review
findings fill it.

Each entry names the trap, where it bites, what goes wrong, and the rule —
with the date and review that found it, so a future reader can judge whether
it still holds:

```markdown
### <Trap name> (found in <review>, <date>)

<Where it bites.> <What goes wrong.> <The rule>, so <consequence avoided>.
```

Good entries look like "upsert traps found in the outreach-agent review,
2026-07-19" — concrete, dated, earned. If an entry could have been written
before the code existed, it belongs in the skill, not here.

**Keep out of this doc:** red-green-refactor, test-behavior-not-
implementation, mock anti-patterns, the bug-fix cycle. All universal, all
already in `my:tdd`. A second copy here is one that drifts — and the drifted
copy is the one the project reads.
