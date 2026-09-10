# Formalization Procedure — Pine Agent

Narrative authority for the **Formalization stage** (pipeline position 3 of 8).
Executable engine: `formalization/formalize.pl` (core Perl, no CPAN).
Contract schema: `formalization/contract_schema.yaml` v1.1.
This document mirrors the `meta/skill_router.md` precedent: design authority
here, deterministic engine there, no logic in Skills or config.

---

## 1. Purpose and non-goals

Formalization converts a READY Router handoff plus the verbatim user request
into a machine-checkable **formalization contract**: variables, parameters,
formulas, boolean conditions, assumptions, ambiguities, edge cases, timeframe
and MTF requirements, repaint classification, data requirements, verification
requirements, and implementation constraints.

**Formalization never:**

- generates Pine Script (any variant) — forbidden at every phase;
- optimizes, improves, simplifies, or redesigns the requested logic
  (normalization is not improvement);
- silently resolves ambiguities or invents thresholds, timeframes, sources,
  precedence, or edge-case behavior;
- bypasses the Router or any downstream gate;
- re-derives routing decisions (they are copied, never recomputed).

## 2. Inputs

1. **User request** — verbatim text (English or Persian), whitespace-normalized
   for storage and hashing (content words unchanged).
2. **Routing contract** — the `routing/2` YAML output of `skills/agent/router.pl`
   (v2 format exactly; the JSON and v1 formats are NOT accepted handoffs).

## 3. Router → Formalization handoff gate

The handoff is accepted **only when all** of the following hold:

- `contract_version: 'routing/2'`
- `routing_status: 'ready'`
- `downstream.allowed: true`
- required routing fields present (status, request_class, selected_skills,
  reason, trace sections).

Any other state — `ambiguous`, `insufficient_coverage`, `blocked`,
`conflict_detected`, `allowed: false`, or a malformed/missing field — produces
a **blocked** formalization contract (blocker records the routing `reason`
verbatim), `implementation_allowed: false`, exit code 2. A non-ready routing
output is never converted into an approved contract.

## 4. Identity (contract-ID chain)

```
request_id ──▶ approved_routing_id ──▶ formalization_id ──▶ approved_formalization_id
                                                                      │
                                                    pre_verification (formalization_id)
                                                    feasibility      (formalization_id)
                                                    implementation   (approved_formalization_id)
```

All ids are deterministic content-addressed SHA-256 prefixes — **no
timestamps, no randomness, no session state**:

| id | rule |
|---|---|
| `request_id` | `"req-"` + first 12 hex of `sha256(UTF-8 bytes of the whitespace-normalized request)` |
| `approved_routing_id` | `"rout-"` + first 12 hex of `sha256(exact bytes of the routing/2 YAML file)` |
| `formalization_id` | `"form-"` + first 12 hex of `sha256(request_id ␟ approved_routing_id ␟ sha256(canonical contract body))`, where `␟` is `\x1F` and the canonical body is the fixed-order serialization of all semantic fields (identity and gate fields excluded) |

Properties: deterministic (same inputs ⇒ byte-identical contract and ids),
unique (distinct inputs ⇒ distinct ids with overwhelming probability),
traceable (parent ids are explicit fields), **stable after approval** (an
approved contract is frozen; a revision produces a NEW `formalization_id` and
sets `supersedes: <old formalization_id>`; no field of the frozen contract
changes).

`approved_formalization_id` is **not a separate artifact**: it is the
`formalization_id` of the contract whose `implementation_allowed: true`.
Downstream contracts copy it verbatim.

## 5. Status model (schema enum unchanged)

`pending | in_progress | completed | blocked` — identical to v1.0. Mapping of
the Phase-5 vocabulary onto the existing enum:

| Phase-5 term | Contract state |
|---|---|
| draft | `status: pending` |
| ready_for_pre_verification | `status: completed`, `blockers: []` |
| approved | `status: completed`, `blockers: []`, **`implementation_allowed: true`** |
| needs_clarification | `status: completed` with ≥1 behavior-affecting ambiguity `unresolved` (gate keeps it unapproved) |
| blocked | `status: blocked` (non-ready routing, Pine code in request, invalid input semantics) |

Approval is expressed **solely** by `implementation_allowed: true` — no
parallel `approved` status value exists (single source of truth; the
implementation and feasibility schemas define approval exactly this way).

## 6. Deterministic extraction rules

The engine extracts **mechanically detectable** elements only. Each extracted
element carries its verbatim origin in `source`/`description`. The agent may
add semantic depth (meanings, formulas) only by **referencing** these
mechanical entries — never by replacing or contradicting them.

- **R1 Sources** — built-in price/volume tokens (`close open high low volume
  hl2 hlc3 ohlc4`, word-bounded) → `variables` entries, type `series float`.
- **R2 Parameters** — `name(number)` and `name: number` / `name=number`
  patterns → `variables` entries, type `const int|float`, verbatim clause
  recorded.
- **R3 Conditions** — comparison/cross clauses
  (`X crosses over Y`, `X is below 30`, `X < 30`, `>=`, `==`, ...) →
  `boolean_conditions` entries with the **verbatim clause** as `condition`;
  `meaning` records "verbatim request clause — semantics preserved, not
  reinterpreted". Conditions are never rewritten into different math.
- **R4 Formulas** — explicit binary arithmetic (`a / b`, `a + b`, keyword
  `divided by`) → `formulas` entries with the verbatim expression.
- **R5 Timeframe** — explicit TF tokens in timeframe context
  (`on the daily chart`, `4h timeframe`, tokens `1m 3m 5m 15m 30m 45m 1h 2h 3h
  4h 12h 1d 1w 1M daily weekly monthly`, case-sensitive so `1m` ≠ `1M`) →
  `timeframe.chart`. Not found → `null` + ambiguity `A-TF`.
- **R6 MTF** — markers (`higher/lower timeframe`, `htf`, `ltf`,
  `multi-timeframe`, `request.security`) → `mtf: true` + `required_data`
  entry. Explicit HTF token in HTF context → recorded; otherwise ambiguity
  `A-HTF-TF`.
- **R7 Repaint classification** (see §7) — always classified, mechanism named.
- **R8 Edge cases** (see §8) — enumerated from detected features.
- **R9 No-Pine guard** — request text containing Pine constructs
  (`//@version`, `indicator(`, `strategy(`, `library(`) → `status: blocked`,
  blocker `B-PINE`: Formalization formalizes requirements, not code.

## 7. Repaint classification (mechanical, documented — never invented)

| Condition | Classification | Mechanism |
|---|---|---|
| MTF detected + explicit confirmation statement (`barstate.isconfirmed`, `confirmed bar/close`, `on bar close`, `lookahead/gaps off/on`, `wait for close`) | `low` | confirmed-bar HTF discipline stated in request |
| MTF detected, no confirmation statement | `high` | unconfirmed HTF data via request.security — no confirmed-bar/lookahead discipline stated |
| no MTF, intrabar markers (`intrabar`, `every tick`, `calc_on_every_tick`) | `medium` | realtime intrabar values can differ from historical bars |
| no MTF, no intrabar | `low` | no repaint mechanism detected in the request; final classification re-checked by Pre/Post-Verification |

AGENT_RULES §3.12 requires a classification on every request; these rules make
that requirement deterministic. Repaint wording in the request is preserved
verbatim in `natural_language_request`.

## 8. Edge cases

Enumerated from detected features; `required_behavior` is filled ONLY from the
request, otherwise `null` (unspecified — recorded, never silently defined):

- always: na propagation during warm-up; first bars / insufficient history;
- division detected and no zero-guard wording (`division by zero`,
  `zero check/guard`, `nz(`): zero-denominator case + ambiguity `A-DIV`
  (behavior-affecting);
- MTF: HTF value not yet confirmed/updated at the chart bar;
- volume source: missing/zero-volume bars;
- ≥ 2 boolean conditions: simultaneous-conditions precedence unspecified +
  ambiguity `A-PREC` (behavior-affecting).

## 9. Ambiguity discipline

Every ambiguity: `{id: A-<n>, description, options, affects_behavior,
resolution_status}`. IDs are assigned in fixed generation order
(`A-TF`, `A-OPER`, `A-THR`, `A-DIV`, `A-HTF-TF`, `A-CONF`, `A-PREC`).

Gate semantics (AGENT_RULES §2.6–2.8; TEST-FORMALIZATION-001):

- `unresolved` behavior-affecting ambiguity ⇒ `implementation_allowed: false`;
- `resolved_assumed` **never** unlocks — even for a behavior-affecting
  ambiguity (explicit `must_not` of the test spec);
- `resolved_by_user` unlocks (all other gate conditions holding);
- non-behavior-affecting ambiguities never block the gate but remain recorded.

Resolution is applied via `--resolve ID=resolved_by_user|resolved_assumed`
(the user's answer, recorded by the agent) — the engine then recomputes the
gate and, if content changed, a **new** `formalization_id` with
`supersedes` linking the previous revision. The engine itself NEVER sets
`resolved_assumed`.

## 10. Determinism

Same request text + same routing bytes ⇒ byte-identical contract (fixed field
order, fixed generation orders, no clock, no randomness, no session state —
mirrors `meta/skill_router.md` §16).

## 11. Output, storage, exit codes

- Contract emitted to stdout; `--out FILE` also writes
  `contracts/<request_id>/formalization.yaml` layout (file name free).
- Exit **0**: valid completed contract produced (approved or awaiting
  clarification — the contract itself states which) / `--gate-check` approved.
- Exit **2**: blocked contract (non-ready routing, Pine in request) /
  `--gate-check` not approved.
- Engine defects (unreadable files, bad usage) die with a message.

## 12. CLI

```
perl formalization/formalize.pl --request-text "TEXT" --routing FILE
                                [--resolve ID=resolved_by_user|resolved_assumed]...
                                [--supersedes form-xxxxxxxxxxxx]
                                [--out FILE]
perl formalization/formalize.pl --gate-check --contract FILE
perl formalization/formalize.pl --selftest
```

`--gate-check` is the executable ordering gate (TEST-FORMALIZATION-001a):
it verifies a contract file has a `formalization_id`, is `completed`, has zero
blockers, and carries `implementation_allowed: true`; it prints
`approved_formalization_id = <id>` on success, otherwise the blocking reasons.

## 13. Honesty and downstream obligations

- `verification_requirements` lists the Pre-Verification checks that apply
  (ids mirror `verification/pre_contract_schema.yaml`).
- `implementation_constraints` always include: Pine v6 only; verbatim
  condition clauses (`C-*`) are binding; no lookahead without user-approved
  policy; unresolved behavior-affecting ambiguities block implementation.
- `source_skills` copies the routed `selected_skills` ∪ `dependency_skills`
  ids verbatim — routing decisions are consumed, not re-derived.