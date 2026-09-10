---
name: alerts-and-webhooks
category: TradingView Architecture
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/alerts/
  - https://www.tradingview.com/pine-script-docs/faq/alerts/
  - https://www.tradingview.com/support/solutions/43000529348-how-to-configure-webhook-alerts/
---

# Alerts & Webhooks

## Purpose
alertcondition vs alert, dynamic alert design, duplicate prevention, webhook payloads.

## When to Use
- Any signal notification, bot integration, or webhook delivery design.

## Core Knowledge

### Two Alert Mechanisms
| | `alertcondition()` | `alert()` |
|---|---|---|
| Type | static, compile-time | dynamic, runtime |
| Scope | global; indicators ONLY | any scope incl. inside `if`; indicators + strategies |
| Message | const string only | dynamic (str.tostring, concatenation) |
| Trigger | user selects condition in UI | fires when code executes |

### `alert()` Frequency
- `alert.freq_once_per_bar` (default) — first trigger per realtime bar.
- `alert.freq_once_per_bar_close` — only on the bar's closing update
  (repaint-safe).
- `alert.freq_all` — every execution (tick-level spam risk).

### Duplicate Prevention Patterns
- State-gate: fire only on transition: `signal and not signal[1]`.
- Persist fired-state: `var bool fired = false` + reset on opposite condition
  (mind realtime rollback — `var` rolls back; combine with
  `barstate.isconfirmed`).
- For bar-close semantics prefer `alert.freq_once_per_bar_close` over manual gates.

### Webhooks
- Plan-gated: available on paid plans (Essential and up), not Basic.
- Setup: Create Alert dialog → Notifications → Webhook URL → paste endpoint.
- Message = the alert message text (often JSON):
```json
{"ticker": "{{ticker}}", "action": "{{strategy.order.action}}", "price": "{{close}}"}
```
- Strategy order-fill alerts carry strategy placeholders; per-order custom
  payloads via alert_message param of strategy.entry/exit/order +
  `{{strategy.order.alert_message}}`.
- Endpoint should validate/parse JSON, be idempotent (TradingView may
  re-send), and handle bursts (rate limits apply per plan/infrastructure).

### Alert Placeholders (UI message templates)
- `{{ticker}} {{exchange}} {{close}} {{open}} {{high}} {{low}} {{volume}}
  {{time}} {{timenow}} {{interval}}`
- Strategy: `{{strategy.position_size}} {{strategy.market_position}}
  {{strategy.order.action}} {{strategy.order.contracts}}
  {{strategy.order.price}} {{strategy.order.id}}
  {{strategy.order.alert_message}}`

### Active-Alert Counts (plan dependent — verify current pricing)
- Basic 1 · Essential 20 · Plus 100 · Premium 400 · higher tiers more.
- Recreating/updating an alert is required after script input changes.

## Common Mistakes
- Using alertcondition() in a strategy (not allowed) — use alert().
- Message with dynamic string in alertcondition (must be const).
- Tick-frequency alerts spamming the webhook; missing de-dup logic.
- Expecting webhook on Basic plan (not available).

## Corrections & Updates
- [2026-09] Created; verified against official alerts docs; alert counts are
  plan-dependent — re-verify on pricing page before quoting to users.
