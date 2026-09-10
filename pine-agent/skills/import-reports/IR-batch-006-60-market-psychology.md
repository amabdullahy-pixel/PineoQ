# Import Report — IR-batch-006-60

```yaml
report_id: IR-batch-006-60
import_batch: batch-006
original_filename: 60-market-psychology.md
source_path: skills/incoming/60-market-psychology.md
proposed_skill_id: market-psychology
final_skill_id: market-psychology
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [behavioral, market-context]
extracted_triggers:
  english: [fear greed proxy VIX, put call ratio PCR,
    capitulation bar, FOMO detection, crowd state euphoria panic,
    funding rate extremes]
  persian: [روانشناسی بازار, ترس و طمع, کندل کاپیتولیشن]
dependencies:
  mandatory: []
  optional: [behavioral-finance, intermarket-analysis, regime-detection,
    signal-fusion, volume-analysis, market-structure,
    multi-symbol-engineering]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
  valid_triggers: pass
  documented_inputs: pass
  documented_outputs: pass
  rules_documented: pass
  constraints_documented: pass
  assumptions_documented: pass
  dependencies_documented: pass
  ambiguities_recorded: pass
  missing_information_recorded: pass
  template_structure_followed: pass
  source_preserved: pass
pine_v6_findings:
  - VIX/VIX3M contango/backwardation semantics — source-verified vs
    reference; CBOE:VIX / CBOE:VIX3M / CBOE:PC symbol IDs preserved as
    verify-per-plan (not independently verifiable across account plans).
  - ta.tr(true) / ta.atr / RVOL patterns consistent with
    volatility-indicators and volume-analysis (batch-004).
  - "Negative claim (verify-before-use): NO native CNN Fear & Greed symbol —
    community approximation only, must be labeled approximate."
repainting_findings: crowd-state proxies computed on confirmed data; 1D security legs use the non-repaint pattern (mtf-engineering).
mtf_findings: proxy legs consume the request budget (multi-symbol-engineering).
runtime_performance_findings: none beyond request budgets.
numerical_stability_findings: capitulation proxy thresholds ATR-normalized (per-source).
duplicate_findings: none.
overlap_findings:
  - behavioral-finance (same batch): bias map vs proxy implementation —
    related_but_distinct. recommended_action: keep_separate
  - intermarket-analysis (same batch): panic state (VIX pct >90 +
    correlation→1) shared. relationship: complementary.
    recommended_action: dependency_relationship
  - regime-detection (batch-005): regime gate before contrarian action.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Crowd-state ladder thresholds = calibrate-per-asset defaults
    (source-declared); Fear&Greed composites labeled approximate by design.
ambiguities:
  - Funding-rate direct-series availability varies by plan — proxy guidance
    preserved (source-declared).
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
