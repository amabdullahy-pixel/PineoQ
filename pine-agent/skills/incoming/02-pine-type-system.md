---
name: pine-type-system
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/type-system/
  - https://www.tradingview.com/pine-script-docs/migration-guides/to-pine-version-6/
---

# Pine Script Type System

## Purpose
Exact rules for qualifiers, casting, tuples, `na`, and type inference.

## When to Use
- Compiler errors about "simple/series" qualifiers.
- Designing function signatures and library APIs.
- Handling `na` and booleans correctly in v6.

## Core Knowledge

### Qualifier Hierarchy
`const < input < simple < series`

| Qualifier | When value is known | Can change per bar? |
|---|---|---|
| `const` | compile time | no |
| `input` | settings dialog | no |
| `simple` | first bar (runtime) | no |
| `series` | runtime, any bar | **yes** |

- A parameter expecting qualifier Q accepts any qualifier ≤ Q (weaker is OK, stronger is an error).
- Expression qualifier = strongest qualifier among operands. Cannot be downgraded manually.
- Reference types (arrays, maps, UDT objects) are always `series`.

### Casting
- Implicit: `int → float` only.
- **v6: no implicit numeric→bool.** Use `bool(x)` explicitly.
- Explicit wrappers: `int()`, `float()`, `bool()`, `string()`, `color()`.
- v6: `bool` no longer auto-casts to `int`/`float`.

### `na` Rules (v6 — strict)
- `bool` can NEVER be `na` → only `true`/`false`.
- `na()`, `nz()`, `fixnan()` reject `bool` arguments (compile error).
- `myBool[1]` on the first bar returns `false` (not `na`).
- Unspecified `if`/`switch` branches returning `bool` → `false`.
- Unique-type parameters (e.g., `plot()` style) no longer accept `na`.

### Tuples
```pine
[macdLine, signalLine, hist] = ta.macd(close, 12, 26, 9)
[a, _ , c] = f()               // _ ignores an element
```
- Tuple items cannot be pre-declared variables; each item is a NEW variable.
- All items inherit the strongest qualifier in the tuple.
- Limit: total tuple elements across all `request.*()` calls ≤ 127.

### Type Inference
- Omitted types are inferred from the initializer; `array.new<float>()` infers element type.
- Declare types explicitly for readability and precise autocomplete.

### Enums (v6)
```pine
enum Mode { Auto, Trend = 1, Range }
```
- Named int constants; valid as map keys and input options.

## Common Mistakes
- Passing `series` where `simple`/`input` is required (e.g., some `request.security` args).
- `nz(someBool)` → compile error in v6.
- Expecting `0` to mean `false` in an `if` → must be `bool(x)`.
- Tuple destructuring onto existing variables.

## Corrections & Updates
- [2026-09] Created; verified against official docs (v6 era).
