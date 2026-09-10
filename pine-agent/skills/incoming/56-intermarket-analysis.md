---
name: intermarket-analysis
category: Economics & Market Context
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
---

# Intermarket Analysis

## Purpose
Dollar, bonds, gold, commodities, equities, FX, crypto relationships and
correlation regimes — implementable with request.security.

## When to Use
- Risk-on/off filters, context confirmation, correlation-regime gating.

## Core Knowledge

### Reference Symbols (commonly used IDs — verify live before relying)
| Instrument | Symbol |
|---|---|
| Dollar Index | `TVC:DXY` |
| US 10Y yield | `TVC:US10Y` |
| VIX | `TVC:VIX` (alt: CBOE:VIX) |
| Gold spot | `OANDA:XAUUSD` / `TVC:GOLD` |
| WTI oil | `TVC:USOIL` / front `NYMEX:CL1!` |
| S&P 500 | `SP:SPX` / `TVC:SPX` |
| BTC | `INDEX:BTCUSD` / exchange feeds |

- Symbol resolution varies by plan/feed — validate each request returns non-na
  (skill 15 pattern) and document the chosen IDs in the project manifest (skill 73).

### Core Relationship Map (contextual, not mechanical laws)
- Equities ↔ yields: easing/rates-down usually supports equities; sharp yield
  SPIKES = equity stress (regime-dependent!).
- DXY inverse vs gold/equities/crypto (weaker dollar = tailwind) — breaks down
  in crisis (everything correlated to cash).
- VIX > threshold (e.g., >25–30) = stress regime → size down (skill 30).
- Gold as fear hedge; oil = inflation/growth proxy.

### Correlation Regimes (Pine implementation)
```pine
spx = request.security("SP:SPX", "1D", close)
rho = ta.correlation(close, spx, 20)
bool corrRegimeStable = rho > 0.5            // per strategy
bool crisisMode = request.security("TVC:VIX", "1D", close) > 28
```
- Regime shifts: corr drift is a FACTOR — recompute per window; collapse of
  diversification assumptions = skill 30 exposure rule.

### Implementation Discipline
- Every intermarket leg = 1 unique request (budget 40, skill 15); align on
  "1D" to dodge session mismatch (skill 14); apply non-repaint HTF pattern for
  HTF context (skill 12/13).
- Decide index vs ETF proxies deliberately (SPX vs SPY: ETF has extended
  hours volume; index doesn't trade).

## Common Mistakes
- Hardcoding symbol IDs that resolve wrong/na on other plans.
- Using correlation levels as constants across years (regimes move).
- Trading the map mechanically ("DXY down → buy" as a rule) instead of a filter.
- na-handling absent when a feed lacks history for the requested depth.

## Corrections & Updates
- [2026-09] Created; symbol table = commonly-used identifiers, mark as
  needs-verification per account (feeds change; run skill 76 checks).
