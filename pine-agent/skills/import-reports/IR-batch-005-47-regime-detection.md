# Import Report — IR-batch-005-47

```yaml
report_id: IR-batch-005-47
import_batch: batch-005
original_filename: 47-regime-detection.md
source_path: skills/incoming/47-regime-detection.md
proposed_skill_id: regime-detection
final_skill_id: regime-detection
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [quant-methods, market-state]
extracted_triggers:
  english: [market regime classification, trending vs ranging,
    volatility regime percentile, Hurst variance ratio regime,
    transitional state, ADX threshold regime]
  persian: [تشخیص رژیم بازار, رونددار یا رنج, رژیم نوسان]
dependencies:
  mandatory: []
  optional: [market-structure, volatility-indicators, stochastic-processes,
    falsification-and-counterexamples]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
  valid_triggers: pass
  documented_inputs: pass
  documented_outputs: pass
  rules_documented: pass
  assumptions_documented: pass
  constraints_documented: pass
  dependencies_documented: pass
  ambiguities_recorded: pass
  missing_information_recorded: pass
  template_structure_followed: pass
  source_preserved: pass
pine_v6_findings:
  - ta.dmi(14,14) for ADX, ta.percentrank(ta.atr(14), 252),
    50/200 SMA relation — all consistent with volatility-indicators and
    trend-indicators (batch-004) verified inventories.
  - Variance-ratio / Hurst approximations are manual computations (no
    built-ins) — consistent with the established negative-claim convention.
repainting_findings: regime labels on confirmed (close-based) data only; unconfirmed HTF regime flags forbidden (rule 6).
mtf_findings: regime axes may combine HTF context — must pass the verified non-repaint acquisition pattern.
runtime_performance_findings: rolling percentile windows (252-bar) bounded; VR computation O(window) per bar — acceptable, budgeted.
numerical_stability_findings: variance ratios require nonzero-variance guards; low R² OU-fit flagged as transitional rather than extrapolated.
duplicate_findings: none.
overlap_findings:
  - market-structure (batch-004): resolves that skill's parked candidate
    (40↔47) and its pending optional-dependency pointer. relationship:
    complementary (structure = direction axis; regime = composite state).
    recommended_action: dependency_relationship
  - signal-engineering / signal-fusion (same batch): regime state is the
    Layer-1 gate both consume. relationship: complementary.
    recommended_action: dependency_relationship
  - technical-analysis-core / trend-indicators / momentum-indicators /
    volatility-indicators / position-sizing / trade-management
    (batches 003–004): all listed regime-detection as a pending optional
    dependency — now resolvable (registry pointers resolved this batch).
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - ADX >25/<20 style thresholds are practice heuristics (source-declared)
    — mandatory percentile normalization + per-symbol falsification
    registered; not presented as universal constants.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-005)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
