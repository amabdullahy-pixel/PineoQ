# Skill: momentum-indicators

## Metadata

```yaml
id: momentum-indicators
name: Momentum Indicators
version: 1.0.0
path: skills/normalized/research/momentum-indicators/skill.md
layer: RESEARCH
domains: [technical-analysis, momentum]
triggers:
  english:
    - RSI Wilder formula
    - stochastic slow fast
    - CCI formula
    - Williams %R
    - TSI
    - divergence detection
    - oscillator regime behavior
  persian:
    - اندیکاتورهای مومنتوم
    - شاخص RSI
    - همگرایی و واگرایی
    - اسیلاتور
dependencies:
  mandatory: []
  optional: [technical-analysis-core, regime-detection, statistics-core, repainting-and-lookahead]
status: normalized
priority: 2
```

## Purpose

RSI, Stochastic, CCI, ROC, Williams %R, Momentum, TSI — exact formulas and
pitfalls, plus divergence-engineering practice and oscillator behavior across
regimes.

## Triggers

Select for: exhaustion/acceleration/divergence logic; mean-reversion triggers;
oscillator selection; "why is my stochastic different from the platform's?";
divergence detector design.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Momentum-logic requirement | description | formalization contract | yes |
| Regime context | design fact | regime-detection | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct oscillator implementation | knowledge applied | Implementation |
| Regime-dependence warnings | warnings | Pre-Verification |
| Divergence detector design | implementation pattern | Implementation |

## Rules

1. Verified formulas: RSI `ta.rsi(src, len)` = 100 − 100/(1+RS),
   RS = rma(avgGain)/rma(avgLoss) (Wilder) — overbought/oversold are
   regime-relative (in strong trends RSI pins 60–80; regime gate first);
   Stochastic `ta.stoch(src, high, low, len)` = raw %K =
   100·(src − lowest(low,len))/(highest(high,len) − lowest(low,len)) — NO
   built-in smoothing/slowing/%D: apply `ta.sma(raw, 3)` manually for slow
   %K / %D; CCI = (src − sma)/(0.015·meanDeviation); ROC = (src − src[len])/
   src[len] × 100; MOM = src − src[len]; Williams %R `ta.wpr(len)` =
   −100·(highest − close)/(highest − lowest) ∈ [−100, 0]; TSI
   `ta.tsi(src, short, long, signal)` double-smoothed momentum.
2. Divergence engineering: price HH/LL vs indicator opposite — detect with
   `ta.pivothigh/ta.pivotlow` on BOTH series (confirmed-with-lag — see
   repainting-and-lookahead); store pivots in arrays and compare levels;
   require indicator-peak within a bar-tolerance window of price-peak.
3. Oscillator behavior across regimes: trend → oscillators pin/extreme
   ("oversold" ≠ buy; regime gate first — see regime-detection); range →
   reversion triggers shine; normalize across assets via z/percentrank (see
   statistics-core) when fusing (see signal-fusion).
4. Warm-up/flat-window handling: na in warm-up windows and divide-by-zero on
   flat windows follow numerical-methods/statistics-core guards.

## Workflow

1. Select the oscillator by regime intent (rule 3) — not by popularity.
2. Implement from verified formulas (rule 1); add manual stochastic smoothing
   explicitly.
3. For divergence, build the confirmed-pivot array comparison (rule 2).
4. Gate all oscillator signals through the regime context (rules 1, 3).

## Constraints

- No built-in slow stochastic — manual smoothing required.
- No divergence detection on unconfirmed pivots (repaint).

## Assumptions

- Formulas verified against reference/support articles by the source
  (RSI support article cited).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Built-in" slow stoch assumed | wrong smoothing | rule 1: manual SMA(raw, 3) |
| RSI extremes traded in trends | pinned oscillator | rule 3: regime gate |
| Divergence repaints | unconfirmed pivots | rule 2: confirmed-with-lag |
| Flat-window division | inf/nan | rule 4: guards |

## Dependencies

Optional: technical-analysis-core (pillar context), regime-detection (regime
gates), statistics-core (normalization), repainting-and-lookahead (pivot
confirmation). Load only on their own triggers.

## Examples

- "Add slow stochastic %D" → rule 1 manual smoothing.
- "Detect RSI bearish divergence" → rule 2 dual-pivot arrays.
- Persian: «چرا RSI در روند اشباع می‌ماند؟» → rule 3 regime behavior.

## Verification Criteria

- Oscillator formulas match the verified table; manual smoothing explicit.
- Regime gating precedes oscillator signal logic.
- Divergence detectors use confirmed pivots with tolerance windows.
- Warm-up/flat-window guards present.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/36-momentum-indicators.md`.
- Layer decision: RESEARCH (consistent with the TA block).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `36-momentum-indicators.md`
- Original source path: `skills/incoming/36-momentum-indicators.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
