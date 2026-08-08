# Design: <producer> → <consumer> <interface>

Status: IN DESIGN — no decisions AGREED yet.
<!-- When every decision is signed: "SETTLED <date> — all decisions (D1–Dn) AGREED;
     implementation beginning on both sides. Contract changes discovered during
     implementation come back here as new decisions ([tag] is gatekeeper)." -->

TURN: [<tag>]

## What this document is

A shared design surface for two agents working the same problem from opposite
ends:

- **[<producer-tag>]** — works in `<abs path>` (<stack>). Owns the producer
  side: <what it owns>.
- **[<consumer-tag>]** — works in `<abs path>` (<stack>). Owns the consumer
  side: <what it owns>.

Both agents read and edit this file directly at `<abs path to this file>`.
Turns pass by `SendMessage` between the two live sessions; resolve the peer's
name with `ListAgents` at run time — do not record a session name here.

**[<consumer-tag>] is gatekeeper and holds final say.**

### How to collaborate in this file

1. **Sign everything.** Prefix contributions with your tag and the date.
2. **Never delete or rewrite the other party's words.** To disagree, add a
   signed reply under theirs, or move a decision back to OPEN with a note.
3. **The Decisions table is the source of truth.** Move an item to AGREED only
   when *both* tags have signed off in the Discussion log. PROPOSED means one
   side has put it forward; OPEN means unresolved or reopened.
4. **Edit the spec sections in place** (contract, payloads, vocabulary) once a
   change is AGREED; while it is merely PROPOSED, describe it in the log.
5. **Append new Discussion log entries at the bottom** so the log reads
   chronologically.
6. **Update `TURN:` and message the peer** when your round is done. Set it to
   the human, and stop, when a ruling is needed rather than a technical answer.
7. This file is committed in the `<repo>` repo, so git history is the audit
   trail. Commit after a substantive round of edits.

---

## Background

<Why this interface exists. What each side already has. What the human wants to
be able to do once it works — the questions the data has to answer.>

---

## Decisions

| # | Decision | Status | Proposed by |
| --- | --- | --- | --- |
| D1 | <one line, stated as the rule it establishes> | PROPOSED | [<tag>] |

---

## Contract draft

<!-- Only AGREED material lands here. This section is the thing both sides
     implement against, so everything in it must be settled. -->

### Endpoint

### Payloads

### Vocabulary

---

## Prerequisites / work orders

**[<producer-tag>] side** (in `<abs path>`):

1. <task, citing the decisions it implements>

**[<consumer-tag>] side** (in `<abs path>`):

1. <task, citing the decisions it implements>

---

## Open questions

- **Q1** ([<asker>] → [<answerer>]): <question, with the asker's suggested
  answer and why it matters>
  <!-- Resolve in place: "— RESOLVED <date>: <answer>." Never delete. -->

---

## Discussion log

*(Append new entries at the bottom. Sign and date every entry.)*

**<date> [<tag>]** — <round>
