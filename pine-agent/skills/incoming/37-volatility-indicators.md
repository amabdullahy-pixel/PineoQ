---
name: volatility-indicators
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/support/solutions/43000501823-average-true-range-atr/
  - https://www.tradingview.com/support/solutions/43000589145-historical-volatility/
---

# Volatility Indicators

## Purpose
ATR, Bollinger, Keltner, Donchian, HV/realized vol — verified forms and uses.

## When to Use
- Stop/target sizing, regime detection, squeeze/breakout logic, normalization.

## Core Knowledge

### ATR
- `ta.tr(true)` = max(h−l, \|h−c[1]\|, \|l−c[1]\|); `ta.atr(len)` = rma(tr, len)
  (Wilder smoothing — verified).
- Uses: stop distance (skill 33), sizing (skill 31), regime z-scores of ATR
  (skill 47/48).

### Bollinger Bands
- `ta.bb(src, len, mult)` → `[middle, upper, lower]`; basis = SMA; bands =
  basis ± mult·stdev (population/biased default).
- `ta.bbw(src, len, mult)` = (upper−lower)/middle — squeeze = bbw percentile low.
- BB %B position: `(src − lower)/(upper − lower)` (manual; guard division).

### Keltner Channels
- `ta.kc(src, len, mult, useTrueRange)` → `[middle, upper, lower]`; basis = EMA;
  envelope = ± mult·ATR (useTrueRange=true) or ± mult·(hi−lo).
- `ta.kcw` = width. BB-in-KC = classic squeeze pattern (manual comparison).

### Donchian Channels
- NO `ta.donchian` — manual: `ta.highest(high, len)` / `ta.lowest(low, len)`,
  mid = average. Breakout logic: `close > ta.highest(high, len)[1]`
  ([1] = exclude current bar, skill 39).

### Historical / Realized Volatility (manual — no built-in HV)
```pine
logR    = math.log(close / close[1])
hvAnn   = ta.stdev(logR, len) * math.sqrt(365.0) * 100   // crypto; 252 equities
realVol = ta.stdev(logR, len)                            // per-bar σ
// Realized vol forecasting (EWMA, skill 26):
var float v = na
v := 0.94 * v + 0.06 * logR * logR
```

### Volatility Regime Notes
- Vol CLUSTERS (skill 26): current vol predicts near-future vol — normalize
  thresholds by vol regime (percentile of ATR/BBW, skill 48).
- Expanders: bbw/kcw percentile breakouts; contraction precedes expansion
  (heuristic, not law — falsify per symbol, skill 66).

## Common Mistakes
- Treating "squeeze → breakout direction" as deterministic (only readiness).
- Using stdev on prices (non-stationary) instead of returns for HV.
- Mixing ATR mult conventions across strategies without revalidation.
- Dividing by bbw/kcw zero-width windows (guard, skill 20).

## Corrections & Updates
- [2026-09] Created; formulas/defaults verified against reference/support.
