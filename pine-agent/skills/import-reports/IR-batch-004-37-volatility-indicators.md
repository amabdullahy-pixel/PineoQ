# Import Report — IR-batch-004-37

```yaml
report_id: IR-batch-004-37
import_batch: batch-004
original_filename: 37-volatility-indicators.md
source_path: skills/incoming/37-volatility-indicators.md
proposed_skill_id: volatility-indicators
final_skill_id: volatility-indicators
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [technical-analysis, volatility]
extracted_triggers:
  english: [ATR true range, Bollinger Bands bbw percentB, Keltner Channels squeeze,
    Donchian manual, historical volatility annualize, EWMA realized vol]
  persian: [اندیکاتورهای نوسان, باند بولینگر, کانال دونچین, نوسان تاریخی]
dependencies:
  mandatory: []
  optional: [technical-analysis-core, time-series-analysis, trade-management,
    falsification-and-counterexamples]
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
  - ta.tr/ta.atr (Wilder), ta.bb/ta.bbw, ta.kc/ta.kcw signatures verified by
    source against reference/support articles; negative claims preserved —
    NO ta.donchian, NO built-in HV (manual patterns registered).
  - Annualization constants (365 crypto / 252 equities) consistent with
    financial-mathematics (batch-003) and time-series-analysis EWMA (batch-003).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: zero-width bbw/kcw division guards recorded.
duplicate_findings: none.
overlap_findings:
  - time-series-analysis (batch-003): EWMA/clustering consumed;
    relationship: complementary. recommended_action: dependency_relationship,
    resolved: true (batch-003 pending pointer resolved)
  - price-action-patterns (same batch): Donchian breakout [1] discipline
    mutually referenced; relationship: complementary.
    recommended_action: keep_separate
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-004)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
