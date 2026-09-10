# Skill: alerts-and-webhooks

## Metadata

```yaml
id: alerts-and-webhooks
name: Alerts & Webhooks
version: 1.0.0
path: skills/normalized/implementation/alerts-and-webhooks/skill.md
layer: IMPLEMENTATION
domains: [alerts, integration]
triggers:
  english:
    - alertcondition vs alert
    - dynamic alert
    - alert frequency
    - webhook payload
    - duplicate alert prevention
    - order-fill alert
    - alert placeholders
  persian:
    - هشدار و وب‌هوک
    - ارسال سیگنال به ربات
    - جلوگیری از هشدار تکراری
    - پیویلود وب‌هوک
dependencies:
  mandatory: []
  optional: [strategy-engine, indicator-strategy-library-architecture, tradingview-execution-model]
status: normalized
priority: 2
```

## Purpose

`alertcondition()` vs `alert()` mechanics, dynamic alert design, duplicate
prevention, and webhook payload construction. Required for any signal
notification, bot integration, or webhook delivery design — and for avoiding
the classic failures (static-message limits, tick-level spam, plan-gated
webhooks unavailable).

## Triggers

Select for: any signal notification or bot-integration requirement; choosing
between `alertcondition()` and `alert()`; alert frequency semantics; webhook
JSON payloads and strategy placeholders; de-duplication of repeated alerts.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Notification requirement | description | user request | yes |
| Script type (indicator/strategy) | metadata | target script | yes |
| User plan tier | context | user request | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Alert mechanism + frequency choice | design decision | Implementation Planning |
| De-dup pattern | implementation pattern | Implementation |
| Webhook payload template | artifact | Implementation |
| Plan-gating constraints | constraint notes | Feasibility |

## Rules

1. Two alert mechanisms: `alertcondition()` — static/compile-time, global scope,
   indicators ONLY, const-string message, user selects the condition in the UI;
   `alert()` — dynamic/runtime, any scope incl. inside `if`, indicators AND
   strategies, message may be dynamic (str.tostring, concatenation), fires when
   the code executes.
2. `alert()` frequency: `alert.freq_once_per_bar` (default — first trigger per
   realtime bar); `alert.freq_once_per_bar_close` (only on the bar's closing
   update — repaint-safe); `alert.freq_all` (every execution — tick-level spam
   risk).
3. Duplicate-prevention patterns: state-gate on transition
   (`signal and not signal[1]`); persist fired-state with
   `var bool fired = false` + reset on the opposite condition (mind realtime
   rollback — `var` rolls back; combine with `barstate.isconfirmed`); for
   bar-close semantics prefer `alert.freq_once_per_bar_close` over manual gates.
4. Webhooks are plan-gated: available on paid plans (Essential and up), not
   Basic. Setup: Create Alert dialog → Notifications → Webhook URL → endpoint.
   Message = the alert message text (often JSON, e.g. with `{{ticker}}`,
   `{{strategy.order.action}}`, `{{close}}` placeholders).
5. Strategy order-fill alerts carry strategy placeholders; per-order custom
   payloads go via the `alert_message` param of `strategy.entry`/`exit`/`order`
   plus `{{strategy.order.alert_message}}`.
6. Endpoints should validate/parse JSON, be idempotent (TradingView may
   re-send), and handle bursts (rate limits apply per plan/infrastructure).
7. Alert placeholders (UI message templates): `{{ticker}} {{exchange}}
   {{close}} {{open}} {{high}} {{low}} {{volume}} {{time}} {{timenow}}
   {{interval}}`; strategy set: `{{strategy.position_size}}
   {{strategy.market_position}} {{strategy.order.action}}
   {{strategy.order.contracts}} {{strategy.order.price}} {{strategy.order.id}}
   {{strategy.order.alert_message}}`.
8. Active-alert counts are plan-dependent (source cites Basic 1 · Essential 20 ·
   Plus 100 · Premium 400 · higher tiers more) — re-verify on the current
   pricing page before quoting to users. Recreating/updating an alert is
   required after script input changes.

## Workflow

1. Determine script type and notification intent (rule 1 selects the mechanism).
2. Choose frequency (rule 2) matching the signal's confirmation semantics.
3. Apply a de-dup pattern (rule 3) when transitions could re-fire.
4. For webhooks, verify plan gating (rule 4) and build the payload (rules 5, 7).
5. Record plan-gating constraints in Feasibility; note alert recreation after
   input changes.

## Constraints

- No `alertcondition()` in strategies (compile error); no dynamic strings in
  `alertcondition()` messages (must be const).
- Webhooks unavailable on Basic; active-alert counts and rate limits are
  plan-dependent — never quote numbers without re-verification.

## Assumptions

- Alert semantics per official alerts docs as claimed by the source; plan
  limits evolve and must be re-checked at use time (source's own caveat,
  preserved).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| `alertcondition()` in a strategy | compile error | use `alert()` |
| Dynamic message in `alertcondition` | compile error | switch to `alert()` or const message |
| Webhook spam on ticks | burst of fires | rule 2/3: frequency + de-dup |
| Webhook missing on Basic | plan gating | rule 4: upgrade or alternative delivery |

## Dependencies

Optional: strategy-engine (order-fill alerts, `alert_message` param),
indicator-strategy-library-architecture (mechanism capability split),
tradingview-execution-model (bar-close timing semantics). Load only on their
own triggers.

## Examples

- "Notify my bot on every long signal with price" → rule 1 `alert()` + rule 7
  placeholders + rule 4 webhook gating.
- "My alert fires 50 times per bar" → rule 2 frequency + rule 3 de-dup.
- Persian: «وب‌هوک کار نمی‌کند» → rule 4 plan gating first.

## Verification Criteria

- Mechanism matches script type; `alertcondition` messages are const.
- Frequency + de-dup pattern documented for every alert.
- Webhook payloads use valid placeholders; endpoint expectations (idempotent,
  JSON) documented.
- Plan-gating constraints recorded in Feasibility, not assumed.

## Ambiguities

- None from the source.

## Missing Information

- Exact current active-alert counts per plan (source's own numbers are
  explicitly marked re-verify-before-quoting).

## Import Notes

- Batch `batch-002` import from `skills/incoming/11-alerts-and-webhooks.md`.
- Structural reorganization into the Skill template only; no semantic changes.
  The source's re-verification caveat for plan numbers is preserved verbatim in
  meaning (rule 8 + Missing Information).

## Source Reference

- Original filename: `11-alerts-and-webhooks.md`
- Original source path: `skills/incoming/11-alerts-and-webhooks.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
