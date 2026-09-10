# Skill: macro-economics

## Metadata

```yaml
id: macro-economics
name: Macro Economics
version: 1.0.0
path: skills/normalized/research/macro-economics/skill.md
layer: RESEARCH
domains: [macro, market-context]
triggers:
  english:
    - request.economic
    - CPI inflation data
    - interest rate INTR
    - GDP unemployment macro series
    - step series macro data
    - economic calendar limitation
  persian:
    - اقتصاد کلان
    - تورم و نرخ بهره
    - داده‌های اقتصادی
dependencies:
  mandatory: []
  optional: [intermarket-analysis, multi-symbol-engineering,
    documentation-verification, falsification-and-counterexamples]
status: normalized
priority: 2
```

## Purpose

Inflation, rates, monetary policy, GDP, employment, liquidity, money supply —
as trader-relevant context with Pine data access (`request.economic`), with
step-series discipline.

## Triggers

Select for: macro regime context for strategy gating; intermarket narrative
validation; inflation/rate/GDP/employment series questions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Macro context need | description | formalization contract | yes |
| Country/field codes needed | parameters | official field list | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Economic-series acquisition pattern | code pattern | Implementation |
| Step-series handling rules | constraints | Implementation |
| Calendar-limitation documentation | constraint record | Pre-Verification |

## Rules

1. Pine data access (verified): `request.economic("US", "CPI")` (inflation),
   `request.economic("US", "INTR")` (policy interest rate),
   `request.economic("US", "GDP")`, `request.economic("US", "UR")`
   (unemployment). Country codes: ISO alpha-2 ("US", "DE", "JP") +
   aggregates ("EU"). Field names are SHORT codes (CPI, INTR, GDP, UR,
   NFP...) — see the official support article for the full field list;
   treat unlisted fields as unverified (see documentation-verification).
2. Step-series discipline: these series update MONTHLY/QUARTERLY — as chart
   overlays they are STEP SERIES (flat for weeks, then jump). Never compute
   short-window indicators (e.g., RSI-14 of CPI) directly on them.
3. Macro → trading logic (step-series aware): regime context = rate
   direction (INTR falling = easing) + CPI trend → liquidity posture; use
   as SLOW FILTERS (e.g., `ratesFalling = ir < ir[60]`). Event risk: NO
   Pine access to future economic-calendar timestamps
   (`request.economic` = history only); event-risk windows (CPI/FOMC
   release days) must be handled manually or via hardcoded calendars —
   document this limit.
4. Monetary policy & liquidity concepts: easing cycle → risk-asset
   tailwinds; tightening → dispersion up, trend persistence down
   (heuristics to falsify per asset — see
   falsification-and-counterexamples). Liquidity proxy ideas: DXY inverse +
   yields direction (see intermarket-analysis), money-supply fields if
   listed in the official field list (verify name before use).

## Workflow

1. Verify the country/field codes against the official field list (rule 1).
2. Acquire series within the request budget (rule 1 — see
   multi-symbol-engineering); treat as step series (rule 2).
3. Use as slow filters/regime context only (rule 3); falsify heuristics
   (rule 4).
4. Document the calendar-access limitation in the project (rule 3).

## Constraints

- No macro series treated like high-frequency price data.
- No assumption of upcoming-event visibility (Pine cannot).
- No hardcoding field names absent from the official list.
- Request budget: macro requests are per-country-per-field unique requests
  (cap 40 — see multi-symbol-engineering).

## Assumptions

- Economic/earnings functions + no-calendar-events limit verified vs
  official support articles (import re-verified 2026-09: signature, ISO
  codes + EU aggregate, CPI/GDP codes verbatim from the official article).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| RSI-14 on CPI | step-series distortion | rule 2: slow filters only |
| "Pine knows CPI day" | impossible | rule 3: calendar limitation |
| Invented field code | request fails/na | rule 1: official list |
| Budget burn | >40 requests | constraint: budget accounting |

## Dependencies

Optional: intermarket-analysis (DXY/yields proxies),
multi-symbol-engineering (request budget), documentation-verification
(field-list checks), falsification-and-counterexamples (macro heuristics).
Load only on their own triggers.

## Examples

- "Gate my strategy by rate direction" → rule 3 slow filter.
- "Can I backtest around CPI days automatically?" → rule 3: no calendar
  access — manual windows.
- Persian: «داده تورم رو چطور بکشم تو پین؟» → rule 1: request.economic.

## Verification Criteria

- Field codes verified against the official list.
- Step-series discipline applied (no short-window indicators on macro
  series).
- Calendar limitation documented.
- Request-budget accounting present.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope (full field list lives in the official support
  article — consult at use time, per rule 1).

## Import Notes

- Batch `batch-006` import from `skills/incoming/55-macro-economics.md`.
- `request.economic()` independently re-verified at import against the
  official support article (43000665359): signature, ISO alpha-2 +
  aggregates, CPI/GDP codes verbatim. Structural reorganization only; no
  semantic changes.

## Source Reference

- Original filename: `55-macro-economics.md`
- Original source path: `skills/incoming/55-macro-economics.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
