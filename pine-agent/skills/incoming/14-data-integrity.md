---
name: data-integrity
category: Repainting & Data Integrity
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/time/
  - https://www.tradingview.com/pine-script-docs/concepts/sessions/
  - https://www.tradingview.com/pine-script-docs/concepts/bar-merging/
---

# Data Integrity

## Purpose
Handling `na`, gaps, sessions, time zones, holidays, and illiquid/synthetic data
so calculations never silently corrupt.

## When to Use
- Session-filtered strategies, cross-market comparisons, illiquid symbols,
  any code where missing data could produce false signals.

## Core Knowledge

### How `na` Arises
- History overflow (`close[1000]` on a 500-bar dataset).
- Missing bars/gaps (no trades, exchange outages, holidays).
- Session boundaries (bars outside the active session with session-filtered `time()`).
- `request.*` with `gaps_on`, illiquid symbols, halted symbols.

### `na` Toolkit
- `na(x)` → true if x is na. `nz(x, repl)` → replace na (default 0).
- `fixnan(x)` → forward-fill with latest non-na value.
- v6: `bool` can't be na; `na()/nz()/fixnan()` reject bools. For tri-state
  (long/short/flat) use int codes `1 / -1 / 0`, not bool.
- NEVER chain math on potentially-na series without guards:
```pine
float r = na(raw) ? 0.0 : raw      // explicit guard
bool valid = not na(v) and not na(w)
```

### Sessions
- State built-ins: session.ismarket, session.ispremarket, session.ispostmarket.
- Canonical filter: `inSess = not na(time(timeframe.period, "0930-1600:23456", syminfo.timezone))`.
- Session string format: HHMM-HHMM[:days] (days: 1=Sun…7=Sat). Use
  session.regular / session.extended with ticker.new()/ticker.modify() to
  choose regular vs extended data context.
- Chart-level extended hours toggle affects available bars; scripts can't force it.

### Time Zones (the #1 silent bug)
- Time values = UNIX ms (UTC-based, zone-agnostic). Rendering hours/days
  REQUIRES a zone: ALWAYS pass syminfo.timezone (exchange IANA zone, DST-safe)
  to hour(), dayofweek(), time(), str.format_time().
- Never hardcode "America/New_York" for user symbols; never use UTC+X offsets
  (DST-unsafe). Chart timezone setting ≠ syminfo.timezone.

### Holidays, Gaps, Weekends
- Traditional markets: overnight/weekend/holiday gaps are normal — detect with
  `time - time[1] > expected interval` rather than assuming contiguous bars.
- Crypto: ~24/7 (only exchange maintenance breaks). Cross-asset alignment:
  compare on a common TF (usually "1D") or na-fill explicitly.
- Holidays = missing daily bars → indicator lookbacks silently span them;
  decide explicitly whether that's acceptable for the strategy.

### Illiquid & Synthetic Symbols
- Zero-volume bars, stale prices (high == low, volume == 0) distort indicators
  and backtests: filter with volume > 0 or minimum tick-move checks.
- Synthetic/combined tickers (spreads built with ticker.modify) inherit quirks
  of both legs; validate both legs' data first.

## Common Mistakes
- nz()-ing price series to 0 (turns missing bars into fake crashes).
- Using chart timezone or UTC offsets instead of syminfo.timezone.
- Assuming bars are contiguous across sessions/holidays.
- Treating zero-volume bars as real trades in backtest stats.

## Corrections & Updates
- [2026-09] Created; verified against official time/sessions/merging docs.
