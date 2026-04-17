# Bats (Bash)

Bats-core plus the `bats-support` / `bats-assert` helper libraries is the
standard stack. Install via git submodules under `test/test_helper/` or
`brew install bats-core bats-assert bats-support`.

## Run

```bash
bats test/foo.bats                          # one file
bats test/foo.bats --filter "pattern"       # filter by test name regex
bats test/                                  # full suite
bats --print-output-on-failure test/        # easier debugging of failures
```

## Paths

`test/*.bats` or `tests/*.bats`. Shared helpers in `test/test_helper.bash`.
Fixture scripts under `test/fixtures/`.

## BDD syntax

Bats has no `describe`/`it` nesting. Encode the capability, outcome, and
scenario in a single `@test` name.

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    PATH="$PWD/bin:$PATH"
}

@test "creating a transaction: persists a record when amount is positive" {
    run create_transaction --amount 100
    assert_success
    assert_output --partial "persisted"
}

@test "creating a transaction: returns failure when amount is zero" {
    run create_transaction --amount 0
    assert_failure
    assert_output --partial "amount must be positive"
}
```

- Test name = `"capability: outcome when scenario"` — one line, since Bats
  has no nesting
- Always invoke the unit under test with `run` — it captures `$status` and
  `$output` and prevents abort-on-failure
- Prefer `assert_success` / `assert_failure` / `assert_output` from
  `bats-assert` over raw `[ ]` checks — the failure messages are far better

## Fixtures

Helper functions in `test_helper.bash`:

```bash
make_config_file() {
    local path="$BATS_TEST_TMPDIR/config"
    cat > "$path" <<EOF
amount=${1:-100}
EOF
    echo "$path"
}
```

Always write to `$BATS_TEST_TMPDIR` — never `$HOME` or the project tree.
Bats cleans the tmpdir after each test automatically.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| Calling the command directly instead of `run cmd` | Use `run` — direct calls lose `$status` and abort on non-zero |
| `[ "$output" = "exact entire output" ]` | `assert_output --partial "stable fragment"` — exact output is brittle |
| Unquoted `"$output"` / `"$status"` in `[[ ]]` | Quote every expansion |
| Writing to `$HOME` or project dirs | Use `$BATS_TEST_TMPDIR` |
| `eval`-ing test inputs | Quote and pass as arguments |
| Reading `$?` after `run` | Use `$status` — `$?` is clobbered by `run` |
| Teardown that depends on command success | Use `|| true` on cleanup or rely on tmpdir |
| Asserting on log line count rather than content | Assert the specific observable output |

## Bash idioms for GREEN code

- `set -euo pipefail` at the top of every script under test
- Quote every variable expansion — `"$var"`, `"${arr[@]}"`
- Prefer `[[ ]]` over `[ ]` for string and path comparisons
- Functions over duplicated snippets (Rule of Three still applies)
- Fail loudly early: validate arguments at the top of each function; prefer
  a `die()` helper over silent `return 1`
- Prefer `local` for every function-scoped variable
