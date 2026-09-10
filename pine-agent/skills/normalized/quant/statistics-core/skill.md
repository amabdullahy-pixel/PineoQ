# Skill: statistics-core

## Metadata

```yaml
id: statistics-core
name: Statistics Core
version: 1.0.0
path: skills/normalized/quant/statistics-core/skill.md
layer: QUANT
domains: [statistics, pine-mapping]
triggers:
  english:
    - descriptive statistics
    - stdev biased or sample
    - mean absolute deviation ta.dev
    - percentile vs percentrank
    - z-score
    - MAD robust
    - IQR outlier fences
  persian:
    - آمار توصیفی
    - انحراف معیار
    - صدک و رتبه صدکی
    - نمره استاندارد z
dependencies:
  mandatory: []
  optional: [mathematical-foundation, numerical-methods, statistical-distributions, time-series-analysis]
status: normalized
priority: 1
```

## Purpose

Descriptive statistics (central tendency, dispersion, percentiles, robust
stats) with exact Pine v6 implementations — the normalization/threshold layer
for any summary of price or indicator distributions.

## Triggers

Select for: any normalization, threshold, or distribution summary; z-score or
band construction; percentile/percentrank confusion; outlier-fence design;
biased-vs-sample stdev questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Statistic/normalization need | description | formalization contract | yes |
| Window length + data character (outliers?) | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct ta.* statistic choice | knowledge applied | Implementation |
| Robust-statistics guidance | design decision | Implementation Planning |
| Degenerate-window risk flags | warnings | Pre-Verification |

## Rules

1. Central tendency (Pine-verified per source): `ta.sma` (mean, ignores na),
   `ta.ema`/`ta.rma`/`ta.wma`/`ta.vwma` (weighted means — smoothing ladder in
   time-series-analysis), `ta.median` (outlier-robust), `ta.mode` (most
   frequent value; tie → smallest value returned), `ta.cog` (center of
   gravity: −Σ(price·weight)/Σprice — weighted, reverses emphasis).
2. Dispersion: `ta.stdev(src, len, biased)` — biased=true (default) divides by
   N (population), false divides by N−1 (sample); the default matters for
   z-scores. `ta.variance` (same flag) = stdev². `ta.dev(src, len)` = Mean
   Absolute Deviation around the SMA — robust-ish alternative to stdev.
   `ta.range(src, len)` = max − min. `ta.tr(handle_na)` = true range;
   `ta.atr` = RMA of tr.
3. Percentiles & ranks — three distinct tools, do not confuse:
   `ta.percentile_linear_interpolation` (interpolates between neighboring
   ranks → value may NOT exist in data; smooth, good for bands);
   `ta.percentile_nearest_rank` (always returns an ACTUAL data point;
   discrete, good for "nth largest"); `ta.percentrank` (% of previous values
   ≤ current value; 0–100 rank of now within history — the normalization
   workhorse).
4. Z-scores & robust statistics: classic
   `(src - ta.sma(src, len)) / ta.stdev(src, len, false)` (sample stdev);
   robust variant `(src - ta.median) / (1.4826 * ta.dev)` — 1.4826 makes MAD
   comparable to σ under normality. Robust practice: median/MAD when fat
   tails or outliers present; clamp z to ±N so a single bar cannot dominate
   logic.
5. Quartiles: Q1/Q3 = percentiles 25/75; IQR = Q3−Q1; outlier fences =
   Q1−1.5·IQR / Q3+1.5·IQR.

## Workflow

1. Choose the statistic per distribution character (rule 1–2); outliers →
   median/MAD path (rule 4).
2. Pick the correct percentile tool by need (rule 3) — bands vs actual-rank
   vs current-normalization.
3. Guard degenerate windows (flat data → stdev 0) per numerical-methods.
4. Record biased-flag choice where sample semantics matter.

## Constraints

- Default `ta.stdev` is biased (population) — explicit flag for sample stats.
- `ta.dev` centers on the SMA, not the median (different from MAD-median).

## Assumptions

- Signatures verified against the v6 reference by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Default biased stdev in sample context | slightly low dispersion (small len) | rule 2: pass biased=false |
| percentile_nearest_rank used for smooth bands | jumpy bands | rule 3: linear_interpolation |
| z on flat window | 0 division → inf/nan | numerical-methods checklist |
| ta.dev confused with MAD-median | wrong center | rule 2/4: different center |

## Dependencies

Optional: mathematical-foundation (precision/epsilon), numerical-methods
(degenerate guards), statistical-distributions (fat-tail context),
time-series-analysis (rolling/expanding practice). Load only on their own
triggers.

## Examples

- "Rank current volume within the last 100 bars" → rule 3 `ta.percentrank`.
- "Outlier-resistant bands" → rule 4 robust z with median/MAD.
- Persian: «چرا باند‌هایم پرش دارد؟» → rule 3: wrong percentile tool.

## Verification Criteria

- Correct biased flag where sample statistics are intended.
- Percentile tool choice matches the stated need.
- Degenerate-window guards present (variance-0 handling).
- z-scores clamped where they feed logic.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/21-statistics-core.md`.
- Resolves the batch-002 pending optional-dependency pointer from
  linear-algebra. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `21-statistics-core.md`
- Original source path: `skills/incoming/21-statistics-core.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
