# Import Report — IR-batch-001-09

```yaml
report_id: IR-batch-001-09
import_batch: batch-001
original_filename: 09-strategy-engine.md
source_path: skills/incoming/09-strategy-engine.md
proposed_skill_id: strategy-engine
final_skill_id: strategy-engine
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [strategies, backtesting]
extracted_triggers:
  english: [strategy.entry, strategy.exit, strategy.order, pyramiding, OCA group,
    process_orders_on_close, calc_on_every_tick, broker emulator, bar magnifier,
    position sizing, commission slippage margin, strategy.position_avg_price,
    trade introspection]
  persian: [موتور استراتژی, ورود و خروج سفارش, پرامیدینگ, سایز پوزیشن,
    کارمزد و اسلیپیج, شبیه‌ساز بروکر]
dependencies:
  mandatory: []
  optional: [tradingview-execution-model, indicator-strategy-library-architecture,
    backtesting-science, trade-management, pine-v6]
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
  - Order/exit/OCA semantics, broker-emulator OHLC path assumption, gap fills at
    open, use_bar_magnifier plan gating, v6 order-trimming behavior — consistent
    with official strategies docs as cited by source.
  - Import-time verification: July 2026 release notes added
    calc_on_every_history_tick (Premium+) and renamed strategy UI items;
    declaration parameters cited by this skill remain valid (backward
    compatibility per release notes). Recorded as missing information, not
    rewritten into rules.
repainting_findings: calc_on_every_tick / process_orders_on_close realism caveats noted — feeds repainting-and-lookahead and backtesting-science classification.
mtf_findings: none directly in scope.
runtime_performance_findings: 9,000-order trim behavior (v6) recorded; no other limits.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - tradingview-execution-model (imported): fill timing summary vs depth;
    relationship: complementary (source itself cross-references skill 09).
    recommended_action: keep_separate
  - backtesting-science / trade-management (pending imports): evaluation
    methodology and exit design vs order mechanics; relationship: expected
    related_but_distinct (confirm on their import). recommended_action: no_action
ambiguities: []
missing_information:
  - July 2026 calc_on_every_history_tick parameter and Properties/report UI
    renames absent from source — documented in the normalized Skill's Missing
    Information section.
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Source cross-reference ("see skill 09 for depth" from skill 07) handled on
    that skill's side as an optional dependency; no content duplicated here.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-001)
recommended_action: keep_separate
next_action: eligible for Router discovery in future Router phase.
```
