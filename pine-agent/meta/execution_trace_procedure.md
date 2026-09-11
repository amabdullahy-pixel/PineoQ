# PHASE 13 — EXECUTION TRACE & DEBUG ENGINE — PROCEDURE
# (meta/execution_trace_procedure.md)
#
# Predecessor: Phase 12 (data acquisition & alignment)
# Successor:   Phase 14 (root cause analysis) — gated.
# Schema:      trace/contract_schema.yaml v1.0
# Engine:      trace/execution_trace.pl (core Perl, zero non-core deps)

## 1. ROLE AND SCOPE

Phase 13 is an execution evidence engine, not a reasoning engine. It answers
only: **"Given the authoritative implementation, plan, Incident, and aligned
data, what execution behavior can be established?"** It must not answer
"why" — Phase 14 owns causality.

Phase 13 NEVER: determines root cause, declares a bug, repairs Pine code,
modifies production source, acquires market data (Phase 12 owns that), reinterprets
upstream contracts, invents missing execution states, or executes Phase 14/15.

## 2. AUTHORITATIVE INPUTS (priority order)

1. **Production implementation** — `implementation/phase9_pine.pine` (immutable during Phase 13)
2. **Phase 8 Implementation Plan** — `implementation/phase9_authoritative_plan.yaml`
3. **Phase 12 Data Contract** — alignment and datasets are authoritative; never substituted
4. **Phase 11 Incident Contract** — observed/reported incident evidence
5. **Phase 10 validated result** — `verification/project root: verification/phase10_post_verification_result.yaml`

No lower-level interpretation may silently override a higher-level artifact.

## 3. HARD INPUT GATE (stages 01–03)

Phase 13 MUST NOT execute unless ALL of:
- Phase 10 REV 4 `verdict: validated` (read-only, ET-G1)
- Phase 11 incident contract `phase11_status ∈ {READY, READY_WITH_WARNINGS}`,
  blockers empty, `next_stage: DATA_ACQUISITION_AND_ALIGNMENT`, downstream open (ET-G2)
- Phase 12 data contract `status ∈ {SUFFICIENT, SUFFICIENT_WITH_WARNINGS}` (mapping
  to READY / READY_WITH_WARNINGS) with `downstream.allowed: true` and
  `next_stage: EXECUTION_TRACE_AND_DEBUG` (ET-G3)
- Identity chain resolves: request → routing → formalization → pre-verification →
  feasibility → planning → implementation → post-verification → incident → data (ET-G4)

Missing/mismatched identities ⇒ BLOCKED. No guessing.

## 4. IDENTITY AND HASH INTEGRITY (stages 04–06, ET-G5..G7)

- Recompute sha256 of the production Pine artifact; it must equal the
  Phase 9 result's recorded `source_sha256` (ET-G5). Mismatch = TRACE-003 ⇒ BLOCKED.
- Plan/implementation traceability: every plan module must appear in the
  implementation's `// === MODULE <id> ===` map (ET-G6); mismatch = TRACE-004.
- Data contract integrity: `data_contract_id` well-formed, `result_hash`
  well-formed, status/gate fields self-consistent (ET-G7).

## 5. EXECUTION MODES (priority, never upgraded)

```
DIRECT > INSTRUMENTED > RECONSTRUCTED > STATIC_ONLY > UNAVAILABLE
```

- **DIRECT** — actual TradingView/Pine runtime observation. NOT AVAILABLE in
  this environment; never claimed without evidence.
- **INSTRUMENTED** — temporary debug build (prompt §10–§12). Requires the
  instrumentation firewall (§7) and verified semantic equivalence (ET-G16).
- **RECONSTRUCTED** — deterministic reconstruction via a verified equivalent
  mechanism over authoritative inputs (§6). Documented per prompt §41, never
  reported as direct runtime observation.
- **STATIC_ONLY** — source facts only; never promoted to runtime evidence (ET-G18).
- **UNAVAILABLE** — no execution evidence at all.

## 6. RECONSTRUCTION INTERPRETER (`pine-subset-reconstruction-v1`)

The engine embeds a deterministic Pine-subset interpreter used ONLY for
deterministic reconstruction. It supports exactly the constructs exercised by
the current production implementation:

- `//@version=6`, `indicator(...)`
- `var <type> <name> = <literal>` state declaration
- `if na(x) or na(y)` / `else` assignment blocks
- `na(...)` tests, boolean operators `and`/`or`/`not`, comparisons
  `<`, `<=`, `>`, `>=`
- series references `close`, `close[1]` (bar-relative, never replaced by
  current values — prompt §15)
- plain declarations `bool x = <expr>`, assignments `x := <expr>`
- final `plot(expr, display=display.none)` recognized as OUTPUT mechanism
  (not traced as a calc node; recorded under output)

Unsupported constructs force UNKNOWN on affected nodes with a trace gap
classified UNSUPPORTED_RUNTIME_SEMANTICS (prompt §41 — no compensating guesses).

**Equivalence checks** (recorded under `reconstruction.equivalence_checks`):
1. source_hash — reconstructed artifact bytes hash to the production hash (exact copy)
2. input_fidelity — bar inputs come exclusively from the Phase 12 dataset (never substituted)
3. condition_equivalence — reconstructed final condition matches the plan's
   signal condition verbatim
4. state_equivalence — `var` state transitions occur exactly at the contract-mandated points

If any check fails ⇒ RECONSTRUCTION_UNTRUSTED; affected evidence downgraded,
never used as authoritative execution evidence.

## 7. INSTRUMENTATION FIREWALL (ET-G16)

Instrumentation may ONLY expose values through a documented debug mechanism.
It must NOT alter condition logic, state transitions, inputs, timeframe,
session, lookback, alerts, drawings, or signal semantics. The manifest
(`trace/instrumentation_manifest.yaml`) records production vs instrumented
hashes, every insertion, and the semantic-equivalence verdict. Unverified
equivalence ⇒ evidence rejected (never called authoritative). Production
source is never edited.

## 8. TRACE MODEL AND NODE IDENTITY

Canonical chain: Market Data → Raw Inputs → Series Values → Intermediate
Calculations → Persistent/Historical State → Boolean Conditions → Module
Conditions → Signal Conditions → Output Conditions.

Each node: `trace_node_id` = `trace-node-` + 12 hex of
sha256(`trace_id|bar|module|expression|role`) — deterministic, no clock/env.
Series references preserved with bar-relative meaning (`close[i-1]`, never
silently replaced). NA ≠ FALSE; NOT_EVALUATED ≠ FALSE (§16/§18).

## 9. LOCALIZATION-DRIVEN TRACE WINDOW (prompt §13/§14)

- EXACT localization → trace the exact bar (+ minimum dependency window).
- PROBABLE → smallest supported candidate range.
- APPROXIMATE → only what data supports.
- UNKNOWN → no bar is traced; no bar invented. Localization uncertainty is
  preserved in the contract.

Window = incident bar + required history (close[1] ⇒ 1 preceding bar; state
variables ⇒ window back to first valid input). `order_type` distinguishes
DEPENDENCY_ORDER from claimed runtime order.

## 10. STATUS MODEL AND GATE

- **READY** — required execution behavior established.
- **READY_WITH_WARNINGS** — usable with non-blocking limitations.
- **PARTIAL_TRACE** — some behavior established, material portions unresolved ⇒ gate closed.
- **INSUFFICIENT_EVIDENCE** — required evidence unavailable ⇒ gate closed.
- **INVALID_INPUT** — structure invalid ⇒ gate closed.
- **BLOCKED** — hard prerequisite/integrity condition ⇒ gate closed.

Only READY / READY_WITH_WARNINGS open `ROOT_CAUSE_ANALYSIS`
(`downstream.allowed: true`). PARTIAL_TRACE never passes for a complete one
(§46: "Do not allow Phase 14 to treat an incomplete trace as complete
evidence"). Exit codes: 0 = gate open, 2 = gate closed, other non-zero = internal failure.

## 11. ROOT-CAUSE FIREWALL (ET-G19)

`root_cause.status` and `repair.status` are permanent placeholders
(NOT_EVALUATED). No causal wording ("caused by", "because of", "reason for
failure", "bug") may appear in engine-derived trace fields. A static anomaly
is recorded as `STATIC_ANOMALY_OBSERVED` evidence, never as a conclusion.
Causal language is mechanically rejected in emitted contracts.

## 12. DATA AUTHORITATIVENESS (prompt §28/§29)

The Phase 12 contract is the only data source. Never substitute internet data,
guessed values, chart visual estimates, or synthetic data. If Phase 12 data is
insufficient: `TRACE_DATA_INSUFFICIENT` and the affected path stops. No new
acquisition inside Phase 13.

## 13. MECHANICAL CHECKS (ET-G1..ET-G23)

| Check | Domain | Enforced |
|---|---|---|
| ET-G1 | phase10_validation_gate | Phase 10 REV 4 verdict validated (read-only) |
| ET-G2 | phase11_gate | incident READY/WITH_WARNINGS, blockers empty, next_stage DATA_ACQUISITION_AND_ALIGNMENT, downstream open |
| ET-G3 | phase12_gate | data contract SUFFICIENT(_WITH_WARNINGS), downstream allowed, next_stage EXECUTION_TRACE_AND_DEBUG |
| ET-G4 | identity_chain_integrity | full chain resolves; no mismatched ids |
| ET-G5 | implementation_hash | recomputed sha256 == Phase 9 recorded source_sha256 |
| ET-G6 | plan_implementation_traceability | plan modules == implementation module map |
| ET-G7 | data_contract_integrity | data_contract_id/result_hash well-formed, gate self-consistent |
| ET-G8 | incident_localization_integrity | localization classification valid, never fabricated |
| ET-G9 | trace_node_schema | node fields complete, valid enums |
| ET-G10 | evidence_classification | classes ∈ allowed set; no promotion violations |
| ET-G11 | series_reference_correctness | close[i-k] preserved bar-relative; no silent substitution |
| ET-G12 | na_unknown_distinction | NA ≠ FALSE, UNKNOWN ≠ FALSE, NOT_EVALUATED ≠ FALSE |
| ET-G13 | boolean_trace_completeness | operands decomposed independently |
| ET-G14 | state_trace integrity | var state transitions recorded with evidence |
| ET-G15 | mtf_trace_integrity | request.* / HTF deps explicit or NOT_APPLICABLE |
| ET-G16 | instrumentation_firewall | equivalence verified or evidence rejected |
| ET-G17 | reconstruction_declaration | mode/documentation present when reconstruction performed |
| ET18 | static_runtime_separation | STATIC_CODE_FACT never labeled runtime evidence |
| ET-G19 | root_cause_firewall | no causal wording; root_cause/repair NOT_EVALUATED |
| ET-G20 | trace_completeness | coverage honest; partial never labeled complete |
| ET-G21 | deterministic_ids | trace_id/node ids content-addressed |
| ET-G22 | deterministic_serialization | byte-identical re-runs |
| ET-G23 | downstream_gate_correctness | gate open iff READY/WITH_WARNINGS |

## 14. FAILURE MODES

TRACE-001..TRACE-014 mapped per prompt §44; each becomes a BLOCKER with its
ET-G id. No failure silently converts to PASS.

## 15. CLI AND ENGINE MAPPING

```
perl trace/execution_trace.pl --incident FILE --data-contract FILE
                             [--implementation FILE] [--plan FILE] [--out FILE]
                             [--mode MODE] [--json]
                             --selftest | --gate-check --trace FILE | --version | --help
```

- `--gate-check --trace FILE` approves only READY / READY_WITH_WARNINGS
  contracts (exit 0); anything else exits 2 with the reason.
- `--selftest` runs the full TRC-001..028 + NG-001..013 suite (exit 0 iff all pass).
- Engine version: `1.0`.
- Stage → check mapping: stages 01–03 (gates ET-G1..G3), 04–06 (identity/hashes
  ET-G4..G7), 07–09 (localization/window ET-G8), 10–12 (reconstruction/
  instrumentation ET-G16/G17), 13–16 (trace nodes/states/conditions ET-G9..G15),
  17 (contract generation ET-G9..G14), 18 (determinism ET-G21/G22),
  19 (result ET-G20), 20 (downstream gate ET-G23).
