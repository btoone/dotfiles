#!/usr/bin/env bats
# Guards the skill-listing routing surface: the `description` and `when_to_use`
# frontmatter of every my-plugin skill, which loads into every session at
# startup and is what the model routes on.
#
# These tests cannot prove routing works — that is the model's job, not a shell
# script's. What they own is narrower and still worth having: that a trim never
# silently drops the vocabulary routing depends on, that every skill is covered
# by such a check, and that the surface does not grow back once trimmed.
#
# The per-skill term lists are hand-authored on purpose. Nothing in the tree can
# derive that someone looking for data-lineage types "source of truth" — that is
# a judgment about how people ask, and it gets edited when the judgment changes.

setup() {
  # Overridable so the coverage and detection checks can run against a
  # synthetic tree instead of mutating the real one.
  SKILLS="${MY_PLUGIN_SKILLS:-$BATS_TEST_DIRNAME/../my-plugin/skills}"
  # Ratchet, not an aspiration: lower it as skills get trimmed, never raise it.
  BUDGET=9039
  # How far the budget may sit above the real surface before it has gone slack.
  SLACK=200
}

# Whitespace-normalized description + when_to_use for one skill, or for every
# skill when called with no argument.
routing_surface() {
  python3 - "$SKILLS" "${1:-}" <<'PY'
import glob, os, re, sys

skills_dir, only = sys.argv[1], sys.argv[2]
pattern = os.path.join(skills_dir, only or '*', 'SKILL.md')
for path in sorted(glob.glob(pattern)):
    frontmatter = open(path).read().split('\n---', 1)[0]
    for key in ('description', 'when_to_use'):
        found = re.search(
            r'^' + key + r':(.*?)(?=^[a-zA-Z][a-zA-Z0-9_-]*:|\Z)',
            frontmatter, re.M | re.S)
        if found:
            value = re.sub(r'^\s*>\s*', ' ', found.group(1), count=1)
            print(' '.join(value.split()))
PY
}

# Characters, not bytes — these descriptions are full of em dashes, and `wc -c`
# would count each as three.
routing_surface_chars() {
  routing_surface "${1:-}" |
    python3 -c 'import sys; print(sum(len(line.rstrip("\n")) for line in sys.stdin))'
}

# Fails naming every missing term, so a trim that drops one says which.
assert_keeps_vocabulary() { # skill term...
  local skill="$1"; shift
  local text missing=()
  text="$(routing_surface "$skill")"

  local term
  for term in "$@"; do
    [[ "$text" == *"$term"* ]] || missing+=("$term")
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "$skill dropped trigger vocabulary: ${missing[*]}"
    return 1
  fi
}

# Skills this file declares a vocabulary check for.
skills_with_vocabulary_test() {
  grep -oE 'assert_keeps_vocabulary [a-z][a-z-]*' "$BATS_TEST_FILENAME" |
    awk '{print $2}' | sort -u
}

@test "skill listing: total routing surface stays within the recorded budget" {
  local total
  total="$(routing_surface_chars)"

  [ "$total" -le "$BUDGET" ] || {
    echo "routing surface is $total chars, budget is $BUDGET"
    false
  }
}

@test "skill listing: the recorded budget stays tight against the real surface" {
  local total drift
  total="$(routing_surface_chars)"
  drift=$(( BUDGET - total ))

  [ "$drift" -le "$SLACK" ] || {
    echo "budget $BUDGET sits $drift chars above the actual $total — a budget"
    echo "this slack has stopped ratcheting; re-baseline it down to $total"
    false
  }
}

@test "skill listing: every skill declares a non-empty routing surface" {
  local dir skill empty=()
  for dir in "$SKILLS"/*/; do
    skill="$(basename "$dir")"
    [ "$(routing_surface_chars "$skill")" -gt 0 ] || empty+=("$skill")
  done

  [ "${#empty[@]}" -eq 0 ] || {
    echo "skills with no description or when_to_use: ${empty[*]}"
    false
  }
}

@test "skill listing: every skill is covered by a vocabulary test" {
  local declared dir skill uncovered=()
  declared="$(skills_with_vocabulary_test)"

  for dir in "$SKILLS"/*/; do
    skill="$(basename "$dir")"
    grep -qx -- "$skill" <<<"$declared" || uncovered+=("$skill")
  done

  [ "${#uncovered[@]}" -eq 0 ] || {
    echo "skills with no vocabulary test: ${uncovered[*]}"
    echo "a skill without one has no floor — the budget test alone rewards gutting it"
    false
  }
}

@test "vocabulary check: fails, naming the term, when a declared term is missing" {
  run assert_keeps_vocabulary trim-context "phrasing no description contains"

  [ "$status" -eq 1 ]
  [[ "$output" == *"trim-context dropped trigger vocabulary"* ]]
  [[ "$output" == *"phrasing no description contains"* ]]
}

@test "maintenance-tasks: keeps the vocabulary a task request routes on" {
  assert_keeps_vocabulary maintenance-tasks \
    "app/tasks" "backfill" "ORDER BY" "no_collection" "not batching"
}

@test "bounded-contexts: keeps the vocabulary a placement question routes on" {
  assert_keeps_vocabulary bounded-contexts \
    "first failing spec" "bounded context" "top-level source directory" \
    "query object" "namespaced" "bounded_contexts.md" "frameworks/"
}

@test "trim-context: keeps the vocabulary a context-trimming request routes on" {
  assert_keeps_vocabulary trim-context \
    "CLAUDE.md" "session start" "trim/audit context" "skill descriptions" \
    "capture-learnings" "audit-memory"
}

@test "data-lineage: keeps the vocabulary a provenance question routes on" {
  assert_keeps_vocabulary data-lineage \
    "source of truth" "stop updating" "which table feeds" "file:line" \
    "reconciliation" "cutover"
}

@test "comments: keeps the vocabulary a comment-writing request routes on" {
  assert_keeps_vocabulary comments \
    "doc comment" "let the code speak" "audit the comments we added" \
    "changeset" "gotcha"
}

@test "capture-learnings: keeps the vocabulary a wrap-up request routes on" {
  assert_keeps_vocabulary capture-learnings \
    "CLAUDE.md" "ADR" "auto-memory" "remember this" \
    "capture what we learned" "wrap up"
}

@test "design-philosophy: keeps the vocabulary a design-tradeoff question routes on" {
  assert_keeps_vocabulary design-philosophy \
    "design tradeoff" "how should I model this" "Rule of Three" "SOLID" \
    "DDD" "coding philosophy"
}

@test "brain-maintenance: keeps the vocabulary a note-wiring request routes on" {
  assert_keeps_vocabulary brain-maintenance \
    "Obsidian" "wiki links" "backlinks" "index.md" "log.md" \
    "link this note up" "lint-brain"
}

@test "feature-guide: keeps the vocabulary a shareable-writeup request routes on" {
  assert_keeps_vocabulary feature-guide \
    "Artifact" "Playwright" "screenshot" "walkthrough" "non-technical"
}

@test "review-triage: keeps the vocabulary a post-review request routes on" {
  assert_keeps_vocabulary review-triage \
    "triage the findings" "/code-review" "ReportFindings" "fix now" \
    "reformat the review output"
}

@test "handoff: keeps the vocabulary an autonomy question routes on" {
  assert_keeps_vocabulary handoff \
    "unattended" "just go" "plan mode" "mechanical gate" "autonomous"
}

@test "headless-tui: keeps the vocabulary a terminal-UI debugging request routes on" {
  assert_keeps_vocabulary headless-tui \
    "fzf" "TUI" "keybinding" "script(1)" "flashes and disappears"
}

@test "tdd: keeps the vocabulary an implementation request routes on" {
  assert_keeps_vocabulary tdd \
    "TDD" "BDD" "add a spec" "TDD this" "go ahead"
}
