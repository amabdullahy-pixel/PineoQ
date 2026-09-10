# Skill: market-microstructure

## Metadata

```yaml
id: market-microstructure
name: Market Microstructure
version: 1.0.0
path: skills/normalized/research/market-microstructure/skill.md
layer: RESEARCH
domains: [market-context, execution]
triggers:
  english:
    - bid ask spread pine
    - order flow footprint
    - slippage market impact
    - futures point value
    - continuous contract rollover
    - syminfo.type branching
  persian:
    - ریزساختار بازار
    - اسپرد و نقدینگی
    - ارزش پوینت فیوچرز
dependencies:
  mandatory: []
  optional: [strategy-engine, backtesting-science, multi-symbol-engineering,
    volume-analysis, asset-class-specialization, liquidity-and-price-structure]
status: normalized
priority: 1
```

## Purpose

Bid/ask, spread, liquidity, slippage, market impact, auction/discovery, and
order-flow concepts — with what Pine can and cannot actually see.

## Triggers

Select for: cost modeling and realism calibration; order-flow-informed
logic; bid/ask availability questions; futures point-value and rollover
questions; asset-class execution differences.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Cost/flow modeling need | description | formalization contract | yes |
| Typical spread estimate per asset | parameter | user/broker reality | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Cost model (spread/slippage/mintick) | parameters | backtesting-science |
| syminfo.type branching pattern | code pattern | Implementation |
| Pine data-access limits record | constraints | Feasibility |

## Rules

1. What Pine CAN access (verified): `bid`/`ask` built-ins return live
   prices on TICK charts ("1T") only — on ALL other timeframes they are
   `na` → spread observable ONLY on tick charts; `syminfo.mintick` =
   minimum price increment (spread floor reference); `request.footprint()`
   (2026-01, Premium/Ultimate — multi-symbol-engineering): per-row volume,
   delta, POC/VA — closest to order-flow data in Pine; intrabar proxies via
   `request.security_lower_tf` (mtf-engineering / volume-analysis): delta/
   CVD approximations (tick-direction heuristic, NOT true bid/ask
   classification).
2. What Pine CANNOT access: live order book/depth, true historical bid/ask
   spread series, queue position, iceberg detection. Model costs with:
   mintick, typical spread estimate per asset class (input), and slippage
   ticks (strategy-engine / backtesting-science).
3. Microstructure concepts → practice: bid–ask spread = round-trip cost
   floor — expectancy must exceed ~spread + commission + slippage
   (performance-metrics); market impact — size ∝ liquidity; small caps /
   low-vol hours → widen estimated slippage; relative-volume filters
   (volume-analysis) avoid illiquid bars; auction theory — value = price
   range with most two-sided trade (VP POC/VA approximation,
   volume-analysis); price discovery = movement between value areas; stop
   runs/liquidity events (liquidity-and-price-structure) — expect fills AT
   or beyond stops on sweeps (gap/emulator fills at open, strategy-engine /
   backtesting-science).
4. Asset-class semantics (verified): `syminfo.type` ∈ {stock, futures,
   index, forex, crypto, fund, dr, cfd, bond, warrant} — branch logic per
   class. Futures: `syminfo.pointvalue` = currency value per 1.0 price
   point (ES = 50); P&L = Δpoints × pointvalue × qty (position-sizing).
   Rollover: Pine uses CONTINUOUS contracts (ES1!) with back-adjustment
   stitching — no native rollover event API; avoid trading through roll
   week distortions manually. Sessions: crypto 24/7; forex ~Sun–Fri;
   futures near-24h ETH with maintenance breaks; equities RTH-only unless
   extended feed. Currency: `strategy(currency = currency.USD)` sets
   account currency; `request.currency_rate(from, to)` for FX conversion
   of metrics.

## Workflow

1. Establish the data-access envelope for the task (rules 1–2); never
   assume bid/ask off tick charts.
2. Build the cost model from mintick + spread estimate + slippage (rule 2).
3. Branch class-specific logic on syminfo.type (rule 4).
4. Route flow proxies through footprint/lower-tf patterns with budgets
   (rule 1).

## Constraints

- No bid/ask logic off tick charts (na → silent logic bugs).
- No zero-cost backtests on wide-spread assets.
- No forgetting futures point value in sizing math.
- No treating continuous-contract history as tradable prices through rolls.

## Assumptions

- bid/ask tick-chart limitation, pointvalue, and continuous-contract
  semantics verified vs official docs (import re-verified 2026-09 for the
  1T-only bid/ask behavior).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Spread logic on 1D chart | bid/ask = na | rule 1: tick charts only |
| Spread >> mintick ignored | unrealistic fills | rule 2: cost model |
| ES sizing without point value | 50× error | rule 4: pointvalue math |
| Trading through roll week | stitched prices | rule 4: avoid manually |

## Dependencies

Optional: strategy-engine (fill mechanics, currency),
backtesting-science (cost realism), multi-symbol-engineering (footprint
budgets), volume-analysis (RVOL/VP approximations),
asset-class-specialization (class sessions/costs),
liquidity-and-price-structure (sweep fills). Load only on their own
triggers.

## Examples

- "Can I read the order book in Pine?" → rule 2: no — model costs instead.
- "Size ES positions correctly" → rule 4 pointvalue.
- Persian: «اسپرد رو تو پین میشه خوند؟» → rule 1: only on tick charts.

## Verification Criteria

- Bid/ask usage gated on 1T timeframe checks.
- Cost model includes mintick floor, spread estimate, slippage.
- Futures sizing uses pointvalue.
- Continuous-contract limitations documented.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/57-market-microstructure.md`.
- The load-bearing bid/ask-1T-only claim independently re-verified at import
  (official chart-information docs + release notes + multiple independent
  sources). `request.footprint()` (2026-01) consistent with batch-001
  release-notes verification. Structural reorganization only; no semantic
  changes.

## Source Reference

- Original filename: `57-market-microstructure.md`
- Original source path: `skills/incoming/57-market-microstructure.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
