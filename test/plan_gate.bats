#!/usr/bin/env bats
# Tests for tools/plan-gate. Each test gets a real throwaway git repo (with real
# worktrees) in BATS_TEST_TMPDIR, because the tool reads `git worktree list` and
# `git rev-parse --show-toplevel` rather than anything stubbable.
#
# Assertions go through the helpers below rather than bare `[[ ]]`. Under macOS
# bash 3.2 a failing `[[ ]]` does NOT trip `set -e`, so a bare one anywhere but
# the last line of a test is silently ignored and the test passes regardless.
# The helpers use `case` + `return 1`, which bats does catch.

setup() {
  GATE="$BATS_TEST_DIRNAME/../tools/plan-gate"
  REPO="$BATS_TEST_TMPDIR/repo"
  TREES="$BATS_TEST_TMPDIR/trees"
  mkdir -p "$REPO/.claude/plans" "$TREES"
  cd "$REPO"
  git init -q -b main .
  git config user.email test@example.com
  git config user.name Test
  git commit -q --allow-empty -m init
}

assert_contains() { # haystack needle
  case "$1" in
    *"$2"*) return 0 ;;
  esac
  printf 'expected to contain: %s\n--- actual ---\n%s\n' "$2" "$1" >&2
  return 1
}

refute_contains() { # haystack needle
  case "$1" in
    *"$2"*)
      printf 'expected NOT to contain: %s\n--- actual ---\n%s\n' "$2" "$1" >&2
      return 1
      ;;
  esac
  return 0
}

make_plan() { # name [status]
  if [ -n "${2:-}" ]; then
    printf -- '---\nplan: %s\nstatus: %s\n---\n\n# Plan: %s\n' "$1" "$2" "$1" \
      > "$REPO/.claude/plans/$1.md"
  else
    printf -- '# Plan: %s\n' "$1" > "$REPO/.claude/plans/$1.md"
  fi
}

make_worktree() { # dirname
  git -C "$REPO" worktree add -q -b "$1" "$TREES/$1" main
}

# The copy of a plan that lives inside a worktree — the authoritative one while
# that tree is building it, since promotion happens on the tree's branch.
make_tree_plan() { # tree plan-name status
  mkdir -p "$TREES/$1/.claude/plans"
  printf -- '---\nplan: %s\nstatus: %s\n---\n\n# Plan: %s\n' "$2" "$3" "$2" \
    > "$TREES/$1/.claude/plans/$2.md"
}

# Everything from a section header up to the next one. Lets a test assert *where*
# a plan is reported, not merely that its name appears somewhere in the output.
section() { # output title
  printf '%s\n' "$1" | awk -v title="$2" '
    index($0, "■ " title) == 1 || index($0, "⚠ " title) == 1 { insec = 1; next }
    /^[■⚠]/ { insec = 0 }
    insec
  '
}

@test "list: a queued plan with a live worktree is reported active" {
  make_plan worktree-aging-view queued
  make_worktree worktree-aging-view

  run "$GATE" list
  [ "$status" -eq 0 ]
  assert_contains "$(section "$output" Active)" worktree-aging-view
  refute_contains "$(section "$output" Queued)" worktree-aging-view
}

@test "list: a worktree whose plan is still unpromoted says so" {
  make_plan worktree-aging-view queued
  make_worktree worktree-aging-view
  make_tree_plan worktree-aging-view worktree-aging-view queued

  run "$GATE" list
  assert_contains "$(section "$output" Active)" "still says queued"
}

@test "list: status comes from the worktree's own copy, not this checkout's" {
  make_plan worktree-aging-view queued
  make_worktree worktree-aging-view
  make_tree_plan worktree-aging-view worktree-aging-view active

  run "$GATE" list
  assert_contains "$(section "$output" Active)" worktree-aging-view
  # Promoted in its tree, so it is listed plainly — no stale-file marker at all.
  refute_contains "$(section "$output" Active)" "worktree-aging-view  ·"
}

@test "list: the worktree's copy wins even when it disagrees downward" {
  make_plan stalled queued
  make_worktree stalled
  make_tree_plan stalled stalled blocked

  run "$GATE" list
  assert_contains "$(section "$output" Blocked)" stalled
  refute_contains "$(section "$output" Active)" stalled
}

@test "list: falls back to this checkout when the tree has no copy of the plan" {
  make_plan hero-consistency queued
  make_worktree hero-consistency

  run "$GATE" list
  assert_contains "$(section "$output" Active)" hero-consistency
  assert_contains "$(section "$output" Active)" "still says queued"
}

@test "list: a queued plan with no worktree stays queued" {
  make_plan hero-consistency queued

  run "$GATE" list
  assert_contains "$(section "$output" Queued)" hero-consistency
  refute_contains "$(section "$output" Active)" hero-consistency
}

@test "list: a worktree named for a Linear issue matches its plan" {
  make_plan rep-directory queued
  make_worktree fndr-12-rep-directory

  run "$GATE" list
  assert_contains "$(section "$output" Active)" rep-directory
  refute_contains "$(section "$output" Queued)" rep-directory
}

@test "list: the main checkout is not a worktree that activates a plan" {
  make_plan repo queued

  run "$GATE" list
  assert_contains "$(section "$output" Queued)" repo
  refute_contains "$(section "$output" Active)" repo
}

@test "list: a worktree-derived active plan silences the no-active-plan warning" {
  make_plan worktree-aging-view queued
  make_worktree worktree-aging-view

  run "$GATE" list
  refute_contains "$output" "No active plan"
}

@test "list: warns when two plans are active on disk with no tree to own them" {
  make_plan alpha active
  make_plan beta active

  run "$GATE" list
  assert_contains "$output" "2 plans active"
}

@test "list: two actives do not warn when a live tree owns each" {
  make_plan alpha active
  make_plan beta queued
  make_worktree beta

  run "$GATE" list
  assert_contains "$(section "$output" Active)" alpha
  assert_contains "$(section "$output" Active)" beta
  refute_contains "$output" "plans active"
}

@test "list: a blocked plan with a worktree stays blocked, not active" {
  make_plan stalled blocked
  make_worktree stalled

  run "$GATE" list
  assert_contains "$(section "$output" Blocked)" stalled
  refute_contains "$(section "$output" Active)" stalled
}

@test "list: an explicitly active plan with a worktree is listed once" {
  make_plan solo active
  make_worktree solo

  run "$GATE" list
  [ "$(section "$output" Active | grep -c solo)" -eq 1 ]
  refute_contains "$output" "plans active"
}

@test "list: a shipped plan with a worktree stays shipped, not active" {
  make_plan drained shipped
  make_worktree drained

  run "$GATE" list
  assert_contains "$(section "$output" Shipped)" drained
  refute_contains "$(section "$output" Active)" drained
}

@test "check: still passes when a queued plan has a worktree" {
  make_plan worktree-aging-view queued
  make_worktree worktree-aging-view

  run "$GATE" check
  [ "$status" -eq 0 ]
}

@test "check: still blocks on a shipped plan" {
  make_plan drained shipped

  run "$GATE" check
  [ "$status" -eq 1 ]
  assert_contains "$output" drained
}
