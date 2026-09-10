---
name: pine-debugging-and-testing
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/writing/debugging/
  - https://www.tradingview.com/pine-script-docs/errors/overview/
---

# Pine Debugging & Testing

## Purpose
Error taxonomy (compile/runtime/logical), native debugging tools, and
Pine-adapted testing practices.

## When to Use
- Any error, any unexpected value, any pre-release check.

## Core Knowledge

### Error Taxonomy (official codes)
| Class | Prefix | Examples | Response |
|---|---|---|---|
| Compile | CE | CE10101 (condition not bool), CE10117 (token limit), undeclared identifier | read message literally — fix types/syntax (skills 01/02) |
| Warning | CW | CW-style "function called in different scopes" (conditional ta.*) | never ignore — usually real bugs |
| Runtime | RE | RE10143 (max_bars_back), RE10139 (memory), loop timeout, request limit, array OOB | guard data/layers (skills 14/69) |
| Logical | — | no error; wrong values | systematic debugging below |

### Native Debugging Tools (verified)
- **Pine Logs:** `log.info/warning/error(msg)` or format-string overloads;
  Pine Logs pane (Editor "More" menu); works historical + realtime; ~10k
  recent historical entries; logs reflect per-tick executions (mind volume).
- **Profiler:** flame-icons top-3 bottlenecks, runtime % per line (skill 69).
- **Plot debugging:** `plot(var, "dbg", display = display.data_window)` +
  conditional bgcolor markers; label.new on suspect bars.
- **Strategy trades list** as behavioral assertion output.

### Systematic Logical-Debug Procedure
1. Reproduce deterministically (fixed symbol/TF/range; seed randomness, skill 28).
2. Localize: plot suspect series vs expectation in Data Window.
3. Verify each pipeline stage separately (data → calc → signal → exec).
4. Check the known silent killers: na propagation (skill 14), repaint (skill 12),
   conditional ta.* history (skill 01), var rollback (skill 07), float
   equality (skill 16).
5. Binary-search the bar of first divergence (barstate/log gating).

### Pine-Adapted Testing
- **Unit-style:** pure functions tested on known inputs at bar 0
  (`if bar_index == 0` + log assertions); edge fns: kama on flat series, ols
  on 1-bar window.
- **Boundary testing:** array size 0/1/cap; length 1 indicators; session
  edges; symbol with volume=na (skill 58).
- **Regression testing:** keep a mini "golden set" of pinned scenarios
  (symbol+TF+range+expected values) rerun after every change (skill 73 ledger).
- **Cross-check:** reimplement one indicator manually (e.g., RSI loop) and
  diff against ta.rsi — validates understanding, not TradingView.

## Common Mistakes
- Fixing symptoms by adding `[1]` everywhere instead of finding the leak.
- Logs left spamming per-tick in production (perf + noise).
- Testing only on the happy symbol/TF.
- Ignoring CW warnings "because it compiles".

## Corrections & Updates
- [2026-09] Created; log.*/profiler/error taxonomy verified vs official
  debugging/errors docs.
