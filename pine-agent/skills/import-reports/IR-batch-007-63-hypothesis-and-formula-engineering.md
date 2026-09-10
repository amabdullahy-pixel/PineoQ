# Import Report — IR-batch-007-63

```yaml
report_id: IR-batch-007-63
import_batch: batch-007
original_filename: 63-hypothesis-and-formula-engineering.md
source_path: skills/incoming/63-hypothesis-and-formula-engineering.md
proposed_skill_id: hypothesis-and-formula-engineering
final_skill_id: hypothesis-and-formula-engineering
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [research-methods, signal-design]
extracted_triggers:
  english: [falsifiable trading hypothesis, formula derivation,
    alternative formulations artifact guard, assumption failure mapping,
    mechanism class, dimension check ATR scaled]
  persian: [مهندسی فرضیه, فرمول‌سازی, فرمول‌های جایگزین]
dependencies:
  mandatory: []
  optional: [statistics-core, adaptive-systems, time-series-analysis,
    regime-detection, probability, backtesting-science,
    market-microstructure]
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
  - No platform-API claims; formula/dimension discipline maps to verified
    quant inventories (statistics-core normalization, adaptive-systems
    threshold families, time-series-analysis stationarity).
repainting_findings: none in scope (preregistration discipline prevents post-hoc threshold fitting).
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: dimension check (unitless/ATR-scaled terms) is a stability discipline — registered.
duplicate_findings: none.
overlap_findings:
  - market-microstructure (batch-006): resolves the batch-006 parked
    candidate {57↔63} — cost/capacity assumptions consumed by the
    assumption-failure table. relationship: complementary.
    recommended_action: dependency_relationship
  - hypothesis template output feeds research-methodology preregistration.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Template + anti-artifact (≥3 formulations) rule formalized by the
    source (method provenance); example hypothesis numbers are illustrative
    defaults, falsify per system.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-007)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
