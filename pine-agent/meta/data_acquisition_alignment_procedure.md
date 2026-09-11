# DATA ACQUISITION & ALIGNMENT PROCEDURE — pine-agent Phase 12

## 0. DOCUMENT AUTHORITY

This document is the narrative authority for Phase 12 of the pine-agent
pipeline. The implementation is `data_acquisition/data_acquisition.pl`; the
contract schema is `data/contract_schema.yaml` (v1.0).

## 1. MISSION & BOUNDARY

Phase 12 consumes the Phase 11 Incident Contract as authoritative incident
evidence and transforms

```
Phase 11 Incident + Market Data Source(s) + Acquisition Metadata
    → Phase 12 Data Acquisition & Alignment Contract
```

The ONLY question Phase 12 answers:

> "Do we have sufficiently trustworthy and correctly aligned market data for
> this Incident, and exactly what data do we have?"

It does NOT answer "why did the signal fail?" — that belongs to Phase 14.

Forbidden in this phase: diagnosing signal behavior, root-cause analysis,
Pine generation/modification/repair, redesign, modifying any Phase 1–11
artifact, executing Phase 13–15, converting data observations into causal
conclusions.

## 2. HARD INPUT GATE

The engine refuses to run unless ALL of:

1. `verification/phase10_post_verification_result.yaml` reads
   `verdict: validated` (Phase 10 REV 4, `post-918536e1e7d8`) — read-only.
2. A Phase 11 incident contract (file) exists and parses.
3. Incident `phase11_status` ∈ {READY, READY_WITH_WARNINGS}.
4. Incident `next_stage: DATA_ACQUISITION_AND_ALIGNMENT` and
   `downstream_allowed: true`.
5. `incident_id` well-formed (`incident-<12 hex>`), blockers empty.

Failure of any item → BLOCKED / INVALID_INPUT with `next_stage: HALT`.
Recovery is never attempted by guessing.

## 3. SOURCE TRUST MODEL

Every source record carries explicit provenance. Authority:
`AUTHORITATIVE | QUALIFIED_EXTERNAL | USER_PROVIDED | DERIVED | UNKNOWN`.
Fact provenance: `ACQUIRED | DERIVED | NORMALIZED | ALIGNED | USER_PROVIDED |
UNKNOWN`. Unavailable metadata is UNKNOWN — never invented. A source that
requires authentication without available credentials is BLOCKED; it is never
silently substituted with an unrelated source.

## 4. EXACT DATA IDENTITY

A dataset is not aligned because the ticker string matches. BTCUSD spot,
BTCUSD perpetual, and BTCUSD CFD are distinct identities; so are
NASDAQ:AAPL and NYSE:AAPL. Validate symbol / exchange / market type /
instrument type / timeframe / timezone / session / price & volume source /
timestamp convention wherever evidence exists. If identity cannot be
established: UNKNOWN (load-bearing) or BLOCKED by severity.

## 5. TIMEFRAME / TIMESTAMP / SESSION

- Timeframe identity is mandatory; silent resampling is forbidden. Any
  resample is recorded as an explicit transformation with methodology, and if
  it cannot reproduce required semantics the status degrades to
  INSUFFICIENT or SUFFICIENT_WITH_WARNINGS.
- Never assume local time == exchange time or UTC == chart display time.
  Timestamp conversion only when the source timezone is known; both source
  and normalized timestamps are recorded for any transformation.
- Bar-boundary semantics (open vs close vs interval) are never assumed; a
  mapping that cannot be established stays UNKNOWN — no bar is chosen
  arbitrarily.
- Session identity (regular/extended/24-7) is recorded; a dataset with
  extended-hours bars is never silently compared with a regular-session-only
  incident; if session identity cannot be established and materially affects
  the incident → BLOCKED.

## 6. DATA INTEGRITY CHECKS (DI01–DI10)

| Check | Name | Rule |
|---|---|---|
| DI01 | missing bars | expected interval with no bar |
| DI02 | duplicate bars | duplicate timestamps/canonical bars |
| DI03 | out-of-order | timestamp ordering violations |
| DI04 | timestamp gaps | unexpected temporal gaps |
| DI05 | OHLC validity | high ≥ max(open,close), low ≤ min(open,close), high ≥ low |
| DI06 | invalid values | NaN / infinite / invalid nulls |
| DI07 | volume integrity | zero vs missing vs negative vs unknown semantics; negative = defect where volume applies |
| DI08 | identity consistency | all bars belong to the intended instrument |
| DI09 | timeframe consistency | bars belong to the declared timeframe |
| DI10 | coverage sufficiency | required historical range exists |

## 7. DO NOT OVER-CLEAN

Normalization is NOT data improvement. No filling, interpolation, deletion of
suspicious bars, smoothing, correction, or source merging. Raw data remains
recoverable; derived/normalized data is a separate, explicitly recorded
transformation output.

## 8. MULTI-SOURCE & CONTRADICTIONS

Source A + Source B never silently become one authoritative dataset. Each
source carries its own identity, authority, coverage, and fingerprint.
Disagreements are recorded as CONTRADICTION with resolution NONE_PRESERVED;
if a contradiction materially affects the incident: BLOCKED or INSUFFICIENT.
A chart image suggesting volume present while data shows zero volume is
exactly such a preserved contradiction — never auto-resolved.

## 9. CHART IMAGE ≠ MARKET DATA

The Phase 11 chart image is visual evidence, never authoritative OHLCV.
Values read from pixels may exist only as VISUAL_ESTIMATE facts and are never
promoted to exact market data.

## 10. INCIDENT LOCALIZATION

Mapping classification: EXACT | PROBABLE | APPROXIMATE | UNKNOWN. EXACT only
when both the incident timestamp and a data bar at that timestamp exist and
identity matches. "Around 14:30" never becomes "bar index 438" unless data
and chart context prove it. bar_index / timestamp / OHLC / volume are never
fabricated.

## 11. EXPECTED / OBSERVED / DATA FACT

Strictly separated categories. `expected` = USER_REPORTED; `observed` =
visual observation; `data_fact` = ACQUIRED/DERIVED fact with provenance.
"volume = X" is a data fact; "volume caused the signal failure" is causal
reasoning and is mechanically rejected.

## 12. SUFFICIENCY HIERARCHY & LOAD-BEARING UNKNOWNS

`SUFFICIENT > SUFFICIENT_WITH_WARNINGS > INSUFFICIENT > BLOCKED` (plus
INVALID_INPUT). Only SUFFICIENT / SUFFICIENT_WITH_WARNINGS open
EXECUTION_TRACE_AND_DEBUG. If an unknown can materially alter downstream
tracing (unknown exchange/timeframe/timezone/session/symbol identity/bar
timestamp/source/required coverage), it stays unknown and affects the gate —
never replaced by ASSUMED to open the gate.

## 13. ROOT-CAUSE FIREWALL

The engine mechanically rejects causal wording (root cause, caused, because
the, reason the signal, why the signal, bug location, faulty condition,
incorrect formula) in any engine-derived field. `root_cause: NOT_EVALUATED`
is permanently emitted. Allowed: "The aligned dataset contains no bar for
timestamp X." Forbidden: "The missing bar probably caused the signal failure."

## 14. FIXTURE FIREWALL

Synthetic fixtures are permitted only inside the selftest. Fixture data is
tagged `TEST_FIXTURE` (`fixture: true` at the engine boundary) and is
mechanically rejected from production contracts: a `--data` dataset with
`fixture: true` or a fingerprint prefixed `TEST_FIXTURE|` produces
INVALID_INPUT. A production contract cannot be produced from fixture data.

## 15. DETERMINISM

All identifiers are SHA-256 over canonical serialization; no clock, no
randomness, no PID, no environment, no machine paths, no filesystem ordering,
no network timing. `data_contract_id = data-<12 hex of sha256(canonical
body)>`. Identical canonical inputs → byte-identical contracts (verified
across 3 fresh processes).

## 16. STAGES (deterministic, non-collapsible)

01 Forensic Audit · 02 Upstream Validation · 03 Phase 11 Input Gate ·
04 Data Source Discovery · 05 Data Acquisition · 06 Provenance Registration ·
07 Raw Preservation/Fingerprinting · 08 Normalization · 09 Timestamp/Timezone
Alignment · 10 Symbol/Exchange/Timeframe/Session Alignment · 11 Incident Bar
Localization · 12 Coverage Validation · 13 Integrity Checks · 14 Multi-Source
Conflict Analysis · 15 Sufficiency Evaluation · 16 Unknown/Limitation
Registration · 17 Data Contract Generation · 18 Determinism Verification ·
19 Phase 12 Result · 20 Downstream Gate.

## 17. MECHANICAL CHECKS (DA-G1..DA-G16)

| Check | Domain | Responsibility |
|---|---|---|
| DA-G1 | upstream_identity | Phase 10 validated + identity chain intact |
| DA-G2 | phase11_gate | incident status/next_stage/identity/identity-chain valid |
| DA-G3 | source_provenance | every source carries authority + provenance enums |
| DA-G4 | dataset_identity | dataset fields/fingerprints well-formed |
| DA-G5 | timestamp_alignment | tz conversion only with known source tz; recorded |
| DA-G6 | timeframe_session | declared tf/session validated; no silent resample |
| DA-G7 | data_integrity | DI01–DI10 executed, verdicts deterministic |
| DA-G8 | coverage_sufficiency | warm-up/lookback context evaluated, not just incident bar |
| DA-G9 | localization | incident→bar mapping classification honest |
| DA-G10 | raw_fingerprint | sha256 over raw bytes preserved or UNAVAILABLE |
| DA-G11 | transformation_traceability | every transform recorded, raw recoverable |
| DA-G12 | unknown_preservation | load-bearing unknowns stay unknown; contradictions preserved |
| DA-G13 | root_cause_firewall | causal wording rejected in engine output |
| DA-G14 | contract_schema | emitted fields match schema v1.0 |
| DA-G15 | determinism | no clock/random/env input; content-addressed ids |
| DA-G16 | downstream_gate | only SUFFICIENT/SUFFICIENT_WITH_WARNINGS open Phase 13 |

## 18. EXIT CODES & GATE

- `0` — READY / READY_WITH_WARNINGS → contract emitted, downstream gate open
  (`next_stage: EXECUTION_TRACE_AND_DEBUG`)
- `2` — INSUFFICIENT_DATA / BLOCKED / INVALID_INPUT (downstream HALT);
  `--gate-check` refusal also exits 2

`--gate-check --data FILE` approves only SUFFICIENT / SUFFICIENT_WITH_WARNINGS
contracts with empty blockers, `downstream.allowed: true`, and
`next_stage: EXECUTION_TRACE_AND_DEBUG`.

## 19. TESTING & DETERMINISM

Selftest DAT-001..DAT-028 plus negative tests NG-001..NG-009 (fabricated
data, invented timestamp/source/OHLCV, assumption masquerading as
acquisition, causal statement masquerading as data fact, silent timezone
conversion, silent resampling, silent data cleaning, fixture leak).
Determinism: 3 fresh processes byte-identical. Upstream regressions must pass
unchanged.

## 20. ENGINE IMPLEMENTATION (data_acquisition.pl)

Core Perl 5, zero non-core dependencies, contract-identical to the Phase 4–11
engines. CLI:

```
perl data_acquisition/data_acquisition.pl
  --incident FILE            Phase 11 contract (required)
  [--data FILE]...           CSV dataset: ts,open,high,low,close,volume
  [--source NAME]            source label for the next --data
  [--authority AUTHORITATIVE|QUALIFIED_EXTERNAL|USER_PROVIDED|DERIVED|UNKNOWN]
  [--provider NAME] [--retrieval METHOD] [--retrieved-at TS]
  [--timezone TZ] [--exchange EX] [--market-type TYPE]
  [--warmup N] [--mtf TF,TF,...]
  [--out FILE] [--help] [--version] [--selftest]
  [--gate-check --data CONTRACT_FILE]
```

Exit codes: 0 = downstream open; 2 = downstream closed/invalid; die on
internal errors (distinct non-zero). No external network access exists in
this environment: without an explicit `--data` source the honest outcome is
INSUFFICIENT_DATA (no-data environment, prompt §28) — never synthetic data.
