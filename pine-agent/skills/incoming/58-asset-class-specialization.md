---
name: asset-class-specialization
category: Economics & Market Context
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/chart-information/
  - https://www.tradingview.com/pine-script-docs/concepts/sessions/
---

# Asset-Class Specialization

## Purpose
Crypto, forex, equities, indices, futures, commodities, bonds, ETFs —
class-specific behaviors and Pine branching.

## When to Use
- Porting one strategy across classes; per-class parameterization.

## Core Knowledge

### Class Detection & Branching
```pine
string cls = syminfo.type
bool isCrypto = cls == "crypto", bool isFut    = cls == "futures"
bool isFx     = cls == "forex",  bool isStock  = cls == "stock"
bool isIndex  = cls == "index",  bool isFund   = cls == "fund"
```
- Same strategy code, class-conditional parameters (session gates, sizing,
  thresholds) via a settings UDT (skill 03).

### Per-Class Realities (verified semantics)
| Class | Sessions | Costs | Key gotchas |
|---|---|---|---|
| Crypto | 24/7 (ismarket true) | fees %, spread small on majors | weekend liquidity dips; funding not modeled |
| Forex | ~Sun–Fri (UTC) | spread-based, no commission usually | no central volume (tick volume only) |
| Equities | RTH + extended | commission + spread | halts, earnings gaps (request.earnings) |
| Index | chart context only | can't trade the index itself | use futures/ETF proxy to trade |
| Futures | ETH + maintenance | commission/contract | pointvalue math (skill 57); rolls |
| Bonds | exchange hours | quoted in yield/points | use TVC:US10Y-style feeds for context |
| ETF | like equities | spread + commission | proxies for index exposure |

- Trading an INDEX directly: not tradable — strategies backtest fills only
  theoretically; trade its future/ETF proxy in production.

### Session Handling per Class
- Crypto: skip session gates (always true); weekend RVOL baselines differ —
  use day-of-week-aware baselines (skill 26).
- Forex: volume fields = tick volume (broker-dependent) — volume filters need
  recalibration (skill 38).
- Equities: earnings/dividend gap risk → request.earnings context gates.

### Class Migration Checklist (porting a strategy)
- [ ] syminfo.type branch exists for every assumption (sessions, volume, costs).
- [ ] Costs re-modeled (spread/commission per class, skill 09).
- [ ] Sizing re-derived (pointvalue for futures, skill 31).
- [ ] Thresholds re-falsified per class (skill 66) — never reuse.

## Common Mistakes
- One parameter set across all classes.
- Forex volume filters without tick-volume awareness.
- Backtesting an index and trading it "directly" (impossible).
- Crypto weekend liquidity treated like weekday.

## Corrections & Updates
- [2026-09] Created; class list/sessions verified vs chart-information docs.
  (Frontmatter `category` field fixed during archiving — stray `class:` line removed.)
