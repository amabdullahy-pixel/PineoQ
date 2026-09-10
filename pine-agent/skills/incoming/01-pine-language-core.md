---
name: pine-language-core
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
---

# Pine Script Language Core

## Purpose
Canonical reference for Pine Script v6 syntax: variables, types, operators,
expressions, functions, methods, scope, conditionals, and loops.

## When to Use
- Writing or reading any Pine Script code.
- Debugging syntax/scope errors.
- Before using loops or conditionals that return values.

## Core Knowledge

### Variable Declaration
- `[<type>] name = expression` — type is optional (inferred).
- Reassignment uses `:=` (`x := x + 1`), not `=`.
- `var name = expr` — initialized ONCE on first bar, persists across bars.
- `varip name = expr` — persists across realtime ticks and intrabar rollbacks.
- `const name = expr` — forces compile-time constant.
- `once` block — executes body once, the first time its condition is true.

### Types
`int`, `float`, `bool`, `string`, `color` + reference types (`array<T>`,
`matrix<T>`, `map<K,V>`, UDT objects, enums).

### Operators
- Arithmetic: `+ - * / % **`  (v6: `const int / const int` may return float)
- Comparison: `== != < > <= >=`
- Logical: `and or not` — **v6: lazily evaluated** (short-circuit). Safe pattern:
  `if array.size(a) > 0 and array.get(a, 0) > 0`
- Ternary: `cond ? a : b` (always returns a value; both branches must be type-compatible)
- History: `close[1]` — **v6: `[]` cannot index history of literals or UDT fields.**

### Functions
```pine
// multi-line
f(int x, float y = 1.0) =>
    z = x * y
    z + 1
```
- Return value = last expression. Params may have defaults.
- No recursion support; a function executes once per bar when called at global scope.
- WARNING: calling `ta.*` functions conditionally (inside `if`) breaks their internal
  history — call every bar, use the result conditionally.

### Methods
```pine
method m(array<float> a, float x) =>
    a.push(x)
```
- First parameter type is mandatory — binds the method to that type.
- Called with dot syntax; supports overloading (same name, different types).

### Scope
- Global scope: column 0. Local scopes: functions, if/switch, loops, `once`.
- Locals are invisible outside; outer variables can be READ and REASSIGNED (`:=`) inside.
- Limit: 1000 variables per scope.

### Conditionals
- `if/else if/else` — can return values: `x = if c then 1 else 2` style (last expr of branch).
- `switch` — two forms (on value / on conditions). When returning values, MUST have
  a default branch, otherwise result is `na`.
- v6: numeric values are NOT implicitly cast to bool → use `bool(x)` explicitly.

### Loops
```pine
for i = 0 to 10 by 1          // end boundary re-evaluated EVERY iteration (v6)
for [i, v] in myArray          // arrays, matrices, maps
while condition
```
- `break` / `continue` supported.
- HARD LIMIT: any loop ≤ 500ms per bar; total script ≤ 20s (Basic) / 40s (other plans).

## Common Mistakes
- Using `=` instead of `:=` to update an existing variable.
- `if ta.rsi(close,14) > x` inside an `if` block → corrupted RSI history.
- Forgetting `else`/`default` → unexpected `na`.
- Assuming `bool` can be `na` (v6: it cannot).
- Building O(n²) loops over large arrays → 500ms loop timeout.

## Corrections & Updates
<!-- Inject new/changed facts here with date. Format: [YYYY-MM] note -->
- [2026-09] Created; verified against official docs (v6 era).
