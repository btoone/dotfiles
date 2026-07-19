#!/usr/bin/env bats
# Tests for tools/agent-board and tools/agent-board-hook.
# tmux and terminal-notifier are PATH-stubbed (test/stubs); board state goes
# to a per-test temp dir via AGENT_BOARD_DIR.

setup() {
  BOARD="$BATS_TEST_DIRNAME/../tools/agent-board"
  HOOK="$BATS_TEST_DIRNAME/../tools/agent-board-hook"
  export AGENT_BOARD_DIR="$BATS_TEST_TMPDIR/board"
  mkdir -p "$AGENT_BOARD_DIR"
  export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"
  export TMUX_STUB_LOG="$BATS_TEST_TMPDIR/tmux.log"
  export NOTIFIER_STUB_LOG="$BATS_TEST_TMPDIR/notifier.log"
  export TMUX_PANE="%1"
}

make_session() { # id pane state
  jq -n --arg id "$1" --arg pane "$2" --arg state "$3" '{
    session_id: $id, cwd: "/tmp/proj", transcript: "", pane: $pane,
    tmux_session: "sess", window_id: "@7", window_name: "win",
    state: $state, reason: "some reason", note: "", on_ice: false,
    updated_at: 1000
  }' > "$AGENT_BOARD_DIR/$1.json"
}

hook_event() { # json
  echo "$1" | "$HOOK"
}

@test "--list orders lanes: permission, answer, working, on-ice, done" {
  make_session done1 %1 done
  make_session work1 %1 working
  make_session perm1 %2 needs-permission
  make_session ans1 %2 needs-answer
  make_session ice1 %1 working
  jq '.on_ice = true' "$AGENT_BOARD_DIR/ice1.json" > "$AGENT_BOARD_DIR/ice1.json.tmp" \
    && mv "$AGENT_BOARD_DIR/ice1.json.tmp" "$AGENT_BOARD_DIR/ice1.json"

  run bash -c "'$BOARD' --list | cut -f3 | tr '\n' ' '"
  [ "$output" = "perm1 ans1 work1 ice1 done1 " ]
}

@test "--list prunes sessions whose pane is gone" {
  make_session alive %1 working
  make_session dead %99 working

  run "$BOARD" --list
  [[ "$output" == *alive* ]]
  [[ "$output" != *dead* ]]
  [ ! -e "$AGENT_BOARD_DIR/dead.json" ]
}

@test "--lines groups sessions under lane headers with counts" {
  make_session ans1 %1 needs-answer
  make_session ans2 %2 needs-answer
  make_session done1 %1 done

  run bash -c "'$BOARD' --lines | tr '\0' '\n' | grep -c '── NEEDS ANSWER (2) ──'"
  [ "$output" = "1" ]
  run bash -c "'$BOARD' --lines | tr '\0' '\n' | grep -c '── DONE (1) ──'"
  [ "$output" = "1" ]
}

@test "a note renders as an indented second line of its record" {
  make_session noted %1 working
  jq '.note = "remember the milk"' "$AGENT_BOARD_DIR/noted.json" > "$AGENT_BOARD_DIR/n.tmp" \
    && mv "$AGENT_BOARD_DIR/n.tmp" "$AGENT_BOARD_DIR/noted.json"

  run bash -c "'$BOARD' --lines | tr '\0' '\n' | grep -c '^     .*📌 remember the milk'"
  [ "$output" = "1" ]
}

@test "--toggle flips on_ice and back" {
  make_session s1 %1 working

  "$BOARD" --toggle s1
  [ "$(jq -r '.on_ice' "$AGENT_BOARD_DIR/s1.json")" = "true" ]
  "$BOARD" --toggle s1
  [ "$(jq -r '.on_ice' "$AGENT_BOARD_DIR/s1.json")" = "false" ]
}

@test "--note attaches to the session in the current tmux window" {
  make_session here %1 working

  run "$BOARD" --note remember the milk
  [ "$(jq -r '.note' "$AGENT_BOARD_DIR/here.json")" = "remember the milk" ]

  run "$BOARD" --note
  [ "$(jq -r '.note' "$AGENT_BOARD_DIR/here.json")" = "" ]
}

@test "stale port registrations are pruned on poke" {
  make_session s1 %1 working
  echo "1" > "$AGENT_BOARD_DIR/.port.stale"

  "$BOARD" --toggle s1
  [ ! -e "$AGENT_BOARD_DIR/.port.stale" ]
}

@test "hook writes board state on UserPromptSubmit" {
  hook_event '{"session_id":"h1","hook_event_name":"UserPromptSubmit","cwd":"/tmp/proj","prompt":"do the thing"}'

  [ -e "$AGENT_BOARD_DIR/h1.json" ]
  [ "$(jq -r '.state' "$AGENT_BOARD_DIR/h1.json")" = "working" ]
  [ "$(jq -r '.tmux_session' "$AGENT_BOARD_DIR/h1.json")" = "sess" ]
  grep -q '@agent_glyph 🔄' "$TMUX_STUB_LOG"
}

@test "hook classifies permission vs input on Notification" {
  hook_event '{"session_id":"h1","hook_event_name":"Notification","cwd":"/tmp/proj","message":"Claude needs your permission to use Bash"}'
  [ "$(jq -r '.state' "$AGENT_BOARD_DIR/h1.json")" = "needs-permission" ]

  hook_event '{"session_id":"h1","hook_event_name":"Notification","cwd":"/tmp/proj","message":"Claude is waiting for your input"}'
  [ "$(jq -r '.state' "$AGENT_BOARD_DIR/h1.json")" = "needs-answer" ]
}

@test "hook raises a clickable notification on Notification events" {
  hook_event '{"session_id":"h1","hook_event_name":"Notification","cwd":"/tmp/proj","message":"Claude is waiting for your input"}'

  grep -q -- '-execute' "$NOTIFIER_STUB_LOG"
  grep -q 'agent-board --jump h1' "$NOTIFIER_STUB_LOG"
}

@test "hook preserves note and on_ice through events, clears on_ice on prompt" {
  make_session h1 %1 working
  jq '.note = "keep me" | .on_ice = true' "$AGENT_BOARD_DIR/h1.json" > "$AGENT_BOARD_DIR/h.tmp" \
    && mv "$AGENT_BOARD_DIR/h.tmp" "$AGENT_BOARD_DIR/h1.json"

  hook_event '{"session_id":"h1","hook_event_name":"PreToolUse","cwd":"/tmp/proj","tool_name":"Bash"}'
  [ "$(jq -r '.note' "$AGENT_BOARD_DIR/h1.json")" = "keep me" ]
  [ "$(jq -r '.on_ice' "$AGENT_BOARD_DIR/h1.json")" = "true" ]

  hook_event '{"session_id":"h1","hook_event_name":"UserPromptSubmit","cwd":"/tmp/proj","prompt":"back"}'
  [ "$(jq -r '.note' "$AGENT_BOARD_DIR/h1.json")" = "keep me" ]
  [ "$(jq -r '.on_ice' "$AGENT_BOARD_DIR/h1.json")" = "false" ]
}

@test "hook syncs window title on PostToolUse without touching board state" {
  make_session h1 %1 working
  transcript="$BATS_TEST_TMPDIR/transcript.jsonl"
  echo '{"type":"custom-title","custom-title":true,"customTitle":"my session title"}' > "$transcript"

  hook_event '{"session_id":"h1","hook_event_name":"PostToolUse","cwd":"/tmp/proj","transcript_path":"'"$transcript"'"}'

  grep -q 'rename-window -t @7 my session title' "$TMUX_STUB_LOG"
  [ "$(jq -r '.updated_at' "$AGENT_BOARD_DIR/h1.json")" = "1000" ]
}

@test "hook removes state and glyph on SessionEnd" {
  make_session h1 %1 working

  hook_event '{"session_id":"h1","hook_event_name":"SessionEnd","cwd":"/tmp/proj"}'

  [ ! -e "$AGENT_BOARD_DIR/h1.json" ]
  grep -q -- '-u @agent_glyph' "$TMUX_STUB_LOG"
}
