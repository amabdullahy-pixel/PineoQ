---
name: position-sizing
category: Financial Math & Risk
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Position Sizing

## Purpose
Fixed fractional, fixed risk, ATR/volatility sizing, Kelly, anti-martingale —
implemented in Pine.

## When to Use
- Every strategy: sizing IS risk. Defaults are rarely right.

## Core Knowledge

### Fixed Fractional (constant % risk)
```pine
riskPct   = input.float(1.0, "Risk %") / 100.0
stopDist  = math.abs(entryLevel - stopLevel)
riskCash  = strategy.equity * riskPct
qtyRaw    = stopDist > 0 ? riskCash / stopDist : na
qty       = math.max(1, math.floor(qtyRaw))     // whole contracts
strategy.entry("L", strategy.long, qty = qty)
```
- Stop distance from structure/ATR; size derives from stop — never the reverse.

### Fixed Risk ($ per trade)
- Same formula with `riskCash = constant`.

### ATR / Volatility Sizing
- Stop = entry ± mult·ATR → `stopDist = mult * ta.atr(len)` (plus buffer).
- Volatility targeting: size ∝ targetVol / realizedVol — position shrinks in
  high-vol regimes (pairs with skill 47/48).

### Kelly Criterion (full formula, use FRACTIONS of it)
- `f* = W − (1 − W)/R`, where W = win rate, R = avgWin/avgLoss (payoff ratio).
- Estimate W,R from ≥100 trades with CIs (skill 25); full Kelly assumes exact
  knowledge → use 1/4–1/2 Kelly; cap at fixed-fractional ceiling.
- Kelly on fat-tailed/mis-estimated data overbets catastrophically.

### Anti-Martingale (the survivable family)
- Increase exposure AFTER wins/equity growth (size ∝ equity = fixed fractional
  is naturally anti-martingale); NEVER increase after losses to "recover".
- Martingale (double after loss) has positive expectancy and guaranteed ruin
  on loss streaks — reject explicitly in reviews (skill 71).

### Sizing Guards
- Cap: `qty = math.min(qty, maxQty)`; exposure cap (skill 30).
- Rounding: `math.floor` (never round UP into more risk); min-qty/mintick checks.
- pyramiding additions: each tranche sized independently; total exposure still
  capped (strategy.risk.max_position_size, skill 30).

## Common Mistakes
- Sizing by "% of equity position" while ignoring stop distance (risk varies
  wildly with stop width).
- Kelly from small samples; full-Kelly bets.
- Martingale variants hidden in "recovery" logic.
- Forgetting commission/slippage inside risk budget.

## Corrections & Updates
- [2026-09] Created; sizing/qty semantics align with strategy engine (skill 09).
