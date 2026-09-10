# Skill: multi-symbol-engineering

## Metadata

```yaml
id: multi-symbol-engineering
name: Multi-Symbol Engineering
version: 1.0.0
path: skills/normalized/implementation/multi-symbol-engineering/skill.md
layer: IMPLEMENTATION
domains: [multi-symbol, data-acquisition]
triggers:
  english:
    - request another symbol
    - benchmark request
    - relative strength
    - correlation with index
    - ticker.new ticker.modify
    - request.financial
    - request.economic
    - request.quandl removed
    - cross-exchange alignment
  persian:
    - دیتای نماد دیگر
    - قدرت نسبی
    - همبستگی با شاخص
    - فیلتر بین‌بازاری
    - هم‌ترازی سشن‌ها
dependencies:
  mandatory: []
  optional: [mtf-engineering, repainting-and-lookahead, data-integrity, pine-v6]
status: normalized
priority: 2
```

## Purpose

Cross-asset data engineering: requesting benchmarks and other symbols,
building/modifying ticker IDs, fundamentals and macro data requests, relative
strength/correlation/regime patterns, and cross-exchange session alignment —
with request-budget discipline.

## Triggers

Select for: RS vs SPX-style comparisons; DXY filters; BTC/ETH ratios; sector
vs index; spread construction; fundamentals/macro series; any second-symbol
request design.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Symbols/benchmarks needed | list | formalization contract | yes |
| Timeframes + repaint tolerance per request | design facts | mtf-engineering pattern choice | yes |
| Plan tier (fundamentals, footprint) | context | user request | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Symbol-request design (IDs, TFs, patterns) | design decision | Implementation |
| Request-budget plan | constraint notes | Feasibility |
| Session-alignment strategy | constraint notes | Formalization |

## Rules

1. Requesting other symbols:
   `request.security("SPX", "1D", close)`-style; use the exchange prefix when
   ambiguous (e.g., "NASDAQ:NDX", "CBOE:VIX"); `syminfo.tickerid` = full ID of
   the chart symbol. Apply repainting-and-lookahead / mtf-engineering rules to
   every request; each unique request counts toward the 40-request cap (64
   Ultimate).
2. Ticker construction: `ticker.new(prefix, ticker, session, adjustment)` for
   custom ticker IDs (e.g., extended-session context); `ticker.modify(tickerid,
   session, adjustment, ...)` to change session or corporate-action adjustments;
   `ticker.standard()` strips modifiers back to the plain symbol.
3. Fundamentals & macro data: `request.financial(symbol, financial_id, period,
   ...)` — FactSet fundamentals, plan-gated, periods "FQ"/"FY"/"TTM"/"D";
   `request.economic(country_code, field, ...)` — macro series;
   `request.quandl()` — REMOVED/deprecated, do not use in new code;
   `request.footprint()` — volume footprint objects (rows, delta, POC, VA) via
   `footprint.*`/`volume_row.*` (added 2026-01, confirmed against release notes
   at import), Premium/Ultimate plans.
4. Analysis patterns: relative strength `close / request.security("SPX", "1D",
   close)`; correlation `ta.correlation(close, request.security("DXY", "1D",
   close), 20)`; regime filter (risk-on/off via benchmark vs its MA). Benchmark
   choice — index vs ETF (SPX vs SPY: ETF has extended hours/volume; index
   doesn't trade) — decide deliberately; normalize RS with its own moving
   average to avoid scale drift.
5. Cross-exchange session alignment: different sessions → mismatched bars and
   na from gaps_on; normalize by comparing on "1D", align sessions explicitly
   via `ticker.modify`, or fill with gaps_off accepting stale-value semantics
   (document it). Crypto vs equities: weekend crypto bars have no equity
   counterpart — equity filters evaluate on stale/na data those days.
6. Request budget discipline: precompute the symbol list; reuse identical
   requests (duplicates are free); guard optional symbols with
   `ignore_invalid_symbol = true` + na checks; validate returned series for na
   rather than letting runtime errors surface.

## Workflow

1. Enumerate required external series; pick IDs with explicit exchange
   prefixes (rule 1).
2. Assign each request an MTF pattern (confirmed/live/lagged) and repaint
   consequence with mtf-engineering + repainting-and-lookahead.
3. Apply session-alignment strategy (rule 5) for cross-exchange pairs.
4. Budget requests (rules 1, 6) and plan-gate fundamentals/footprint (rule 3).
5. Record alignment and stale-value semantics in the Formalization contract.

## Constraints

- `request.quandl()` is removed — forbidden in new code.
- Fundamentals and footprint are plan-gated — never assumed available.
- Unique-request caps (40/64) shared with mtf-engineering.

## Assumptions

- Symbol/financial/economic request semantics per official docs as claimed by
  the source; footprint addition date verified at import.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Wrong benchmark resolved | ambiguous symbol | rule 1: exchange prefix |
| Weekend filter misfires on crypto | missing equity bars | rule 5: alignment strategy |
| quandl in new code | compile/runtime failure | rule 3: removed — do not use |
| Optional symbol missing | na series | rule 6: ignore_invalid_symbol + na checks |

## Dependencies

Optional: mtf-engineering (request patterns/budgets), repainting-and-lookahead
(HTF confirmation), data-integrity (na/session handling), pine-v6
(dynamic-requests default). Load only on their own triggers.

## Examples

- "Show BTC dominance-style ratio" → rule 4 RS pattern + normalization.
- "Filter longs by SPX above its 200-SMA" → rule 4 regime filter + rule 1
  confirmed request pattern.
- Persian: «درخواست نماد دوم بودجه request را می‌سوزاند» → rule 6: reuse
  identical requests.

## Verification Criteria

- Every external symbol request has an exchange-ambiguous-free ID and a
  documented MTF pattern.
- No `request.quandl()` anywhere.
- Session-alignment semantics documented for cross-exchange comparisons.
- Request budget counted with duplicate-reuse; optional symbols na-guarded.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope (plan-gating specifics covered by the shared
  re-verify caveat on plan limits).

## Import Notes

- Batch `batch-002` import from `skills/incoming/15-multi-symbol-engineering.md`.
- Structural reorganization only; no semantic changes. Source cross-references
  "skill 12/13" → optional dependencies (both imported this batch).
- The `request.footprint()` 2026-01 addition was independently confirmed
  against official release notes during batch-001 import; consistency holds.

## Source Reference

- Original filename: `15-multi-symbol-engineering.md`
- Original source path: `skills/incoming/15-multi-symbol-engineering.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
