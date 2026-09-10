# Import Report — IR-batch-006-58

```yaml
report_id: IR-batch-006-58
import_batch: batch-006
original_filename: 58-asset-class-specialization.md
source_path: skills/incoming/58-asset-class-specialization.md
proposed_skill_id: asset-class-specialization
final_skill_id: asset-class-specialization
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [market-context, asset-classes]
extracted_triggers:
  english: [crypto forex equities futures differences,
    syminfo.type class detection, session handling per class,
    porting strategy across markets, index not tradable,
    tick volume forex]
  persian: [تفاوت کلاس‌های دارایی, پرت کردن استراتژی بین بازارها,
    سشن‌های هر کلاس]
dependencies:
  mandatory: []
  optional: [market-microstructure, data-integrity,
    multi-symbol-engineering, position-sizing, volume-analysis,
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
  - syminfo.type class list {stock, futures, index, forex, crypto, fund,
    dr, cfd, bond, warrant} — consistent with market-microstructure
    (same batch, source-verified vs chart-information docs).
  - request.earnings for earnings context — consistent with the official
    economic/financial data article verified for macro-economics
    (same batch).
  - Forex tick-volume semantics — consistent with volume-analysis
    (batch-004) conventions.
repainting_findings: none in scope (sessions/earnings gaps are data-reality, not repaint modes; earnings gap handling routed to data-integrity).
mtf_findings: earnings/dividend context requests consume the request budget (multi-symbol-engineering).
runtime_performance_findings: none beyond request budgets.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - market-microstructure (same batch): 57 = what Pine can see + execution
    semantics; 58 = porting workflow per class. related_but_distinct.
    recommended_action: keep_separate
  - volume-analysis (batch-004): resolves its pending optional-dependency
    pointer to asset-class specialization content (tick-volume
    recalibration). relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Per-class realities verified vs official chart-information/sessions docs
    (source-declared); funding-not-modeled for crypto preserved as platform
    reality note.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Source frontmatter stray `class:` line (alongside `category:`) noted by
    the source itself as fixed during archiving — normalized file carries
    standard metadata only; original untouched.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
