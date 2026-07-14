# Minitest (Ruby)

Rails' default test framework. Works in Spec style (`describe`/`it`) or
classic style (class-based `test "..."` blocks). **Match whichever style the
codebase already uses** — neither is preferred in the abstract. Classic style
is the Rails default and the safer choice in Rails apps: the base
`ActiveSupport::TestCase` has no `let`, and a top-level `describe` block runs
without fixture access.

## Run

```bash
bin/rails test test/path/file_test.rb:LINE   # single test by line
bin/rails test test/path/file_test.rb        # one file
bin/rails test                               # full suite
bundle exec rake test                        # non-Rails projects
ruby -Itest test/path/file_test.rb -n /pattern/   # filter by name regex
```

## Paths

`test/` mirrors `app/` and `lib/`. A class at
`app/services/transactions/create.rb` has its test at
`test/services/transactions/create_test.rb`.

## Spec style (when the codebase uses it)

```ruby
require 'test_helper'

describe Transactions::Create do
  describe 'creating a transaction' do
    it 'returns a failure when amount is zero' do
      result = Transactions::Create.new(amount: 0).call
      _(result).must_be :failure?
    end
  end
end
```

- `describe` names a capability — `'creating a transaction'`, NOT `'#call'`
- `it` states the outcome including scenario — `'returns a failure when amount is zero'`
- Minitest/Spec has no `context` — fold the scenario into the `it` name, or
  nest another `describe`

## Classic style (Rails default)

```ruby
class TransactionCreationTest < ActiveSupport::TestCase
  test 'returns a failure when amount is zero' do
    result = Transactions::Create.new(amount: 0).call
    assert_predicate result, :failure?
  end
end
```

The BDD principles still apply — the `test '...'` string names the outcome,
not the method.

## Factories and fixtures

**Match what the codebase already uses.** Rails ships with fixtures and many
suites standardize on them (shared personas like `users(:rep)`); others use
FactoryBot for per-test variation. Don't introduce the missing one into a
suite that has settled on the other.

```ruby
users(:rep)                      # fixture persona
create(:transaction, amount: 0)  # FactoryBot, when the suite uses it
```

Either way, never `Transaction.new` or `Transaction.create!` inline in a test
when the suite's helper covers it — add the missing fixture or factory instead.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| `obj.stubs(:internal_method)` (Mocha) on the unit under test | Test the outcome |
| `obj.expects(:internal_method)` on internals | Test observable state |
| `assert_instance_of Klass, obj` | Assert on behavior, not type |
| `assert obj.send(:private_method)` | Test through the public interface |
| `Time.now`/`Date.today` in code under test, or stubbed in a test | `Time.current`/`Date.current` (zone-aware); freeze with `travel_to` — see Flaky tests |
| Asserting on fixture IDs | Query by domain attribute |
| Leaking state via `@ivar` from `setup` into assertions | Set up via factories in each test; avoid hidden state |

## Multi-write units (ActiveRecord)

When one action writes several rows, wrap it in `ApplicationRecord.transaction`
— `save!` raising rolls back nothing already committed. Three traps in the
rollback test and the implementation:

- **Vacuous fail-on-first stubs** — a rollback test that fails the *first*
  write passes even without a transaction. Fail a *later* record so an
  earlier record's committed write is what proves the rollback.
- **`ActiveRecord::Rollback` swallowed in nested transactions** — a nested
  `transaction` block absorbs it silently (it's not re-raised past the
  innermost block unless `requires_new: true` with savepoints). Prefer
  raising a real error, or explicit compensation like `destroy!`.
- **Asserting over an association the action just emptied** — capture the
  records in a local before the action; afterwards the association may be
  empty or stale and the assertion loops over nothing.

## Flaky tests

Two families cause almost all flakes. Fix them at the source — never paper over
a flake with a retry; a flake is a false negative that makes every red ambiguous.

**Clock & date flakes (any test level).** A test asserting over a *relative
window* — `this_month`, `last_30_days`, "next 14 days", "this week",
days-in-stage — fails at month/week/day boundaries unless time is frozen. Freeze
with `travel_to`, and pick a **mid-window instant at noon** so a day's or hour's
drift can't cross a boundary:

```ruby
travel_to Time.zone.local(2026, 6, 15, 12) do
  # fixtures and assertions now share one fixed "now"
end
```

Fixtures dated relative to today (`close_date: <%= Date.today + 30 %>`) are a
trap — they're evaluated at load time and can land past a boundary. Prefer fixed
dates and freeze the clock, or derive fixture dates from the same frozen `now`.

**Browser races (system tests).** Never read DOM state synchronously after a
JS-driven change — `el.checked?`, `el.text`, `el.value`, `all(...)` are one-shot
snapshots that don't wait. Use Capybara's auto-waiting matchers:

```ruby
toggle_all.check
assert_selector "tbody input[type=checkbox]:checked", count: lead_count  # waits
# not: all("…").each { |cb| assert cb.checked? }                         # snapshot
```

After a Turbo form submit, assert the destination (`assert_current_path`) — it
waits — rather than reading the next page synchronously.

## Ruby idioms for GREEN code

- **POROs over framework objects** when persistence, callbacks, or
  associations aren't needed
- No trailing `if`/`unless` on complex lines — use explicit guard clauses
- Prefer `Result` objects over raising for expected failure paths
- Keyword arguments beyond a single positional parameter
