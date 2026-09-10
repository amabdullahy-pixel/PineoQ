# Skill: system-psychology

## Metadata

```yaml
id: system-psychology
name: System Psychology
version: 1.0.0
path: skills/normalized/research/system-psychology/skill.md
layer: RESEARCH
domains: [behavioral, system-design]
triggers:
  english:
    - drawdown tolerance operator
    - overtrading circuit breaker
    - signal frequency fit
    - alert fatigue
    - automation ladder
    - deployment readiness human
  persian:
    - روانشناسی سیستم معاملاتی
    - تحمل افت سرمایه
    - معامله‌گری بیش از حد
dependencies:
  mandatory: []
  optional: [position-sizing, monte-carlo-and-resampling,
    signal-engineering, risk-management, alerts-and-webhooks,
    tradingview-execution-model, strategy-engine, backtesting-science]
status: normalized
priority: 1
```

## Purpose

The human-strategy interface: drawdown tolerance, signal frequency, fatigue,
overtrading, execution constraints — engineered INTO the system, not left to
willpower.

## Triggers

Select for: designing a system for a real operator; live-deployment
readiness walkthroughs; overtrading/alert-fatigue complaints;
manual-override policy design.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Operator profile (attention, DD tolerance) | parameters | user, measured | yes |
| Expected signal frequency | metric | signal design | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Sizing constrained by operator DD tolerance | parameter | position-sizing |
| Frequency/capacity fit decision | design decision | signal-engineering |
| Circuit-breaker + override policy | code requirements | Implementation |
| Deployment readiness checklist | verification record | Post-Verification |

## Rules

1. Drawdown tolerance (design parameter, not afterthought): the REAL
   constraint is the drawdown that makes the OPERATOR abandon the system.
   Measure operator tolerance honestly; position sizing must target the
   historical/MC 95th-pct drawdown BELOW that tolerance (MC DD distribution
   — monte-carlo-and-resampling). Pain pacing: losing streaks of length L
   occur with probability 1−W^L sequences — design so the expected worst
   streak per month is tolerable.
2. Signal frequency fit: signals/day > operator capacity → missed
   executions = live/backtest divergence; cap by cooldown + score threshold
   (signal-engineering). Too FEW signals → impatience-driven rule breaking.
   Frequency must match the operator's engagement style; measure the actual
   alert-to-action rate.
3. Fatigue & overtrading guardrails IN CODE: after N consecutive losses,
   manual-override probability rises — pre-commit override rules in writing
   or hard-lock via `strategy.risk.max_cons_loss_days` (risk-management).
   Native circuit breaker: `strategy.risk.max_intraday_filled_orders(6)`;
   daily counters reset on session change (`ta.change(time("D"))`).
   Alert fatigue: batch/summarize notifications (alerts-and-webhooks);
   tick-frequency alerts burn attention — `freq_once_per_bar_close`
   default discipline.
4. Human execution constraints: engineer against live/backtest divergence
   sources — intrabar alerts (tradingview-execution-model), fills at open
   vs intended (strategy-engine), alert latency, missed bars outside
   session; prefer close-confirmed signals + webhook automation
   (alerts-and-webhooks). Automation ladder: manual → alert-assisted →
   semi-auto (webhook to execution layer) → full auto; each step reduces
   bias leakage but adds failure modes to test (duplicate webhooks,
   idempotency).
5. Deployment readiness checklist: operator's real DD tolerance measured,
   sizing validated against MC 95%; signal frequency matches capacity,
   alerts de-duplicated; override rules written BEFORE live use, circuit
   breakers active; 2–4 weeks paper/forward run matches backtest stats
   (backtesting-science gate).

## Workflow

1. Measure operator tolerance and capacity (rules 1–2).
2. Constrain sizing and frequency from those measurements (rules 1–2).
3. Encode circuit breakers and override policy in code (rule 3).
4. Run the deployment readiness checklist before live use (rule 5).

## Constraints

- No sizing to strategy tolerance while ignoring operator tolerance.
- No intrabar alerts for human-executed systems (chasing unconfirmed
  signals).
- No live use without a pre-committed override policy (fatigue wins).

## Assumptions

- Native circuit breakers + alert semantics cross-referenced from verified
  skills 09/11/30/31 inventories (source-declared, consistent).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Operator abandons at −15% | sizing ignored human DD | rule 1: tolerance-first sizing |
| Human chases intrabar alerts | unconfirmed signals | rule 3: close-confirmed only |
| Fatigue override mid-drawdown | no written policy | rule 3/5: pre-commit + lock |
| Frequency mismatch found live | missed executions | rule 2: capacity fit upfront |

## Dependencies

Optional: position-sizing (tolerance-constrained sizing),
monte-carlo-and-resampling (95th-pct DD), signal-engineering
(frequency capping), risk-management (risk functions),
alerts-and-webhooks (dedup/webhooks), tradingview-execution-model
(execution semantics), strategy-engine (fill mechanics),
backtesting-science (forward-run gate). Load only on their own triggers.

## Examples

- "I keep overriding my system during drawdowns" → rules 1, 3.
- "My alerts fire too often to follow" → rules 2–3.
- Persian: « وسط ضرر تصمیم‌های احساسی می‌گیرم» → rules 1, 3, 5.

## Verification Criteria

- Operator DD tolerance measured and sizing validated against MC 95%.
- Frequency/capacity fit documented with alert-to-action measurement.
- Circuit breakers + written override policy active before live use.
- Forward/paper run compared to backtest stats.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/61-system-psychology.md`.
- Resolves the batch-006 parked candidate {29↔61} (financial-mathematics ↔
  system-psychology: related_but_distinct — 29 is the math of finance, 61
  is operator-system interface; no merge). Source's illustrative Pine
  snippet preserved as prose + inline identifiers per normalization
  convention (no code generated). Structural reorganization only; no
  semantic changes.

## Source Reference

- Original filename: `61-system-psychology.md`
- Original source path: `skills/incoming/61-system-psychology.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
