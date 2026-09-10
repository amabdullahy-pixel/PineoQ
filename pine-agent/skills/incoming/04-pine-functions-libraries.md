---
name: pine-functions-libraries
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/libraries/
  - https://www.tradingview.com/pine-script-docs/language/methods/
---

# Pine Functions & Libraries

## Purpose
Namespaces, user-defined functions/methods, and building/importing libraries.

## When to Use
- Organizing reusable logic; publishing shared code; importing community libraries.

## Core Knowledge

### Built-in Namespaces
`ta` (indicators), `math` (math fns/constants), `str`, `array`, `matrix`, `map`,
`request` (security/financial/seed/dividends/splits/footprint), `ticker`,
`syminfo`, `timeframe`, `time`, `color`, `input`, `plot*`/`label`/`line`/`box`/
`table`/`polyline` (drawing), `alert`, `strategy`, `position`, `order`,
`session`, `barstate`, `chart`, `currency`, `dayofweek`, `extend`, `format`,
`hline`, `location`, `math.*` constants, `size`, `xloc`, `yloc`, `display`.

### User-Defined Functions
- Return = last expression; params can have defaults; supports tuple returns.
- Each call site creates an independent instance with its own internal history.
- Conditional-call trap: a `ta.*` call inside `if`/`for` updates only when executed
  → wrong series. Standard fix: compute globally, branch on result.

### Methods
- `method name(Type firstParam, ...) =>` — called as `obj.name(...)`.
- Overloading: same method name for different first-param types.
- Can extend built-in types (arrays, UDTs, enums).

### Libraries
```pine
//@version=6
library("mylib", overlay = false)

//  #version=1                     ← bump when exports change
export f(float x) =>
    x * 2
```
- Import: `import user/mylib/1 as my` → `my.f(2.0)`.
- Libraries export: functions, methods, UDTs, enums.
- Constraints: libraries cannot be added to a chart / cannot plot directly;
  exported functions must not reference global-scope variables — pass everything
  as parameters.
- Version in import path pins behavior; bump library `#version` on breaking changes.

### Reusable Component Design
- Inputs-first: expose tunables via `input.*`, not magic numbers.
- Single responsibility per function; no hidden global state.
- Type-annotate public signatures for clarity.
- Guard rails: validate inputs (array sizes, lookbacks) and handle `na` explicitly.

## Common Mistakes
- Exporting a function that closes over a global variable (compile error).
- Calling the same UDF twice "sometimes" and wondering why series differ.
- Importing without version pin, then library updates silently change behavior.
- Mutating an input array inside a library function (side effects leak to caller).

## Corrections & Updates
- [2026-09] Created; verified against official docs (v6 era).
