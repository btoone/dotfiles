# RSpec (Ruby)

## Run

```bash
bin/rspec spec/path/file_spec.rb:LINE   # single example by line
bin/rspec spec/path/file_spec.rb        # one file
bin/rspec                               # full suite
bundle exec rspec ...                   # when bin/ wrappers are absent
```

## Paths

`spec/` mirrors `app/` and `lib/`. A class at
`app/services/transactions/create.rb` has its spec at
`spec/services/transactions/create_spec.rb`.

## BDD syntax

```ruby
RSpec.describe Transactions::Create do
  describe 'creating a transaction' do
    context 'when amount is zero' do
      it 'returns a failure' do
        result = described_class.new(amount: 0).call
        expect(result).to be_failure
      end
    end
  end
end
```

- `describe` names a capability — `'creating a transaction'`, NOT `'#call'`
- `context` names a scenario — `'when amount is zero'`, NOT `'with valid params'`
- `it` states the outcome — `'returns a failure'`

## Factories

Use FactoryBot:

```ruby
create(:transaction, amount: 0)    # persisted
build(:transaction, amount: 0)     # in-memory
build_stubbed(:transaction)        # persistence stubbed
```

Never `Transaction.new` or `Transaction.create!` in a spec when a factory
exists. Add missing factories to `spec/factories/`.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| `expect(obj).to receive(:internal_method)` | Test the outcome (return value, state change) |
| `allow(obj).to receive(:internal_method).and_return(...)` on the unit under test | Set up real inputs instead |
| `obj.send(:private_method)` in a spec | Test through the public interface |
| `obj.instance_variable_get(:@x)` | Assert on observable state |
| Asserting on `described_class::CONSTANT` | Test behavior that uses the constant |
| `Time.now`/`Date.today` in code under test, or stubbed in a spec | `Time.current`/`Date.current` (zone-aware); freeze with `travel_to` — see Flaky tests |
| `let!` with side-effectful setup across many examples | Prefer `before` with explicit intent |

## Flaky tests

Two families cause almost all flakes. Fix them at the source — never paper over
a flake with a retry; a flake is a false negative that makes every red ambiguous.

**Clock & date flakes (any spec level).** A spec asserting over a *relative
window* — `this_month`, `last_30_days`, "next 14 days", "this week",
days-in-stage — fails at month/week/day boundaries unless time is frozen. Freeze
with `travel_to`, and pick a **mid-window instant at noon** so a day's or hour's
drift can't cross a boundary:

```ruby
travel_to Time.zone.local(2026, 6, 15, 12) do
  # factories and assertions now share one fixed "now"
end
```

Factory traits or fixtures dated relative to today (`close_date: Date.today + 30`)
are a trap — they can land past a boundary. Prefer fixed dates and freeze the
clock, or derive dates from the same frozen `now`.

**Browser races (feature/system specs).** Never read DOM state synchronously
after a JS-driven change — `el.checked?`, `el.text`, `el.value`, `all(...)` are
one-shot snapshots that don't wait. Use Capybara's auto-waiting matchers:

```ruby
toggle_all.check
expect(page).to have_selector("tbody input[type=checkbox]:checked", count: lead_count)
# not: all("…").each { |cb| expect(cb).to be_checked }  # snapshot, no wait
```

After a Turbo form submit, assert the destination (`have_current_path`) — it
waits — rather than reading the next page synchronously.

## Ruby idioms for GREEN code

- **POROs over framework objects** when persistence, callbacks, or
  associations aren't needed — a service object inheriting from nothing is
  lighter than one inheriting from `ApplicationRecord`
- No trailing `if`/`unless` guards on complex lines — use explicit guard clauses
- Prefer `Result` objects over raising for expected failure paths
- Keyword arguments for anything with more than one parameter
