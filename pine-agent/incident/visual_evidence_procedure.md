# PHASE 11 — VISUAL EVIDENCE PROCEDURE
**version:** 1.0.0 · **stage:** incident_intake · **engine:** `incident/incident_intake.pl`
**successor:** `PHASE_12_DATA_ACQUISITION_AND_ALIGNMENT`

Narrative authority for Phase 11. The engine executes the mechanical checks
INT-G1..INT-G8 and enforces the vocabulary, gates, and identity rules below.
Where this document and any prose disagree, this document governs Phase 11.

---

## 1. MISSION & BOUNDARY

Phase 11 is a deterministic evidence-ingestion layer between:

```
USER + CHART IMAGE + OBSERVATION   →   STRUCTURED INCIDENT EVIDENCE
```

It answers: *what does the user claim happened, what is actually observable in
the supplied visual evidence, where is the suspected event, and what evidence
is available?*

It does **not** answer *why* — root-cause diagnosis belongs to Phase 14.
It does not obtain market data (Phase 12), does not execute or compile Pine
(Phase 13), does not diagnose (Phase 14), and does not repair anything.

**Core principle: OBSERVATION ≠ INFERENCE ≠ DIAGNOSIS.**

| Class | Meaning | Example |
|---|---|---|
| OBSERVED | directly visible in supplied image | "A green candle is visible" |
| USER_REPORTED | explicitly stated by user, not independently established | "Volume expanded here" |
| INFERRED | reasonable interpretation of visible evidence, not directly proven | "the highlighted region appears to correspond to a potential signal event" |
| UNKNOWN | cannot be established from supplied evidence | exact bar timestamp |

Forbidden conversions: USER_REPORTED → OBSERVED; OBSERVED → ROOT_CAUSE.

---

## 2. INPUT MODEL

Supported inputs (none fabricated when absent):

```
incident_description / user_report      chart_image (0..n)
symbol / exchange / timeframe / timezone
suspected_timestamp / suspected_bar / suspected_region
expected_behavior / observed_behavior / user_notes
indicator_name / implementation_id / source_artifact
```

Missing-information vocabulary (use the most precise applicable):

| status | meaning |
|---|---|
| UNKNOWN | looked for, could not be established |
| NOT_PROVIDED | user did not supply the field |
| NOT_VISIBLE | field exists conceptually but is not visible in image |
| NOT_ESTABLISHED | effort did not establish the value |

---

## 3. VISUAL INSPECTION DIMENSIONS

When an image is supplied, inspect systematically — extract only what is
actually available:

1. **Chart identity** — symbol, exchange, timeframe, chart type, session
   info. Classification rule: a value is OBSERVED only when literally
   readable; otherwise the field records UNKNOWN/NOT_VISIBLE with the reason
   in `limitations`.
2. **Price structure** — candle direction, approximate movement, visible
   highs/lows, apparent trend, consolidation, breakout/breakdown, gaps when
   visually evident. INFERRED when interpretation is involved.
3. **Volume** — panel presence, relative bar heights, apparent expansion/
   contraction. Exact values only when numerically visible.
4. §; indicators pane presence; visible signal construct name (BUY/SELL
   markers, arrows, labels, shapes, alerts, colored bars/backgrounds).
5. **Signals** — identify visible signal constructs; absence phrasing is
   restricted to visual claims ("no visible BUY marker detected in the
   inspected region"), never runtime claims.

---

## 4. REGION LOCALIZATION

Preserve the user's reference verbatim, identify the approximate region,
record the localization method:

```
USER_POINTED | VISUALLY_IDENTIFIED | TEXT_LABEL | TIME_AXIS |
PRICE_AXIS | APPROXIMATE_ONLY | NOT_LOCALIZABLE
```

Never invent a precise bar index or timestamp. When exact localization is
impossible:

```
bar_index: UNKNOWN
timestamp: UNKNOWN
precision: APPROXIMATE   # or UNKNOWN
```

Every localization claim must trace to an evidence id (`localization_trace`).

---

## 5. EXPECTED / OBSERVED / USER_INTERPRETATION

The Incident Contract keeps three separate fields:

- **EXPECTED** — what the user believes should have happened ("BUY signal
  should have appeared") — source USER_TEXT.
- **OBSERVED** — what the supplied evidence actually demonstrates ("No visible
  BUY marker is present in the inspected region") — source CHART_IMAGE /
  USER_TEXT / MIXED / NONE.
- **USER_INTERPRETATION** — the user's causal reading ("volume expansion and
  upward price movement should have triggered BUY") — NOT a requirement, NOT
  evidence.

The user's interpretation is never converted into observed fact or requirement.

---

## 6. CONFIDENCE & PROVENANCE

Every evidence item carries:

- **classification** OBSERVED | USER_REPORT | INFERRED | UNKNOWN (schema enum)
- **confidence** HIGH (directly visible, unambiguous) · MEDIUM (visible but
  partially obscured/approximate/dependent on scaling) · LOW (weak indication) ·
  UNDETERMINED (quality/missing info prevents classification)
- **provenance source** CHART_IMAGE | USER_TEXT | USER_MARKED_REGION |
  PROJECT_ARTIFACT | UNKNOWN

LOW/UNDETERMINED evidence is never converted into definitive technical claims.
Web-derived data is NOT an evidence source in Phase 11 (Phase 12's domain).

---

## 7. IMAGE FINGERPRINT

`image_sha256` is computed over the raw bytes of the supplied image
(`Digest::SHA`, core Perl) — for evidence identity only. The image is never
modified or recompressed for the authoritative record. When fingerprinting is
unavailable: `image_fingerprint_status: UNAVAILABLE` — never fabricated.

---

## 8. CONTRADICTIONS, MULTIPLE INCIDENTS, MULTIPLE IMAGES

- **Contradictions** between user statement and visible image: record as
  `CONTRADICTORY_EVIDENCE` in `contradictions[]` with `resolution:
  NONE_PRESERVED` — both claims preserved, never silently resolved.
- **Multiple independent anomalies** in one report → independent incidents
  (INCIDENT-001, INCIDENT-002, ...) each with independent evidence and
  localization; merging requires deterministic documented justification.
  If clearly the same event, one incident.
- **Multiple images**: each evidence item records `source_image: IMG-002`;
  no assumed chronological order; contradictory evidence is recorded, not
  merged.

---

## 9. INCIDENT IDENTITY (deterministic)

```
incident_id = "incident-" + first 12 hex of sha256(canonical_body)
```

**Canonical body** (UTF-8, `\n`-joined, in fixed field order — no timestamps,
no randomness, no process/env values):

```
user_report_bytes_sha256 | image fingerprints in supplied order |
target.symbol|exchange|timeframe|timezone|implementation_id |
localization.method|timestamp|bar_index|region |
expected | observed | user_interpretation |
evidence ids+classifications+confidences | contradictions count |
limitations count | schema_version
```

Identical canonical inputs produce identical ids. The incident contract is
never mutated in place; a changed body yields a new incident_id (with
`supersedes` linking when applicable).

---

## 10. STATUS MODEL & SUFFICIENCY

| status | meaning |
|---|---|
| READY | structurally valid + sufficient for Phase 12 to attempt data acquisition |
| READY_WITH_WARNINGS | can proceed; important evidence incomplete/approximate |
| INSUFFICIENT_VISUAL_EVIDENCE | image/description cannot establish a meaningful investigation target |
| INVALID_INPUT | malformed/unusable input |
| BLOCKED | hard architectural/contract condition prevents continuation |

**Sufficient for Phase 12** (all required): investigation target established
(symbol and/or timeframe identified, or Phase 12 can obtain them from the
exchange context), region/localization present (USER_POINTED or better), and
the expected/observed distinction captured. Do not demand information Phase 12
can legitimately obtain later.

**Insufficient** — e.g. no readable symbol/timeframe, no clear region, and a
description too vague to identify the investigation target.

Warnings include: no image, no target identity, approximate-only localization,
low/undetermined-confidence evidence present, unresolved contradiction,
non-readable axes, compressed screenshot. Warnings never block; blockers do.

---

## 11. ROOT-CAUSE FIREWALL (no leakage)

Phase 11 must not output "Root cause:". It may output "Suspected anomaly:" or
"Investigation target:" only. Mechanically enforced: any `root cause` mention
in engine output is rejected (negative test INT-010 / NG-001..NG-008).

---

## 12. STAGES (deterministic, non-collapsible)

```
01 FORENSIC AUDIT              08 EXPECTED VS OBSERVED SEPARATION
02 UPSTREAM VALIDATION         09 EVIDENCE / CONFIDENCE / PROVENANCE
03 INPUT VALIDATION            10 UNKNOWN / CONTRADICTION ANALYSIS
04 IMAGE INGESTION             11 INCIDENT CONTRACT GENERATION
05 VISUAL EVIDENCE EXTRACTION  12 DETERMINISM / INTEGRITY
06 USER OBSERVATION NORMALIZATION  13 PHASE 11 RESULT
07 REGION/EVENT LOCALIZATION   14 DOWNSTREAM GATE
```

Stage 01/02 operate on the repository (Phase 10 REV 4 result present and
`validated`, validated artifact hash recorded, no upstream mutation). Stages
03–11 operate on the incident input. Stage 12 re-derives the identity from the
canonical body. Stage 14 sets `downstream_allowed` strictly per the gate rules.

---

## 13. EXIT CODES & GATE

```
exit 0   READY | READY_WITH_WARNINGS  (downstream_allowed true)
exit 2   INSUFFICIENT_VISUAL_EVIDENCE | INVALID_INPUT | BLOCKED  (next_stage HALT)
```

`--gate-check --incident FILE` approves only READY/READY_WITH_WARNINGS
contracts with empty blockers and `next_stage:
DATA_ACQUISITION_AND_ALIGNMENT` (exit 0), refuses all others (exit 2).

---

## 14. TESTING & DETERMINISM

Selftest covers INT-001..INT-010 plus negative tests NG-001..NG-008:
valid image + clear observation → READY; missing symbol/timeframe →
READY_WITH_WARNINGS when Phase 12 can identify the target; text-only incident →
READY_WITH_WARNINGS; no identifiable region → INSUFFICIENT_VISUAL_EVIDENCE;
contradiction → preserved not resolved; multiple incidents → independent
records; identical input → byte-identical output; different image bytes →
different fingerprint; missing optional fields → explicit UNKNOWN/NOT_PROVIDED
(no fabrication); root-cause inference attempt → rejected. Negative set:
visual evidence → automatic root cause / code repair / market data retrieval;
unknown timestamp/bar → fabricated; no visible marker → definite runtime claim;
user interpretation → observed fact; skill knowledge → evidence.

Determinism: 3 fresh processes, byte-identical contract + ids. No clock,
randomness, environment, or machine paths in output. The engine never reads or
writes Phase 1–10 artifacts except read-only inspection during Stage 01/02.

## 15. ENGINE IMPLEMENTATION (incident_intake.pl)

The intake engine is `incident/incident_intake.pl` (core Perl 5, zero
non-core dependencies). Runtime contract is identical to the Phase 4–9
engines: deterministic, fail-loudly, no silent fallback.

### CLI

    perl incident/incident_intake.pl \
      (--user-report FILE | --report-text TEXT) \
      [--image FILE]... \
      [--image-obs IMG-001|statement|classification|confidence]... \
      [--symbol S] [--exchange E] [--timeframe TF] [--timezone TZ] \
      [--implementation-id ID] [--expected TEXT] [--observed TEXT] \
      [--interpretation TEXT] [--region TEXT] [--artifact PATH] \
      [--out FILE]

`--gate-check --incident FILE` approves only READY / READY_WITH_WARNINGS
contracts with empty blockers and
`next_stage: DATA_ACQUISITION_AND_ALIGNMENT` (exit 0); every other contract
is refused (exit 2).

### Stage → check mapping

| Stage | Check | Responsibility |
|---|---|---|
| 01/02 | (CLI-level) | forensic state audit; upstream Phase 10 result must read `verdict: validated` (read-only) |
| 03 | INT-G1 | input validation |
| 04 | INT-G2 | image ingestion (fingerprint over raw bytes; never modified) |
| 05 | INT-G3 | visual evidence extraction (vocabulary discipline) |
| 06 | INT-G4 | user observation normalization (verbatim preserved) |
| 07 | INT-G5 | region/event localization (never invent bar index/timestamp) |
| 08 | INT-G6 | expected / observed / interpretation separation (+ firewall) |
| 09 | (accumulator merge) | evidence/unknowns/limitations into findings |
| 10 | INT-G7 | contradiction analysis (recorded, never resolved) |
| 11 | INT-G8 | sufficiency decision |
| 12 | INT-G8 | downstream gate (Phase 12 opening rule) |
| 13/14 | — | contract emission (fixed field order) + identity |

### Exit codes

- `0` — READY or READY_WITH_WARNINGS (downstream_allowed true)
- `2` — INSUFFICIENT_VISUAL_EVIDENCE, INVALID_INPUT, or BLOCKED
  (next_stage HALT); gate-check refusal also exits 2

