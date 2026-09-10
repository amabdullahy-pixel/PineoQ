# Skill: trade-management

## Metadata

```yaml
id: trade-management
name: Trade Management
version: 1.0.0
path: skills/normalized/implementation/trade-management/skill.md
layer: IMPLEMENTATION
domains: [strategies, exits]
triggers:
  english:
    - stop loss target
    - trailing stop
    - break-even move
    - R multiple targets
    - chandelier stop
    - structure stop
    - time stop
    - partial exit
  persian:
    - حد ضرر و حد سود
    - حد ضرر متحرک
    - سیو سود پله‌ای
    - خروج بر اساس ساختار
dependencies:
  mandatory: []
  optional: [strategy-engine, tradingview-execution-model, repainting-and-lookahead, regime-detection]
status: normalized
priority: 1
```

## Purpose

Stops, targets, trailing, break-even, R:R, and dynamic/structure exits —
every entry needs a planned exit family BEFORE firing; parameter-unit
discipline and ratchet correctness are the core failure preventions.

## Triggers

Select for: designing any stop/target/exit family; trailing-stop
implementations; break-even logic; R-multiple target plans; structure- or
time-based exits; partial-exit ladders.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Exit-family requirement | description | formalization contract | yes |
| Entry risk unit (R definition) | design fact | trade plan | yes |
| Regime context | design fact | regime-detection | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Exit-family implementation | code patterns | Implementation |
| Unit-semantics verification | verification checks | Pre/Post-Verification |
| Ratchet/BE side-effect analysis | verification output | Post-Verification |

## Rules

1. `strategy.exit` parameter units (per strategy-engine): `profit`/`loss` =
   distance in TICKS from entry price; `limit`/`stop` = ABSOLUTE prices;
   `trail_price` (trigger price) or `trail_points` (ticks) + `trail_offset`
   (ticks); `qty`/`qty_percent` for partial exits; `from_entry` ties to the
   entry id; TP+SL on one exit = OCA bracket (one fills → other cancels).
2. Stop families: fixed price/tick (simple, regime-blind); ATR stop = entry −
   mult·ta.atr(len) (volatility-normalized); Chandelier trailing = ta.highest
   (high, len) − mult·ATR (long); structure stop below last CONFIRMED swing
   low via ta.pivotlow (confirmed r bars later — lag acknowledged); time stop
   after N bars via `strategy.closedtrades.bars`/bar counters.
3. Trailing patterns: (a) native `strategy.exit(..., trail_points, trail_offset)`;
   (b) manual ratchet with full control — var trailStop; on longs only move UP
   via math.max(trailStop, close − 3·ATR); update trailing on bar close for
   backtest-consistent behavior (see tradingview-execution-model).
4. Break-even logic: move stop to BE + costs after 1–1.5R (trigger via high ≥
   avg_price + riskDist); caution — naive BE stops increase scratch rate;
   measure the effect (see performance-metrics MAE/MFE).
5. R:R & dynamic exits: initial risk defines the unit; targets at 2R/3R or
   trail; partial at 1R (qty_percent = 50), remainder trailed by
   structure/ATR; exit design responds to regime — trend regimes trail wide,
   range regimes take quick fixed targets (see regime-detection).
6. Discipline: every strategy.exit variant must exist for ALL entry paths;
   verify exit assumptions — gap fills at open (see strategy-engine),
   intrabar path ambiguity (OCA tie ordering), stops not inside spread noise.

## Workflow

1. Plan the exit family before the entry fires (rule 6).
2. Choose stop family per regime and structure availability (rule 2).
3. Implement trailing with explicit ratchet direction guards (rule 3).
4. Wire BE/behavior changes behind measured triggers (rule 4); keep
   tick-vs-price units consistent per call (rule 1).

## Constraints

- No mixing of tick-distance and absolute-price params in one call.
- Structure stops must use confirmed pivots only (unconfirmed = repaint, see
  repainting-and-lookahead).

## Assumptions

- strategy.exit parameter semantics per strategies docs (verified batch-001).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| TP/SL at wrong distance | tick/price unit mix | rule 1: units per param |
| Trail moves against the trade | missing math.max/min | rule 3: ratchet guard |
| Death by scratches | BE + tight trail | rule 4: measure via MAE/MFE |
| Structure stop repaints | unconfirmed pivot | constraint: confirmed pivots |

## Dependencies

Optional: strategy-engine (exit/OCA mechanics),
tradingview-execution-model (bar-close update timing),
repainting-and-lookahead (confirmed-pivot requirement), regime-detection
(regime-responsive exits). Load only on their own triggers.

## Examples

- "Trail with an ATR chandelier" → rules 2–3.
- "Take half at 1R, trail the rest" → rule 5 partial + trail.
- Persian: «استاپ من برعکس کار می‌کند» → rule 1/3: units + ratchet direction.

## Verification Criteria

- Param units verified per call (ticks vs price).
- All entry paths have exit variants; ratchet guards present.
- BE/trail behavior changes measured, not assumed.
- Confirmed pivots only for structure stops.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/33-trade-management.md`.
- Resolves the batch-001 pending optional-dependency pointer from
  strategy-engine. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `33-trade-management.md`
- Original source path: `skills/incoming/33-trade-management.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
