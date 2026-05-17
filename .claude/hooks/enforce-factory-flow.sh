#!/usr/bin/env bash
set -euo pipefail

# Blocks direct commits on main and enforces gate-before-complete.
# Note: real commit enforcement is the git pre-commit hook (tamper-resistant).
# This hook is defense-in-depth with better error messages.

# --- functions ---

die() { echo "ERROR: $*" >&2; exit 1; }
die_block() { echo "$*" >&2; exit 2; }

detect_default_branch() {
  local branch
  branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  [[ -n "$branch" ]] && { echo "$branch"; return; }
  git rev-parse --verify main >/dev/null 2>&1 && { echo "main"; return; }
  git rev-parse --verify master >/dev/null 2>&1 && { echo "master"; return; }
  echo "main"
}

check_gate_passed() {
  local item_id="$1"
  local factory_dir
  factory_dir=$(find_factory_dir)
  [[ -n "$factory_dir" ]] || return 1

  local runs_file="$factory_dir/.runs/${item_id}.json"
  [[ -f "$runs_file" ]] || return 1
  grep -q '"gate_result"' "$runs_file" || return 1
  grep '"gate_result"' "$runs_file" | grep -q '"pass"'
}

find_factory_dir() {
  # Look for factory dir relative to cwd
  if [[ -d "factory/.runs" ]]; then
    echo "factory"
  elif [[ -d ".runs" ]] && [[ -f "../factory.json" || -f "factory.json" ]]; then
    echo "."
  else
    echo ""
  fi
}

# --- main ---

main() {
  local input
  input=$(cat)

  local command
  command=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
ti = data.get('tool_input', {})
print(ti.get('command', ''))
" <<< "$input" 2>/dev/null || echo "")

  [[ -n "$command" ]] || exit 0

  # Lockout check: when violation lockout is active, only allow revert-like commands
  local factory_dir
  factory_dir=$(find_factory_dir)
  if [[ -n "$factory_dir" ]] && [[ -f "$factory_dir/.runs/.violation-lockout" ]]; then
    # Allow revert-like commands through
    if ! echo "$command" | grep -qE '(git\s+checkout|git\s+restore|git\s+stash|git\s+diff|git\s+status)'; then
      local locked_files
      locked_files=$(cat "$factory_dir/.runs/.violation-lockout" 2>/dev/null | tr '\n' ' ')
      die_block "BLOCKED: Source files modified on default branch. Only revert commands allowed. Run: git checkout -- ${locked_files}"
    fi
  fi

  # Check for git commit or git merge on default branch
  if echo "$command" | grep -qE '(git\s+commit|git\s+merge)'; then
    # Bootstrap: allow if factory is not yet tracked in git
    if ! git show HEAD:factory/factory.json >/dev/null 2>&1; then
      exit 0
    fi

    local git_dir=""
    # Extract cd target if command starts with cd (worktree pattern)
    if echo "$command" | grep -qE '^cd\s+'; then
      git_dir=$(echo "$command" | sed -n 's/^cd[[:space:]]*\([^;&|]*\).*/\1/p' | tr -d "'\"" | sed 's/[[:space:]]*$//')
    fi
    # Also check -C flag: git -C /path/to/dir commit
    if [[ -z "$git_dir" ]]; then
      git_dir=$(echo "$command" | grep -oE 'git\s+-C\s+[^ ]+' | awk '{print $3}' || true)
    fi

    local current_branch
    if [[ -n "$git_dir" ]] && [[ -d "$git_dir" ]]; then
      current_branch=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    else
      current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    fi
    local default_branch
    default_branch=$(detect_default_branch)

    if [[ "$current_branch" == "$default_branch" ]]; then
      die_block "BLOCKED: Cannot commit or merge directly on the main branch.

Do this instead:
1. Create or find a backlog item in factory/backlog/ (status: open)
2. Run: ./factory/resolve <item_id>
3. The resolve output IS the agent prompt - use it verbatim with the Agent tool (isolation: worktree)
4. The agent commits inside the worktree (on a fix/ branch) - that is allowed
5. After the agent finishes: ./factory/gate <item_id>
6. If gate passes: ./factory/complete <item_id> (this script merges to main for you)

Never commit to main directly. Never skip the gate.

Full workflow docs: factory/CLAUDE.md"
    fi
    exit 0
  fi

  # Check for factory/complete - require gate pass
  if echo "$command" | grep -qE '(\./factory/complete|factory/complete)'; then
    # Extract item_id - first non-flag argument after complete
    local item_id
    item_id=$(echo "$command" | grep -oE '(factory/complete)\s+([A-Za-z0-9_-]+)' | awk '{print $2}')
    [[ -n "$item_id" ]] || exit 0

    # Skip check for --wont-fix and --no-branch modes
    if echo "$command" | grep -qE '\-\-wont-fix|\-\-no-branch'; then
      exit 0
    fi

    if ! check_gate_passed "$item_id"; then
      die_block "BLOCKED: Gate has not passed for $item_id.

Run: ./factory/gate $item_id
Then retry: ./factory/complete $item_id

If the gate fails, fix the issues in the worktree and re-run the gate. Do not bypass it."
    fi
    exit 0
  fi

  # All other commands: allow
  exit 0
}

main "$@"
