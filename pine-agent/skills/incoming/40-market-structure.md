---
name: market-structure
category: Market Structure & Geometry
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/script/CnB3fSph-Smart-Money-Concepts-SMC-LuxAlgo/
  - https://dailypriceaction.com/blog/smc-market-structure/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Market Structure

## Purpose
HH/HL/LH/LL, BOS, CHoCH, internal vs external structure, swing engine —
SMC-standard definitions with code-implementable rules.

## When to Use
- Trend state engines, entry models, SMC-style systems.

## Core Knowledge

### Definitions (community-standard, 2024–2026)
- Uptrend = Higher Highs (HH) + Higher Lows (HL). Downtrend = LL + LH.
- **BOS (Break of Structure)** = CONTINUATION: close beyond the prior swing in
  the TREND direction (bull: close > last swing high while bullish).
- **CHoCH (Change of Character)** = first structure break AGAINST the trend —
  early reversal warning, not confirmation (bull: close < last higher low).
- Internal structure = minor swings INSIDE major legs; external = major
  swings. Signals: external for bias, internal for entries.

### Swing Engine (confirmed pivots)
```pine
ph = ta.pivothigh(high, L, R)      // price of pivot, R bars after confirmation
pl = ta.pivotlow(low, L, R)
var float lastSwingHigh = na, var float prevSwingHigh = na
var float lastSwingLow  = na, var float prevSwingLow  = na
if not na(ph)
    prevSwingHigh := lastSwingHigh
    lastSwingHigh := ph
if not na(pl)
    prevSwingLow := lastSwingLow
    lastSwingLow := pl
```
- Classification on pivot confirmation: new high > prev high AND pullback low >
  prev low → HH+HL (bull persists), etc. Lag = R bars (acknowledge, skill 12).

### BOS / CHoCH State Machine
```pine
int trend = 0                        // 1 bull, -1 bear, 0 undefined
bool bosBull   = not na(lastSwingHigh) and close > lastSwingHigh and trend >= 0
bool chochBull = not na(lastSwingHigh) and close > lastSwingHigh and trend < 0
bool bosBear   = not na(lastSwingLow)  and close < lastSwingLow  and trend <= 0
bool chochBear = not na(lastSwingLow)  and close < lastSwingLow  and trend > 0
if chochBull or bosBull
    trend := 1
if chochBear or bosBear
    trend := -1
```
- Close-based (not wick) breaks; use confirmed bars (barstate.isconfirmed, skill 07).

## Common Mistakes
- Wick-breaks counted as BOS (community standard: CLOSE through).
- Treating CHoCH as a guaranteed reversal (it's a warning).
- Mixing internal/external swings in one state variable.
- Unconfirmed-pivot logic (repaint) or live-bar structure reads.

## Corrections & Updates
- [2026-09] Created; definitions verified across major SMC sources (LuxAlgo
  et al.); variations exist between schools — parameterize L/R and document choices.
