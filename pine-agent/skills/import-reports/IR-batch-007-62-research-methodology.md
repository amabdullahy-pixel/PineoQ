# Import Report — IR-batch-007-62

```yaml
report_id: IR-batch-007-62
import_batch: batch-007
original_filename: 62-research-methodology.md
source_path: skills/incoming/62-research-methodology.md
proposed_skill_id: research-methodology
final_skill_id: research-methodology
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [research-methods, validation]
extracted_triggers:
  english: [scientific method trading, preregistration hypothesis,
    reproducibility seed pinning, HARKing metric shopping,
    verdict PASS FAIL INCONCLUSIVE, research loop]
  persian: [روش‌شناسی پژوهش, فرضیه آزمون‌پذیر, تکرارپذیری]
dependencies:
  mandatory: []
  optional: [walk-forward-and-validation, overfitting-and-robustness,
    falsification-and-counterexamples, monte-carlo-and-resampling,
    statistical-testing, pine-project-documentation]
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
  - Nondeterminism sources named (unseeded random, timenow, varip) — all
    consistent with verified language-core (var/varip semantics) and
    monte-carlo-and-resampling (math.random seed) inventories.
  - Bar-Magnifier plan-dependence cross-reference consistent with
    backtesting-science (batch-006, re-verified limits).
repainting_findings: none in scope (validation discipline; one-OOS-peek rule is leakage prevention).
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - walk-forward-and-validation / overfitting-and-robustness
    (batches 006): the loop's steps 5–6 reference them directly —
    pipeline stages, not duplicates. relationship: complementary.
    recommended_action: dependency_relationship
  - falsification-and-counterexamples (same batch): step 6 executor.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Preregistration/HARKing recorded as open-science methodology adapted
    to trading (source-declared provenance).
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
