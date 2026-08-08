#!/usr/bin/env bats
# Tests for tools/skill-usage. The tool reads three real things — a git repo of
# skills (creation dates come from `git log --diff-filter=A`), a corpus of
# .jsonl transcripts, and the vocabulary declarations in skill_frontmatter.bats
# — so the fixtures are real files in BATS_TEST_TMPDIR rather than stubs.
#
# `--now` is injected in every test so verdicts don't drift as the wall clock
# moves; without it the tool uses today.
#
# Assertions go through the helpers below rather than bare `[[ ]]`. Under macOS
# bash 3.2 a failing `[[ ]]` does NOT trip `set -e`, so a bare one anywhere but
# the last line of a test is silently ignored and the test passes regardless.

setup() {
  USAGE="$BATS_TEST_DIRNAME/../tools/skill-usage"
  SKILLS="$BATS_TEST_TMPDIR/skills"
  CORPUS="$BATS_TEST_TMPDIR/corpus"
  VOCAB="$BATS_TEST_TMPDIR/vocab.bats"
  NOW=2026-08-08
  mkdir -p "$SKILLS" "$CORPUS"
  cd "$SKILLS"
  git init -q -b main .
  git config user.email test@example.com
  git config user.name Test
  : > "$VOCAB"
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

# A skill directory committed on a given date, so creation date is real history.
make_skill() { # name created-date
  mkdir -p "$SKILLS/$1"
  printf -- '---\nname: %s\ndescription: a test skill\n---\n\n# %s\n' "$1" "$1" \
    > "$SKILLS/$1/SKILL.md"
  git -C "$SKILLS" add "$1/SKILL.md"
  GIT_AUTHOR_DATE="$2T12:00:00" GIT_COMMITTER_DATE="$2T12:00:00" \
    git -C "$SKILLS" commit -q -m "add $1"
}

# One transcript line recording a Skill invocation at a given timestamp.
record_fire() { # name date [session]
  printf '{"type":"assistant","timestamp":"%sT10:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"my:%s"}}]}}\n' \
    "$2" "$1" >> "$CORPUS/${3:-session}.jsonl"
}

# One user-typed prompt in the corpus. Tool-result lines carry an array-valued
# content field and must not count as something the user said.
record_prompt() { # text [session]
  printf '{"type":"user","timestamp":"2026-08-01T10:00:00.000Z","message":{"role":"user","content":"%s"}}\n' \
    "$1" >> "$CORPUS/${2:-session}.jsonl"
}

record_tool_result() { # text [session]
  printf '{"type":"user","timestamp":"2026-08-01T10:00:00.000Z","message":{"role":"user","content":[{"type":"tool_result","content":"%s"}]}}\n' \
    "$1" >> "$CORPUS/${2:-session}.jsonl"
}

declare_vocabulary() { # name phrase...
  local name="$1"; shift
  printf '  assert_keeps_vocabulary %s \\\n' "$name" >> "$VOCAB"
  local phrase
  for phrase in "$@"; do
    printf '    "%s" \\\n' "$phrase" >> "$VOCAB"
  done
  printf '\n' >> "$VOCAB"
}

run_usage() {
  run "$USAGE" --now "$NOW" --skills "$SKILLS" --corpus "$CORPUS" \
    --vocab "$VOCAB" "$@"
}

@test "a skill invoked recently reads as active" {
  make_skill busy 2026-01-01
  record_fire busy 2026-08-05
  record_fire busy 2026-08-06

  run_usage
  assert_contains "$output" busy
  assert_contains "$output" active
  assert_contains "$output" 2026-08-06
}

@test "counts every invocation across separate transcripts" {
  make_skill busy 2026-01-01
  record_fire busy 2026-08-05 one
  record_fire busy 2026-08-06 two
  record_fire busy 2026-08-06 two
  record_fire busy 2026-08-06 two
  record_fire busy 2026-08-06 three
  record_fire busy 2026-08-06 three
  record_fire busy 2026-08-06 three

  # 7 appears nowhere else in these fixtures, so a wrong tally cannot pass.
  run_usage
  assert_contains "$output" "7"
}

@test "a skill younger than the threshold is too new to judge" {
  make_skill newborn 2026-08-06
  record_prompt "unrelated work happening in this session"

  run_usage
  assert_contains "$output" newborn
  assert_contains "$output" "too new"
  refute_contains "$output" "remove"
}

@test "never fired past the threshold, with its trigger words in real prompts, is displaced" {
  make_skill loser 2026-06-01
  declare_vocabulary loser "unattended run" "just go" "mechanical gate"
  record_prompt "set this up as an unattended run please"
  record_prompt "just go ahead and finish it"

  run_usage
  assert_contains "$output" loser
  assert_contains "$output" displaced
}

@test "one trigger phrase is too thin to convict — generic words appear everywhere" {
  make_skill broad 2026-06-01
  declare_vocabulary broad "Artifact" "Playwright" "walkthrough"
  record_prompt "publish that as an Artifact for me"

  run_usage
  assert_contains "$output" broad
  assert_contains "$output" unexercised
  refute_contains "$output" displaced
}

@test "never fired past the threshold with no matching prompts is unexercised, not displaced" {
  make_skill episodic 2026-06-01
  declare_vocabulary episodic "the other repo's agent" "producer/consumer"
  record_prompt "plenty of unrelated work in the corpus"

  run_usage
  assert_contains "$output" episodic
  assert_contains "$output" unexercised
  refute_contains "$output" displaced
}

@test "tool output does not count as something the user said" {
  make_skill episodic 2026-06-01
  declare_vocabulary episodic "producer/consumer"
  record_tool_result "the producer/consumer contract lives here"

  run_usage
  assert_contains "$output" unexercised
}

@test "a skill quiet for months is dormant rather than removable" {
  make_skill seasonal 2025-01-01
  record_fire seasonal 2025-06-01

  run_usage
  assert_contains "$output" seasonal
  assert_contains "$output" dormant
  refute_contains "$output" displaced
}

@test "a skill only ever reached by typing its name is flagged as a command" {
  make_skill typed 2026-01-01
  record_fire typed 2026-08-04
  record_fire typed 2026-08-05
  record_fire typed 2026-08-06
  record_prompt "/my:typed do the thing"
  record_prompt "/my:typed again"
  record_prompt "/my:typed once more"

  run_usage
  assert_contains "$output" typed
  assert_contains "$output" command
}

@test "a single invocation is too small a sample to call a skill typed-only" {
  make_skill once 2026-01-01
  record_fire once 2026-08-05
  record_prompt "/my:once do the thing"

  run_usage
  assert_contains "$output" once
  refute_contains "$output" command
}

@test "a skill the model routes to on its own is not flagged as a command" {
  make_skill routed 2026-01-01
  record_fire routed 2026-08-05
  record_fire routed 2026-08-06

  run_usage
  refute_contains "$output" "command"
}

@test "the threshold is adjustable" {
  make_skill newborn 2026-08-06
  declare_vocabulary newborn "some phrase"

  run "$USAGE" --now "$NOW" --skills "$SKILLS" --corpus "$CORPUS" \
    --vocab "$VOCAB" --weeks 0
  refute_contains "$output" "too new"
}

@test "an empty corpus is reported as no evidence rather than as never fired" {
  make_skill lonely 2026-01-01
  rm -f "$CORPUS"/*.jsonl

  run_usage
  assert_contains "$output" "no transcripts"
}

@test "names the corpus it read, since a skill used on another machine looks dead here" {
  make_skill busy 2026-01-01
  record_fire busy 2026-08-05

  run_usage
  assert_contains "$output" "$CORPUS"
}

@test "a missing corpus directory fails loudly instead of reporting zeros" {
  make_skill lonely 2026-01-01

  run "$USAGE" --now "$NOW" --skills "$SKILLS" --corpus "$BATS_TEST_TMPDIR/nope" \
    --vocab "$VOCAB"
  [ "$status" -ne 0 ]
  assert_contains "$output" "nope"
}
