---
name: system-psychology
category: Behavioral Finance
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/strategies/
---

# System Psychology

## Purpose
The human-strategy interface: drawdown tolerance, signal frequency, fatigue,
overtrading, execution constraints — engineered INTO the system.

## When to Use
- System design for a real operator; walkthrough of live-deployment readiness.

## Core Knowledge

### Drawdown Tolerance (design parameter, not afterthought)
- Real constraint: the size of drawdown that makes the OPERATOR abandon the
  system. Measure operator tolerance honestly; then position sizing (skill 31)
  must target historical/MC 95th-pct drawdown BELOW that tolerance (MC DD
  distribution, skill 28).
- Pain pacing: losing streaks of length L occur with probability 1−W^L
  sequences — design so expected worst streak per month is tolerable.

### Signal Frequency Fit
- Trade frequency vs operator attention: signals/day > capacity → missed
  executions = live/backtest divergence. Cap by cooldown + score threshold
  (skill 45).
- Too FEW signals → impatience-driven rule breaking. Frequency should match
  operator's engagement style; measure actual alert-to-action rate.

### Signal Fatigue & Overtrading
- Fatigue: after N consecutive losses, manual override probability rises —
  pre-commit: override rules in writing, or hard-lock via
  `strategy.risk.max_cons_loss_days` (skill 30).
- Overtrading guardrails IN CODE:
```pine
var int tradesToday = 0
if ta.change(time("D")) != 0
    tradesToday := 0
strategy.risk.max_intraday_filled_orders(6)      // native circuit breaker
// plus custom: entries only when tradesToday < cap
```
- Alert fatigue: batch/summarize notifications (skill 11); tick-frequency
  alerts burn attention (freq_once_per_bar_close default discipline).

### Human Execution Constraints
- Live/backtest divergence sources to engineer against: intrabar alerts
  (skill 07), fills at open vs intended (skill 09), alert latency, missed bars
  outside session — prefer close-confirmed signals + webhook automation (skill 11).
- Automation ladder: manual → alert-assisted → semi-auto (webhook to execution
  layer) → full auto; each step reduces bias leakage but adds failure modes to
  test (duplicate webhooks, idempotency).

### Deployment Readiness Checklist
- [ ] Operator's real DD tolerance measured; sizing validated against MC 95%.
- [ ] Signal frequency matches capacity; alerts de-duplicated.
- [ ] Override rules written BEFORE live use; circuit breakers active.
- [ ] 2–4 weeks paper/forward run matches backtest stats (skill 51 gate).

## Common Mistakes
- Sizing to strategy tolerance while ignoring operator tolerance.
- Alerts firing intrabar → human chases unconfirmed signals.
- No pre-committed override policy (fatigue wins).
- Frequency mismatch discovered live instead of designed upfront.

## Corrections & Updates
- [2026-09] Created; native circuit breakers + alert semantics
  cross-referenced from skills 09/11/30/31.
