---
name: macro-economics
category: Economics & Market Context
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/support/solutions/43000665359-what-economic-data-is-available-in-pine/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Macro Economics

## Purpose
Inflation, rates, monetary policy, GDP, employment, liquidity, money supply —
as trader-relevant context with Pine data access.

## When to Use
- Macro regime context for strategy gating; intermarket narrative validation.

## Core Knowledge

### Pine Data Access (verified)
```pine
cpi = request.economic("US", "CPI")            // inflation
ir  = request.economic("US", "INTR")           // policy interest rate
gdp = request.economic("US", "GDP")
ur  = request.economic("US", "UR")             // unemployment
```
- Country codes: ISO alpha-2 ("US", "DE", "JP") + aggregates ("EU").
- Field names are SHORT codes (CPI, INTR, GDP, UR, NFP...) — see official
  support article for the full field list; treat unlisted fields as unverified
  (skill 76).
- Frequency: these series update MONTHLY/QUARTERLY — as chart overlays they
  are STEP SERIES (flat for weeks, then jump). Never compute short-window
  indicators (e.g., RSI-14 of CPI) directly on them.

### Macro → Trading Logic (step-series aware)
- Regime context: rate direction (INTR falling = easing) + CPI trend =
  liquidity posture; use as SLOW FILTERS (e.g., `ratesFalling = ir < ir[60]`).
- Event risk: NO Pine access to future economic-calendar timestamps
  (request.economic = history only). Event-risk windows (CPI/FOMC release
  days) must be handled manually or via hardcoded calendars — document this limit.

### Monetary Policy & Liquidity Concepts
- Easing cycle → risk-asset tailwinds; tightening → dispersion up, trend
  persistence down (heuristics to falsify per asset, skill 66).
- Liquidity proxy ideas: DXY inverse + yields direction (skill 56), money
  supply fields if listed in the official field list (verify name before use).

## Common Mistakes
- Using macro series like high-frequency price data (step-series distortion).
- Assuming Pine can see upcoming events (it cannot).
- Hardcoding field names not present in the official list.
- Request budget burn: macro requests are per-country-per-field unique
  requests (cap 40, skill 15).

## Corrections & Updates
- [2026-09] Created; economic/earnings functions + no-calendar-events limit
  verified vs official support articles.
