# Code Factory

AI agent pipeline that produces native applications from behavioral specs through controlled, gated workflows.

## Quick Start

```bash
./resolve <item_id>      # Assemble context, create worktree, emit agent prompt
# Run agent with the emitted prompt
./gate <item_id>          # Three-layer quality gate
./complete <item_id>      # Merge, record telemetry, clean up
```

Or let the factory select work:

```bash
./resolve --next          # Triage picks the highest-priority ready item
./triage                  # See all items: ready, blocked, fixed
./triage --next 3         # Preview what would be dispatched
```

## Workflow

### 1. Resolve

`./resolve <item_id>` does 17 steps: concurrency check, dependency check, file ownership check, atomicity validation, sensitivity classification, gate weight assignment, agent selection, context module assembly, SHA pinning, worktree creation, telemetry insertion, and prompt emission.

The prompt is emitted between `---PROMPT-START---` and `---PROMPT-END---` markers on stdout. Use it verbatim with the Agent tool. Never compose agent prompts manually.

Agent must run with `isolation: "worktree"`. The worktree path is in `.runs/<item_id>.json`.

### 2. Gate

`./gate <item_id>` runs quality checks in layers:

- **Layer 1 (all tiers):** Build, test, lint, import allowlist, package allowlist, bounded-impact diff check, new file cap
- **Layer 2 (medium + heavy):** @MainActor enforcement, FetchDescriptor guard, ATS bypass, secrets scan, shared-capability reuse
- **Layer 3 (configurable):** Evaluator agent scoring via `./score`. Controlled by `gate.evaluator_weights` in factory.json (default: `["heavy"]`). Set to `["medium", "heavy"]` or `["light", "medium", "heavy"]` to score more items. Evaluator feedback is written to `.runs/<item_id>.evaluator-feedback.txt` on fail/review for agent retry context.

Gate weight assigned by resolve. Escalates mid-run if diff exceeds scope thresholds (>3 files or >200 lines on medium -> heavy).

**Dependency approval:** Import and package checks enforce allowlists. Banned imports hard-fail. Unknown imports/packages (not in allowed list) trigger exit code 3 ("needs_approval") and write structured requests to `.runs/<item_id>.pending-approvals.json`. The `approve` script then invokes the dependency-resolver agent, which reviews requests against the `gate.dependency_friendliness` setting (strict/moderate/permissive) and approves or denies each. Approved dependencies are added to quality files; denied ones fail with reasoning.

### 3. Complete

`./complete <item_id>` merges the branch back to main using rebase-then-merge (no-ff). Serialized via flock.

Modes:
- `./complete <item_id>` - normal merge
- `./complete <item_id> --wont-fix` - terminal state, no merge, unblocks dependents
- `./complete <item_id> --no-branch <status>` - status update only

On merge conflict: `./merge-resolve <item_id>` handles auto-resolution and re-implementation.

Idempotent: safe to re-run after crash.

## Concurrency

Hard cap: 3 parallel agents. Enforced by mkdir-based lock on `.resolve.lock`.

Each `.in-progress` entry: `ITEM_ID\tTIMESTAMP\tPID`. TTL 45 min with liveness check (kill -0).

## Autonomous Loop

```bash
./run              # Start autonomous dispatch loop
./run --status     # Show current state
./run --resume     # Reset circuit breaker
./run --cleanup    # Remove stale artifacts
```

Circuit breaker trips on 2 consecutive failures in the same rejection category. Telemetry health check halts on 0 writes in 30 minutes.

## Installation

```bash
./install /path/to/target --language swift      # Swift project (12 agents, SwiftUI quality configs)
./install /path/to/target --language python     # Python project (10 agents, pytest/ruff quality)
./install /path/to/target --language generic    # Minimal starter (10 agents, empty quality stubs)
./install /path/to/target --auto-onboard        # Auto-detect language, scan imports/packages
./install /path/to/target --update              # Engine-only update, project files untouched
```

Fresh install creates the full factory structure: engine scripts, factory.json (from language template), agents, quality configs, scaffold directories, context templates, and CLAUDE.md section. Refuses if factory.json already exists.

`--auto-onboard` runs the `onboard` script after install: detects language from file extensions and manifests, populates factory.json with build/test/lint commands, and scans the codebase to write quality/allowed-imports.json and quality/allowed-packages.json from actual imports and dependencies. Can combine with `--language` (template first, then onboard refines). Cannot combine with `--update`.

Update mode replaces engine files only (scripts, CLAUDE.md, install-templates, meta tools). Never touches factory.json, agents, quality, context, or backlog.

Records the source factory's git SHA in `factory/.upstream-sha`.

## Configuration (factory.json)

Every installed factory has a `factory.json` in the project tier. This file drives all language-specific behavior:

- `project.file_extensions` - which files to analyze (e.g., [".swift"], [".py"])
- `commands.build/test/lint` - how to build, test, lint
- `pipeline.stages` - ordered stage list (e.g., ["spec", "test", "impl", "views", "wire"])
- `pipeline.stage_agents` - maps stages to agent names
- `pipeline.feature_path` - path template for features (e.g., "Features/{feature}/")
- `imports.pattern` - regex with capture group 1 for module name extraction
- `packages.manifest` - package manifest filename (e.g., "Package.swift")
- `gate.layer2_checks` - which structural lint checks to run
- `gate.dependency_friendliness` - "strict", "moderate" (default), or "permissive" for dependency approval
- `gate.evaluator_weights` - which gate weights run Layer 3 evaluator (default: ["heavy"])

factory.json is project-owned. Engine updates never overwrite it.

## Contributing Upstream

```bash
./factory/meta/contribute /path/to/upstream-factory-repo
```

One-way diff generator. Compares local engine files against the upstream factory, generates a unified patch at `meta/.contribute-patch`. Only diffs engine files from `.factory-manifest` - never includes project files.

## Other Commands

```bash
./intake "task description"       # Clarifier -> decomposer -> human review
./intake --direct <file>          # Skip clarifier
./cancel <item_id>                # Stop in-flight item, suspend dependents
./track                           # Show stage progress
./track <feature> <stage>         # Mark stage complete
./prereq <feature> <stage>        # Check stage prerequisites
./validate --build                # Run build checks
./report                          # Telemetry dashboard
./report dimensions               # Dimension failure rates
./report economics                # Token spend and throughput by model
./report cycle-time               # Item lifecycle timing
./report hotspots                 # Most-changed files and gate failure correlation
./report throughput               # Items completed per day
./report scope                    # Declared vs actual scope
./report escalations              # Gate weight escalation frequency
./report all                      # All sections
./db init                         # Initialize telemetry database
./approve <item_id>               # Emit dependency-resolver prompt for pending approvals
./approve --apply <item_id>       # Apply resolver decisions to quality files
./onboard /path/to/target         # Auto-detect language, scan imports/packages
./install /path/to/target         # Install factory into another repo
./meta/contribute /path/to/upstream  # Generate upstream contribution patch
```

## Rules

CRITICAL: Never edit source files directly on the main branch. All changes go through worktrees via ./resolve.
CRITICAL: Never skip the gate. Run ./gate after every agent run, before ./complete.
CRITICAL: Never compose agent prompts manually. ./resolve output IS the prompt.

1. Never skip `./complete`. It tracks progress and prevents drift.
2. Max 3 parallel agents. Resolve enforces this.
3. Only use factory-defined agents from `agents/`. Never use general-purpose agents.
4. If the factory doesn't have what you need, extend the factory first.
5. Gate failures with high confidence: retry with score breakdown. Near-threshold + low confidence: human review.
6. 2-retry ceiling per pipeline step. After that: human escalation.
7. If a factory script fails, errors, or produces unexpected output: STOP. Report the exact error to the user. Never work around it, improvise a manual alternative, or attempt to fix factory scripts inline. Factory bugs are fixed upstream.

## File Structure

```
# Engine (replaced on update)
bin/                 All engine scripts (resolve, gate, complete, run, intake,
                     cancel, score, report, triage, track, prereq, validate,
                     sanitize-spec, validate-behavior, db, merge-resolve,
                     install, approve, onboard, test)
resolve, gate, ...   Symlinks to bin/ for backward compatibility
CLAUDE.md            Factory documentation
install-templates/   Language-specific starters (agents, quality, factory.json)
.factory-manifest    Declares engine vs project files
meta/                Tooling
  test               Test suite
  contribute         One-way upstream diff generator

# Project (created on install, never overwritten)
factory.json         Required config - drives all language-specific behavior
agents/              Agent definitions (project-owned, language-specific)
quality/             Registries, rubrics, schemas
context/             Config files (tiers, atomicity, module-map, platform-conventions)
backlog/             Work items with YAML frontmatter
tracking/            Stage tracking files per feature
background-docs/     Project specs and reference documentation

# Runtime (gitignored)
.runs/               Runtime context per item
.in-progress         Active items with timestamps and PIDs
.telemetry.db        SQLite telemetry
.resolve.lock        Concurrency lock
.merge.lock          Serialization lock
.upstream-sha        Tracks source factory commit
.circuit-breaker     Circuit breaker state
```

Engine scripts live in `bin/` with symlinks at the factory root for backward compatibility. Both `./factory/resolve` and `./factory/bin/resolve` work.

## Handling Gate Failures

1. Gate fails at Layer 1 (deterministic): fix the specific failure (build error, import violation, scope violation)
2. Gate returns "needs_approval" (exit 3): unknown imports/packages detected. Run `./approve <item_id>` to get a resolver prompt, invoke the dependency-resolver agent, then `./approve --apply <item_id>` to apply decisions. Re-gate after.
3. Gate fails at Layer 2 (structural lint): fix the pattern violation (@MainActor, secrets, duplication)
4. Gate fails at Layer 3 (evaluator): review per-dimension scores, retry with breakdown as context
5. Gate returns "review": human must review - low-confidence scores, borderline results
6. After 2 retries: escalate to human with both attempts and score breakdowns

---

# Factory

This project uses the Code Factory workflow. See `factory/CLAUDE.md` for full documentation.

### Resolving Backlog Items

```bash
./factory/resolve <item_id>    # or: ./factory/resolve --next
```

After the agent completes:

```bash
./factory/complete <item_id>
```

**Rules:**
- Never compose agent prompts manually. `./factory/resolve` output IS the prompt.
- Never skip `./factory/complete`. It tracks progress and prevents drift.
- Only use factory-defined agents from `factory/agents/`.
- Max 3 parallel agents.
- If a factory script fails, errors, or produces unexpected output: STOP. Report the exact error to the user. Never work around it, improvise a manual alternative, or attempt to fix the factory scripts inline. Factory bugs are fixed upstream.
