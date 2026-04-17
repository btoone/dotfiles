# Vitest / Jest (JavaScript / TypeScript)

This file covers both runners. The APIs are near-identical — differences are
called out inline.

## Run

```bash
npx vitest run path/to/file.test.ts              # single file (no watch)
npx vitest run path/to/file.test.ts -t "pattern" # filter by test name
npx vitest run                                   # full suite
npx jest path/to/file.test.ts                    # Jest equivalent
npm test -- path/to/file.test.ts                 # project-scripted
```

Prefer `vitest run` (single run) over watch mode while driving TDD — watch
can mask failures by caching state.

## Paths

Either colocated (`foo.ts` next to `foo.test.ts`) or under `__tests__/`.
Follow the convention already in the repo.

## BDD syntax

```ts
import { describe, it, expect } from 'vitest'; // or 'jest' via globals
import { createTransaction } from './createTransaction';

describe('creating a transaction', () => {
  describe('when amount is zero', () => {
    it('returns a failure', () => {
      const result = createTransaction({ amount: 0 });
      expect(result.ok).toBe(false);
    });
  });
});
```

- Outer `describe` names the capability — `'creating a transaction'`, NOT
  `'createTransaction()'`
- Nested `describe` names the scenario — `'when amount is zero'`
- `it` states the outcome — `'returns a failure'`

## Factories

JS/TS has no de facto standard. Use builder functions:

```ts
// test/factories/transaction.ts
export const aTransaction = (
  overrides: Partial<Transaction> = {},
): Transaction => ({
  id: 'txn_1',
  amount: 100,
  status: 'pending',
  ...overrides,
});
```

Never `new Transaction({...})` or raw object literals in tests when a builder
exists. Add a builder when a type is used in more than one test.

## Framework-specific anti-patterns

| Smell | Fix |
|-------|-----|
| `vi.spyOn(module, 'internalFn')` / `jest.spyOn` on the unit under test | Test the outcome |
| `vi.mock('./sibling')` / `jest.mock` to stub internal modules | Only mock external boundaries (network, FS, time); refactor seams for internals |
| `(obj as any).privateField` / `@ts-ignore` in tests | Assert on the public API |
| `expect(x).toBeTruthy()` as a catch-all | Assert the specific expected value |
| `toEqual` on a whole fixture when one field is under test | Assert the changed field only |
| Snapshot tests for logic (not rendered UI) | Write explicit assertions |
| `useFakeTimers` without `useRealTimers()` in teardown | Reset in `afterEach`; or pass a clock |

## JS/TS idioms for GREEN code

- **Plain functions and data > classes** for domain logic; use classes only
  when identity or lifecycle matters
- **Discriminated unions > booleans** for states:
  `Result<T, E> = { ok: true; value: T } | { ok: false; error: E }`
- Prefer `readonly` + spread-updates over mutation
- Narrow types at the boundary; keep the core strongly-typed
- Accept the smallest interface you need as input; return concrete types
