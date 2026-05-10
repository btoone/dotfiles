# pytest (Python)

Default to `pytest` — it is the de facto standard and works for plain Python,
Django, FastAPI, and Flask projects. Fall back to stdlib `unittest` only if
the project clearly uses it (no `pytest` in deps, `unittest.TestCase`
subclasses everywhere).

## Run

```bash
pytest path/to/test_file.py                      # one file
pytest path/to/test_file.py::test_name           # one test
pytest path/to/test_file.py -k "pattern"         # filter by name substring
pytest                                           # full suite
pytest -x                                        # stop on first failure
pytest --lf                                      # rerun last failures only
python -m pytest ...                             # when pytest isn't on PATH
uv run pytest ...                                # uv-managed projects
poetry run pytest ...                            # poetry-managed projects
python -m unittest path.to.test_module           # stdlib fallback
```

Avoid `-q` / `-s` while driving TDD — full output makes failures legible.

## Paths

`tests/` mirrors the source tree, or test files colocated as `test_foo.py`
next to `foo.py`. Follow whichever layout already exists. Test files are
`test_*.py`; test functions are `test_*`. `conftest.py` holds shared fixtures
for everything in its directory and below.

## BDD syntax

pytest has no `describe`/`it`. Express BDD via the test function name and
nested classes for scenarios.

```python
# tests/test_transactions.py
from app.transactions import create_transaction


class TestCreatingATransaction:
    class TestWhenAmountIsZero:
        def test_returns_a_failure(self):
            result = create_transaction(amount=0)
            assert result.ok is False

    class TestWhenAmountIsPositive:
        def test_persists_the_record(self, transaction_repo):
            create_transaction(amount=100)
            assert transaction_repo.count() == 1
```

- Outer class names the capability — `TestCreatingATransaction`, NOT
  `TestCreateTransaction`
- Nested class names the scenario — `TestWhenAmountIsZero`
- Test function states the outcome — `test_returns_a_failure`
- Read top-down, the path reads as a sentence: *creating a transaction, when
  amount is zero, returns a failure*

Plain functions are fine too when there is no scenario to nest:

```python
def test_creating_a_transaction_returns_a_failure_when_amount_is_zero():
    ...
```

Use parametrize to express a table of scenarios cleanly:

```python
import pytest

@pytest.mark.parametrize(
    "amount, expected_ok",
    [
        pytest.param(0, False, id="when amount is zero"),
        pytest.param(100, True, id="when amount is positive"),
    ],
)
def test_creating_a_transaction(amount, expected_ok):
    assert create_transaction(amount=amount).ok is expected_ok
```

`id=` strings become the scenario name in test output — write them as prose.

## Factories

Prefer a factory library over raw constructors:

- `factory_boy` — most common, integrates with Django/SQLAlchemy
- `polyfactory` — pydantic / dataclass / attrs friendly
- Plain builder function when the project has no factory dep

```python
# tests/factories.py
import factory
from app.transactions import Transaction

class TransactionFactory(factory.Factory):
    class Meta:
        model = Transaction
    id = factory.Sequence(lambda n: f"txn_{n}")
    amount = 100
    status = "pending"
```

```python
def test_resolving_a_dispute():
    txn = TransactionFactory(status="disputed")
    ...
```

Builder-function fallback when no factory lib is in use:

```python
def a_transaction(**overrides) -> Transaction:
    defaults = dict(id="txn_1", amount=100, status="pending")
    return Transaction(**{**defaults, **overrides})
```

Never `Transaction(...)` directly in tests when a factory or builder exists.
Add one as soon as a type is constructed in more than one test.

## Fixtures

`pytest` fixtures replace `setUp`/`tearDown`. Keep them small and composable;
put shared ones in `conftest.py` at the right scope (`function` is the
default; use `module`/`session` only for genuinely expensive setup).

```python
# tests/conftest.py
import pytest

@pytest.fixture
def transaction_repo():
    return InMemoryTransactionRepo()
```

Don't hide assertions inside fixtures — fixtures arrange, tests assert.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| `mocker.patch('app.module.internal_fn')` on the unit under test | Test the outcome |
| `unittest.mock.patch.object(self, '_private')` | Test through the public interface |
| `obj._private_field` / name-mangled `_Class__attr` access in tests | Assert on the public API |
| `assert result` as a catch-all | Assert the specific value (`assert result.ok is False`) |
| `assert x == y` on a whole object when one field is under test | Assert the changed field only |
| `freezegun` / `time.sleep` to coordinate timing | Inject a clock; use `freeze_time` only at boundaries |
| `monkeypatch` on internal helpers | Refactor a seam; only patch external boundaries |
| `pytest.mark.skip` left in committed code | Delete the test or fix it |
| Fixtures with side effects that aren't reset between tests | Scope to `function`; clean up via `yield` teardown |
| `assertRaises` without checking the message/type specifically | `pytest.raises(SpecificError, match="...")` |
| Snapshot tests (`syrupy`) for pure logic | Write explicit assertions; reserve snapshots for rendered output |

## Python idioms for GREEN code

- **Plain functions and dataclasses > classes with state** for domain logic;
  reach for a class only when identity or lifecycle matters
- **Type hints on public APIs** — `def create_transaction(amount: int) -> Result`
- Prefer **explicit return types** (`Result`, `dataclass`, `TypedDict`) over
  tuples or dicts for multi-field returns
- **Sum-type-ish results** via `dataclass` + a discriminator field, or a
  union of small dataclasses, beat boolean flags for state
- Use **`pathlib.Path`** over string paths; **`datetime.datetime` aware**
  (with tz) over naive
- Raise specific exceptions (`ValueError`, custom domain errors) — never bare
  `Exception`. Don't catch what you can't handle
- Keep modules small and seam-friendly; inject collaborators rather than
  importing them inside functions
- For async code: `pytest-asyncio` with `@pytest.mark.asyncio`; never call
  `asyncio.run` inside a test body
