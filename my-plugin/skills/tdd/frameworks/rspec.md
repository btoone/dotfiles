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
| Stubbing `Time.now` / `Date.today` directly | Use `ActiveSupport::Testing::TimeHelpers` (`travel_to`) |
| `let!` with side-effectful setup across many examples | Prefer `before` with explicit intent |

## Ruby idioms for GREEN code

- **POROs over framework objects** when persistence, callbacks, or
  associations aren't needed — a service object inheriting from nothing is
  lighter than one inheriting from `ApplicationRecord`
- No trailing `if`/`unless` guards on complex lines — use explicit guard clauses
- Prefer `Result` objects over raising for expected failure paths
- Keyword arguments for anything with more than one parameter
