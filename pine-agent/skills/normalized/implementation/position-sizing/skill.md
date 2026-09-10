# Skill: position-sizing

## Metadata

```yaml
id: position-sizing
name: Position Sizing
version: 1.0.0
path: skills/normalized/implementation/position-sizing/skill.md
layer: IMPLEMENTATION
domains: [risk-control, strategies]
triggers:
  english:
    - fixed fractional sizing
    - ATR volatility sizing
    - Kelly criterion
    - anti-martingale
    - position size from stop
    - qty calculation
  persian:
    - سایز پوزیشن
    - ریسک ثابت درصدی
    - کریتری کلی
    - آنتی مارتینگل
dependencies:
  mandatory: []
  optional: [risk-management, strategy-engine, statistical-testing, regime-detection]
status: normalized
priority: 1
```

## Purpose

Fixed fractional, fixed risk, ATR/volatility sizing, Kelly, and
anti-martingale implemented in Pine — sizing IS risk: every strategy sizes
positions from its stop, never the reverse.

## Triggers

Select for: every strategy build (defaults are rarely right); qty-from-stop
calculations; volatility-targeted sizing; Kelly-fraction questions; spotting
martingale variants hidden in "recovery" logic.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Risk% target / risk model | parameter | user/formalization | yes |
| Stop distance source (structure/ATR) | design fact | trade-management | yes |
| Trade history (for Kelly W, R) | data | strategy results | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Sizing formula implementation | implementation pattern | Implementation |
| qty guards (floor, cap) | code pattern | Implementation |
| Kelly-fraction policy | design decision | Implementation Planning |

## Rules

1. Fixed fractional (constant % risk): riskPct input /100; stopDist =
   |entryLevel − stopLevel|; riskCash = strategy.equity × riskPct; qtyRaw =
   stopDist > 0 ? riskCash / stopDist : na; qty = max(1, floor(qtyRaw))
   (whole contracts); pass qty into strategy.entry. Stop distance comes from
   structure/ATR; size derives from stop — never the reverse.
2. Fixed risk ($ per trade): same formula with riskCash = constant.
3. ATR/volatility sizing: stop = entry ± mult·ATR → stopDist = mult·ta.atr(len)
   (plus buffer); volatility targeting — size ∝ targetVol/realizedVol
   (position shrinks in high-vol regimes; pairs with regime-detection/
   adaptive-systems).
4. Kelly criterion (full formula, use FRACTIONS of it): f* = W − (1−W)/R
   where W = win rate, R = avgWin/avgLoss (payoff ratio); estimate W and R
   from ≥100 trades WITH CIs (see statistical-testing); full Kelly assumes
   exact knowledge → use 1/4–1/2 Kelly; cap at the fixed-fractional ceiling;
   Kelly on fat-tailed/mis-estimated data overbets catastrophically.
5. Anti-martingale (the survivable family): increase exposure AFTER wins/
   equity growth (fixed-fractional sizing is naturally anti-martingale); NEVER
   increase after losses to "recover"; martingale (double after loss) has
   positive expectancy and guaranteed ruin on loss streaks — reject explicitly
   in reviews (see code-review-and-refactoring).
6. Sizing guards: cap qty = min(qty, maxQty); exposure cap (see
   risk-management); rounding via math.floor (never round UP into more risk);
   min-qty/mintick checks; pyramiding additions sized independently per
   tranche with total exposure still capped (strategy.risk.max_position_size).

## Workflow

1. Establish the stop first (trade-management families), then derive size
   (rule 1).
2. Choose the risk model (fixed-fractional default; vol-targeting where
   regime-aware); document it.
3. Apply guards: floor rounding, caps, min-qty, cost share inside the risk
   budget (rule 6).
4. For Kelly, enforce sample/CI requirements and the fraction policy (rule 4).

## Constraints

- Never size by "% of equity position" while ignoring stop distance.
- No martingale-family sizing anywhere in agent-produced code.

## Assumptions

- qty/entry semantics align with strategy-engine (batch-001 verified facts).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Risk varies with stop width | %-of-equity sizing | rule 1: size from stop |
| Kelly from small samples | <100 trades | rule 4: CIs + fraction, or fixed-fractional |
| Hidden martingale | size grows after losses | rule 5: reject in review |
| Costs ignored | risk budget overstated | rule 6: commission/slippage share |

## Dependencies

Optional: risk-management (exposure caps, native guardrails),
strategy-engine (entry/qty mechanics), statistical-testing (Kelly estimate
CIs), regime-detection (vol-targeting context). Load only on their own
triggers.

## Examples

- "Risk 1% per trade with an ATR stop" → rules 1, 3 combined.
- "Should I use full Kelly?" → rule 4: fractions + CIs + cap.
- Persian: «حجم ورودم را چطور حساب کنم؟» → rule 1 formula.

## Verification Criteria

- Size math derives from stop distance with guarded division.
- floor-rounding and caps present; no upward rounding into more risk.
- Kelly usage (if any) meets sample/CI/fraction policy.
- No size increases after losses anywhere in the logic.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/31-position-sizing.md`.
- Layer decision: IMPLEMENTATION (function = sizing code patterns for
  strategies), consistent with risk-management's classification.
- Resolves the batch-003 pending optional-dependency pointer from
  risk-management. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `31-position-sizing.md`
- Original source path: `skills/incoming/31-position-sizing.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
