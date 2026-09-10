# Skill: intermarket-analysis

## Metadata

```yaml
id: intermarket-analysis
name: Intermarket Analysis
version: 1.0.0
path: skills/normalized/research/intermarket-analysis/skill.md
layer: RESEARCH
domains: [market-context, correlations]
triggers:
  english:
    - DXY dollar index filter
    - yields equities relationship
    - VIX stress regime
    - correlation regime gating
    - risk on risk off
    - gold oil proxy
  persian:
    - تحلیل بین‌بازاری
    - رابطه دلار و طلا
    - رژیم همبستگی
dependencies:
  mandatory: []
  optional: [multi-symbol-engineering, data-integrity,
    repainting-and-lookahead, regime-detection, macro-economics]
status: normalized
priority: 2
```

## Purpose

Dollar, bonds, gold, commodities, equities, FX, crypto relationships and
correlation regimes — implementable with `request.security`.

## Triggers

Select for: risk-on/off filters; context confirmation from related markets;
correlation-regime gating; VIX stress overlays.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Intermarket context need | description | formalization contract | yes |
| Reference symbols chosen | symbol IDs | user (verified per plan) | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correlation-regime implementation | code pattern | Implementation |
| Stress-regime gate | contract field | risk-management, regime-detection |
| Symbol-ID verification record | documentation | Pre-Verification |

## Rules

1. Reference symbols (commonly used IDs — VERIFY LIVE before relying):
   Dollar `TVC:DXY`; US 10Y `TVC:US10Y`; VIX `TVC:VIX` (alt CBOE:VIX); Gold
   `OANDA:XAUUSD` / `TVC:GOLD`; WTI `TVC:USOIL` / front `NYMEX:CL1!`; S&P
   `SP:SPX` / `TVC:SPX`; BTC `INDEX:BTCUSD` / exchange feeds. Symbol
   resolution varies by plan/feed — validate each request returns non-na
   (multi-symbol-engineering pattern) and document the chosen IDs in the
   project manifest.
2. Core relationship map (contextual, NOT mechanical laws): equities ↔
   yields — easing/rates-down usually supports equities, sharp yield SPIKES
   = equity stress (regime-dependent); DXY inverse vs gold/equities/crypto —
   breaks down in crisis (everything correlated to cash); VIX > threshold
   (e.g., >25–30) = stress regime → size down (risk-management); gold as
   fear hedge; oil = inflation/growth proxy.
3. Correlation regimes (Pine): `spx = request.security("SP:SPX", "1D",
   close)`; `rho = ta.correlation(close, spx, 20)`; per-strategy thresholds
   (e.g., `corrRegimeStable = rho > 0.5`); crisis mode via VIX gate.
   Correlation drift is a FACTOR — recompute per window; collapse of
   diversification assumptions = exposure rule (risk-management).
4. Implementation discipline: every intermarket leg = 1 unique request
   (budget 40 — multi-symbol-engineering); align on "1D" to dodge session
   mismatch (data-integrity); apply the non-repaint HTF pattern for HTF
   context (repainting-and-lookahead / mtf-engineering); decide index vs
   ETF proxies deliberately (SPX vs SPY: ETF has extended-hours volume;
   index doesn't trade).

## Workflow

1. Choose and VERIFY reference symbol IDs per plan (rule 1).
2. Acquire legs within the request budget; align timeframes (rule 4).
3. Compute correlation regimes on rolling windows (rule 3).
4. Use relationships as FILTERS/context, never mechanical triggers (rule 2).

## Constraints

- No hardcoded symbol IDs assumed valid across plans (verify live).
- No correlation constants across years (regimes move).
- No mechanical map trading ("DXY down → buy") — filter only.
- na-handling required when a feed lacks requested history depth.

## Assumptions

- Relationship map = practice heuristics to falsify (source-declared);
  symbol table = commonly-used identifiers, needs-verification per account
  (feeds change).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Symbol resolves na | plan/feed difference | rule 1: live verification |
| Stale correlation constant | regime drift | rule 3: recompute per window |
| Mechanical map trade | unconditional rule | rule 2: filter only |
| Session-mismatched legs | misaligned bars | rule 4: "1D" alignment |

## Dependencies

Optional: multi-symbol-engineering (request budget), data-integrity
(session alignment), repainting-and-lookahead / mtf-engineering (HTF
pattern), regime-detection (stress regimes), macro-economics (rates/CPI
context). Load only on their own triggers.

## Examples

- "Size down when VIX is high" → rule 2/3 stress gate.
- "Does my altcoin follow BTC?" → rule 3 rolling correlation.
- Persian: «طلا با دلار رابطه عکس داره همیشه؟» → rule 2: contextual, not law.

## Verification Criteria

- Symbol IDs verified live and documented.
- Correlations computed per rolling window, never hardcoded.
- Request-budget accounting per leg.
- HTF legs use the non-repaint pattern.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope (symbol ID validity is plan-dependent by
  nature — handled by rule 1 verification discipline).

## Import Notes

- Batch `batch-006` import from `skills/incoming/56-intermarket-analysis.md`.
- Symbol table preserved as needs-verify-per-plan (source-declared); no
  external verification possible for plan-dependent feed availability —
  handled by mandatory live checks. Structural reorganization only; no
  semantic changes.

## Source Reference

- Original filename: `56-intermarket-analysis.md`
- Original source path: `skills/incoming/56-intermarket-analysis.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
