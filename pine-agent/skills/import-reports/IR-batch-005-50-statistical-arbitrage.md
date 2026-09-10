# Import Report — IR-batch-005-50

```yaml
report_id: IR-batch-005-50
import_batch: batch-005
original_filename: 50-statistical-arbitrage.md
source_path: skills/incoming/50-statistical-arbitrage.md
proposed_skill_id: statistical-arbitrage
final_skill_id: statistical-arbitrage
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [quant-methods, pairs-trading]
extracted_triggers:
  english: [pair trading, cointegration vs correlation, spread z-score,
    Engle-Granger, hedge ratio beta, half-life spread,
    correlation breakdown guard]
  persian: [آربیتراژ آماری, معامله جفتی, هم‌انباشتگی, نیم‌عمر اسپرد]
dependencies:
  mandatory: []
  optional: [regression-correlation, stochastic-processes,
    multi-symbol-engineering, data-integrity]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: RESEARCH (pass — method skill; execution mapped via multi-symbol-engineering)
  justified_primary_layer_detail: the skill's function is the relative-value methodology; its Pine mapping routes through the multi-symbol acquisition skill, which owns request.* execution.
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
  - "Negative claim (verify-before-use): NO built-in cointegration test
    (no formal Engle-Granger / ADF in Pine) — spread stationarity checked
    via rolling OLS residual behavior + half-life decay, consistent with the
    statistical-testing negative claim (batch-003)."
  - hedge ratio via manual rolling OLS (regression-correlation patterns);
    half-life from AR(1) coefficient — manual, per stochastic-processes.
  - Two-leg data acquisition routed through multi-symbol-engineering
    (batch-002) request.* budget patterns.
repainting_findings: spread/z-score computed on confirmed bars; synchronized-bar handling per data-integrity (request MTF alignment discipline).
mtf_findings: two-leg acquisition requires careful request.* budgeting (multi-symbol-engineering) and session-alignment guards (data-integrity).
runtime_performance_findings: rolling OLS per bar is O(window) — budgeted; correlation-breakdown guard bounds position risk before compute limits matter.
numerical_stability_findings: div-0 guards on spread standard deviation; near-singular hedge estimation guarded (rolling window floor).
duplicate_findings: none.
overlap_findings:
  - regression-correlation (batch-003): resolves that skill's pending pointer (line 570 registry reference). relationship: complementary. recommended_action: dependency_relationship
  - stochastic-processes (batch-003): resolves its pending pointer (line 636 registry reference — half-life/OU). relationship: complementary. recommended_action: dependency_relationship
  - time-series-analysis (batch-003): stationarity concepts handoff. relationship: complementary. recommended_action: keep_separate
provenance_note:
  - Cointegration/Engle-Granger/half-life methodology is standard econometrics
    (source-declared); Pine implementations manual, no invented built-ins.
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
