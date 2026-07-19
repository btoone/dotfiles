---
name: headless-tui
description: Drive and debug interactive terminal UIs (fzf pickers, TUIs, REPL prompts) headlessly from an agent session using script(1) ptys and timed keystroke pipes - use when you cannot press the keys yourself. Triggers - a TUI "flashes and disappears", an fzf binding or keybinding "does nothing", behavior differs inside a popup vs direct CLI, or any change to an interactive tool needs verification without asking the user to test it.
---

# Headless TUI Debugging

Agents can't press keys in an interactive UI — but `script(1)` allocates a real
pty, and a timed pipe of keystrokes stands in for the human. This turns "please
try it and tell me what happened" into a reproducible test you run yourself.

## The core pattern

```bash
{ sleep 1.5; printf '\x0e'; sleep 1.5; printf 'hello\r'; sleep 1.5; printf '\x1b'; sleep 0.5; } \
  | gtimeout 15 script -q transcript.out <the-interactive-command> >/dev/null 2>&1
```

Anatomy:
- **`script -q file cmd`** (macOS syntax) runs `cmd` in a pty; the UI believes it
  has a terminal. `transcript.out` captures everything drawn — inspect it with
  `/bin/cat -v` (raw `cat` may be aliased to bat, and ANSI bytes will confuse it).
- **The `{ sleep; printf; ... }` pipe** is the human: each `sleep` gives the UI
  time to render before the next "keystroke". Start with generous delays (1–2s);
  flaky results usually mean a sleep is too short.
- **`gtimeout`** (coreutils) is the seatbelt: a TUI waiting for input it never
  gets will otherwise hang your shell until the harness kills it. Without a
  timeout, one wrong keystroke costs you a 2-minute tool-call timeout.
- Run **concurrent instances** with `&` + `wait` to test multi-instance behavior
  (port registrations, lock files, live-reload fan-out).

Common keystroke bytes: `\r` enter · `\x1b` esc · `\x1b[B` down · `\x1b[A` up ·
ctrl-X is X&0x1f (`\x0e` ctrl-n, `\x13` ctrl-s, `\x14` ctrl-t).

## Verify by side effect, not by screen

The transcript is for diagnosing rendering; **assertions belong on side effects**:
after the scripted run, check the state file / output file / process list that
the interaction should have mutated. A saved note, a toggled flag, a created
port file — those are unambiguous. Screen-scraping the pty transcript is a last
resort.

## Isolate before you integrate

If a flow fails end-to-end, first drive the inner command alone (e.g. the
sub-fzf an `execute(...)` binding spawns). If it works in isolation, the bug is
in the integration: environment, cursor position, field extraction, stdin
inheritance. Real example: an fzf board's ctrl-n "flashed and did nothing" —
the editor was fine in isolation; the pty run of the full board revealed the
cursor opened on an unselectable header row, so `{3}` expanded to empty and the
action no-op'd. One scripted run distinguished hypotheses that log-reading
could not.

## Design for it

When building interactive tools, add non-interactive subcommands (`--list`,
`--lines`, `--preview <id>`) that expose the data the UI renders. They make the
tool testable without a pty at all — reserve the pty harness for the genuinely
interactive parts (bindings, focus, nested pickers).
