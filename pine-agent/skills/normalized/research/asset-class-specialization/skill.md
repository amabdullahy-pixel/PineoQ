# Skill: asset-class-specialization

## Metadata

```yaml
id: asset-class-specialization
name: Asset-Class Specialization
version: 1.0.0
path: skills/normalized/research/asset-class-specialization/skill.md
layer: RESEARCH
domains: [market-context, asset-classes]
triggers:
  english:
    - crypto forex equities futures differences
    - syminfo.type class detection
    - session handling per class
    - porting strategy across markets
    - index not tradable
    - tick volume forex
  persian:
    - تفاوت کلاس‌های دارایی
    - پرت کردن استراتژی بین بازارها
    - سشن‌های هر کلاس
dependencies:
  mandatory: []
  optional: [market-microstructure, data-integrity, multi-symbol-engineering,
    position-sizing, volume-analysis, falsification-and-counterexamples]
status: normalized
priority: 2
```

## Purpose

Crypto, forex, equities, indices, futures, commodities, bonds, ETFs —
class-specific behaviors and Pine branching for porting one strategy across
classes.

## Triggers

Select for: porting a strategy across asset classes; per-class
parameterization; session/volume/cost differences; "why doesn't it work on
forex?" style questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Target class(es) | list | formalization contract | yes |
| Class-conditional parameter values | parameters | user (per class) | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| syminfo.type branching pattern | code pattern | Implementation |
| Per-class parameter table | design artifact | Implementation |
| Migration checklist results | verification record | Pre/Post-Verification |

## Rules

1. Class detection & branching: `string cls = syminfo.type` — crypto /
   futures / forex / stock / index / fund (+ dr, cfd, bond, warrant — see
   market-microstructure); same strategy code with class-conditional
   parameters (session gates, sizing, thresholds) via a settings UDT
   (pine-data-structures).
2. Per-class realities (verified semantics): crypto — 24/7 (ismarket true),
   fees %, small spreads on majors, weekend liquidity dips, funding not
   modeled; forex — ~Sun–Fri UTC, spread-based (no commission usually), no
   central volume (TICK volume only); equities — RTH + extended,
   commission + spread, halts, earnings gaps (`request.earnings`); index —
   chart context only, NOT tradable (use futures/ETF proxy in production);
   futures — ETH + maintenance breaks, commission/contract, pointvalue math
   (market-microstructure), rolls; bonds — exchange hours, quoted in
   yield/points (TVC:US10Y-style feeds for context); ETF — like equities,
   proxies for index exposure.
3. Session handling per class: crypto — skip session gates; weekend RVOL
   baselines differ → day-of-week-aware baselines (time-series-analysis);
   forex — volume fields = tick volume (broker-dependent) → volume filters
   need recalibration (volume-analysis); equities — earnings/dividend gap
   risk → `request.earnings` context gates.
4. Class migration checklist (porting a strategy): syminfo.type branch
   exists for EVERY assumption (sessions, volume, costs); costs re-modeled
   per class (strategy-engine / backtesting-science); sizing re-derived
   (pointvalue for futures — position-sizing); thresholds re-falsified per
   class (falsification-and-counterexamples) — never reuse.

## Workflow

1. Detect class via syminfo.type; enumerate assumptions (rule 1).
2. Apply the per-class reality table (rule 2).
3. Rework sessions/volume handling per class (rule 3).
4. Run the full migration checklist before declaring portability (rule 4).

## Constraints

- One parameter set across all classes is forbidden.
- Forex volume filters without tick-volume awareness are invalid.
- Backtesting an index and trading it "directly" is impossible.
- Crypto weekend liquidity must not be treated like weekday.

## Assumptions

- Class list/sessions verified vs chart-information and sessions docs
  (source-verified).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Same params on BTC and EURUSD | no branching | rule 1/4: class-conditional |
| OBV on forex pair | no real volume | rule 3: tick-volume recalibration |
| "Trading SPX" | index not tradable | rule 2: futures/ETF proxy |
| Weekend crypto signals | weekday baselines | rule 3: DOW-aware baselines |

## Dependencies

Optional: market-microstructure (class semantics, pointvalue),
data-integrity (session alignment), multi-symbol-engineering (earnings
requests), position-sizing (class sizing), volume-analysis (tick-volume
recalibration), falsification-and-counterexamples (per-class thresholds).
Load only on their own triggers.

## Examples

- "Port my equity strategy to crypto" → rule 4 migration checklist.
- "Why is my volume filter wrong on forex?" → rule 3 tick volume.
- Persian: «استراتژی سهامی رو بردم روی کریپتو، چرا خراب شد؟» → rule 4:
  re-falsify thresholds.

## Verification Criteria

- syminfo.type branching covers every documented assumption.
- Costs and sizing re-derived per class.
- Session/volume handling class-aware.
- Migration checklist completed and recorded.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/58-asset-class-specialization.md`.
- Source frontmatter carried a stray `class:` line alongside `category:` —
  recorded by the source itself as fixed during archiving; normalized file
  uses the standard metadata only (no content change). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `58-asset-class-specialization.md`
- Original source path: `skills/incoming/58-asset-class-specialization.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
