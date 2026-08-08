---
name: agent-contract
description: >
  Negotiate an interface between two agents working it from opposite ends — a
  producer and a consumer in separate repos — through one shared signed design
  doc, turns passed over SendMessage. Covers the document skeleton, the
  OPEN/PROPOSED/AGREED decision lifecycle, naming one side gatekeeper with final
  say, escalating to the human, and reopening a settled contract. Use when two
  repos must agree on a contract and each has its own agent session: "design the
  contract with the other repo's agent", "get the two agents to agree on the
  payload", a producer/consumer API, an ingestion format, or an event schema
  crossing a repo boundary. Do NOT use for one agent's autonomy on a task
  (that's handoff) or for subagents inside one session.
---

# Agent Contract

Two agents, two repos, one interface between them. Each knows its own side in
detail and the other side only by guess. The failure mode isn't disagreement —
it's both sides implementing confidently against incompatible assumptions and
finding out at integration.

The fix is a single document both agents write into, where a decision isn't
real until both have signed it. The doc is the durable record; everything else
here is transport.

## Setting up

**Two tags.** One per agent, in square brackets, tied to a working directory
and a one-line ownership claim:

```
- **[outreach-agent]** — works in `/Users/brandon/code/agents` (TypeScript).
  Owns the producer side: prospect data, milestone derivation, the push run.
- **[sales_board]** — works in `/Users/brandon/code/sales_board` (Rails).
  Owns the consumer side: the endpoint, the anti-corruption layer, reporting.
```

Every contribution to the doc is prefixed with a tag and a date, forever. An
unsigned edit is indistinguishable from the other side agreeing to it.

**One home repo.** The live doc lives in the producer's repo and is committed
there — git history becomes the audit trail of the negotiation, which is the
whole reason not to keep it in `/tmp`. The consumer repo gets a *snapshot* once
the design settles, stamped with where it came from:

```
> **Snapshot** — copied 2026-07-19 from `~/code/agents/docs/design/x.md`
> at commit `77ffc26`. The live contract stays in the agents repo; this copy
> preserves the finished design. Do not edit — contract changes happen in the
> original as new numbered decisions.
```

**Name a gatekeeper.** One side gets final say, and it should be whichever side
owns the side effects — the one that has to *do* something with the data, not
the one that merely sends it. Record the designation in the doc when it's made.

Start from `template.md` in this skill directory.

## Passing the turn

Both agents run as live Claude sessions, one per repo. Turns pass by message;
the doc carries the substance.

1. Write your round into the doc. Commit it.
2. `ListAgents` to find the peer session. **Resolve the name at run time — never
   hardcode a session name or `[ref]` into the doc.** Sessions are recreated
   constantly; a stored ref is stale the moment it's written.
3. `SendMessage` a *pointer*, not the argument: which decisions moved, and where
   to read them.

```
Round 4 is in docs/design/sales-board-ingestion.md at HEAD.
D23 PROPOSED, D24 AGREED, Q7 answered. Your turn.
```

**Never put substance only in the message.** A message isn't in git and the
other side can't cite it. If it matters, it's in the doc, and the message says
where.

**Never ask the peer to run something your own session was denied.** Permission
decisions are per-session; routing a blocked action through the other agent
launders the user's refusal. Blocked work goes back to your own user.

**When the peer isn't live**, either arm a `Monitor` on the file and keep
working, or fall back to the human relaying between sessions — both are
legitimate; the protocol doesn't depend on the transport.

```
Monitor: git -C <repo> log --oneline -1 -- <doc> in a poll loop
```

**Escalation is a turn, too.** Set the turn to the human and stop, rather than
guessing:

```
TURN: brandon (ruling needed on D21 — scope call, not a technical one)
```

Automating routine turns is what makes rounds cheap. It must not automate away
the moment where the human rules — in practice the biggest calls come from
there, and they arrive as directives the gatekeeper then records.

## Decisions

The decisions table is the source of truth. Prose in the log is argument;
the table is what was settled.

| Status | Meaning |
|---|---|
| `OPEN` | Unresolved, or reopened after a signed objection |
| `PROPOSED` | One side has put it forward; the other hasn't signed |
| `AGREED` | **Both** tags have signed off in the discussion log |

Numbered `D1…Dn`, never renumbered — later rounds append. A decision that
supersedes an earlier one says so in its own text (`Supersedes D14's v1 scope`)
rather than editing D14 into something it never said.

Open questions get the same treatment: `Q1…Qn`, addressed from one tag to the
other, resolved **in place** with the date and answer rather than deleted. A
deleted question looks like one nobody asked.

**Edit the spec sections in place only once a decision is AGREED.** While it's
merely PROPOSED it lives in the discussion log. This is what keeps the middle of
the document trustworthy: if it's written in the contract section, it's settled.

**Never delete or rewrite the other side's words.** To disagree, add a signed
reply beneath theirs, or move a decision back to `OPEN` with a note.

## Using the gatekeeper role

The gatekeeper rules when a decision needs to land and the sides don't converge.
It is not a license to skip the protocol — proposals, signed replies, and the
audit trail all still stand. A ruling is marked as one:

```
**D20 — the fix, ruled AGREED as gatekeeper** (it is a correctness prerequisite
of the already-agreed D17, and your D19 argument is the justification): […]
If this creates a real problem on your side, reply and I'll reopen it.
```

Two things make that work: the ruling states *why* it was needed, and it leaves
the door open. A gatekeeper that rules often has stopped negotiating.

## Ending, and reopening

The doc ends with a per-side **work orders** section — a numbered task list for
each tag — so the negotiation produces two executable briefs rather than an
agreement nobody can act on. Hand each side its own list; `my:handoff` covers
turning one into an unattended run.

Mark the status `SETTLED <date>` when every decision is AGREED.

Then expect to reopen it. Implementation and post-implementation review both
surface questions the design never decided, and they belong in the same document
as new numbered decisions — not a new doc, which would strand the history. A
settled contract reopening is normal; that's why the decision numbers never get
reused.
