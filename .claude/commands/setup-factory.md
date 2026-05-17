Auto-detect this project's language and tooling, then configure factory.json so the factory pipeline works out of the box.

## Step 1: Detect language and tooling

Read these files (skip any that don't exist):
- File extensions in `src/`, `lib/`, or project root (`.swift`, `.ts`, `.py`, `.go`, `.rs`, etc.)
- `package.json` (look at `scripts.build`, `scripts.test`, `scripts.lint`)
- `pyproject.toml` or `setup.py`
- `Package.swift`
- `Cargo.toml`, `go.mod`, `Makefile`

Determine: primary language, build command, test command, lint command, package manifest filename, file extensions, and import regex pattern.

## Step 2: Update factory/factory.json

Open `factory/factory.json` and set these fields based on what you detected:

- `project.file_extensions` - array of extensions found (e.g. `[".swift"]`, `[".ts", ".tsx"]`)
- `commands.build` - detected build command (e.g. `"swift build"`, `"npm run build"`, `"python -m py_compile"`)
- `commands.test` - detected test command (e.g. `"swift test"`, `"npm test"`, `"pytest"`)
- `commands.lint` - detected lint command, or `""` if none found
- `imports.pattern` - regex with capture group 1 for module name:
  - Swift: `"^import\\s+(\\w+)"`
  - TypeScript/JS: `"^import\\s+.*from\\s+['\"]([^'\"]+)['\"]"`
  - Python: `"^(?:from\\s+(\\S+)|import\\s+(\\S+))"`
  - Go: `"\"([^\"]+)\""`
  - Rust: `"^use\\s+(\\w+)"`
- `packages.manifest` - e.g. `"Package.swift"`, `"package.json"`, `"pyproject.toml"`

Only update fields you can confidently detect. Leave others at their template defaults.

## Step 3: Run onboard scan

If `./factory/onboard` exists, run:

```bash
./factory/onboard .
```

This scans existing imports and packages into `quality/allowed-imports.json` and `quality/allowed-packages.json`.

## Step 4: Commit everything

Stage and commit all factory files in one commit:

```bash
mkdir -p factory/.runs
python3 -c "import secrets; print(secrets.token_hex(16))" > factory/.runs/.commit-token
git add .claude/ factory/ CLAUDE.md .gitignore
git commit -m "chore: configure factory for $(detected_language) project"
```

The `python3` line generates a one-time commit token that the pre-commit hook consumes. This handles the case where an older pre-commit hook lacks bootstrap detection. Newer hooks detect that `factory/factory.json` is not yet in git history and allow the commit directly.

IMPORTANT: `.claude/` MUST be committed. It contains hooks and settings that must be available in worktrees and clones. If `.claude/` is not tracked, hooks won't fire in factory worktrees.

## Step 5: Print summary

Print what was configured: language detected, build/test/lint commands, number of allowed imports and packages found by onboard, and any fields left at defaults.
