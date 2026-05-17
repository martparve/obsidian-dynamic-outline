# rubric: type-duplication
version: 1
applies_to: [builder, implementer, view-assembler]
weight_total: 100

## Dimensions
| id | dimension | weight | what to look for |
|----|-----------|--------|------------------|
| TD-1 | shared_reuse | 35 | New code uses existing shared capabilities instead of reimplementing |
| TD-2 | type_uniqueness | 30 | No new types that duplicate existing types in name or shape |
| TD-3 | pattern_conformance | 20 | Code follows patterns.md decisions (use X, never Y) |
| TD-4 | function_overlap | 15 | No new functions that overlap existing shared function signatures |

## Scoring
0.0 / 0.25 / 0.5 / 0.75 / 1.0 per dimension.
Weighted score = sum(score * weight) / weight_total.

## Fail Conditions
- TD-1 or TD-2 at 0.0 = automatic fail.
- More than 3 issues at severity 0.25 or worse = automatic fail.

## Evaluator Instructions
- TD-1: Compare new code against shared-capabilities.md. Score 1.0 if all available shared functions used. Score 0.5 if partial reuse. Score 0.0 if reimplements existing shared capability.
- TD-2: Search codebase for types with same name or structurally identical shape. Score 1.0 if unique. Score 0.25 if name collision. Score 0.0 if structural duplicate.
- TD-3: Check new code against each relevant entry in patterns.md. Score 1.0 if all followed. Score 0.5 if minor deviation. Score 0.0 if "never Y" pattern violated.
- TD-4: Compare new function signatures against shared-capabilities.md entries. Score 1.0 if no overlap. Score 0.5 if similar but different. Score 0.0 if duplicate signature.
