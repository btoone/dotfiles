#!/usr/bin/env bats
# Guards the skill-listing routing surface: the `description` and `when_to_use`
# frontmatter of every my-plugin skill, which loads into every session at
# startup and is what the model routes on.
#
# These tests cannot prove routing works — that is the model's job, not a shell
# script's. What they own is narrower and still worth having: that a trim never
# silently drops the vocabulary routing depends on, and that the surface does
# not grow back once trimmed.

setup() {
  # Overridable so the vocabulary tests can be mutation-checked against a
  # perturbed copy of the tree.
  SKILLS="${MY_PLUGIN_SKILLS:-$BATS_TEST_DIRNAME/../my-plugin/skills}"
  # Ratchet, not an aspiration: lower it as skills get trimmed, never raise it.
  BUDGET=12209
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

@test "skill listing: total routing surface stays within the recorded budget" {
  local total
  total="$(routing_surface_chars)"

  [ "$total" -le "$BUDGET" ] || {
    echo "routing surface is $total chars, budget is $BUDGET"
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
