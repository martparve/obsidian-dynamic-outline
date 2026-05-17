# rubric: spec-review
version: 1
applies_to: [spec-writer]
weight_total: 100

## Dimensions
| id | dimension | weight | what to look for |
|----|-----------|--------|------------------|
| SR-1 | completeness | 30 | All behaviors from behavior.md are covered, none dropped |
| SR-2 | testability | 25 | Every requirement can be verified by a test (no vague language) |
| SR-3 | consistency | 25 | No contradictions between requirements, types used consistently |
| SR-4 | semantic_fidelity | 20 | Spec preserves the original behavioral intent without distortion |

## Scoring
0.0 / 0.25 / 0.5 / 0.75 / 1.0 per dimension.
Weighted score = sum(score * weight) / weight_total.

## Fail Conditions
- SR-1 at 0.0 = automatic fail (missing behaviors means incomplete spec).
- SR-4 at 0.0 = automatic fail (distorted intent means wrong spec).
- More than 3 issues at severity 0.25 or worse = automatic fail.

## Evaluator Instructions
- SR-1: Cross-reference spec requirements against behavior.md entries. Score 1.0 if all covered. Score 0.5 if minor behaviors omitted. Score 0.0 if major behavior group missing.
- SR-2: Check each requirement for concrete, verifiable criteria. Score 1.0 if all testable. Score 0.5 if some use "should" without measurable criteria. Score 0.0 if requirements are vague ("works well", "handles gracefully").
- SR-3: Check type names, property names, and flow descriptions for internal consistency. Score 1.0 if consistent. Score 0.5 if naming varies but intent clear. Score 0.0 if contradictory requirements exist.
- SR-4: Compare spec requirements against original behavior descriptions. Score 1.0 if intent preserved. Score 0.5 if minor interpretation differences. Score 0.0 if behavior meaning changed or inverted.
