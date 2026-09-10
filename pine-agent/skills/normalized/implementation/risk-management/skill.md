# Skill: risk-management

## Metadata

```yaml
id: risk-management
name: Risk Management
version: 1.0.0
path: skills/normalized/implementation/risk-management/skill.md
layer: IMPLEMENTATION
domains: [risk-control, strategies]
triggers:
  english:
    - risk per trade
    - daily loss limit
    - strategy.risk
    - drawdown accounting high-water mark
    - risk of ruin
    - exposure cap
    - correlated positions risk
  persian:
    - مدیریت ریسک
    - حد ضرر روزانه
    - افت سرمایه
    - احتمال نابودی
    - سقف پوزیشن
dependencies:
  mandatory: []
  optional: [strategy-engine, position-sizing, monte-carlo-and-resampling, multi-symbol-engineering]
status: normalized
priority: 1
```

## Purpose

Risk per trade, drawdown control, risk of ruin, exposure, correlation risk,
and daily loss limits with verified v6 native tools (`strategy.risk.*`) plus
portable manual patterns — the capital-preservation layer for any strategy
build.

## Triggers

Select for: any strategy build; before trusting any backtest; capital-
preservation design; daily-loss or drawdown circuit breakers; exposure/
correlated-position caps; "was strategy.risk.* removed?" doubts.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Risk requirements (per-trade %, daily cap) | parameters | user/formalization | yes |
| Strategy context (equity, positions) | data | strategy script | yes |
| Trade history (for ruin estimates) | data | strategy results | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Risk-control design (native + manual) | design decision | Implementation |
| Sizing requirements | handoff | position-sizing |
| Ruin/exposure analysis | verification output | Post-Verification |

## Rules

1. Per-trade risk: Risk$ = (entry − stop) distance × size; Risk% = Risk$ /
   equity; design target = constant Risk% per trade (0.5–2% typical); sizing
   mechanics live in position-sizing; worst-case per trade must include
   gaps/slippage — effective stop is worse than theoretical (broker emulator
   fills gaps at bar open, see strategy-engine).
2. Native risk guardrails (v6 — VERIFIED PRESENT; import-time re-verification
   against official docs passed): `strategy.risk.max_intraday_loss(value,
   type)` (type: `strategy.percent_of_equity` / `strategy.cash`; the
   reference also lists `strategy.fixed_loss_dollars` — verify exact accepted
   constants per symbol before relying); `strategy.risk.max_drawdown(value,
   type)`; `strategy.risk.max_intraday_filled_orders(count)`;
   `strategy.risk.max_cons_loss_days(count)`;
   `strategy.risk.max_position_size(count)`;
   `strategy.risk.allow_entry_in(strategy.direction.long|short|all)`.
   Semantics: once a limit trips it stops that day/session and CANNOT be
   undone intraday; these act in backtests too.
3. Manual daily-loss limit (portable pattern): snapshot day-start equity on
   `ta.change(time("D")) != 0`; compute dayPnL; gate ALL entries with
   `not dailyStop` where dailyStop = dayPnL ≤ −X% of initial capital.
4. Drawdown accounting: equity high-water mark via `var float hwm` updated
   with `math.max(hwm, strategy.equity)`; DD = 1 − equity/hwm; native
   `strategy.max_drawdown` and `strategy.max_drawdown_percent` (closed+open
   equity, tester definition — existence re-verified at import).
5. Risk of ruin: analytic forms assume i.i.d. trades and fixed fraction —
   real trades cluster; practical estimate = Monte Carlo on trade history
   (see monte-carlo-and-resampling), P(ruin) = fraction of paths breaching
   the loss cap; report with CIs (see statistical-testing).
6. Exposure & correlation risk: exposure = Σ|position value| / equity (with
   pyramiding > 1 easily exceeds 100%); correlated concurrent positions are
   one bet in disguise — cap correlated exposure jointly (e.g., BTC+ETH
   longs share one risk bucket; see multi-symbol-engineering); v6 default
   margin 100% (no implicit leverage) — margin ≤ 100 simulates leverage and
   margin-call liquidations (see strategy-engine).

## Workflow

1. Set per-trade Risk% target and stop placement; hand sizing math to
   position-sizing (rule 1).
2. Choose native `strategy.risk.*` guardrails (rule 2) and/or the portable
   manual daily-stop pattern (rule 3); document trip semantics.
3. Implement HWM/DD accounting (rule 4) for reporting.
4. Estimate P(ruin) via MC with CIs (rule 5); cap correlated exposure
   jointly (rule 6).

## Constraints

- `strategy.risk.*` trips are irreversible intraday — design thresholds
  accordingly.
- The existence of all six `strategy.risk.*` functions is verified; any
  contrary claim must be re-run through pine-version-intelligence.

## Assumptions

- v6 reference presence of `strategy.risk.*` verified by the source AND
  independently re-verified at import (official Strategies docs + v6
  reference index).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "strategy.risk.* removed in v6" claim | false rumor | rule 2: verified present; run pine-version-intelligence |
| Gap through stop | worse-than-theoretical loss | rule 1: gap-aware stop distance |
| Correlated positions summed as diversified | hidden concentration | rule 6: joint risk buckets |
| No daily stop on continuous strategy | runaway day | rule 3: manual limit or native guardrail |

## Dependencies

Optional: strategy-engine (emulator fills, margin mechanics),
position-sizing (sizing math), monte-carlo-and-resampling (ruin estimation),
multi-symbol-engineering (correlated-symbol context). Load only on their own
triggers.

## Examples

- "Halt trading after a −2% day" → rule 3 manual pattern or rule 2
  max_intraday_loss.
- "Cap total exposure across my BTC/ETH longs" → rule 6 joint bucket.
- Persian: «استراتژی‌ام روز بد را متوقف کند» → rule 3.

## Verification Criteria

- Per-trade risk math includes gap/slippage worst case.
- Risk guardrail choice (native vs manual) documented with trip semantics.
- HWM/DD accounting implemented for reporting.
- Ruin estimates MC-based with CIs; correlated exposure capped jointly.

## Ambiguities

- The `strategy.fixed_loss_dollars` constant: listed by the source as present
  in the reference but flagged verify-per-symbol before relying (preserved
  verbatim).

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/30-risk-management.md`.
- VERIFICATION EVENT corroborated: the source documents that an earlier
  research pass falsely claimed `strategy.risk.*` was removed in v6, corrected
  by direct reference check. At import this was INDEPENDENTLY re-verified:
  official TradingView Strategies concepts page and the v6 reference index
  list the risk functions; `strategy.max_drawdown_percent` confirmed on the
  official Strategies page. A third-party blog repeating the removal claim
  was identified as the false claim the source warned about. No semantic
  changes required — the source's correction stands, now double-verified.
- Layer decision: primary layer IMPLEMENTATION (function = building risk
  controls into strategies with Pine APIs/patterns), secondary domain
  quant/risk.
- Structural reorganization otherwise; no semantic changes.

## Source Reference

- Original filename: `30-risk-management.md`
- Original source path: `skills/incoming/30-risk-management.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed (load-bearing claims independently re-verified)
- Import date: 2026-09 (batch-003)
