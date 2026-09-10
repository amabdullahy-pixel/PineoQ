---
name: pine-data-structures
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/language/arrays/
  - https://www.tradingview.com/pine-script-docs/language/matrices/
  - https://www.tradingview.com/pine-script-docs/language/maps/
  - https://www.tradingview.com/pine-script-docs/language/objects/
---

# Pine Script Data Structures

## Purpose
Arrays, matrices, maps, UDTs, and persistence patterns with exact limits.

## When to Use
- Any state that must survive bars (signals history, zones, positions).
- Choosing the right container; avoiding size/limit errors.

## Core Knowledge

### Arrays — `array<T>` (1-D)
- Create: `array.new<float>()`, `array.from(1, 2, 3)`, `array.copy(a)`.
- LIMIT: **100,000 elements** total per array.
- v6: **negative indices** in `array.get/set/insert/remove` (`-1` = last element).
- Key ops: push/pop/shift, insert/remove, slice, join, sort, `array.includes`,
  `array.last`, `array.first`, binary search.
- Iterate: `for [i, v] in a` or index loop.

### Matrices — `matrix<T>` (2-D)
- Create: `matrix.new<float>(rows, cols, initial)`.
- LIMIT: rows × cols ≤ **100,000** total elements.
- Key ops: get/set, row/col add/remove, `matrix.submatrix`, transpose, determinant,
  eigenvalues/eigenvectors (`matrix.eigenvalues/eigenvectors`), sort.
- Typical use: covariance matrices, multi-symbol grids, linear algebra.

### Maps — `map<K,V>` (unordered key→value)
- Create: `map.new<string, float>()`.
- LIMIT: ≤ **100,000 elements** = **50,000 key/value pairs**.
- Keys must be VALUE types (int, float, bool, string, color, enum) — no arrays/UDT keys.
- `map.keys(m)` / `map.values(m)` return arrays; iterate with `for [k, v] in m`.

### UDTs — user-defined types
```pine
type Zone
    float top
    float bottom
    int   startBar
    bool  broken = false        // default field values allowed

Zone z = Zone.new(high, low, bar_index)
```
- Objects are **references**: assignment/passes share ONE object.
- `.copy()` = shallow copy (nested collections still shared → deep copy manually).
- Fields can hold any type incl. other UDTs, arrays, maps.
- v6: UDT arrays/matrices support sort & binary search via `sort_field`.

### Persistence Patterns
- `var a = array.new<float>()` — persistent buffer across bars (trim with shift to cap memory).
- `var z = Zone.new(...)` — persistent object; mutate fields per bar.
- `varip` — state that must survive intrabar ticks (tick-level counters, partial-bar state).
- Clear-on-condition: reinitialize inside `if` using `:=`.

## Common Mistakes
- Forgetting `.copy()` → aliasing bugs (two "copies" mutate one object).
- Deep-copying by hand but missing a nested collection.
- Unbounded `array.push` on every bar → eventual 100,000 limit / loop timeouts.
- Using a UDT/array as map key (not allowed).

## Corrections & Updates
- [2026-09] Created; verified against official docs (v6 era).
