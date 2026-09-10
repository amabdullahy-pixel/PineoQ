# Skill: statistical-arbitrage

## Metadata

```yaml
id: statistical-arbitrage
name: Statistical Arbitrage
version: 1.0.0
path: skills/normalized/research/statistical-arbitrage/skill.md
layer: RESEARCH
domains: [quant-methods, pairs-trading]
triggers:
  english:
    - pair trading
    - cointegration vs correlation
    - spread z-score
    - Engle-Granger
    - hedge ratio beta
    - half-life spread
    - correlation breakdown guard
  persian:
    - آربیتراژ آماری
    - معامله جفتی
    - هم‌انباشتگی
    - نیم‌عمر اسپرد
dependencies:
  mandatory: []
  optional: [regression-correlation, stochastic-processes, multi-symbol-engineering, data-integrity]
status: normalized
priority: 2
```

## Purpose

Pair trading: spread construction, z-score entries, cointegration vs
correlation, half-life sizing, correlation-breakdown guards, and relative
value — the two-leg relative-value methodology mapped to Pine's execution
reality.

## Triggers

Select for: two-leg relative-value systems (A vs B, or asset vs benchmark);
spread z-score designs; "is this pair tradeable?" evaluation; correlation
decoupling protection.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Pair definition (A, B) | symbols | user/formalization | yes |
| Z-entry/exit/stop thresholds | parameters | user (falsify) | yes |
| Session/calendar relationship | context | data-integrity | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Spread/half-life design | implementation pattern | Implementation |
| Breakdown guard rules | verification checks | Post-Verification |
| Two-leg execution plan | design output | strategy-engine |

## Rules

1. Correlation ≠ cointegration (the cardinal rule): correlation = co-movement
   of RETURNS (short-term); cointegration = long-run EQUILIBRIUM of PRICE
   levels (spread stationary); two trending series can be 0.99 correlated
   with a non-stationary spread → spurious regression, unbounded spread risk
   (the regression-correlation warning, applied).
2. Engle–Granger workflow (conceptual pipeline in Pine): (1) hedge ratio β —
   OLS of log(A) on log(B) over a window (manual OLS — see
   regression-correlation; use LOG prices: elasticity-style β); (2) spread
   S = ln(A) − β·ln(B); (3) z-score z = (S − sma(S, len))/stdev(S, len,
   false); (4) entries |z| > 2 (long spread z<−2, short z>2), exit z→0, stop
   |z| > 3.5; (5) formal ADF test NOT available in Pine — approximate
   stationarity via variance-ratio/Hurst (see stochastic-processes) and
   require a sane OU fit.
3. Half-life (OU fit) sizes the window: regress ΔS on lagged S
   (ΔS = a + b·S[1]); b < 0 → halfLife = −ln(2)/ln(1+b); use a rolling
   stats window len ≈ 3–5× halfLife; reject the pair if half-life is absurd
   (≤2 bars = costs eat the edge; > holding horizon).
4. Correlation-breakdown guard: rolling corr of RETURNS (e.g., 20 bars);
   disable/flatten when rho < rhoMin OR |z| > 3.5 (structural break, not
   reversion) → re-calibrate β before re-arming.
5. Pine execution reality: both legs = 2 symbols via request.security (see
   multi-symbol-engineering; watch the 40-request budget); one strategy
   simulates the SPREAD; per-leg sizing = qty ∝ β ratio; account for BOTH
   legs' commission/slippage in expectancy (see performance-metrics); crypto
   pairs 24/7 alignment OK; cross-class pairs align sessions (see
   data-integrity).

## Workflow

1. Screen the pair: returns correlation is NOT sufficient — require the
   Engle–Granger pipeline + sane half-life (rules 1–3).
2. Size the stats window from half-life (rule 3); set z thresholds.
3. Arm the breakdown guard (rule 4) before going live.
4. Implement spread simulation with two-leg costs (rule 5).

## Constraints

- Pairing on correlation alone is forbidden (the #1 failure).
- No position held through a structural decoupling (guard mandatory).
- Both legs' costs must be inside expectancy.

## Assumptions

- Workflow/half-life formulas verified by the source against quant sources
  (QuantStart Engle–Granger, RobotWealth, Hudson & Thames); ADF absence
  consistent with statistical-testing's verified negative claim.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Correlated but not cointegrated | non-stationary spread | rule 1–2: full pipeline |
| Half-life ≤2 bars | costs eat edge | rule 3: reject pair |
| Held through decoupling | rho collapse | rule 4: breakdown guard |
| β re-estimated too fast | whipsaw hedging costs | rule 4: recalibrate discipline |

## Dependencies

Optional: regression-correlation (OLS/β), stochastic-processes (OU
half-life/VR), multi-symbol-engineering (two-leg data), data-integrity
(session alignment). Load only on their own triggers.

## Examples

- "Trade BTC vs ETH spread" → rules 2–5 with 24/7 alignment.
- "Is my spread mean-reverting enough?" → rules 2–3 stationarity + half-life.
- Persian: «همبستگی ۹۹٪ یعنی جفت خوبه؟» → rule 1: correlation ≠ cointegration.

## Verification Criteria

- Cointegration pipeline executed (log-price β, spread stationarity checks).
- Half-life sane and window sized from it.
- Breakdown guard implemented (rho floor + z-stop).
- Two-leg costs included in expectancy.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/50-statistical-arbitrage.md`.
- Resolves the pending optional-dependency pointers from regression-
  correlation and stochastic-processes (both batch-003).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `50-statistical-arbitrage.md`
- Original source path: `skills/incoming/50-statistical-arbitrage.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
