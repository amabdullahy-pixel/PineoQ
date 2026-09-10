# Import Report — IR-batch-007-66

```yaml
report_id: IR-batch-007-66
import_batch: batch-007
original_filename: 66-falsification-and-counterexamples.md
source_path: skills/incoming/66-falsification-and-counterexamples.md
proposed_skill_id: falsification-and-counterexamples
final_skill_id: falsification-and-counterexamples
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [research-methods, validation]
extracted_triggers:
  english: [counterexample hunt, kill criteria refuted,
    random signal control, simplification test, cost stress test,
    red team strategy]
  persian: [ابطال فرضیه, مثال نقض, تست تخریب استراتژی]
dependencies:
  mandatory: []
  optional: [liquidity-and-price-structure, data-integrity,
    monte-carlo-and-resampling, probability, regime-detection,
    asset-class-specialization, optimization-and-calibration,
    overfitting-and-robustness, backtesting-science, statistical-testing,
    pine-debugging-and-testing, repainting-and-lookahead,
    pine-performance-engineering]
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
  - No platform-API claims; micro-red-team probes (degenerate inputs,
    repaint-probe, budget-probe) route to verified skills
    (pine-debugging-and-testing, repainting-and-lookahead,
    pine-performance-engineering — all registered this batch).
repainting_findings: repaint-probe (reload chart, compare signals before/after) registered as a mandatory battery item via repainting-and-lookahead.
mtf_findings: none in scope.
runtime_performance_findings: budget-probe (longest history × heaviest loop) registered via pine-performance-engineering.
numerical_stability_findings: degenerate-input feeding (0-length arrays, constant series, extremes) registered via pine-debugging-and-testing.
duplicate_findings: none.
overlap_findings:
  - overfitting-and-robustness (batch-006): robustness battery (keep it
    working) vs falsification battery (try to break it) — related_but_
    distinct, complementary stages. recommended_action: keep_separate
  - research-methodology (same batch): step-6 executor of the loop.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Battery formalized by the source (method provenance); random-signal
    control made mandatory by design.
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
