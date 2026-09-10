# Skill: walk-forward-and-validation

## Metadata

```yaml
id: walk-forward-and-validation
name: Walk-Forward & Validation
version: 1.0.0
path: skills/normalized/research/walk-forward-and-validation/skill.md
layer: RESEARCH
domains: [backtesting, validation]
triggers:
  english:
    - in-sample out-of-sample
    - walk-forward analysis
    - rolling window validation
    - anchored window
    - OOS discipline
    - date gating backtest
  persian:
    - درون‌نمونه و برون‌نمونه
    - اعتبارسنجی قدم‌به‌قدم
    - بازه غلتان
dependencies:
  mandatory: []
  optional: [statistical-testing, overfitting-and-robustness,
    backtesting-science, drawing-and-visualization]
status: normalized
priority: 1
```

## Purpose

In-sample vs out-of-sample discipline, walk-forward, rolling and anchored
windows — implementable in Pine via date gating; the mandatory step before
declaring any backtest result valid.

## Triggers

Select for: before declaring any backtest result valid; IS/OOS split design;
walk-forward schemes; "does my edge hold out-of-sample?" questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Result to validate | report | backtest | yes |
| OOS cut (date) + scheme | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| IS/OOS gating implementation | code pattern | Implementation |
| Scheme selection (holdout/rolling/anchored/WF) | design decision | Implementation Planning |
| OOS verdict rules | verification checks | Post-Verification |

## Rules

1. IS/OOS split (manual but mandatory): date-gate with `input.time` —
   `bool isIS = time < oosStart`, `bool isOOS = time >= oosStart`; gate
   entries by segment; style OOS markers differently; report OOS metrics
   separately. NEVER touch parameters after seeing OOS — one OOS peek per
   claim; multiple peeks = OOS becomes in-sample (trial inflation — see
   statistical-testing / overfitting-and-robustness).
2. Validation schemes: holdout split (fixed IS/OOS cut — minimum standard);
   rolling window (train [t−W, t), test [t, t+H), roll — for regime
   changes); anchored window (train [start, t), test [t, t+H), extend — for
   compounding-era stability); walk-forward (rolling scheme + stitched OOS
   equity — gold standard). Stitched OOS segments are the ONLY honest
   equity curve.
3. Proportions: IS ≈ 3–4× OOS length; OOS ≥ 6 months or ≥ 30 trades.
4. Pine practice: segmented stats via date-gated counters (separate
   win/loss/PF arrays for IS and OOS — probability accumulation pattern);
   dashboard shows both (drawing-and-visualization); rolling-window results
   vary by cut point — run 2–3 cut points minimum.
5. OOS quality bar: direction must match IS sign; magnitude may decay
   30–50% and still be acceptable; near-zero OOS = refit happened.

## Workflow

1. Fix the OOS cut and scheme BEFORE tuning (rule 1–2).
2. Implement date-gated segmented stats (rule 4).
3. Run the chosen scheme; multiple cut points for rolling (rule 4).
4. Apply the OOS quality bar (rule 5); one peek per claim (rule 1).

## Constraints

- No optimizing on full history then "validating" on the same history.
- No re-running OOS repeatedly after tweaks (silent leakage).
- OOS window too short = noise dominates.
- IS and OOS metrics must use identical cost settings.

## Assumptions

- Manual date-gating is the standard TradingView workflow (no native split
  feature — consistent with optimization-and-calibration findings).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Same history trains and validates | no cut | rule 1: date gate |
| OOS re-run after each tweak | silent leakage | rule 1: one peek per claim |
| OOS window too short | noise | rule 3: ≥6 months / ≥30 trades |
| IS vs OOS costs differ | unfair compare | constraint: identical costs |

## Dependencies

Optional: statistical-testing (trial inflation math),
overfitting-and-robustness (post-validation battery),
backtesting-science (bias context), drawing-and-visualization (segmented
dashboard). Load only on their own triggers.

## Examples

- "Validate my strategy on 2025+ data" → rule 1 date gating.
- "Walk-forward my momentum system" → rule 2 rolling + stitched OOS.
- Persian: «استراتژی رو خارج از نمونه تست کنم؟» → rule 1: OOS split.

## Verification Criteria

- OOS cut fixed and documented before tuning.
- Segmented IS/OOS metrics reported separately with identical costs.
- Stitched OOS equity used for walk-forward claims.
- One OOS peek per claim enforced.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/53-walk-forward-and-validation.md`.
- Resolves the batch-005 parked candidates {44↔53} and {48↔53}
  (quantitative-analysis and adaptive-systems both consume OOS validation —
  confirmed complementary). Structural reorganization only; no semantic
  changes.

## Source Reference

- Original filename: `53-walk-forward-and-validation.md`
- Original source path: `skills/incoming/53-walk-forward-and-validation.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
