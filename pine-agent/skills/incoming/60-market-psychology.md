---
name: market-psychology
category: Behavioral Finance
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/support/solutions/43000762390-funding-rate-a-guide-to-market-sentiment/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Market Psychology

## Purpose
Fear, greed, panic, euphoria, capitulation, FOMO, crowd behavior — with
quantifiable proxies available in Pine.

## When to Use
- Contrarian context, regime overlays, exhaustion detection.

## Core Knowledge

### Fear/Greed Proxies (verified on TradingView)
```pine
// Volatility structure (institutional fear barometer)
vix   = request.security("CBOE:VIX",   "1D", close)
vix3m = request.security("CBOE:VIX3M", "1D", close)
bool backwardation = vix > vix3m          // stress = backwardation
bool contango      = vix3m > vix          // calm = contango

// Options positioning
pcr = request.security("CBOE:PC", "1D", close)   // put/call ratio (verify ID per plan)
// Crypto positioning: funding-rate data exists as TradingView metrics
// (see support article); proxy via premium index or community scripts
// if no direct series.
```
- CNN Fear & Greed: NO native symbol — community-script approximation only
  (aggregate VIX trend, momentum, PCR, safe-haven demand). Label as approximate.

### Crowd-State Ladder (with proxy thresholds — calibrate per asset)
| State | Signature | Proxy |
|---|---|---|
| Complacency | low vol, contango, low RVOL | VIX percentile <20 |
| Anxiety | mild vol rise | VIX 40–70th pct |
| Fear | backwardation onset, PCR skew | VIX >VIX3M |
| Panic | VIX spike, correlation→1 | VIX pct >90 + rho↑ (skill 56) |
| Capitulation | volume flush + wick reversal | see below |
| Euphoria/FOMO | RVOL surge on extension, funding extremes | RVOL>2.5 at run highs |

### Capitulation Proxy (computable)
```pine
rvol      = volume / ta.sma(volume, 50)
bigWick   = math.min(close, open) - low > 1.5 * (ta.atr(14) * 0.5)  // lower wick dominant
wideRange = ta.tr(true) > 2.0 * ta.atr(14)
bool capitulationBar = rvol > 3 and wideRange and bigWick and close > open * 0.99
```
- Capitulation marks CANDIDATE bottoms (sell-side exhaustion) — require
  confirmation structure (skill 40) before trading it.

### FOMO Proxy
- RVOL > 2.5 + consecutive-body extension + distance-from-VWAP extreme
  (skill 38) → crowd chasing; expect mean-reversion risk (regime-dependent, skill 47).

### Usage Discipline
- Proxies = context LAYERS (hierarchical fusion, skill 46), not triggers.
- Extremes persist longer than expected in trends — pair with regime gate
  (skill 47) before fading.

## Common Mistakes
- Fading euphoria in strong trends without regime confirmation.
- Treating PCR/funding mid-range values as information (noise).
- Trusting Fear&Greed-style composites as precise signals (they're approximations).
- Symbol IDs assumed without per-plan verification.

## Corrections & Updates
- [2026-09] Created; VIX/VIX3M semantics verified vs reference; PCR symbol
  IDs flagged verify-per-plan; funding-rate access per support article.
