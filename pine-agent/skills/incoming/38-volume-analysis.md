---
name: volume-analysis
category: Technical Analysis
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
---

# Volume Analysis

## Purpose
Volume, OBV, VWAP, relative volume, anomalies, VP/delta concepts — with
verified built-in availability.

## When to Use
- Confirmation filters, institutional-activity proxies, intrabar analytics.

## Core Knowledge

### Verified Built-ins
- `volume` — bar volume (na on symbols without volume data — guard, skill 14).
- `ta.obv` — cumulative: ±volume by close direction;
  = `ta.cum(math.sign(ta.change(close)) * volume)`.
- `ta.vwap(src)` — session-anchored VWAP (resets each session by default, hlc3 source).
- Anchored VWAP: `ta.vwap(src, anchor, stdev_mult)` — `anchor` (bool) RESETS
  accumulation when true; stdev_mult adds ± bands.
- NO built-ins for: relative volume, volume profile, delta/CVD (manual below).

### Relative Volume & Anomalies
- RVOL = `volume / ta.sma(volume, 20)` (>2 = anomaly candidate).
- Session-aware RVOL: compare same time-of-day buckets (skill 26 seasonality arrays).
- Zero-volume bars on illiquid symbols poison OBV/VWAP — filter (skill 14).

### Delta / CVD (intrabar approximation)
```pine
closes = request.security_lower_tf(syminfo.tickerid, "1", close)
vols   = request.security_lower_tf(syminfo.tickerid, "1", volume)
var float cvd = 0.0
float barDelta = 0.0
if array.size(closes) > 1
    for i = 1 to array.size(closes) - 1
        barDelta += array.get(closes, i) > array.get(closes, i - 1) ?
             array.get(vols, i) : -array.get(vols, i)
cvd += barDelta
```
- Intrabar budget: plan-capped LTF bars (skill 13). Heuristic = tick-direction
  classification, NOT true bid/ask delta (unless request.footprint, skill 15).

### Volume Profile Concepts (script approximation)
- No built-in TA function. Pattern: price-bin arrays (e.g., bin = ATR/4),
  distribute intrabar volume into bins, find POC (max bin) & value area
  (accumulate outward from POC to ~70% volume). Keep bins bounded (≤100k elems).

### VWAP Discipline
- VWAP = institutional benchmark: distance from VWAP in σ-bands (stdev_mult)
  as reversion context; trend days ride the upper band (regime!, skill 47).

## Common Mistakes
- Delta from CHART timeframe close direction (loses intrabar info) instead of
  security_lower_tf.
- Forgetting VWAP session reset semantics (anchored vs session variants).
- RVOL on symbols with na volume (indexes) → na propagation.
- Building unbounded profile bins across long histories (100k limit).

## Corrections & Updates
- [2026-09] Created; availability verified (obv/vwap exist; rvol/VP/delta manual).
