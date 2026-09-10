---
name: multi-symbol-engineering
category: Repainting & Data Integrity
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
  - https://www.tradingview.com/pine-script-docs/release-notes/
---

# Multi-Symbol Engineering

## Purpose
Cross-asset data: benchmarks, correlation, relative strength, intermarket context.

## When to Use
- RS vs SPX, DXY filters, BTC/ETH ratios, sector vs index, spread construction.

## Core Knowledge

### Requesting Other Symbols
```pine
spx   = request.security("SPX",         "1D", close)
bench = request.security("NASDAQ:NDX",  "1D", close)
vix   = request.security("CBOE:VIX",    "1D", close)
```
- Symbol needs the exchange prefix when ambiguous. syminfo.tickerid = full ID of chart symbol.
- Apply skill 12/13 rules: HTF requests need confirmed patterns; each unique
  request counts toward the 40-request cap (64 Ultimate).

### Ticker Construction
- `ticker.new(prefix, ticker, session, adjustment)` — build custom ticker IDs (e.g., extended-session context).
- `ticker.modify(tickerid, session, adjustment, ...)` — change session or corporate-action adjustments of an existing ID.
- `ticker.standard()` — strip modifiers back to the plain symbol.

### Fundamentals & Macro Data
- `request.financial(symbol, financial_id, period, ...)` — FactSet fundamentals, plan-gated; periods: "FQ", "FY", "TTM", "D".
- `request.economic(country_code, field, ...)` — macro/economic series.
- `request.quandl()` — REMOVED/deprecated; do not use in new code.
- `request.footprint()` — [2026-01] volume footprint objects (rows, delta, POC, VA) via footprint.*/volume_row.*; Premium/Ultimate plans.

### Analysis Patterns
```pine
// Relative strength
rs = close / request.security("SPX", "1D", close)

// Correlation
corr = ta.correlation(close, request.security("DXY", "1D", close), 20)

// Regime filter (risk-on/off)
riskOn = request.security("SPX", "1D", close) > request.security("SPX", "1D", ta.sma(close, 200))
```
- Benchmark choice: index vs ETF (SPX vs SPY — ETF has extended hours/volume;
  index doesn't trade). Decide deliberately.
- Normalize RS with its own moving average to avoid scale drift.

### Cross-Exchange Session Alignment
- Different sessions → mismatched bars and na from gaps_on.
- Normalize: compare on "1D", or align sessions explicitly via ticker.modify,
  or fill with gaps_off + accept stale-value semantics (document it!).
- Crypto vs equities: weekend crypto bars have no equity counterpart — equity
  filters evaluate on stale/na data those days.

### Request Budget Discipline
- Precompute symbol list; reuse identical requests (duplicates are free).
- Guard with `ignore_invalid_symbol = true` + na checks for optional symbols.
- Runtime errors on bad symbols: catch by validating na of the returned series.

## Common Mistakes
- Requesting a benchmark without exchange prefix (wrong symbol resolved).
- Comparing symbols across exchanges without session alignment.
- Burning request budget in loops on dynamic symbols unnecessarily.
- Using request.quandl (removed) in new code.

## Corrections & Updates
- [2026-09] Created; verified against official docs; request.footprint added
  2026-01 — verify plan availability before relying on it.
