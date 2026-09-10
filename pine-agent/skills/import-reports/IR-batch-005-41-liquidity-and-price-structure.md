# Import Report — IR-batch-005-41

```yaml
report_id: IR-batch-005-41
import_batch: batch-005
original_filename: 41-liquidity-and-price-structure.md
source_path: skills/incoming/41-liquidity-and-price-structure.md
proposed_skill_id: liquidity-and-price-structure
final_skill_id: liquidity-and-price-structure
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [market-structure, liquidity]
extracted_triggers:
  english: [liquidity pools sweeps, stop run, fair value gap FVG, order block OB,
    displacement, consequent encroachment, inverse FVG, equal highs lows]
  persian: [نقدینگی و استاپ‌هانت, گپ ارزش منصفانه, بلوک سفارش, جابجایی قیمتی]
dependencies:
  mandatory: []
  optional: [market-structure, price-action-patterns, signal-fusion,
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
  - Detection idioms ([1]-excluded extremes, UDT zone arrays, barstate gating)
    consistent with batch-001/002 verified facts (language core, execution
    model, repainting).
repainting_findings: live-bar zone/sweep detection classified as a repaint source; confirmed-bar gating registered as mandatory mitigation (rule 5).
mtf_findings: none in scope.
runtime_performance_findings: unbounded zone arrays flagged; caps + mitigation state machine required (rule 4).
numerical_stability_findings: ATR-unit tolerances (e.g., 0.1–0.25·ATR) instead of absolute ticks.
duplicate_findings: none.
overlap_findings:
  - price-action-patterns (batch-004): resolves the batch-004 parked candidate;
    pivot/zone mechanics vs liquidity logic. relationship: related_but_distinct
    (complementary). recommended_action: keep_separate
  - market-structure (batch-004): BOS/CHoCH context consumed here.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Source self-declares confidence=medium: SMC concepts (FVG, OB, sweeps,
    CE) lack a single canonical specification and are community-standard
    provenance, NOT official TradingView documentation. Handled by mandatory
    parameterize-and-falsify discipline (declared school variants), not by
    silently picking one school.
ambiguities:
  - SMC definitions lack canonical specification (source-declared, preserved
    as a designed ambiguity handled by parameterization).
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
