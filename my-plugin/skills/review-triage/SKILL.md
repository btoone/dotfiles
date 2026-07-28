---
name: review-triage
description: >
  Reformat the findings of a just-run code review into a decision-ready triage
  report. Takes the findings already in the conversation — a ReportFindings
  call, a JSON array, or a prose list — and groups them by recommended action:
  fix now / judgment call / skip. Use AFTER /code-review or any review that
  produced a findings list, when the user wants output they can act on.
  Triggers: "triage the findings", "reformat the review output", "which of
  these should I fix".
---

# Review triage

Turn a pile of findings into a short list of decisions. The review already did
the analysis — your job is to arrange it so every item arrives pre-judged and
the user only has to agree or veto.

## Source

Use the most recent findings in this conversation: a `ReportFindings` tool
call's arguments, a JSON array of finding objects, or a prose findings list —
whichever appeared last. If args name a file, Read it and treat its contents
as the findings. If you can find no findings at all, say so and stop — never
run a review yourself.

Preserve every finding. Reformatting must not silently drop items; if two
findings are duplicates, present them as one and say so.

## Sizing

For each finding, briefly Read the cited `file:line` neighborhood — just
enough to sketch the fix and size it Small / Medium / Large. This is a skim,
not a re-review: do not hunt for new problems, do not verify the claim, do
not edit anything.

## Grouping

Sort every finding into exactly one bucket, by recommendation:

- **Fix now** — verified or self-evident, real breakage, and the fix is cheap
  relative to the damage. CONFIRMED correctness/regression findings with a
  Small fix land here by default.
- **Judgment call** — real but arguable: PLAUSIBLE (unverified) claims,
  behavior changes the user may have intended, or fixes whose cost rivals
  their benefit. Say what fact or preference the decision hinges on.
- **Skip** — speculative, cosmetic, or not worth the churn. Skipping needs a
  stated reason too; "low impact" alone is not one.

Every item gets a recommendation and a reason. Never present a finding
neutrally — that just hands the analysis back to the user.

## Output

Plain markdown in the conversation — do not call ReportFindings, do not write
a file unless args ask for one. Number findings consecutively across all
buckets so "fix 1 3 5" is unambiguous. Per finding:

```
## Review triage — 10 findings: 4 fix now, 3 judgment calls, 3 skip

### Fix now

**1. `tools/agent-board:32`** — prune treats a failed tmux call as "no sessions"
- Breaks when: tmux server restarts mid-poll → every state file deleted
- Fix: guard on list-panes exit status before pruning (Small)

### Judgment call

**5. `tools/agent-board-hook:14`** — blocked-session alert lost outside tmux
- Hinges on: do you ever run Claude outside tmux and want banners there?
- Fix if yes: fall back to bare terminal-notifier without the jump (Small)

### Skip

**8. `tools/agent-board-hook:35`** — poke_board runs synchronously per event
- Why skip: adds ~10ms to hook; no user-visible latency reported. Revisit
  only if hooks feel slow.

### Decide

Reply `fix 1 2 3 4` (the fix-now set), or adjust the numbers.
```

Keep each finding to three lines or fewer. The failure scenario stays concrete
(inputs → wrong outcome), the fix sketch stays one line, and the whole report
should fit on one screen for a typical review.

## Handoff

When the user replies with a fix set, you become the fix orchestrator — you
do not edit code in this session. The reviewers were fresh agents; keep the
fixers fresh too, and keep this session at the altitude of briefs, diffs, and
gates.

1. **Brief.** For each chosen finding (or a coherent group touching the same
   code), write a self-contained fix brief: file:line, the concrete failure
   scenario, the fix sketch, and the first failing test to write. Put briefs
   where the project keeps in-flight work (the active plan file's follow-ups,
   else a triage file under the plans directory) — a brief must make sense to
   an agent with none of this session's context.
2. **Delegate.** Spawn a fresh implementer subagent per slice with the brief
   as its spec, following the project's TDD skill if one exists. Slices with
   disjoint file sets may run in parallel, each warned off the others' files.
3. **Verify.** Review each diff yourself between slices. Re-run the project's
   gates yourself before reporting — never accept an implementer's "green".
4. **Escalate.** A judgment-call finding whose hinge question is still
   unanswered goes back to the user — never to an implementer to guess.
5. **Ship.** The session that makes the shipping push owns the plan's
   lifecycle. If the repo keeps plan files (`.claude/plans/`) and the active
   plan has no unfinished phase left once the accepted fixes land, walk its
   Finishing flow before pushing — set `status: shipped`, route durable
   learnings out (my:capture-learnings), delete the file, commit — exactly as
   `my:continue-plan` specifies. The implementing session is gone by now;
   never leave a completed plan `active` for a session that no longer exists.

Exception: a purely mechanical fix the finding already fully specifies (typo,
stale comment, dead line) may be applied inline; anything that changes
behavior gets a fresh implementer.
