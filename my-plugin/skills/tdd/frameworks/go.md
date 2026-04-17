# Go (standard `testing` + table-driven subtests)

## Run

```bash
go test ./path/to/pkg                           # one package
go test ./path/to/pkg -run TestCreateTransaction            # one test (regex)
go test ./path/to/pkg -run TestCreateTransaction/when_amount_is_zero  # subtest
go test ./...                                   # full module
go test -race ./...                             # with race detector (preferred in CI)
go test -count=1 ./...                          # defeat test caching
```

## Paths

`foo_test.go` lives next to `foo.go` in the same package. `foo_test.go` files
declared as `package foo_test` (external) test the public API only — prefer
this for behavioral tests. Internal (`package foo`) tests are for unexported
helpers.

## BDD via table-driven subtests

Go has no `describe`/`it`. Express BDD via function names and `t.Run`
subtests whose names read as scenarios.

```go
func TestCreatingATransaction(t *testing.T) {
    tests := []struct {
        name   string // scenario in prose
        amount int
        wantOk bool
    }{
        {"when amount is zero", 0, false},
        {"when amount is positive", 100, true},
    }
    for _, tc := range tests {
        t.Run(tc.name, func(t *testing.T) {
            got := CreateTransaction(tc.amount)
            if got.OK != tc.wantOk {
                t.Errorf("OK = %v, want %v", got.OK, tc.wantOk)
            }
        })
    }
}
```

- Outer test name = capability — `TestCreatingATransaction`, NOT `TestCreate`
- Subtest name = scenario in prose — `"when amount is zero"`
- Failure messages state observed vs expected — `"OK = %v, want %v"`

## Factories

Test helpers that build valid fixtures. Always call `t.Helper()` so failures
point at the caller.

```go
func newTestTransaction(t *testing.T, opts ...func(*Transaction)) *Transaction {
    t.Helper()
    tx := &Transaction{Amount: 100, Status: "pending"}
    for _, opt := range opts {
        opt(tx)
    }
    return tx
}
```

Avoid raw struct literals in tests when a helper exists. Use
`testify/require` for fail-fast setup assertions, `testify/assert` for
behavioral checks — or plain `t.Fatal`/`t.Errorf` if the project is
dependency-light.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| Adding an interface only to mock an internal collaborator | Refactor the boundary, or test the real thing |
| `reflect` to poke at unexported fields | Test through exported API; use an internal test file if genuinely needed |
| Test helper without `t.Helper()` | Add `t.Helper()` so the failure points at the test body |
| `require.NoError(t, err)` then re-checking `err` later | Let `require` fail fast; don't re-check |
| `if got != want { t.Errorf(...) }` with no `%v` context | Format the actual and expected values |
| Sharing a fixture across `t.Parallel()` subtests | Build per-subtest via the helper |
| `time.Now()` called directly in code under test | Inject a clock at the boundary |
| Goroutines leaked across tests | Use `t.Cleanup` to cancel contexts / close channels |

## Go idioms for GREEN code

- **Zero values are meaningful** — design so the zero value is a valid state
  where possible
- **Errors as values**, not exceptions — return `(T, error)`; don't panic for
  expected failures
- **Accept interfaces, return structs** — define interfaces at the consumer,
  not the producer
- Prefer small packages with clear seams over deep hierarchies
- `context.Context` is the first parameter on any I/O-bound function
