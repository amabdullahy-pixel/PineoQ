# CHANGELOG — pine-agent

Chronological, append-only. Never rewrite or delete historical entries.

---

## 0.1.0 - Initial architecture scaffold

**Date:** 2026-09-09
**Status:** architecture-stage

### Added

- Directory scaffold: `config/`, `formalization/`, `feasibility/`,
  `implementation/`, `verification/`, `meta/`, `skills/{incoming,normalized,
  archived,rejected,review-needed}/`, `templates/`,
  `tests/{routing,skill-loading,formalization,contracts}/`.
- `PROJECT_MANIFEST.yaml` — authoritative machine-readable project snapshot.
- `AGENT_RULES.md` — binding rules (pipeline gating, ambiguity/assumption
  tracking, verification discipline, Pine v6 policy, Skill economy).
- `README.md` — full pipeline documentation with per-stage purpose/responsibility.
- Contract schemas: `formalization/contract_schema.yaml`,
  `feasibility/contract_schema.yaml`,
  `implementation/contract_schema.yaml`,
  `verification/pre_contract_schema.yaml`,
  `verification/post_contract_schema.yaml`.
- Meta docs: `meta/skill_router.md`, `meta/context_loading_policy.md`,
  `meta/project_memory.md`.
- Config: `config/routing.yaml`, `config/feasibility.yaml`,
  `config/verification.yaml`, `config/token_policy.yaml`.
- Templates: `templates/skill-template.md`,
  `templates/manifest-template.yaml`,
  `templates/verification-report-template.yaml`.
- `skills/registry.yaml` — initialized EMPTY (`skills: []`).
- 8 initial test specifications under `tests/` (routing, skill-loading,
  formalization, contracts).

### Architectural decisions

- **AD-01 Gated pipeline with hard stage ordering** — Formalization before any
  code generation; Feasibility strictly between Formalization and
  Implementation; stages cannot be skipped or reordered.
- **AD-02 YAML contracts between all stages** — machine-checkable handoffs;
  `status` / `blockers` / `ambiguities` are first-class fields.
- **AD-03 Minimum-required Skill loading** — Router selects only trigger-matched
  Skills plus mandatory dependencies from `registry.yaml`; never the full catalog.
- **AD-04 Registry starts empty; no placeholder Skills** — Skills enter only via
  a future Import/Normalize phase.
- **AD-05 Ambiguities and blockers are first-class contract fields** — ambiguous
  requests are recorded, never silently resolved; failed stages record reasons.
- **AD-06 Pre-Verification and Post-Verification are separate stages** —
  pre checks intent (logic/math/data) before code exists; post checks the
  artifact (syntax/runtime/repaint/perf) after Implementation.
- **AD-07 Scaffold contains no Pine code and no Skills** — Import Mode and
  Implementation Mode are gated behind future manifest status changes;
  `implementation_allowed: false` globally.
- **AD-08 Honest validation policy** — ACTUALLY VERIFIED vs STATICALLY
  REVIEWED distinction is contractual; compile confirmations require a
  user-reported TradingView result.

### Constraints (enforced in this phase)

- No Pine Script code generated anywhere in the scaffold.
- No Skills created, imported, rewritten, or summarized.
- `skills/normalized/` and `skills/incoming/` empty (incoming holds only
  `.gitkeep`).
- `skills/registry.yaml` remains empty.

### Known bugs

- None.

### Validation

- Structure validated against the required tree (see manifest
  `validation_results`).

---

## 0.2.0 - Import Mode batch-001: Skills 01–10 normalized and registered

**Date:** 2026-09 (batch-001)
**Status:** import-mode, batch 1 of 8

### Added

- 10 normalized Skills under `skills/normalized/` — layer directories `core/`
  (7), `meta/` (1), `implementation/` (3) — each following
  `templates/skill-template.md` plus the mandatory Import extensions
  (Ambiguities / Missing Information / Import Notes / Source Reference):
  pine-language-core, pine-type-system, pine-data-structures,
  pine-functions-libraries, pine-v6 (CORE); pine-version-intelligence (META);
  tradingview-execution-model (CORE); indicator-strategy-library-architecture,
  strategy-engine, drawing-and-visualization (IMPLEMENTATION).
- 10 individual Import Reports + `batch-001-report.md` +
  `processing-index.yaml` under `skills/import-reports/`.
- Registry first population: 10 entries, all `status: normalized`,
  `activation: eligible`, `validation_status: passed`, full
  english/persian trigger sets.

### Decisions

- **Normalized-Skill layout** — one directory per Skill
  (`skills/normalized/<layer>/<skill-id>/skill.md`) for independent loadability
  and future per-Skill metadata.
- **Layer assignment from function** — pine-version-intelligence classified
  META (not the source's "Pine Script Core" tag); recorded in its report.
- **Dependency direction** — source cross-references ("see skill N") became
  optional dependencies; no content duplication between Skills.
- **Verification scope honesty** — version-sensitive claims spot-checked
  against official release notes (2026-09 fetch); confirmed `once` (Aug 2026),
  `request.footprint()` (Jan 2026), multiline strings (Apr 2026), UDT
  sort/binary search via `sort_field` (Apr + Aug 2026). July 2026 items absent
  from sources (calc_on_every_history_tick, strategy UI renames, automatic
  parentheses) recorded as missing_information in skills 05/08/09 — NOT
  rewritten into any rule (import does not improve).

### Preserved (unchanged)

- All 77 raw sources in `skills/incoming/` untouched (verified by wc/md5 at
  batch close).
- All architectural contracts, configs, templates, and tests unmodified.

### Constraints kept

- No Pine Script code generated. No new Skill invented. No merge, no silent
  correction, no registry placeholder. Incoming sources not moved or modified.

### Validation

- All 14 validation gates passed for each of the 10 Skills (see reports
  IR-batch-001-01 … IR-batch-001-10).
- Duplicate/overlap analysis completed for batch pairs; no exact_duplicate or
  partial_overlap found; 3 cross-batch candidates parked in the index.
- Progress: 10/77 processed; batch-002 = skills/incoming/11..20.

---

## 0.3.0 - Import Mode batch-002: Skills 11–20 normalized and registered

**Date:** 2026-09 (batch-002)
**Status:** import-mode, batch 2 of 8

### Added

- 10 normalized Skills under `skills/normalized/` — `implementation/` (4:
  alerts-and-webhooks, mtf-engineering, data-integrity,
  multi-symbol-engineering), `verification/` (1: repainting-and-lookahead —
  new layer directory), `quant/` (5: mathematical-foundation, linear-algebra,
  calculus-and-optimization, analytical-geometry, numerical-methods — new
  layer directory).
- 10 individual Import Reports + `batch-002-report.md` under
  `skills/import-reports/`; processing index advanced.
- Registry: 10 entries appended (20 total), all `status: normalized`,
  `activation: eligible`, `validation_status: passed`.

### Decisions

- **Layer assignments from function** — repainting-and-lookahead classified
  VERIFICATION (audit/checklist function) despite source category
  "Repainting & Data Integrity"; QUANT block kept as its own layer directory.
- **Pending-optional-dependency convention documented in the registry header**
  — ids of not-yet-imported skills are deterministic and tracked; Router
  treats missing optional deps as no-op.
- **Unverified-claim handling exercised** — one claim flagged (below),
  preserved verbatim, proposed interpretation recorded separately.

### Verification

- Operator precedence table + na-propagation CONFIRMED against the official
  Operators page (2026-09 fetch).
- UNVERIFIED claim preserved (mathematical-foundation): "division by zero →
  math.inf/math.nan" — official docs silent on runtime results; community
  evidence indicates runtime na. Guard-every-denominator rule remains
  unconditional.
- Negative claims preserved as verify-before-use gates: request.quandl()
  REMOVED; ta.slope does not exist; matrix diff/dot/lu/chol/qr do not exist.
- Batch-001 pending optional-dependency pointers RESOLVED:
  repainting-and-lookahead + mtf-engineering now registered.

### Preserved (unchanged)

- All 77 raw sources untouched; architectural contracts/configs/templates/tests
  unmodified.

### Validation

- All 14 validation gates passed for each of the 10 Skills (reports
  IR-batch-002-11 … IR-batch-002-20).
- No exact_duplicate/partial_overlap; new cross-batch candidates parked in the
  index (with 21, 52).
- Progress: 20/77 processed (26%); batch-003 = skills/incoming/21..30.

---

## 0.4.0 - Import Mode batch-003: Skills 21–30 normalized and registered

**Date:** 2026-09 (batch-003)
**Status:** import-mode, batch 3 of 8

### Added

- 10 normalized Skills under `skills/normalized/` — `quant/` (8:
  statistics-core, probability, statistical-distributions,
  regression-correlation, statistical-testing, time-series-analysis,
  stochastic-processes, monte-carlo-and-resampling), `implementation/` (1:
  risk-management).
- 10 individual Import Reports + `batch-003-report.md`; processing index
  advanced.
- Registry: 10 entries appended (30 total), all `status: normalized`,
  `activation: eligible`, `validation_status: passed`.

### Decisions

- **Layer assignment from function** — risk-management classified
  IMPLEMENTATION (builds risk controls with Pine APIs) despite the source's
  "Financial Math & Risk" category; recorded in its report.
- **Double-verification standard exercised** — the batch's load-bearing claim
  (strategy.risk.* existence in v6) verified by the source AND independently
  re-verified at import.

### Verification

- VERIFICATION EVENT corroborated (risk-management): an earlier research
  pass's false claim that strategy.risk.* was removed in v6 is debunked —
  official Strategies docs + v6 reference index confirm all six functions;
  strategy.max_drawdown_percent confirmed. A third-party blog repeating the
  removal claim identified as the false claim the source warned about.
- Negative claims preserved as verify-before-use gates: no built-in
  distribution functions; no built-in hypothesis-test functions; ADF not
  available.
- Batch-002 pending optional-dependency pointers RESOLVED: statistics-core,
  financial-mathematics now registered.

### Preserved (unchanged)

- All 77 raw sources untouched; architectural contracts/configs/templates/tests
  unmodified.

### Validation

- All 14 validation gates passed per Skill (IR-batch-003-21 …
  IR-batch-003-30).
- No exact_duplicate/partial_overlap; new cross-batch candidates parked (31,
  51, 53, 54).
- Progress: 30/77 processed (39%); batch-004 = skills/incoming/31..40.

---

## 0.5.0 - Import Mode batch-004: Skills 31–40 normalized and registered

**Date:** 2026-09 (batch-004)
**Status:** import-mode, batch 4 of 8

### Added

- 10 normalized Skills under `skills/normalized/` — `implementation/` (2:
  position-sizing, trade-management), `quant/` (1: performance-metrics),
  `research/` (7: technical-analysis-core, trend-indicators,
  momentum-indicators, volatility-indicators, volume-analysis,
  price-action-patterns, market-structure — NEW layer directory).
- 10 individual Import Reports + `batch-004-report.md`; processing index
  advanced.
- Registry: 10 entries appended (40 total), all `status: normalized`,
  `activation: eligible`, `validation_status: passed`.

### Decisions

- **RESEARCH layer established** — indicator/market-knowledge skills
  (classification, formulas, structure disciplines) separated from QUANT's
  mathematical tooling; used at Formalization/Planning, with
  implementation-stage work remaining downstream.
- **Layer assignments from function** — position-sizing/trade-management
  IMPLEMENTATION; performance-metrics QUANT; the TA block RESEARCH.

### Verification

- Two signature-level claims corroborated at import (trend-indicators):
  ta.supertrend direction = −1 uptrend / +1 downtrend (multiple independent
  sources incl. one quoting the Pine reference); ta.alma 5-parameter
  signature with optional floor bool (v6-labeled reference listing).
- Negative claims preserved as verify-before-use gates: ta.kama absent; no
  built-in stochastic smoothing/%D; no ta.donchian; no built-in HV; no
  built-in RVOL/VP/delta; no built-in candlestick patterns; no built-in
  Sharpe/Sortino/Calmar functions.
- Five batch-003/002/001 pending optional-dependency pointers RESOLVED:
  position-sizing, trade-management, performance-metrics, trend-indicators,
  volatility-indicators.

### Preserved (unchanged)

- All 77 raw sources untouched; architectural contracts/configs/templates/tests
  unmodified.

### Validation

- All 14 validation gates passed per Skill (IR-batch-004-31 …
  IR-batch-004-40).
- No exact_duplicate/partial_overlap; new cross-batch candidates parked (47,
  41).
- Progress: 40/77 processed (51.9%); batch-005 = skills/incoming/41..50.

## [0.6.0] — batch-005: RESEARCH quantitative/methods block (41–50)

### Added

- 10 normalized Skills under `skills/normalized/research/` — first
  single-layer batch (all RESEARCH):
  liquidity-and-price-structure, fibonacci-and-harmonic,
  advanced-market-geometry, quantitative-analysis, signal-engineering,
  signal-fusion, regime-detection, adaptive-systems, signal-processing,
  statistical-arbitrage.
- 10 individual import reports (IR-batch-005-41 … IR-batch-005-50) +
  `batch-005-report.md`.
- Registry: +10 entries (50 total), all normalized/eligible/passed;
  stale pending-dependency example in the registry header refreshed
  (documentation-only).
- Processing index advanced: 50/77 (64.9%); pending = incoming 51–77;
  batch-006 = incoming 51–60.

### Resolved

- Parked candidates: 40↔47 (dependency_relationship),
  39↔41 (related_but_distinct, keep_separate); registry pending-dep pointers
  to batch-005 ids now resolvable (batches 002–004 consumers).
- New parked candidates: 44↔53, 48↔53 (walk-forward-and-validation).

### Preserved (unchanged)

- All 77 raw sources untouched; architecture files unmodified; no Pine code
  generated; no Skills invented, merged, or activated beyond documented rules.

### Validation

- All 14 validation gates passed per Skill (IR-batch-005-41 …
  IR-batch-005-50).
- No exact_duplicate/partial_overlap; negative claims (no built-in
  fib/harmonic/FFT/wavelet/cointegration) preserved as verify-before-use
  gates.

## [0.7.0] — batch-006: backtesting validation + market context block (51–60)

### Added

- 10 normalized Skills under `skills/normalized/research/` — second
  single-layer batch (all RESEARCH):
  backtesting-science, optimization-and-calibration,
  walk-forward-and-validation, overfitting-and-robustness,
  macro-economics, intermarket-analysis, market-microstructure,
  asset-class-specialization, behavioral-finance, market-psychology.
- 10 individual import reports (IR-batch-006-51 … IR-batch-006-60) +
  `batch-006-report.md`.
- Registry: +10 entries (60 total), all normalized/eligible/passed.
- Processing index advanced: 60/77 (77.9%); pending = incoming 61–77;
  batch-007 = incoming 61–70.

### Verified

- Three independent verification events (import, 2026-09): Bar Magnifier
  200k-LTF-bar budget + Deep Backtesting 2M bars/1M trades (official
  support article + blog); `request.economic()` signature/ISO codes/CPI-GDP
  fields (official support article fetched live); `bid`/`ask` 1T-only
  semantics (official chart-information docs).

### Resolved

- Parked candidates: 09↔51 (keep_separate), 18↔52 (no_action), 25↔54,
  28↔51, 44↔53, 48↔53 (dependency_relationship); registry pending-dep
  pointers from statistical-testing and monte-carlo-and-resampling now
  resolvable.
- New parked candidates: 29↔61, 57↔63.

### Preserved (unchanged)

- All 77 raw sources untouched; architecture files unmodified; no Pine code
  generated; no Skills invented, merged, or activated beyond documented rules.

### Validation

- All 14 validation gates passed per Skill (IR-batch-006-51 …
  IR-batch-006-60).
- No exact_duplicate/partial_overlap; negative claims (no built-in
  optimizer, no calendar access, no order-book access, no native Fear&Greed)
  preserved as verify-before-use gates; symbol-ID claims preserved as
  verify-per-plan.

## [0.8.0] — batch-007: methodology + Pine engineering block (61–70)

### Added

- 10 normalized Skills: system-psychology, research-methodology,
  hypothesis-and-formula-engineering (RESEARCH), natural-language-to-math
  (**FORMALIZATION** — first skill in that layer, new
  `skills/normalized/formalization/` directory), research-to-code,
  falsification-and-counterexamples, causal-reasoning (RESEARCH),
  pine-code-architecture, pine-performance-engineering (IMPLEMENTATION),
  pine-debugging-and-testing (VERIFICATION).
- 10 individual import reports (IR-batch-007-61 … IR-batch-007-70) +
  `batch-007-report.md`.
- Registry: +10 entries (70 total), all normalized/eligible/passed;
  header pending-dependency example refreshed (72/77 now the referenced
  pending skills).
- Processing index advanced: 70/77 (90.9%); pending = incoming 71–77;
  batch-008 = final batch.

### Verified

- Two independent verification events (import, 2026-09): native Pine
  Profiler (official profiling docs + support article — flame-icons top-3
  detail exact); Pine Logs (official debugging docs + blog — log.*/10k-
  historical-entry cap).

### Resolved

- Parked candidates: 10↔69 (open since batch-001 — dependency_relationship),
  29↔61 (no_action), 57↔63 (dependency_relationship); registry pending-dep
  pointers to falsification-and-counterexamples, pine-code-architecture,
  pine-performance-engineering now resolvable.
- Layer-from-function assignments recorded: 64 → FORMALIZATION,
  70 → VERIFICATION (same precedent as repainting-and-lookahead).

### Preserved (unchanged)

- All 77 raw sources untouched; architecture files unmodified; no Pine code
  generated; no Skills invented, merged, or activated beyond documented rules.

### Validation

- All 14 validation gates passed per Skill (IR-batch-007-61 …
  IR-batch-007-70).
- No exact_duplicate/partial_overlap; key related_but_distinct pairs
  documented (62↔65, 66↔54, 68↔08).

## [0.9.0] — batch-008 (FINAL): agent-operations block (71–77); Import Mode complete

### Added

- 7 normalized Skills: code-review-and-refactoring (VERIFICATION),
  requirements-engineering (FORMALIZATION), project-knowledge-management,
  context-compression, skill-routing, documentation-verification,
  pine-project-documentation (META).
- 7 individual import reports (IR-batch-008-71 … IR-batch-008-77) +
  `batch-008-report.md` + `final-import-report.md` (closes Import Mode).
- Registry: +7 entries (**77 total — the complete 77-skill library**), all
  normalized/eligible/passed; header note updated: full dependency closure
  achieved.
- Processing index terminal state: 77/77, pending 0.

### Resolved

- Final parked candidate {06↔76} (open since batch-002) — related_but_
  distinct, keep_separate. Zero unresolved duplicate candidates remain.
- All pending optional-dependency pointers (72, 77, and prior) now resolve;
  every registry dependency id resolves to a registered entry.

### Recorded (not fixed — Import Mode creates no Skills)

- FEASIBILITY is the only architectural layer without a source Skill (the
  raw library contains none; feasibility checks remain owned by
  config/feasibility.yaml).

### Preserved (unchanged)

- All 77 raw sources untouched; architecture files unmodified; no Pine code
  generated; no Skills invented, merged, or activated beyond documented rules.

### Validation

- All 14 validation gates passed per Skill (IR-batch-008-71 …
  IR-batch-008-77); full-project verification pass green (sources, registry
  integrity, dependency closure, report coverage, no-Pine-code).

## [1.0.0] — PHASE 3: Router Design Mode (design only — no executable logic)

### Added

- `meta/skill_router.md` v2.0.0 — full Router Design Specification:
  14-stage routing pipeline (normalization → intent → classification →
  domains → matching → minimal coverage → dependency resolution →
  redundancy elimination → conflict/gap analysis → context estimation →
  decision → trace → handoff → termination); routing/2 output contract
  (`routing_status`: ready | ambiguous | insufficient_coverage | blocked |
  conflict_detected; mandatory 5-section routing_trace);
  match grades (match/partial_match/weak_match/no_match) with
  weak_match-never-selected-alone; minimal-sufficiency optimization under
  hard caps; deterministic tie-breaking; S/M/L/XL context sizing;
  safety rules; worked example.
- `config/routing.yaml` v2 — restructured into the five mandated layers:
  classification_rules, matching_rules, selection_rules,
  dependency_rules, context_policy; v0.1 behaviors preserved
  (max 5 selected, depth 3, no fuzzy matching, controlled failures on
  empty registry / no match, excluded categories unchanged).
- 6 new routing test specifications (TEST-ROUTING-003 … TEST-ROUTING-008):
  determinism + contract conformance; trigger fidelity (weak_match never
  selected alone); minimal sufficiency + caps + tie-breaks; dependency
  closure/cycles/depth; status-gated Formalization handoff; mandatory
  trace + recorded redundancy (never merge).
- Manifest: status → router-design-stage; architectural decisions AD-07
  (routing/2 contract) and AD-08 (five-layer separation) recorded;
  validation results + change history extended.

### Preserved (unchanged)

- The 77-Skill Registry (no entry touched); all Skill files; AGENT_RULES.md;
  token/context policies (mirrored, never redefined); the v0.1 routing tests
  (001/002 remain valid — v2 keeps their controlled-failure semantics);
  zero Pine code; no executable Router logic created.

### Design decisions recorded

- AD-07: routing/2 contract with five-value status semantics + mandatory
  trace; controlled-failure behaviors preserved verbatim.
- AD-08: five-layer routing configuration with strict Registry/config/
  Router/Formalization separation (no Skill content in routing.yaml; no
  routing logic in Skills).

### Validation

- All PHASE 3 success criteria verified against the design (deterministic
  classification, Registry-driven selection, dependency closure, redundancy
  control, explicit conflicts/ambiguity, explainability, no bypassing);
  verification pass green (YAML layer structure, spec-id uniqueness,
  registry untouched, no Pine code).


## 1.1.0 - PHASE 4: Router Implementation (2026-09)

### Added

- `skills/agent/router.pl` — the Router decision engine (core Perl 5, zero
  dependencies; runs on the stock Git-for-Windows Perl). Executes the
  routing/2 spec (meta/skill_router.md) end to end against the populated
  77-skill registry:
  - YAML-subset parsers for skills/registry.yaml, config/routing.yaml
    (five layers), and the Import Mode overlap record
    (processing-index.yaml duplicate_candidates)
  - 14-stage pipeline: normalization → classification (EN+FA markers,
    config-driven class order) → domain identification (Registry domains
    only, ≤3 secondary) → matching (exact registered triggers, EN+FA equal
    force; match/partial_match/weak_match/no_match) → minimal set (class
    cores per skill-routing rule 2/3 + trigger-matched topics; hard cap
    max_selected_skills from config) → recursive mandatory-dependency
    closure (cycle/missing/depth → blocked; provenance preserved) →
    redundancy elimination via Import Mode overlap classifications
    (complementary retained, related_but_distinct resolved by capability,
    identical-capability alternatives resolved by tie-break — never
    merged) → conflict/ambiguity/coverage-gap gates → context estimate
    (S/M/L/XL) → decision → mandatory five-section trace → handoff
  - Status gating: only routing_status=ready sets downstream.allowed=true;
    ready exits 0, every non-ready status exits 2 and stops before
    Formalization
  - Output formats: routing/2 YAML (default), JSON, and a v0.1
    compatibility adapter (status routed/blocked, numeric
    estimated_context_size, unresolved_triggers)
- Determinism (spec §16): byte-identical output across processes for the
  same request + registry revision; tie-breaks fully ordered (priority →
  domain-breadth → dep-count → id lexicographic); all caps read from
  config/routing.yaml

### Validation

- Built-in acceptance suite: `perl skills/agent/router.pl --selftest` —
  80/80 assertions green, covering TEST-ROUTING-001..008 (all 8 routing
  test specs, real-registry and synthetic fixtures)
- Cross-process byte-determinism verified (diff clean)
- Gate coherence verified: ready → exit 0; ambiguous/no-match → exit 2;
  non-ready never reaches Formalization
- Trigger-fidelity refinements: request-side normalization matches the
  registered-trigger normalization (hyphens/underscores); analytical class
  recognizes backtesting/validation phrasing; Persian triggers verified
  with equal force (حجم نسبی → volume-analysis)
- Registry (77/77), all 77 Skill files, and raw sources (223,995 bytes)
  byte-identical; no Pine code in any Phase-4 artifact; architecture files
  unmodified
- A PowerShell harness drafted early in the phase was removed as corrupted;
  the engine's built-in selftest is the executable acceptance suite

## 1.2.0 - Router Scenario Fixtures (2026-09)

### Added

- `tests/routing/scenarios/scenarios.yaml` — 10 concrete registry-backed
  routing scenarios validating the Phase-3 design end to end against the
  REAL 77-skill registry via the Phase-4 engine:
  - SCEN-001/002 debug: debugging class core {06, 70} + repaint-audit topic
    joined by exact trigger; code-review (71) excluded (related_but_distinct)
  - SCEN-003/004 MTF: 'request.security' → mtf-engineering with Registry
    domains (data-acquisition, mtf); non-repaint HTF pattern joins the set;
    pine-version-intelligence enforced for code-touching requests
  - SCEN-005 multi-domain: strategy core {01, 06, 09} + momentum-indicators
    ('divergence detection', 'RSI Wilder formula'); related-but-unneeded
    TA/volume skills stay unloaded
  - SCEN-006 complementary pair 44+46 retained (retain_both rule)
  - SCEN-007 related_but_distinct pair 09+51: needed member kept, partner
    excluded with recorded reason, NO merge
  - SCEN-008 META-layer discoverability ('publication checklist tradingview')
  - SCEN-009 negative: Persian debug request with no registered Persian
    trigger → controlled failure; unmatched terms itemized (recorded
    coverage gap — remedy belongs to Import Mode, not routing)
  - SCEN-010 negative: RSI1 > RSI3 ambiguity gate → ambiguous, itemized,
    handoff refused
- `router.pl --scenarios FILE` — scenario runner (parser + per-expectation
  assertions + exit codes); requests embed registered trigger phrases
  verbatim because trigger fidelity is binding (no fuzzy matching)

### Fixed

- Scenario parser: boolean coercion for downstream_allowed;
  redundancy_note_contains kept scalar; ambiguity-check ternary repaired;
  unmatched-terms extractor now preserves Persian tokens so coverage gaps
  in Persian are itemized rather than silently emptied

### Validation

- `perl skills/agent/router.pl --scenarios tests/routing/scenarios/scenarios.yaml`
  → 57/57 assertions green across 10 scenarios
- Selftest unchanged: 80/80 (TEST-ROUTING-001..008)
- Cross-process determinism re-verified (byte-identical)
- Registry 77/77, Skill files 77, raw sources 223,995 bytes — untouched;
  no Pine code in any artifact

## 1.3.0 - PHASE 5: Formalization Layer Implementation (2026-09)

### Added

- `meta/formalization_procedure.md` — narrative authority for the stage:
  inputs (verbatim request + routing/2 handoff), identity chain
  (request_id → approved_routing_id → formalization_id), mechanical
  extraction rules (R1–R9: sources, parameters, conditions, formulas,
  timeframes, MTF, repaint classification, edge cases, no-Pine), ambiguity
  taxonomy (A-TF, A-OPER, A-THR, A-DIV, A-HTF-TF, A-CONF, A-PREC),
  determinism, and gate semantics.
- `formalization/contract_schema.yaml` upgraded to **v1.1** — approval is
  expressed solely by `implementation_allowed` (no separate approval status
  enum value); `supersedes` documented as a revision field excluded from the
  content hash; backward-compatible with v1.0 consumers (all v1.0 fields
  preserved).
- `formalization/formalize.pl` — the Formalization decision engine (core
  Perl 5, zero dependencies; same runtime contract as router.pl):
  - Parses the routing/2 YAML handoff exactly as router.pl emits it;
    non-ready/malformed handoffs → `status: blocked` + `B-ROUTING`/
    `B-ROUTING-INVALID`, exit 2 (only `ready` + `downstream.allowed=true`
    proceeds — status gating inherited, never bypassed)
  - Mechanical extraction only: verbatim clause preservation (conditions,
    formulas, sources, parameter bindings are copied, never improved);
    ambiguities recorded with options, never guessed; required_behavior of
    edge cases never invented; routing decisions copied verbatim
  - Repaint risk classified mechanically per procedure §7 / AGENT_RULES §3.12
    (high: unconfirmed MTF; medium: intrabar; low: confirmed-discipline or
    none detected)
  - Pine constructs in the request → `status: blocked` + `B-PINE`, exit 2
    (Formalization converts requirements, not code)
  - Ambiguity gate: `implementation_allowed: true` ⇔ status completed AND
    blockers empty AND every behavior-affecting ambiguity is
    `resolved_by_user` (`resolved_assumed` NEVER unlocks — via `--resolve
    ID=resolved_by_user|resolved_assumed`)
  - Content-addressed identity (SHA-256, no clock/randomness): byte-identical
    output for identical inputs; `--supersedes` records revisions without
    changing the content-derived id chain
  - `--gate-check --contract FILE` — executable ordering gate for the next
    stage (verifies id shape, status, empty blockers, and the gate flag)
  - UTF-8 end to end (Persian requests round-trip verbatim)
- `tests/formalization/implementation-blocked-by-ambiguity.spec.yaml`
  behavior is now executable (covered by the engine selftest).

### Validation

- `perl formalization/formalize.pl --selftest` — **106/106 assertions green**
  (TEST-FORMAL-001..013): ready→completed with full identity chain; all four
  non-ready routing statuses blocked with verbatim routing reason; malformed
  handoffs blocked; determinism (byte-identical; distinct inputs → distinct
  ids; supersedes id-stable); verbatim preservation with operator/
  state-vs-event and vague-threshold ambiguities recorded; MTF representation
  (chart-context timeframe preference, HTF required_data, undeclared-HTF
  ambiguity); repaint classes (high/medium/low); edge cases + division-guard
  ambiguity; the TEST-FORMALIZATION-001 must_not gate (assumed resolution
  never unlocks; user resolution unlocks; revision id change); schema field
  presence + no-Pine invariant on contract output; --gate-check
  approve/refuse paths; Persian determinism.
- Router regression after the change: selftest 80/80 + scenarios 57/57 —
  routing untouched.
- No-Pine sweep: zero Pine constructs in any pipeline artifact (config/,
  formalization/, feasibility/, implementation/, verification/, templates/,
  tests/); Skill corpus hits are authoritative Import Mode content;
  formalize.pl hits are negative-test fixtures that exercise the B-PINE gate.
- Registry (77/77), Skill files, raw sources, config/, and all prior test
  specs untouched; no Pine code generated.

## 1.4.0 - PHASE 6: Pre-Verification Layer Implementation (2026-09)

### Added

- `meta/pre_verification_procedure.md` — narrative authority for the stage:
  inputs (the formalization contract verbatim), the 14 mechanical checks
  PC01–PC14 with domains (identity chain, formalization approval gate,
  variable completeness, formula math/dependency, boolean-condition
  consistency, assumption validity, ambiguity resolution, edge-case
  coverage, MTF consistency, repaint identification, required-data,
  contradictions, implicit assumptions, traceability/duplicate ids),
  severity taxonomy (blocker | warning), determinism (no clock, no
  randomness, no environment), the canonical verification_id body, and
  gate semantics (only PASS / PASS_WITH_WARNINGS open FEASIBILITY).
- `verification/pre_contract_schema.yaml` upgraded to **v1.1** — additive:
  verification_id derivation now mixes sha256 of the input contract bytes
  into the canonical body ("any contract change ⇒ new id"); gate-check
  reads the emitted result contract; all v1.0 fields preserved
  (backward-compatible with v1.0 consumers).
- `verification/pre_verify.pl` — the Pre-Verification decision engine
  (core Perl 5, zero non-core deps; same runtime contract as
  router.pl/formalize.pl):
  - Parses the formalization contract exactly as formalize.pl emits it;
    malformed/missing input → `INVALID_INPUT` + `B-INPUT`, exit 2
  - Executes PC01–PC14 mechanically — no interpretation, no improvement:
    verbatim clause parsing only (`X is above/below Y`, `crosses
    over/under`), every finding carries refs tracing to contract
    elements
  - Inherited gates stay binding: formalization `status: completed`,
    empty blockers, `implementation_allowed: true` (PC02); every
    behavior-affecting ambiguity must be `resolved_by_user` —
    `resolved_assumed` NEVER unlocks (PC07, TEST-FORMALIZATION-001
    must_not chain)
  - Deterministic verification_id (`pre-` + 12 hex): id body = identity
    chain + contract sha + check verdicts + findings + warnings +
    unresolved items + mirrored ambiguity states
  - `--gate-check --contract FILE` — executable ordering gate for
    FEASIBILITY (id shape, PASS*, empty blockers, feasibility_allowed)
  - UTF-8 end to end (Persian round-trips verbatim); no Pine constructs
    possible in output (T-PRE-019 invariant)

### Validation

- `perl verification/pre_verify.pl --selftest` — **36/36 assertions
  green** (TEST-PRE-001..020): PASS baseline (14 checks, all pass); all
  three B-GATE refusals; unresolved and resolved_assumed ambiguity
  blockers (resolved_by_user unlocks); formula dependency errors;
  missing-variable blockers with subject traced in refs; contradictory
  conditions (B-CONTRA); incomplete required-data (B-DATA-TF, null
  handling); MTF triple inconsistency (chart/data/repaint); repaint
  classification (null, malformed, high→warning); edge-case coverage
  (division w/o E-DIV blocked; zero-guard wording clears); traceability
  (empty source_skills; every finding has refs); id determinism
  (byte-stable; content-sensitive); byte-identical repeated output;
  malformed/missing input → INVALID_INPUT; no-Pine invariant;
  --gate-check approve/refuse paths (PASS, INVALID_INPUT, BLOCKED+HALT).
- Live end-to-end: the Phase-5 formalization contract (pa_formal.yaml) →
  `result: PASS`, exit 0; `--gate-check` approves
  (`pre-22be95b4fbd0`).
- Regressions after the change: `router.pl --selftest` 80/80,
  `router.pl --scenarios` 57/57, `formalize.pl --selftest` 106/106 —
  Router, Formalization, Skills, Registry, config/ untouched.
- No-Pine sweep: zero Pine constructs in the pre-verification result;
  the only `indicator(`/`strategy(` literals in verification/ are the
  negative-test assertions of the selftest itself.
- Registry (77/77), Skill files, raw sources, config/, and all prior
  test specs untouched; no Pine code generated.

## 1.5.0 - PHASE 7: Feasibility Layer Implementation (2026-09)

### Added

- `meta/feasibility_procedure.md` — narrative authority for the stage:
  inputs (the formalization contract + the Phase-6 pre-verification result,
  both verbatim), the 12 mechanical checks FB01–FB12 with domains
  (identity chain, Phase-6 handoff gate, Pine-language capability,
  runtime model, timeframe/MTF, data availability, repaint/execution,
  drawing resources, alerts, market/session, performance, requirement
  classification), the capability knowledge base (seeded ONLY from
  Import-Mode-preserved evidence: confirmed | unavailable |
  requires_verification — never invented), no-silent-fallback policy
  (unavailable capability/data recorded, never substituted), advisory
  limits (object/request budgets stay UNKNOWN_REQUIRES_VERIFICATION —
  never invented as hard limits), severity taxonomy
  (blocker | warning), determinism (no clock, no randomness, no
  environment), the canonical feasibility_id body (sha256, first 12 hex),
  and gate semantics (only FEASIBLE / FEASIBLE_WITH_WARNINGS open
  IMPLEMENTATION_PLANNING).
- `feasibility/contract_schema.yaml` upgraded to **v1.1** — additive:
  the four mandated output sections (blockers, warnings, unknowns,
  partial_items) retained; unsupported_items, capabilities, constraints,
  data_requirements, platform_requirements, requirement_classifications
  documented with the v1.0 affirmation mapping (all v1.0 fields
  preserved; backward-compatible).
- `config/feasibility.yaml` extended — `capability_kb` (19 entries, each
  with evidence basis from Import Mode verification events or preserved
  negative claims; critical unknowns block, advisory warn),
  `data_kinds` vocabulary (obtainable/conditional/requires_verification/
  unavailable), `performance_hints` (conservative advisory thresholds
  only). Existing `feasibility:` check/verdict config untouched.
- `feasibility/feasibility.pl` — the Feasibility decision engine (core
  Perl 5, zero non-core deps; same runtime contract as router.pl/
  formalize.pl/pre_verify.pl):
  - Parses the formalization contract AND the pre-verification result
    exactly as the upstream engines emit them; malformed/missing input →
    `INVALID_INPUT` + `B-INPUT`, exit 2
  - Executes FB01–FB12 mechanically; Phase-6 handoff gate binding
    (non-PASS result, non-empty blockers, feasibility_allowed=false,
    next_stage≠FEASIBILITY, identity mismatch → `BLOCKED` + `B-HANDOFF-*`,
    exit 2 — status gating inherited, never bypassed)
  - Capability scan (KB keyword match over request prose, formulas,
    conditions): unavailable → `B-CAP-UNAVAILABLE` + unsupported_items
    (never substituted); requires_verification load-bearing →
    `B-UNKNOWN-CRITICAL`; prose-only unknown → `W-UNKNOWN-CAP`
  - Data availability against the evidenced vocabulary: unavailable →
    `B-DATA-UNAVAILABLE`; symbol-dependent → `B-DATA-UNKNOWN`; 1T-only
    conditional (bid/ask/spread) enforced mechanically (`B-DATA-TF-1T`)
  - Timeframe/MTF: unparseable TF notation → `B-TF-INVALID`; HTF/LTF
    relation violations warned (never auto-corrected)
  - Repaint classification mirrored VERBATIM (never reclassified);
    high → `W-REPAINT-ACCEPT` (user acceptance surfaced, non-blocking)
  - Runtime model: intrabar/realtime wording → `W-SEMANTIC-DIFF` +
    partial_items with explicit feasible_part / non_feasible_part /
    semantic_difference (never silently narrowed)
  - Advisory resource unknowns (`W-LIMIT-UNKNOWN`, `W-PERF-LOOP`,
    `W-PERF-REQUESTS`) — no invented platform limits
  - Per-requirement classification precedence: UNKNOWN_REQUIRES_
    VERIFICATION > NOT_FEASIBLE > PARTIAL > EXACT (never upgraded)
  - Deterministic feasibility_id; `--gate-check --feasibility FILE`
    executable ordering gate for Implementation Planning; UTF-8 end to
    end (Persian round-trips; Persian prose produces no false capability
    claims); no Pine constructs possible in output (T-FEAS-019)

### Fixed (Phase-7 artifacts only — no immutable phase touched)

- `default_config_path` — separator normalization before dirname (MSYS/
  Git-for-Windows Perl returns '.' for backslash paths; config could not
  be located when invoked by absolute path).
- `parse_pre` — `next_stage` is emitted UNQUOTED by pre_verify.pl; the
  quoted-only regex silently dropped it, making the FB02 stage check
  dead code. Now accepts both forms.
- `parse_config` performance_hints — inline comments polluted values
  (e.g. request_calls_warn became `"4'  # ..."`); quoted values stop at
  the closing quote, unquoted values strip trailing comments.
- Selftest fixture heredoc — interpolated `$blockers`/`$warnings`
  variables carried their own indentation, emitting 4-space keys that
  the blockers-empty check missed (false B-HANDOFF-BLOCKERS).
- Selftest assertions — Perl grep-LIST argument swallowing consumed the
  trailing test names inside `$ok->(...)` calls (fatal HASH-ref error);
  wrapped in parentheses.

### Validation

- `perl feasibility/feasibility.pl --selftest` — **55/55 assertions
  green** (TEST-FEAS-001..022): PASS baseline FEASIBLE (12 checks, all
  pass); PASS_WITH_WARNINGS opens; BLOCKED pre → BLOCKED/HALT; invalid
  handoff variants refused; unavailable capability → NOT_FEASIBLE +
  unsupported recorded; unavailable data (order book) → NOT_FEASIBLE;
  meaningless TF → B-TF-INVALID; repaint mirrored verbatim + acceptance
  surfaced; advisory drawing unknown (no invented limits); every-tick +
  alert → PARTIALLY_FEASIBLE/HALT with explicit portions, C-1 PARTIAL,
  recommendation needs_user_input; EXACT baseline; NOT_FEASIBLE status
  failed; prose-unknown advisory vs load-bearing-unknown blocker
  (F-1 UNKNOWN_REQUIRES_VERIFICATION); findings carry refs; id
  determinism (byte-stable, content-sensitive); byte-identical output;
  malformed/missing input → INVALID_INPUT/HALT; no-Pine invariant;
  --gate-check approve/refuse paths; Persian UTF-8 determinism + no
  invented capabilities; no-silent-fallback (never PARTIAL-with-
  substitution).
- Regressions after the change: `router.pl --selftest` 80/80,
  `formalize.pl --selftest` 106/106, `pre_verify.pl --selftest` 36/36 —
  Router, Formalization, Pre-Verification, Skills, Registry, config/
  untouched.
- No-Pine sweep: zero Pine constructs in the feasibility result; the
  only `indicator(`/`strategy(` literals in feasibility/ are negative-
  test fixtures in the selftest.
- Registry (77/77), Skill files, raw sources, routing.yaml, and all
  prior test specs untouched; no Pine code generated.

---

## 1.6.0 - PHASE 8: Implementation Planning Layer Implementation (2026-09)

### Added

- `meta/implementation_planning_procedure.md` — narrative authority for the stage:
  inputs (the formalization contract + the Phase-6 pre result + the Phase-7
  feasibility result, all verbatim), the 14 mechanical checks IP01–IP14 with
  domains (identity chain, planning handoff gate, requirements inventory,
  architecture, module decomposition, data flow, state architecture, MTF
  architecture, signal architecture, drawing architecture, alert architecture,
  performance plan, dependency graph, verification hooks), the deterministic
  module model (M-DATA / M-CALC / M-STATE / M-SIGNAL / M-DRAW / M-ALERT /
  M-INTEG), the topological (Kahn) implementation order with category ranks,
  no-semantic-drift verbatim-mirroring policy, severity taxonomy
  (blocker | warning), determinism (no clock, no randomness, no environment),
  the canonical planning_id body (sha256, first 12 hex), and gate semantics
  (only READY / READY_WITH_WARNINGS open IMPLEMENTATION).
- `implementation/contract_schema.yaml` upgraded to **v1.1** — additive:
  the planning contract block documented (identity chain completion, planning
  status enum, checks/findings/warnings/decisions, architecture sections,
  modules, dependency_graph, implementation_order, verification_hooks,
  implementation_allowed, next_stage); all v1.0 fields preserved
  (backward-compatible with v1.0 consumers).
- `implementation/implementation_plan.pl` — the Implementation Planning decision
  engine (core Perl 5, zero non-core deps; same runtime contract as
  router.pl/formalize.pl/pre_verify.pl/feasibility.pl):
  - Parses the formalization contract, the pre result, and the feasibility
    result exactly as the upstream engines emit them; malformed/missing input
    → `INVALID_INPUT` + `B-INPUT`, exit 2
  - Executes IP01–IP14 mechanically — no interpretation, no improvement:
    verbatim clause parsing only, every finding carries refs tracing to
    upstream contract elements
  - Hard handoff gate (IP02): feasibility_status must be FEASIBLE or
    FEASIBLE_WITH_WARNINGS; **PARTIALLY_FEASIBLE is never reinterpreted as
    feasible**; blockers non-empty, planning_allowed false, wrong next_stage,
    or a broken inherited Phase-6 gate all → `BLOCKED` + `B-HANDOFF-*`, exit 2
  - Deterministic module derivation from the contract (none invented); the
    dependency graph is checked for cycles (`B-DEP-CYCLE`) and missing deps
    (`B-DEP-MISSING`); implementation order is the deterministic topological
    (Kahn) order with fixed category ranks
  - Verbatim mirroring: conditions, formulas, timeframes, repaint
    classification, and feasibility constraints are copied, never decided;
    unresolved implementation choices become `decisions[]`
    (NEEDS_USER_INPUT) with warnings
  - Deterministic `planning_id` (`plan-` + 12 hex of sha256 over the canonical
    body); byte-identical output across processes; `--gate-check --plan FILE`
    executable ordering gate for IMPLEMENTATION; UTF-8 end to end (Persian
    round-trips verbatim); no Pine constructs possible in output (T-PLAN-025)

### Validation

- `perl implementation/implementation_plan.pl --selftest` — **46/46 assertions
  green** (TEST-PLAN-001..027): valid FEASIBLE → READY; FEASIBLE_WITH_WARNINGS
  → READY_WITH_WARNINGS with carried upstream warning; PARTIALLY_FEASIBLE /
  NOT_FEASIBLE / BLOCKED feasibility → BLOCKED with B-HANDOFF-STATUS; feasibility
  blockers → B-HANDOFF-BLOCKERS; planning_allowed false → B-HANDOFF-GATE;
  next_stage wrong → B-HANDOFF-STAGE; inherited Phase-6 gate re-checked
  (B-HANDOFF-PRE-STATUS / B-HANDOFF-PRE-GATE); chain mismatches →
  B-HANDOFF-CHAIN; malformed/missing input → INVALID_INPUT; module
  decomposition (base 3 modules, full 7); requirements coverage (no B-COVERAGE);
  deterministic topological implementation order; verbatim signal conditions;
  MTF architecture iff data/mtf with chart TF mirrored verbatim; drawing budget
  stays UNKNOWN_REQUIRES_VERIFICATION (no invented limits); alert timing stays
  user alert-configuration; unbounded-loop wording → W-LOOP-BOUND warning +
  NEEDS_USER_INPUT decision (never a blocker); mechanical data count + carried
  W-PERF warnings; deterministic content-sensitive planning_id; byte-identical
  repeated output; NO-PINE output invariant; downstream --gate-check approve /
  refuse paths; state architecture with crossover refs and documented
  recalc-and-rollback semantics.
- Live end-to-end: authentic fixtures (contract → pre → feasibility, all
  produced by the real upstream engines) feed the planning engine →
  `planning_status: READY`, `implementation_allowed: true`,
  `next_stage: IMPLEMENTATION`, `--gate-check` approves (exit 0).
- Downstream gate verified: READY plan → exit 0; BLOCKED plan → exit 2.
- Cross-process byte-identical determinism verified (3 fresh processes).
- Dependency graph cycle/missing detection verified with synthetic injected
  graphs (cycle A→B→C→A, self-loop, missing dep B→NONEXISTENT); the real
  mechanically-derived graph is acyclic and fully resolved.
- Persian UTF-8 determinism verified: byte-identical output, valid planning_id,
  no false capability claims.
- No-Pine sweep: zero Pine constructs in any Phase-8 artifact; the only
  `indicator(`/`strategy(`/`library(` literals in implementation/ are the
  negative-test assertion strings of the selftest itself (T-PLAN-025),
  matching the precedent in formalize.pl / pre_verify.pl / feasibility.pl.
- Regressions after the change: `router.pl --selftest` 80/80,
  `router.pl --scenarios` 57/57, `formalize.pl --selftest` 106/106,
  `pre_verify.pl --selftest` 36/36, `feasibility.pl --selftest` 55/55 —
  Router, Formalization, Pre-Verification, Feasibility, Skills (77/77),
  Registry, raw Skill sources, routing.yaml, config/ untouched; no Pine code
  in any Phase-8 artifact.

### Fixed (Phase-8 artifacts only — no immutable phase touched)

- None required; the engine was already complete and validated on arrival.
  (Debug/scratch files `_dbg.pl`, `_t_*.yaml` were pre-existing fixtures used
  by the selftest and left untouched.)

### Preserved (unchanged)

- The 77-Skill Registry, all 77 Skill files, all 77 raw sources, all
  architectural contracts, configs, templates, and all prior test specs
  untouched; no Pine code generated; no Skills invented, merged, or
  activated beyond documented rules.

## 1.7.0 - PHASE 9: Implementation Layer Complete (2026-09-10)

### Added

- `implementation/implement.pl` — the Phase 9 Implementation decision engine
  (core Perl 5, zero non-core deps; same runtime contract as router.pl /
  formalize.pl / pre_verify.pl / feasibility.pl / implementation_plan.pl):
  - Consumes the authoritative Phase-8 plan verbatim
    (`phase9_authoritative_plan.yaml`, produced by `_stage01.pl` from the
    authentic upstream engine fixtures); malformed/missing input →
    `INVALID_INPUT` + `B-INPUT`, exit 2
  - Executes the Stage 02–10 gates mechanically — no interpretation:
    input/gate validation (S02: planning_status READY*, implementation_allowed,
    empty plan blockers, next_stage IMPLEMENTATION, identity-chain shape),
    plan validation (S03: module references, dependency-cycle DFS,
    implementation_order topological coherence), code architecture
    realization + module implementation (S04/S05: Pine v6 source generated
    strictly per plan modules in implementation_order — no behavior invented),
    integration (S06), compile validation (S07: honest
    UNKNOWN_REQUIRES_EXTERNAL_VALIDATION — no TradingView compiler exists in
    this environment; COMPILE_PASS is never claimed; AGENT_RULES #21),
    static checks (S08: //@version=6 header, indicator() declaration,
    duplicate declarations, placeholder/debug artifacts), traceability
    (S09: module source_requirements, signal refs, state refs, no orphan
    modules), determinism (S10: timestamp/random/env-path scans, identity
    chain completeness, canonical implementation_id)
  - Deterministic `implementation_id` (`impl-` + 12 hex of sha256 over the
    canonical body: identity chain + source sha + implementation order);
    content-addressed — any generated-source change ⇒ new id
  - Result contract (schema v1.1, same emit format as prior stages); exit 0
    only on COMPLETED; result contracts stay Pine-free (metadata only)

### Validation

- `perl implementation/implement.pl --selftest` — **10/10 assertions green**
  (TEST-IMPL-001..008): COMPLETED status; gates open; well-formed 7-link
  identity chain; 9 checks, none failed; zero blockers; honest compile
  status; no-Pine result invariant; stable implementation_id;
  byte-identical repeated output.
- Live end-to-end: the authoritative Phase-8 plan (READY,
  implementation_allowed true) → `implementation_status: COMPLETED`, zero
  findings / warnings / blockers, `next_stage: POST_VERIFICATION`, exit 0.
- Generated Pine (`phase9_pine.pine`): `//@version=6` first line;
  indicator() declaration; modules M-STATE → M-SIGNAL → M-INTEG emitted in
  plan order; contract condition C-1 (`close crosses over 30`) and edge
  cases E-NA / E-FIRST honored verbatim; executable content verified
  identical to the pre-recovery preserved artifact (only faithful metadata
  comments were added by the parser fix below).
- Determinism: byte-identical result + Pine across 3 fresh processes;
  `source_sha256` content-addresses the Pine bytes;
  `implementation_id: impl-31ffd64d8c54`.
- Regressions after the change: `router.pl --selftest` 80/80,
  `router.pl --scenarios tests/routing/scenarios/scenarios.yaml` 57/57,
  `formalize.pl --selftest` 106/106, `pre_verify.pl --selftest` 36/36,
  `feasibility.pl --selftest` 55/55, `implementation_plan.pl --selftest`
  46/46 — Router, Formalization, Pre-Verification, Feasibility,
  Implementation Planning, Skills (77/77), Registry, raw Skill sources,
  routing.yaml, config/ untouched.

### Fixed (Phase-9 artifacts only — no immutable phase touched)

- `implement.pl` static-check regex: `@version` interpolated as an array
  inside `m{^//@version=6}` (fatal compile error under use strict;
  introduced by the programmatic writer `_gen1.pl`, which consumes the
  `\@` escape while emitting the engine). Restored the `_fixer3.pl` repair
  that a later engine rewrite clobbered. Consequence: the on-disk result
  contract was stale replica output (Python `_regen_result.py`) carrying a
  self-contradicting `S-NO-VERSION` blocker — its own `source_sha256` matched
  a source whose first line is `//@version=6` (false positive diagnosed in
  `_debug_check.py`) plus `check_id: 'null'` shapes the Perl engine never
  emits. Replaced by authoritative engine output.
- `implement.pl` plan parser: the inline-value alternation could not match
  bracketed lists (`['C-1']`, `[]`), silently truncating every module entry
  at its first list field — `source_requirements` / `dependencies` / `refs`
  parsed empty, producing five false traceability warnings (T-NO-SRC ×3,
  T-STATE-REF ×2 — contradicting the plan bytes, which declare them) and
  vacuous S03 dependency-cycle checks. Added an alternation branch for
  bracketed list values mapping to real arrays. No semantic, threshold,
  formula, condition, or module-boundary change; the generated executable
  Pine content is byte-identical (metadata comments only).

### Preserved (unchanged)

- All upstream contracts and engines (Phases 1–8), the 77-Skill Registry,
  all Skill files and raw sources, configs, templates, prior test specs,
  and the authoritative Phase-8 plan (`phase9_authoritative_plan.yaml`,
  byte-untouched) preserved. Upstream semantics, module boundaries, signal
  polarity/timing, MTF/repaint posture, and plan-derived behavior unchanged:
  the implementation mirrors the plan verbatim.
- Forensic scratch artifacts (`_dbg.pl`, `_fixer*.pl`, `_gen1.pl`,
  `_regen_result.py`, `_stage01.pl`, `_debug_check.py`, `_test_write.pl`,
  `_p8.pl`, `_t_*.yaml`) preserved as recovery evidence (no destructive
  cleanup; removal intentionally out of scope).
