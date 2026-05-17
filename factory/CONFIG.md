# CONFIG.md - Factory Configuration Reference

## Quick Start

```bash
./factory/resolve <item_id>    # Assemble context + emit agent prompt
./factory/gate <item_id>       # Run quality gate (3 layers)
./factory/complete <item_id>   # Merge branch, record telemetry
```

## factory.json Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `project.name` | string | `""` | Project display name |
| `project.file_extensions` | string[] | `[".swift"]` | Source file extensions to analyze |
| `commands.build` | string | `""` | Build command (e.g. `swift build`, `make`) |
| `commands.test` | string | `""` | Test command (e.g. `swift test`, `pytest`) |
| `commands.lint` | string | `""` | Lint command (e.g. `swiftlint`, `ruff check .`) |
| `pipeline.stages` | string[] | `["spec","test","impl","views","wire"]` | Ordered pipeline stage names |
| `pipeline.stage_agents` | object | `{"spec":"spec-writer",...}` | Maps each stage to its agent name |
| `pipeline.skip_stages` | string[] | `[]` | Stages to skip during resolve |
| `pipeline.feature_path` | string | `"Features/{feature}/"` | Path template for feature directories |
| `imports.pattern` | string | `"^import\\s+(\\S+)"` | Regex with capture group 1 for module name |
| `imports.file_extensions` | string[] | `[".swift"]` | Files to scan for imports |
| `packages.manifest` | string | `"Package.swift"` | Package manifest filename |
| `packages.new_dep_pattern` | string | `"\\.package\\("` | Regex to detect new dependency declarations |
| `gate.layer2_checks` | string[] | `["mainactor",...]` | Which Layer 2 structural checks to run |
| `gate.dependency_friendliness` | string | `"moderate"` | Approval threshold: `strict`, `moderate`, `permissive` |
| `gate.evaluator_weights` | string[] | `["heavy"]` | Gate weights that trigger Layer 3 evaluator |

## Quality Files

| File | Purpose | Format |
|------|---------|--------|
| `quality/patterns.md` | Codebase patterns agents must follow | Markdown |
| `quality/shared-capabilities.md` | Reusable components agents should use, not duplicate | Markdown |
| `quality/justification-criteria.md` | When to justify deviations from patterns | Markdown |
| `quality/rubrics/` | Evaluator scoring rubrics | Markdown |

Import allowlists, package allowlists, and platform terms are configured in `factory.json` under `imports.allowed`, `packages.allowed`, and `gate.platform_terms`.

Agent interface schemas live in `agents/schemas/`.

## Context Files

| File | Purpose |
|------|---------|
| `context/tiers.json` | Size limits per gate weight (max_files, max_lines) |
| `context/atomicity.json` | File groups that must change together |
| `context/module-map.json` | Module ownership and boundary definitions |
| `context/platform-conventions.md` | Coding standards included in every agent prompt |

## Common Tasks

- **Allow an import:** Add the module name to `imports.allowed.<layer>.allowed` in `factory.json`
- **Allow a package:** Add the package name to `packages.allowed` in `factory.json`
- **Change gate strictness:** Set `gate.dependency_friendliness` in `factory.json` to `strict`, `moderate`, or `permissive`
- **Add a pipeline stage:** Append to `pipeline.stages`, add a mapping in `pipeline.stage_agents`, create the agent in `agents/`
- **Handle gate exit code 3 (needs_approval):** Run `./factory/approve <item_id>`, invoke the dependency-resolver agent with the emitted prompt, then `./factory/approve --apply <item_id>` to write decisions to factory.json. Re-gate after.
- **Skip a stage:** Add the stage name to `pipeline.skip_stages`
- **Enable Layer 3 evaluator for more items:** Add `"medium"` or `"light"` to `gate.evaluator_weights`
