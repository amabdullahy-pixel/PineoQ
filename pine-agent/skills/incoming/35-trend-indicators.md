---
name: trend-indicators
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Trend Indicators

## Purpose
MA family + directional systems with verified v6 signatures and formulas.

## When to Use
- Trend filters, regime classification, crossover systems, dynamic levels.

## Core Knowledge

### Moving Average Family (v6 verified)
| Function | Formula/Notes |
|---|---|
| `ta.sma(src, len)` | arithmetic mean |
| `ta.ema(src, len)` | α = 2/(len+1), recursive |
| `ta.rma(src, len)` | α = 1/len (Wilder); ≡ EMA of length 2L−1 |
| `ta.wma(src, len)` | linear weights len..1 |
| `ta.vwma(src, len)` | sma(src·vol)/sma(vol) |
| `ta.hma(src, len)` | wma(2·wma(src, len/2) − wma(src, len), √len) |
| `ta.alma(src, len, offset, sigma, floor=false)` | Gaussian-weighted; offset shifts kernel center (smoothness↔responsiveness); sigma = width |
| `ta.swma(src)` | fixed 4-bar weights 1:2:2:1 ÷ 6; NO length param |
| **ta.kama** | **DOES NOT EXIST** — implement manually (below) |

### KAMA (manual reference implementation)
```pine
kama(float src, int len, int fast, int slow) =>
    float change = math.abs(src - src[len])
    float vol = 0.0
    for i = 0 to len - 1
        vol += math.abs(src[i] - src[i + 1])
    float er = vol > 0 ? change / vol : 0.0                    // efficiency ratio
    float sc = math.pow(er * (2.0 / (fast + 1) - 2.0 / (slow + 1)) + 2.0 / (slow + 1), 2)
    var float k = na
    k := na(k) ? src : k + sc * (src - k)
    k
```

### Directional Systems
- MACD: `ta.macd(src, fast, slow, signal)` → [macd, signal, hist] (12/26/9 classic).
- DMI/ADX: `ta.dmi(diLen, adxSmooth)` → [+DI, −DI, ADX]; Wilder smoothing on
  DM, DX smoothed by adxSmoothing. ADX>25 trending heuristic (regime input, skill 47).
- Supertrend: `ta.supertrend(factor, atrPeriod)` → [st, direction];
  **direction = −1 UPTREND / +1 DOWNTREND** (counterintuitive — quote from reference).
- CMO: `ta.cmo` (−100..+100); RCI: `ta.rci` (Spearman-style rank corr, −100..+100).

### Crossover Discipline
- `ta.crossover(a, b)` fires on the bar of crossing; in realtime that bar is
  unconfirmed → repaint risk (skill 12): gate with `barstate.isconfirmed` or `[1]`.
- MA crossovers = laggy by construction; tune lengths per asset (skill 54).

## Common Mistakes
- Calling ta.kama (compile error) or trusting "built-in" claims.
- Reading supertrend direction wrong sign.
- HMA with odd lengths (int division of len/2 changes behavior).
- Stacking 3 MA crosses as "confirmation" (same-family redundancy).

## Corrections & Updates
- [2026-09] Created; all signatures/formulas verified against v6 reference,
  including supertrend direction quote and ta.kama absence.
