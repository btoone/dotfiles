# TDD Philosophy Insert

Copy this section into your CLAUDE.md for any project. Adapt the test framework references to your stack.

---

## 🚨 CRITICAL: Test-Driven Development is Non-Negotiable

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written
in response to a failing test. No exceptions.

### The Red-Green-Refactor Cycle

**ALWAYS follow this workflow**:

1. **🔴 RED**: Write a failing test that describes the desired behavior
   - Run the test → Should FAIL

2. **🟢 GREEN**: Write the minimum code to make the test pass
   - Run the test again → Should PASS

3. **🔨 REFACTOR**: Clean up the code while keeping tests green
   - Extract methods, remove duplication, improve naming
   - Run tests after each change

**Repeat this cycle for every single feature, bug fix, or change.**

### What This Means in Practice

❌ **NEVER do this**:
```
# Writing production code first, then tests afterward
```

✅ **ALWAYS do this**:
```
# 1. Write the test FIRST (it will fail)
# 2. Run test → RED (fails)
# 3. Write minimum code to make it GREEN
# 4. Run test → GREEN (passes)
# 5. REFACTOR while keeping tests green
```

### Behavior-Driven Testing

**Core Principle**: Test behavior through public APIs. Never test implementation details.

**What is "behavior"?**
- The observable outcome of an action
- Given specific inputs, what outputs/side effects occur?
- State changes visible through public interfaces
- What the user/caller experiences

**What is "implementation"?**
- Private methods
- Internal data structures
- Which collaborators get called
- Order of internal operations
- Instance variables

### Anti-Patterns: NEVER DO THESE

❌ **Testing internal state via instance variables**
→ This breaks if you change internal structure

❌ **Testing private methods directly**
→ Private methods are implementation details; test through public interface

❌ **Testing the order of internal operations**
→ Order is implementation; test the outcome instead

❌ **Using mocks for internal collaborators**
→ Mocking is for external services (APIs, email), not internal classes

❌ **Tests that break when you refactor**
→ If extracting a method breaks tests, they're testing implementation

### Correct Patterns: ALWAYS DO THESE

✅ **Test observable outcomes**
→ Tests what the user of this code cares about

✅ **Test state changes through public interface**
→ Tests behavior through public methods, not internal state

✅ **Test HTTP response and side effects** (for web apps)
→ Tests the full behavior from user's perspective

✅ **Test error conditions through behavior**
→ Tests the error behavior, not how the check is implemented

### Test Smells: Signs You're Testing Implementation

🚩 Your test uses mocks/stubs for internal collaborators
🚩 Your test breaks when you refactor without changing behavior
🚩 Your test name describes HOW instead of WHAT
🚩 Your test uses `send` or equivalent to call private methods
🚩 Your test asserts on things the user/caller doesn't care about
🚩 Your test accesses internal state directly
🚩 You need to change tests when refactoring

### TDD Workflow Checklist

**Before Writing Any Production Code:**
- [ ] Have you written a failing test first?
- [ ] Does the test describe the behavior you want, not the implementation?
- [ ] Is the test using the public API?
- [ ] Would this test still pass if you completely rewrote the implementation?
- [ ] Have you run the test and confirmed it fails for the right reason?

**After Writing Production Code:**
- [ ] Does your code make the test pass?
- [ ] Did you write the minimum code needed to pass?
- [ ] Have you run all tests to ensure nothing broke?

**During Refactoring:**
- [ ] Are you running tests after each refactoring step?
- [ ] Are all tests still green?

**Red Flags (Stop and Fix):**
🚨 You wrote production code before writing a test → DELETE the code, write test first
🚨 Your test passes immediately → The test might not be testing anything meaningful
🚨 Tests are brittle and break with small changes → Rewrite to test behavior

---

### Stack-Specific Adaptations

**For JavaScript/TypeScript (Jest/Vitest):**
```typescript
// Test behavior, not implementation
describe('CartService', () => {
  it('calculates total including tax', () => {
    const cart = new CartService();
    cart.addItem({ price: 100, quantity: 2 });

    expect(cart.getTotal({ taxRate: 0.1 })).toBe(220);
  });
});
```

**For Ruby/Rails (Minitest):**
```ruby
describe 'Cart total calculation' do
  it 'calculates total including tax' do
    cart = Cart.new
    cart.add_item(price: 100, quantity: 2)

    assert_equal 220, cart.total(tax_rate: 0.1)
  end
end
```

**For Python (pytest):**
```python
def test_cart_calculates_total_including_tax():
    cart = Cart()
    cart.add_item(price=100, quantity=2)

    assert cart.get_total(tax_rate=0.1) == 220
```
