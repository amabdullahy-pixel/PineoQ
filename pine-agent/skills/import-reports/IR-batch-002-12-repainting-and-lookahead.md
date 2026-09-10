# Import Report — IR-batch-002-12

```yaml
report_id: IR-batch-002-12
import_batch: batch-002
original_filename: 12-repainting-and-lookahead.md
source_path: skills/incoming/12-repainting-and-lookahead.md
proposed_skill_id: repainting-and-lookahead
final_skill_id: repainting-and-lookahead
final_status: normalized
activation_status: eligible
primary_layer: VERIFICATION
domains: [repainting, data-integrity]
extracted_triggers:
  english: [repainting, lookahead, future leak, barmerge.lookahead_on,
    non-repainting HTF pattern, repaint audit, historical differs from realtime]
  persian: [ریپینت, نشت اطلاعات آینده, lookahead, ممیزی ریپینت,
    ناسازگاری تاریخچه با لحظه‌ای]
dependencies:
  mandatory: []
  optional: [tradingview-execution-model, mtf-engineering, strategy-engine,
    data-integrity]
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
  - barmerge lookahead semantics, the official [1]+lookahead_on HTF pattern,
    barstate.isconfirmed-in-security exclusion — consistent with the
    execution-model skill and official repainting docs cited by the source.
  - ">95% of indicators repaint" is a TradingView-stated statistic; preserved
    as a qualitative doc claim, recorded as an ambiguity (not a measurement).
repainting_findings:
  - This IS the repaint-taxonomy skill — full cause taxonomy, lookahead
    mechanics, official non-repainting pattern, and the audit checklist now
    registered; batch-001 skills' deferred repaint classifications resolve here.
mtf_findings: lookahead mapping (period-end vs period-start visibility) documented; depth deferred to mtf-engineering (same batch).
runtime_performance_findings: calc_on_every_tick / varip backtest-critical warnings recorded.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - tradingview-execution-model (batch-001): execution semantics vs repaint
    taxonomy; source-level cross-reference now formalized as optional
    dependency. relationship: complementary. recommended_action: keep_separate
  - mtf-engineering (batch-002): acquisition patterns vs audit discipline;
    relationship: complementary. recommended_action: keep_separate
ambiguities:
  - The >95% figure treated as qualitative documentation, not precise data.
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-002)
recommended_action: no_action
next_action: eligible for Router discovery; resolves the batch-001
  pending-dependency pointer from tradingview-execution-model.
```
