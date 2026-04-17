# Minitest (Ruby)

Rails' default test framework. Works in Spec style (BDD, preferred here) or
Test/Unit style (class-based). Match whichever style the codebase already uses.

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

## BDD syntax (Minitest/Spec — preferred)

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

## Classic style (acceptable when the codebase uses it)

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

## Factories

FactoryBot works with Minitest — prefer it over Rails fixtures for
behavioral tests. Fixtures are fine for reference data that rarely varies.

```ruby
create(:transaction, amount: 0)
build(:transaction, amount: 0)
```

Never `Transaction.new` or `Transaction.create!` in a test when a factory exists.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| `obj.stubs(:internal_method)` (Mocha) on the unit under test | Test the outcome |
| `obj.expects(:internal_method)` on internals | Test observable state |
| `assert_instance_of Klass, obj` | Assert on behavior, not type |
| `assert obj.send(:private_method)` | Test through the public interface |
| Stubbing `Time.now` directly | `travel_to` / `freeze_time` from `ActiveSupport::Testing::TimeHelpers` |
| Asserting on fixture IDs | Query by domain attribute |
| Leaking state via `@ivar` from `setup` into assertions | Set up via factories in each test; avoid hidden state |

## Ruby idioms for GREEN code

- **POROs over framework objects** when persistence, callbacks, or
  associations aren't needed
- No trailing `if`/`unless` on complex lines — use explicit guard clauses
- Prefer `Result` objects over raising for expected failure paths
- Keyword arguments beyond a single positional parameter
