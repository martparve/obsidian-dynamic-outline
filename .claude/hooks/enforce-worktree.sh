#!/usr/bin/env bash
set -euo pipefail

# Blocks Edit/Write on source files when on the default branch.
# Source files must be edited in a worktree created by ./factory/resolve.

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

is_allowed_path() {
  local file_path="$1"
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  # Allow backlog edits (needed to create/manage work items on main)
  [[ -n "$repo_root" ]] && [[ "$file_path" == "$repo_root/factory/backlog/"* ]] && return 0
  # Allow common root config files
  local basename
  basename=$(basename "$file_path")
  case "$basename" in
    .gitignore|.gitattributes|Package.swift|Package.resolved|\
    factory.json|Makefile|Dockerfile|docker-compose.yml|\
    pyproject.toml|setup.py|setup.cfg|requirements.txt|\
    Cargo.toml|Cargo.lock|go.mod|go.sum|\
    CLAUDE.md|README.md|LICENSE|.swiftlint.yml)
      return 0
      ;;
  esac
  return 1
}

# --- main ---

find_factory_dir() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  [[ -n "$repo_root" ]] || return
  if [[ -d "$repo_root/factory/.runs" ]]; then
    echo "$repo_root/factory"
  elif [[ -d "$repo_root/.runs" ]]; then
    echo "$repo_root"
  fi
}

main() {
  local input
  input=$(cat)

  # Lockout check: block ALL Edit/Write when violation lockout is active
  local factory_dir
  factory_dir=$(find_factory_dir)
  if [[ -n "$factory_dir" ]] && [[ -f "$factory_dir/.runs/.violation-lockout" ]]; then
    local locked_files
    locked_files=$(cat "$factory_dir/.runs/.violation-lockout" 2>/dev/null | tr '\n' ' ')
    die_block "BLOCKED: Source files modified on default branch. Revert with: git checkout -- ${locked_files}. See .runs/.violation-lockout for details."
  fi

  local file_path
  file_path=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
ti = data.get('tool_input', {})
print(ti.get('file_path', ''))
" <<< "$input" 2>/dev/null || echo "")

  [[ -n "$file_path" ]] || exit 0

  # Determine which git repo the file belongs to
  local file_dir
  file_dir=$(dirname "$file_path")
  local current_branch
  if [[ -d "$file_dir" ]]; then
    current_branch=$(git -C "$file_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  else
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  fi
  [[ -n "$current_branch" ]] || exit 0

  local default_branch
  default_branch=$(detect_default_branch)

  [[ "$current_branch" == "$default_branch" ]] || exit 0

  if is_allowed_path "$file_path"; then
    exit 0
  fi

  die_block "BLOCKED: Cannot edit source files on the main branch.

Do this instead:
1. Create or find a backlog item in factory/backlog/ (status: open)
2. Run: ./factory/resolve <item_id>
3. The resolve output IS the agent prompt - use it verbatim with the Agent tool (isolation: worktree)
4. After the agent finishes: ./factory/gate <item_id>
5. If gate passes: ./factory/complete <item_id>

Never edit source files directly. Never compose agent prompts manually.

Full workflow docs: factory/CLAUDE.md"
}

main "$@"
