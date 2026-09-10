# Feasibility Procedure — Pine Agent

Narrative authority for the **Feasibility stage** (pipeline position 5 of 8).
Executable engine: `feasibility/feasibility.pl` (core Perl, no CPAN).
Contract schema: `feasibility/contract_schema.yaml` v1.1.
Mirrors the `meta/pre_verification_procedure.md` precedent.

## 1. Purpose and non-goals

Feasibility answers: **"Can this specification be implemented in the target
environment (Pine Script v6 / TradingView)?"** — evaluated *as written*.

Pre-Verification answered "is the specification internally coherent?".
Feasibility never re-litigates coherence, never redesigns, and never silently
substitutes. **Feasibility never:** performs Formalization or Pre-Verification
redesign; changes timeframes, calculation frequency, data sources, repaint
behavior, signal timing, precision, drawings, or history; approximates rules;
writes Implementation Planning; generates Pine Script (no `indicator()` /
`strategy()` / Pine modules — B-PINE-class invariant, tested).

## 2. Inputs and handoff gate

Two inputs, both verbatim:

1. `--contract FILE` — the formalization contract (the specification to assess).
2. `--pre FILE` — the Phase-6 pre-verification result (the handoff gate).

The handoff is accepted only when the pre result parses and satisfies the
executable ordering gate semantics (mirrors `pre_verify.pl --gate-check`):
`verification_id` well-formed (`pre-` + 12 hex), `result` is
`PASS | PASS_WITH_WARNINGS`, `blockers: []`, `feasibility_allowed: true`,
`next_stage: FEASIBILITY`. Cross-checks: `request_id` and `formalization_id`
must be identical in both inputs (mismatch ⇒ `B-HANDOFF-CHAIN`).
Any violation ⇒ `feasibility_status: BLOCKED` (`B-HANDOFF*`),
`implementation_planning_allowed: false`, `next_stage: HALT`, exit 2.
Unparseable/missing input ⇒ `INVALID_INPUT` (`B-INPUT`), exit 2.

## 3. Documentation-evidence policy (no invented facts)

Capability knowledge lives in `config/feasibility.yaml` (`capability_kb`,
`data_kinds`, `performance_hints`). Every entry carries a `status`:

- `confirmed` — Import-Mode-verified event or core documented behavior;
  `basis` names the source record.
- `unavailable` — preserved negative claim (documented removal/absence);
  emits `unsupported_items[]` + blocker; **no substitution is applied**.
- `requires_verification` — no authoritative record; emits
  `unknowns[]` with `UNKNOWN_REQUIRES_VERIFICATION`. Unknowns attached to a
  boolean condition, formula, or required-data entry are **critical** ⇒
  blocker (`B-UNKNOWN-CRITICAL` / `B-DATA-UNKNOWN`); advisory unknowns
  (prose-only, budget headroom) ⇒ warning + recorded unknown.

Uncertainty is preserved, never converted to fact. Web access is not assumed.

## 4. The 12 checks (fixed order; each maps to a mandated domain)

| id | domain (mandated) | fails (blocker) when |
|---|---|---|
| FB01 | identity chain (all) | id chain missing/malformed in either input |
| FB02 | Phase-6 handoff gate (hard gates) | pre result not PASS*, blockers non-empty, feasibility_allowed false, or cross-contract id mismatch |
| FB03 | F01 Pine language | capability token = `unavailable` (B-CAP-UNAVAILABLE); critical unknown (B-UNKNOWN-CRITICAL) |
| FB04 | F02 runtime model | — (records platform_requirements; intrabar/every-tick wording + confirmed-data dependency ⇒ W-SEMANTIC-DIFF partial) |
| FB05 | F03 timeframe/MTF | meaningless timeframe token (B-TF-INVALID); TF-relation conflicts warn (W-TF-RELATION) — never substituted |
| FB06 | F04 data availability | kind `unavailable` (B-DATA-UNAVAILABLE); unresolvable kind (B-DATA-UNKNOWN); bid/ask/spread outside `1T` (B-DATA-TF-1T, verified basis) |
| FB07 | F05 repaint/execution | — (classification mirrored verbatim; `high` ⇒ W-REPAINT-ACCEPT surfacing user-acceptance requirement) |
| FB08 | F06 drawing/resources | — (documented limits cited where recorded; else advisory unknown + W-LIMIT-UNKNOWN) |
| FB09 | F07 alerts | — (alert representability recorded; timing constraint from FB04 applies) |
| FB10 | F08 symbol/session/market data | — (session/symbol constraints recorded; unknowns per §3) |
| FB11 | F09 performance | — (mechanical counters vs conservative advisory hints ⇒ W-PERF* warnings; no invented hard limits) |
| FB12 | F10 exact/partial classification | — (per-requirement classification; see §5) |

Verdicts: `pass` / `warn` / `fail` per check; every finding carries `refs`.

## 5. Requirement classification (F10)

Substantive requirements = boolean conditions (`C-*`), formulas (`F-*`),
required-data entries, and edge cases (`E-*`). Each receives exactly one of:

- `EXACT` — no adverse finding attached.
- `PARTIAL` — attached `W-SEMANTIC-DIFF`: `partial_items[]` states the
  feasible portion, the non-feasible portion, and the semantic difference.
  PARTIAL is **never** upgraded to EXACT.
- `NOT_FEASIBLE` — attached blocker.
- `UNKNOWN_REQUIRES_VERIFICATION` — attached critical unknown (also a blocker).

## 6. Result model and gate

`feasibility_status: FEASIBLE | FEASIBLE_WITH_WARNINGS | PARTIALLY_FEASIBLE |
NOT_FEASIBLE | BLOCKED | INVALID_INPUT`. The schema v1.0 `status` enum is
preserved: FEASIBLE/FEASIBLE_WITH_WARNINGS → `passed`;
PARTIALLY_FEASIBLE/NOT_FEASIBLE → `failed`; BLOCKED/INVALID_INPUT → `blocked`.
`recommendation` (v1.0): proceed / proceed_with_changes / needs_user_input /
reject respectively. **Only FEASIBLE or FEASIBLE_WITH_WARNINGS opens
Implementation Planning** (`implementation_planning_allowed: true`,
`next_stage: IMPLEMENTATION_PLANNING`); everything else emits
`next_stage: HALT`, `implementation_allowed: false`, exit 2.

## 7. Determinism and identity

No clock, no randomness, no environment values.
`feasibility_id = "feas-" + first 12 hex of sha256(UTF-8 of canonical body)`;
body = fixed-order `\x1F`-joined serialization of: request_id ␟
approved_routing_id ␟ formalization_id ␟ verification_id ␟
sha256(formalization bytes) ␟ sha256(pre-result bytes) ␟ the 12 check
verdicts ␟ findings (id, check_id, severity, code, message, refs joined
`\x1E`) ␟ warning codes ␟ unknown ids+criticality ␟ partial/unsupported
requirement ids ␟ per-requirement classifications (`req=class`). Identity and
gate fields are excluded. Byte-identical inputs ⇒ byte-identical output.

## 8. CLI and exit codes

```
perl feasibility/feasibility.pl --contract FILE --pre FILE [--out FILE]
perl feasibility/feasibility.pl --gate-check --feasibility FILE
perl feasibility/feasibility.pl --selftest
```

Exit 0: FEASIBLE / FEASIBLE_WITH_WARNINGS / gate-check approved.
Exit 2: everything else. Engine defects die with a message.