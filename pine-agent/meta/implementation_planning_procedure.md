# Implementation Planning Procedure — Pine Agent

Narrative authority for the **Implementation Planning stage** (pipeline
position 6 of 8). Executable engine:
`implementation/implementation_plan.pl` (core Perl, no CPAN). Contract
schema: `implementation/contract_schema.yaml` v1.1. Mirrors the
`meta/feasibility_procedure.md` precedent.

## 1. Purpose and non-goals

Implementation Planning answers: **"HOW should the feasible specification be
constructed?"** — as a deterministic blueprint. It defines modules, data
flow, state, MTF, signal, drawing, alert, and performance architecture
*without constructing any of them*.

Implementation Planning never: modifies user requirements; adds or removes
behavior; approximates mathematics; changes thresholds, timeframes, repaint
behavior, alert timing, or data sources; silently optimizes semantics;
performs Implementation or Post-Verification; generates Pine Script (no
`indicator()` / `strategy()` / `library()` / Pine functions / Pine files —
B-PINE-class invariant, tested). A planning decision that would alter
behavior is recorded as a blocker or unresolved decision, never silently
chosen.

## 2. Inputs and handoff gate

Three inputs, all verbatim:

1. `--contract FILE` — the formalization contract (the specification).
2. `--pre FILE` — the Phase-6 pre-verification result.
3. `--feasibility FILE` — the Phase-7 feasibility result (the handoff gate).

The handoff is accepted only when the feasibility result parses and
satisfies the executable ordering gate semantics (mirrors
`feasibility.pl --gate-check`): `feasibility_id` well-formed (`feas-` +
12 hex), `feasibility_status` is `FEASIBLE | FEASIBLE_WITH_WARNINGS`,
`blockers: []`, `implementation_planning_allowed: true`,
`next_stage: IMPLEMENTATION_PLANNING`. **PARTIALLY_FEASIBLE is never
reinterpreted as feasible** — it halts.

Cross-checks (identity chain, mirrors FB01/FB02): `request_id`,
`approved_routing_id`, `formalization_id` identical across all three
inputs; `verification_id` identical between the pre result and the
feasibility result; the pre result must remain `PASS|PASS_WITH_WARNINGS`
with `feasibility_allowed: true` and `next_stage: FEASIBILITY` (the
inherited Phase-6 gate is re-checked, never bypassed).

Any violation ⇒ `planning_status: BLOCKED` (`B-HANDOFF*`),
`implementation_allowed: false`, `next_stage: HALT`, exit 2.
Unparseable/missing input ⇒ `INVALID_INPUT` (`B-INPUT`), exit 2.

## 3. No-semantic-drift policy (verbatim mirroring)

Everything behavior-bearing is **copied, never decided**:

- Boolean conditions, formulas, edge cases, required-data entries,
  chart timeframe, and the repaint classification are mirrored verbatim
  into the plan (signal/MTF/state/drawing sections reference the exact
  upstream text and ids).
- Feasibility constraints and platform requirements are copied verbatim
  into the corresponding architecture sections (their `basis` travels
  with them — no invented platform facts).
- Repaint behavior is never reclassified; alert timing is never chosen
  (frequency/timing beyond the contract is an alert-setting concern and
  is recorded as a user configuration item).
- Unresolved implementation choices (e.g., an exact loop bound) are
  recorded in `decisions[]` with `status: NEEDS_USER_INPUT` plus a
  warning — never silently settled.

## 4. The 14 checks (fixed order; each maps to a mandated domain)

| id | domain (mandated) | blocks when |
|---|---|---|
| IP01 | identity chain | id chain missing/malformed/mismatched across the three inputs |
| IP02 | planning handoff gate | feasibility result not FEASIBLE*, blockers non-empty, planning_allowed false, next_stage wrong, or inherited pre gate broken |
| IP03 | requirements inventory | a condition/formula/edge-case/required-data requirement is not attached to any module (B-COVERAGE) |
| IP04 | architecture derivation | — (deterministic layer model; records modules) |
| IP05 | module decomposition | — (fields per module; source refs must be upstream ids) |
| IP06 | data flow | — (producers/transformations/consumers from module deps) |
| IP07 | state architecture | — (per-bar/realtime state planned iff crossover/prior-value mechanics present) |
| IP08 | MTF architecture | — (planned iff mtf flag or HTF/LTF data; discipline copied verbatim from feasibility constraints) |
| IP09 | signal architecture | — (exact conditions preserved; precedence recorded, never re-decided) |
| IP10 | drawing architecture | — (iff drawing tokens; budget stays UNKNOWN_REQUIRES_VERIFICATION — no invented limits) |
| IP11 | alert architecture | — (iff alert tokens; timing mirrors contract semantics) |
| IP12 | performance plan | — (mechanical counters + carried W-PERF* warnings; unbounded-loop wording yields a NEEDS_USER_INPUT decision) |
| IP13 | dependency graph | cycle (B-DEP-CYCLE) or missing dependency (B-DEP-MISSING) |
| IP14 | verification hooks | — (per-module hooks; metadata only) |

Verdicts: `pass` / `warn` / `fail`; every finding carries `refs` tracing
to upstream contract elements (a reviewer can answer "why does this module
exist?" from `source_requirements`).

## 5. Module model (deterministic derivation)

Modules are derived mechanically from the contract — none is invented:

| module | created iff | depends on |
|---|---|---|
| `M-DATA` | required_data non-empty | — |
| `M-CALC` | formulas non-empty | M-DATA (when both exist; conservative planning convention) |
| `M-STATE` | crossover/prior-value/cumulative mechanics detected | M-CALC |
| `M-SIGNAL` | boolean_conditions non-empty | M-CALC, M-STATE (when present) |
| `M-DRAW` | drawing tokens in request prose | M-SIGNAL |
| `M-ALERT` | alert tokens in request prose | M-SIGNAL |
| `M-INTEG` | always (wiring + v6 target) | all other modules |

Dependency over-approximation is conservative and documented; it can never
remove or alter semantics.

## 6. Implementation order (deterministic)

Topological (Kahn) sort over the dependency graph with a fixed priority
key `(category_rank, module_id)`; category ranks: DATA 0, CALC 1, STATE 2,
SIGNAL 3, DRAW 4, ALERT 5, INTEG 6; ties broken by module id
lexicographically. The order is therefore derived from dependencies and
stable across runs — never arbitrary. Cycles block before ordering.

## 7. Result model and gate

`planning_status: READY | READY_WITH_WARNINGS | BLOCKED | INVALID_INPUT`.
Warnings (non-blocking, carried): advisory unknowns from feasibility
(drawing/request budgets), unbounded-loop NEEDS_USER_INPUT decisions,
surfaced upstream warnings. Only READY / READY_WITH_WARNINGS set
`implementation_allowed: true` and `next_stage: IMPLEMENTATION`;
everything else sets `next_stage: HALT`, `implementation_allowed: false`,
exit 2. The v1.0 implementation contract (downstream consumer of the plan)
keeps its own status enum untouched.

## 8. Determinism and identity

No clock, no randomness, no environment values.
`planning_id = "plan-" + first 12 hex of sha256(UTF-8 of canonical body)`;
body = fixed-order `\x1F`-joined serialization of: request_id ␟
approved_routing_id ␟ formalization_id ␟ verification_id ␟ feasibility_id ␟
sha256(formalization bytes) ␟ sha256(pre bytes) ␟ sha256(feasibility
bytes) ␟ modules (id, purpose, deps joined `\x1E`, order) ␟ requirement
coverage map (`req=module`) ␟ warning codes ␟ decisions (id+status).
Identity and gate fields are excluded. Byte-identical inputs ⇒
byte-identical output (verified cross-run).

## 9. CLI and exit codes

```
perl implementation/implementation_plan.pl --contract FILE --pre FILE --feasibility FILE [--out FILE]
perl implementation/implementation_plan.pl --gate-check --plan FILE
perl implementation/implementation_plan.pl --selftest
```

Exit 0: READY / READY_WITH_WARNINGS / gate-check approved.
Exit 2: everything else. Engine defects die with a message.