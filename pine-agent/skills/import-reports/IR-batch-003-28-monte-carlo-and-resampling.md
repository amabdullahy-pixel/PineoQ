# Import Report — IR-batch-003-28

```yaml
report_id: IR-batch-003-28
import_batch: batch-003
original_filename: 28-monte-carlo-and-resampling.md
source_path: skills/incoming/28-monte-carlo-and-resampling.md
proposed_skill_id: monte-carlo-and-resampling
final_skill_id: monte-carlo-and-resampling
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [statistics, simulation]
extracted_triggers:
  english: [bootstrap, Monte Carlo equity, drawdown distribution,
    probability of ruin, block bootstrap, math.random seed reproducibility,
    scenario analysis]
  persian: [مونت کارلو, بوت‌استرپ, توزیع افت سرمایه, احتمال نابودی]
dependencies:
  mandatory: []
  optional: [strategy-engine, overfitting-and-robustness, stochastic-processes,
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
  - math.random seed reproducibility + strategy.closedtrades.* access verified
    against reference/FAQ by the source; ~9,000-trade cap consistent with
    strategy-engine's v6 order-trimming facts (batch-001).
  - last-bar-only simulation (barstate.islast) consistent with
    drawing-and-visualization dashboard pattern discipline (batch-001).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: hard budget rules registered (500ms/bar, 20s/40s, iteration caps, array caps, summary-stats-only).
numerical_stability_findings: autocorrelation/serial-correlation handling via block bootstrap recorded.
duplicate_findings: none.
overlap_findings:
  - strategy-engine (batch-001): trade introspection consumed;
    relationship: complementary. recommended_action: dependency_relationship
  - backtesting-science (pending import, 51): evaluation methodology expected
    there; relationship: expected related_but_distinct.
    recommended_action: no_action
ambiguities: []
missing_information:
  - Deep Backtesting trade-retention specifics (plan-dependent — re-verify at
    use time).
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-003)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
