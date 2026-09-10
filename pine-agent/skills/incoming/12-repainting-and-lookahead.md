---
name: repainting-and-lookahead
category: Repainting & Data Integrity
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/repainting/
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
---

# Repainting & Lookahead

## Purpose
Detect, prevent, and correctly reason about repainting, future leaks, and
historical/realtime discrepancies. The most dangerous failure class in Pine.

## When to Use
- ALWAYS before publishing, backtesting, or trusting any signal.
- Auditing existing scripts (third-party or legacy).
- Designing alert logic that must match backtest behavior.

## Core Knowledge

### Definition
Repainting = script behavior where historical results differ from realtime
results. TradingView: >95% of indicators repaint in some form. Not all
repainting is evil (e.g., a volume profile updating on the live bar), but
future-leaking repainting invalidates backtests.

### Complete Cause Taxonomy
1. **Fluid realtime OHLC** — `high/low/close` change every tick until commit.
2. **Unconfirmed HTF data** — `request.security()` without offset returns the
   developing HTF bar; reload bakes in the final value → history "changes".
3. **`varip`** — tick-level state not reproducible from historical OHLC.
4. **Plotting into the past** — e.g., pivot confirmed after N bars then drawn at
   `bar_index[N]` → illusion of instant historical signals.
5. **`timenow`** — wall-clock time, unreproducible on history.
6. **Intrabar alerts/orders** — fire on ticks, vanish/alter at bar close.

### Lookahead Mechanics
- `barmerge.lookahead_off` (default): HTF data visible only at END of HTF period.
- `barmerge.lookahead_on`: HTF data visible from START of HTF period →
  **FUTURE LEAK unless paired with `[1]` offset.**
- Classic leak (FORBIDDEN in publications):
```pine
// LEAK: shows the daily high at the START of the day
request.security(syminfo.tickerid, "1D", high, lookahead = barmerge.lookahead_on)
```
- Rule: lookahead_on is ONLY safe with a confirmed-data offset ([1]), or for
  equal/lower timeframe contexts.

### The Official Non-Repainting HTF Pattern
```pine
float htfClose = request.security(syminfo.tickerid, "1D", close[1],
     lookahead = barmerge.lookahead_on)
```
- `[1]` = last COMPLETED HTF bar; lookahead_on aligns it to the period start
  (removes lag without leaking). Data is locked → no repaint.

### Official Anti-Repaint Recommendations
- Gate triggers on `barstate.isconfirmed` (not usable inside request.security).
- Use prior-bar values for calculations sensitive to the live bar.
- Use `open` (fixed during the bar) when possible: `ta.crossover(open, ma[1])`.
- Strategies: avoid `calc_on_every_tick = true`; avoid varip in backtest-critical logic.

### Repaint Audit Checklist (run on any script)
- [ ] Raw close/high/low in triggers without isconfirmed/[1]?
- [ ] request.security HTF without offset, or lookahead_on without [1]?
- [ ] varip used for signals/orders?
- [ ] Shapes/labels drawn N bars into the past after confirmation?
- [ ] timenow or reload-sensitive barstate.isnew/isrealtime logic?
- [ ] calc_on_every_tick = true in a strategy?

## Common Mistakes
- Calling a [1]+lookahead_on HTF plot "the same value" as the live HTF close — it is the PREVIOUS HTF bar's close by design.
- Trusting a backtest from a script that plots into the past.
- "Fixing" repaint by shifting everything [1] — adds a full bar of lag instead.

## Corrections & Updates
- [2026-09] Created; verified against official repainting docs (v6 era).
