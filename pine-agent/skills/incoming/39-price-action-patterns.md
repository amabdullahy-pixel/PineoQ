---
name: price-action-patterns
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/language/objects/
---

# Price Action Patterns

## Purpose
Candles, swing points, breakouts, S/R — Pine-verified implementations
(no built-in pattern library).

## When to Use
- Entry triggers, level-based logic, structure confirmation.

## Core Knowledge

### Candlestick Patterns (manual — NO built-ins)
- Base measures: body = \|close−open\|; range = high−low;
  upperWick = high − max(open, close); lowerWick = min(open, close) − low.
```pine
bullEngulf = close > open and close[1] < open[1] and
     close > open[1] and open <= close[1] and body > body[1]
doji      = body <= 0.1 * range
hammer    = lowerWick > 2 * body and upperWick < body
```
- Community libraries exist for full pattern sets (import per skill 04); verify
  pattern definitions match YOUR trading definition before use (skill 76).

### Swing Points (pivots)
- `ta.pivothigh(l, r)` / `ta.pivotlow(l, r)` — returns pivot PRICE r bars AFTER
  confirmation, else na. Confirmation lag is structural (skill 12).
- Store confirmed swings: `var array<float>` + `var array<int>` (bar indices) —
  basis for structure logic (skill 40).

### Breakouts & Breakdowns
- `breakUp = close > ta.highest(high, len)[1]` — [1] excludes the developing
  bar (prevents "self-breaking").
- Breakout quality filters: close (not just high) beyond level; RVOL >
  threshold (skill 38); retest logic: price returns to level within N bars
  without closing back inside range.
- False-breakout check: close back inside level → fail (stop-run awareness, skill 41).

### Support/Resistance (manual zone engine)
- Sources: confirmed pivots (clustered), session/anchor highs-lows,
  big-volume bars' extremes.
- Zone = price band (not line): merge pivots within tolerance (e.g., 0.5·ATR)
  into zone arrays {top, bottom, touches, lastTouchBar}; strengthen on touch;
  invalidate on close-through. Render with box.new (skill 10).

## Common Mistakes
- Candle patterns on bar[0] intrabar (unconfirmed) — gate isconfirmed.
- Treating every pivot as S/R without clustering/strength ranking.
- Breakouts measured against levels that include the current bar.
- Wick/body definitions differing from the pattern dictionary you cite.

## Corrections & Updates
- [2026-09] Created; no built-in candle patterns/pivot-lag semantics verified.
