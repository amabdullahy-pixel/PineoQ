# Pre-Verification Procedure — Pine Agent

Narrative authority for the **Pre-Verification stage** (pipeline position 4 of 8).
Executable engine: `verification/pre_verify.pl` (core Perl, no CPAN).
Contract schema: `verification/pre_contract_schema.yaml` v1.1.
Mirrors the `meta/formalization_procedure.md` precedent.

## 1. Purpose and non-goals

Pre-Verification verifies a **completed Formalization contract** before
Feasibility or Implementation. It checks the *specification*, never code.

**Pre-Verification never:** generates Pine Script; modifies requirements;
silently resolves ambiguities; redesigns formulas; invents requirements;
bypasses Formalization gates; performs Feasibility (Phase 7), Implementation
Planning, Implementation, or Post-Verification.

## 2. Input and handoff gate

Input: exactly one formalization contract file (the YAML emitted by
`formalize.pl`). The handoff is accepted only when the contract parses,
carries `schema_version: '1.1'` (or `'1.0'`), `stage: formalization`, a
well-formed id chain, and passes the executable ordering gate semantics
(`--gate-check` of formalize.pl): `status: completed`, `blockers: []`,
`implementation_allowed: true`. Any other state ⇒ `result: BLOCKED`
(`B-GATE`/`B-INPUT`), `feasibility_allowed: false`, `next_stage: HALT`,
exit 2. Unparseable input ⇒ `result: INVALID_INPUT`, exit 2.

## 3. The 14 checks (fixed order; each maps to a mandated domain)

| id | domain (mandated #) | verdict fail when |
|---|---|---|
| PC01 | traceability / identity (14) | id chain missing/malformed or mismatched |
| PC02 | formalization approval gate (hard gates) | not completed / blockers / implementation_allowed false |
| PC03 | variable completeness (3) | referenced name absent from variables |
| PC04 | formula math + dependency consistency (2,4) | depends_on unknown; operand undefined; division w/o guard record |
| PC05 | boolean-condition consistency (5) | contradictory clause pair; malformed id |
| PC06 | assumption validity (6) | behavior-affecting assumption not user-confirmed (warning) |
| PC07 | ambiguity resolution state (7) | behavior-affecting unresolved OR resolved_assumed (blocker — must_not inherited) |
| PC08 | edge-case coverage (8) | division w/o E-DIV; ≥2 conditions w/o E-PREC (contract self-inconsistency) |
| PC09 | MTF/timeframe consistency (9) | mtf w/o chart TF or w/o required_data; non-mtf w/ required_data; HTF entry w/o timeframe and w/o A-HTF-TF |
| PC10 | repaint identification (10) | repaint_risk null/malformed (AGENT_RULES §3.12) |
| PC11 | required-data completeness (11) | entry w/o kind; timeframe-null entry w/o A-HTF-TF record |
| PC12 | contradictions (12) | same subject above AND below the same threshold |
| PC13 | hidden/implicit assumptions (13) | vague threshold wording w/o A-THR; conditions w/o timing wording and w/o A-CONF |
| PC14 | traceability integrity (14) | source_skills / verification_requirements / implementation_constraints empty; duplicate ids |

Verdicts: `pass` (no findings), `warn` (warnings only), `fail` (≥1 blocker).

## 4. Result model

`result: PASS | PASS_WITH_WARNINGS | BLOCKED | INVALID_INPUT` — the Phase-6
machine vocabulary. The schema `status` enum (v1.0) is preserved:
PASS/PASS_WITH_WARNINGS → `passed`; BLOCKED/INVALID_INPUT → `blocked`.
`feasibility_allowed: true` ⇔ result PASS or PASS_WITH_WARNINGS (permission
to START Phase 7 — never `feasibility_passed`, which stays spec-only).
`implementation_allowed` mirrors the upstream gate AND the local verdict.
`next_stage: FEASIBILITY | HALT`.

## 5. Determinism and identity

No clock, no randomness, no environment values. `verification_id = "pre-" +
first 12 hex of sha256(UTF-8 of request_id ␟ approved_routing_id ␟
formalization_id ␟ sha256(canonical body))` where `␟` is `\x1F` and the
canonical body is the fixed-order `\x1F`-joined serialization of: the 14
check verdicts, findings (id, check_id, severity, message, refs joined
`\x1E`), warnings, unresolved_items, and the mirrored ambiguity resolution
states. Identity/gate fields are excluded. Same contract bytes ⇒ byte-identical
result; any contract change ⇒ new verification_id.

## 6. Traceability

Every finding carries `refs` — ids/names of the formalization elements that
caused it (variable names, C-*/F-*/E-*/A-* ids, required_data indexes,
field names). A reviewer can answer "why did this finding occur?" from the
result document alone.

## 7. CLI and exit codes

```
perl verification/pre_verify.pl --contract FILE [--out FILE]
perl verification/pre_verify.pl --gate-check --contract FILE
perl verification/pre_verify.pl --selftest
```

Exit 0: PASS / PASS_WITH_WARNINGS / gate-check approved. Exit 2: BLOCKED /
INVALID_INPUT / gate-check refused. Engine defects die with a message.