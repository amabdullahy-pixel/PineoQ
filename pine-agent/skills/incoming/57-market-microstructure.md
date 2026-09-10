---
name: market-microstructure
category: Economics & Market Context
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/chart-information/
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
---

# Market Microstructure

## Purpose
Bid/ask, spread, liquidity, slippage, market impact, auction/discovery, order
flow concepts + what Pine can actually see.

## When to Use
- Cost modeling, realism calibration, order-flow-informed logic.

## Core Knowledge

### What Pine CAN Access (verified)
- Tick charts ("1T"): `bid` / `ask` built-ins return live prices; on ALL other
  timeframes they are `na` → spread observable ONLY on tick charts.
- `syminfo.mintick` — minimum price increment (spread floor reference).
- `request.footprint()` (2026-01, Premium/Ultimate, skill 15): per-row volume,
  delta, POC/VA — closest to order-flow data in Pine.
- Intrabar proxies via `request.security_lower_tf` (skill 13/38): delta/CVD
  approximations (tick-direction heuristic, NOT true bid/ask classification).

### What Pine CANNOT Access
- Live order book/depth, true historical bid/ask spread series, queue
  position, iceberg detection. Model costs with: mintick, typical spread
  estimate per asset class (input), and slippage ticks (skill 09/51).

### Microstructure Concepts → Practice
- Bid–ask spread = round-trip cost floor: expectancy must exceed ~spread +
  commission + slippage (skill 32).
- Market impact: size ∝ liquidity; small caps / low-vol hours → widen
  estimated slippage; relative-volume filters (skill 38) avoid illiquid bars.
- Auction theory: value = price range with most two-sided trade (VP POC/VA,
  skill 38 approximation); price discovery = movement between value areas.
- Stop runs/liquidity events: skill 41 — expect fills AT or beyond stops on
  sweeps (gap/emulator fills at open, skill 09).

### Asset-Class Microstructure Notes (verified semantics)
- `syminfo.type`: stock / futures / index / forex / crypto / fund / dr / cfd /
  bond / warrant — branch logic per class:
```pine
bool isCrypto = syminfo.type == "crypto"     // 24/7: session gates off
bool isFut    = syminfo.type == "futures"    // point value matters (below)
```
- Futures: syminfo.pointvalue = currency value per 1.0 price point (ES = 50):
  P&L = Δpoints × pointvalue × qty. Rollover: Pine uses CONTINUOUS contracts
  (ES1!) with back-adjustment stitching — no native rollover event API; avoid
  trading through roll week distortions manually.
- Sessions: crypto ismarket=true 24/7; forex ~Sun–Fri; futures near-24h ETH
  with maintenance breaks; equities RTH-only unless extended feed.
- Currency: `strategy(currency = currency.USD)` sets account currency;
  request.currency_rate(from, to) for FX conversion of metrics.

## Common Mistakes
- Assuming bid/ask exist off tick charts (na → silent logic bugs).
- Zero-cost backtests on wide-spread assets (spread >> mintick).
- Forgetting futures point value in sizing math (skill 31).
- Treating continuous-contract history as tradable prices through rolls.

## Corrections & Updates
- [2026-09] Created; bid/ask tick-chart limitation + pointvalue + continuous
  contract semantics verified vs official docs.
