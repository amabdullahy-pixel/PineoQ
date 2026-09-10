---
name: pine-v6
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/release-notes/
  - https://www.tradingview.com/pine-script-docs/migration-guides/to-pine-version-6/
---

# Pine Script v6

## Purpose
Current-version behavior, features, migration checklist, limits, best practices.

## When to Use
- Writing any NEW script (target v6), migrating v5 code, auditing legacy code.

## Core Knowledge

### Status
- v6 released: **2024-12-10**. Current stable as of 2026-09. v7: not announced.

### Defining v6 Changes (vs v5)
1. **Dynamic requests by default** — `dynamic_requests = true`; `request.*()` may use
   `series string` args and run inside loops/conditionals/local scopes.
2. **Strict booleans** — `bool` cannot be `na`; numeric→bool implicit cast removed.
3. **Lazy `and`/`or`** — short-circuit evaluation.
4. **Negative array indices** for get/set/insert/remove.
5. **Strategy order trimming** — hitting the ~9,000-trade historic limit trims oldest
   orders instead of halting with error.
6. `timeframe.period` always includes multiplier (`"1D"`, not `"D"`).
7. `const int / const int` division → fractional float allowed.
8. `[]` cannot index history of literals or UDT fields.
9. `when` parameter removed from strategy functions; `transp` removed.
10. Loop end boundary evaluated dynamically before every iteration.

### Post-Release Additions (via release notes)
- [2026-01] `request.footprint()` — volume footprint, POC, VA (plan-gated).
- [2026-04] Multiline string literals (`"""…"""` / `'''…'''`).
- UDT array/matrix sort + binary search via `sort_field`.
- [2026-08] `once` conditional structure (run block once when condition first true).

### Migration Checklist (v5 → v6)
- [ ] Replace implicit numeric→bool with explicit `bool()`.
- [ ] Remove `na()`/`nz()` calls on booleans; replace with explicit `false` handling.
- [ ] Check `timeframe.period` string comparisons (`"D"` → `"1D"`).
- [ ] Review dynamic requests: accidental series-string requests = new runtime errors/limits.
- [ ] `transp` / `when` usages removed.
- [ ] Re-test strategies relying on `bool` `na` states (now `false`).

### Limit Reference (summary)
- Total execution: 20s (Basic) / 40s (paid); loop ≤ 500ms/bar.
- Compiled size: ≤ 100,256 tokens (IL); imported libraries ≤ 1M tokens.
- 64 plot counts; drawings 50 default → 500 max (labels/lines/boxes), 100 polylines, 9 tables.
- `request.*`: 40 unique calls (64 on Ultimate); LTF intrabars 100K–200K by plan;
  total tuple elements across requests ≤ 127.
- 1,000 variables per scope.

### Best Practices
- Always `//@version=6`; compile-clean with no warnings.
- Prefer `var`+arrays for state; trim buffers explicitly.
- Guard request calls for plan limits; never assume Ultimate limits.
- Keep loops O(n) and bounded; validate loop bounds.

## Common Mistakes
- Trusting v5 behavior of `bool` `na` in migrated code.
- Unbounded dynamic requests inside loops (performance/limit blowups).

## Corrections & Updates
- [2026-09] Created; verified against release notes (v6 era, no v7 as of now).
