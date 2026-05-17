# Justification Criteria

Rules for evaluating justification requests when an agent needs something not in registries.

## Import justification

- A new import must not duplicate functionality available in already-allowed frameworks.
- The import must be necessary for the item's acceptance criteria, not just convenient.
- Banned imports are hard bans. No justification overrides them.

## Package justification

- A new package must have a clear purpose not served by platform frameworks.
- Packages must have active maintenance and a compatible license.
- Prefer platform frameworks over third-party packages when both can solve the problem.

## Shared capability justification

- A new shared capability must be used by the current item and plausibly reusable by other features.
- Must not duplicate an existing entry in shared-capabilities.md.
- Functions should be genuinely shared (used by 2+ features) not prematurely extracted from one feature.
