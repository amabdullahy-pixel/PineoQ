# Skill: natural-language-to-math

## Metadata

```yaml
id: natural-language-to-math
name: Natural Language to Math
version: 1.0.0
path: skills/normalized/formalization/natural-language-to-math/skill.md
layer: FORMALIZATION
domains: [formalization, requirements]
triggers:
  english:
    - verbal rule to pine
    - formal logic boolean conditions
    - ambiguity table requirements
    - de morgan precedence guard
    - translation validation echo
    - vague requirement clarification
  persian:
    - تبدیل قواعد کلامی به ریاضی
    - منطق صوری
    - رفع ابهام شرط‌ها
dependencies:
  mandatory: []
  optional: [pine-language-core, data-integrity, tradingview-execution-model,
    repainting-and-lookahead, liquidity-and-price-structure,
    requirements-engineering]
status: normalized
priority: 1
```

## Purpose

Translating verbal trading rules into formal logic → mathematics → Boolean
conditions → Pine. Canonical pipeline: **Natural Language → Formal Logic →
Mathematics → Boolean Conditions → Pine**.

## Triggers

Select for: every user-stated rule; every vague "I want it to buy when…"
requirement; ambiguity resolution before coding; long condition-string
audits.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Verbal rule | natural language | user request | yes |
| Assumption declarations | records | this skill → requester | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Formalization contract fields (variables, formulas, booleans) | contract | formalization/contract_schema |
| Ambiguity list for requester confirmation | ambiguities | user, Pre-Verification |
| Boolean condition definitions | predicates | Implementation |

## Rules

1. Translation pipeline (work the example): verbal — "RSI1 > RSI3 and the
   difference must be at least 18 and no expansion". Step 1 formal logic:
   identify predicates/terms — P₁ = rsi₁ > rsi₃ · P₂ = (rsi₁ − rsi₃) ≥ 18 ·
   P₃ = expansion = false. Step 2 mathematics: define each term with
   window/normalization — rsi₁ = RSI(close, len₁)@tf₁, rsi₃ = RSI(close,
   len₃)@tf₃ — AMBIGUITY CHECK: "RSI1/RSI3" = RSI with two different
   LENGTHS on one series, or RSI of two different SYMBOLS/TIMEFRAMES? Ask
   or state the assumption explicitly. Step 3 Boolean conditions: r1 =
   ta.rsi(close, len1), r3 = ta.rsi(close, len3); P1 = r1 > r3; P2 =
   (r1 − r3) >= 18.0; P3 = not expansionActive; rule = P1 and P2 and P3.
   Step 4 Pine semantics check: v6 lazy and/or (safe — pine-language-core);
   explicit parentheses around every and/or mix; bool(x) never implicit;
   terms defined at GLOBAL scope if from ta.* (no conditional ta calls —
   pine-language-core).
2. Ambiguity table (ask before coding): "above/below" → close vs high/low?
   bar close? — default: close, confirmed bar; "crosses" → intrabar touch
   vs close-through — default: close-through (isconfirmed); "RSI1, RSI3" →
   lengths? timeframes? symbols? — default: lengths unless told otherwise;
   "strong move" → how measured? — default: body > k·avgBody or ATR
   multiples (liquidity-and-price-structure displacement pattern); "and/or"
   in speech → inclusive/exclusive — default: inclusive OR, confirm
   exclusivity; "quickly/fast" → bars? %? — default: N bars (state N).
3. Boolean algebra guards: De Morgan for negation —
   `not (A and B) == not A or not B`; precedence — and binds tighter than
   or, PARENthesize: `(A and B) or C ≠ A and (B or C)`; XOR trap — verbal
   "or" usually means inclusive OR, XOR only if stated; unknowns propagate
   — any na term makes the whole conjunction na-ish → guard with
   `not na(...)` (data-integrity) or barstate gates
   (tradingview-execution-model).
4. Validation of the translation: echo the formalization BACK to the
   requester in plain language + the exact intended semantics; get
   confirmation BEFORE building (requirements loop —
   requirements-engineering).

## Workflow

1. Extract predicates/terms; identify every ambiguity (rule 1).
2. Declare defaults or ask; never silently resolve (rule 2).
3. Apply algebra guards to the assembled conditions (rule 3).
4. Echo the formalization for confirmation (rule 4); then it may enter the
   formalization contract.

## Constraints

- No coding the ambiguous reading without declaring the assumption.
- No and/or precedence bugs in long condition strings.
- No intrabar "crosses" implementations (repaints —
  repainting-and-lookahead).
- No missing na-guards on multi-term conditions.

## Assumptions

- Pine semantics (lazy evaluation, precedence, na-propagation) consistent
  with the verified Operators page and language-core inventory.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Silent assumption | no declared default | rule 2: ask or declare |
| Precedence bug | long mixed conditions | rule 3: parenthesize |
| Intrabar crosses | repaint | constraint: close-through default |
| na-propagation bug | missing guard | rule 3: not na(...) gates |

## Dependencies

Optional: pine-language-core (semantics), data-integrity (na-guards),
tradingview-execution-model (barstate), repainting-and-lookahead
(cross semantics), liquidity-and-price-structure (strong-move defaults),
requirements-engineering (confirmation loop). Load only on their own
triggers.

## Examples

- "Buy when RSI1 > RSI3 by at least 18" → rule 1 worked pipeline.
- "What does 'strong move' mean here?" → rule 2 ambiguity table.
- Persian: «منظورم از تقاطع چیه دقیقا؟» → rule 2: close-through default
  declared.

## Verification Criteria

- Every verbal rule decomposed through the four-step pipeline.
- All ambiguities declared or resolved WITH the requester (never silently).
- Parenthesization and na-guards verified on assembled conditions.
- Requester confirmation recorded before implementation.

## Ambiguities

- None from the source (the skill's function IS ambiguity management).

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/64-natural-language-to-math.md`.
- **Layer FORMALIZATION** — assigned from the skill's actual function (the
  canonical NL→logic→math→Boolean→Pine pipeline is the Formalization-stage
  method); first FORMALIZATION-layer skill registered; creates the
  `formalization/` directory under skills/normalized/. Source's illustrative
  Pine lines preserved as rule prose + inline identifiers per normalization
  convention (no code generated). Structural reorganization only; no
  semantic changes.

## Source Reference

- Original filename: `64-natural-language-to-math.md`
- Original source path: `skills/incoming/64-natural-language-to-math.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
