---
name: walk-forward-and-validation
category: Backtesting & Optimization
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
---

# Walk-Forward & Validation

## Purpose
In-sample vs out-of-sample discipline, walk-forward, rolling and anchored
windows — implementable in Pine via date gating.

## When to Use
- Before declaring any backtest result valid.

## Core Knowledge

### IS / OOS Split (manual but mandatory)
```pine
oosStart = input.time(timestamp("1 Jan 2025 00:00 +0000"), "OOS start")
bool isIS  = time < oosStart
bool isOOS = time >= oosStart
if longSignal and (isIS or showOOS)
    strategy.entry("L", strategy.long)
// OOS trade markers styled differently; report OOS metrics separately
```
- NEVER touch parameters after seeing OOS — one OOS peek per claim; multiple
  peeks = OOS becomes in-sample (trial inflation, skill 25/54).

### Validation Schemes
| Scheme | How | Use |
|---|---|---|
| Holdout split | fixed IS/OOS cut | minimum standard |
| Rolling window | train [t−W, t), test [t, t+H), roll forward | regime changes |
| Anchored window | train [start, t), test [t, t+H), extend | compounding-era stability |
| Walk-forward | rolling scheme + stitched OOS equity | gold standard |

- Walk-forward reading: stitched OOS segments = the ONLY honest equity curve.
- Typical proportions: IS ≈ 3–4× OOS length; OOS ≥ 6 months or ≥ 30 trades.

### Pine Practice
- Segmented stats via date-gated counters (skill 22 accumulation pattern):
  separate win/loss/PF arrays for IS and OOS; dashboard shows both (skill 10).
- Rolling-window results vary by cut point — run 2–3 cut points minimum.
- OOS result quality bar: direction must match IS sign; magnitude may decay
  30–50% and still be acceptable; near-zero OOS = refit happened.

## Common Mistakes
- Optimizing on full history then "validating" on the same history.
- Re-running OOS repeatedly after tweaks (silent leakage).
- OOS window too short (noise dominates).
- Comparing IS and OOS metrics computed with different cost settings.

## Corrections & Updates
- [2026-09] Created; manual date-gating is the standard TV workflow (no native
  split feature — consistent with skill 52 findings).
