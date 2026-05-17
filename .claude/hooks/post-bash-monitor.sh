#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook on Bash. Checks if source files were modified on the
# default branch after any Bash command. Outcome-based - catches all write
# methods regardless of command-string obfuscation.

# --- functions ---

die() { echo "ERROR: $*" >&2; exit 1; }

detect_default_branch() {
  local branch
  branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  [[ -n "$branch" ]] && { echo "$branch"; return; }
  git rev-parse --verify main >/dev/null 2>&1 && { echo "main"; return; }
  git rev-parse --verify master >/dev/null 2>&1 && { echo "master"; return; }
  echo "main"
}

is_source_file() {
  local f="$1"
  [[ "$f" == factory/* ]] && return 1
  [[ "$f" == .claude/* ]] && return 1
  [[ "$f" == .git/* ]] && return 1
  case "$(basename "$f")" in
    .gitignore|.gitattributes|CLAUDE.md|README.md|LICENSE|\
    factory.json|Makefile|Dockerfile|docker-compose.yml|\
    pyproject.toml|setup.py|setup.cfg|requirements.txt|\
    Package.swift|Package.resolved|.swiftlint.yml|\
    Cargo.toml|Cargo.lock|go.mod|go.sum)
      return 1
      ;;
  esac
  return 0
}

# --- main ---

main() {
  local input
  input=$(cat)

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  local default_branch
  default_branch=$(detect_default_branch)

  [[ "$current_branch" == "$default_branch" ]] || exit 0

  # Find factory dir for lockout file
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  local factory_dir=""
  if [[ -n "$repo_root" ]]; then
    if [[ -d "$repo_root/factory/.runs" ]]; then
      factory_dir="$repo_root/factory"
    elif [[ -d "$repo_root/.runs" ]]; then
      factory_dir="$repo_root"
    fi
  fi

  local changed_files
  changed_files=$(git diff --name-only 2>/dev/null) || true

  local source_files=""
  if [[ -n "$changed_files" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      if is_source_file "$f"; then
        if [[ -n "$source_files" ]]; then
          source_files="$source_files, $f"
        else
          source_files="$f"
        fi
      fi
    done <<< "$changed_files"
  fi

  if [[ -z "$source_files" ]]; then
    # No violations - clear lockout if it exists
    if [[ -n "$factory_dir" ]] && [[ -f "$factory_dir/.runs/.violation-lockout" ]]; then
      rm -f "$factory_dir/.runs/.violation-lockout"
    fi
    exit 0
  fi

  # Write lockout marker file
  if [[ -n "$factory_dir" ]]; then
    mkdir -p "$factory_dir/.runs"
    echo "$source_files" | tr ', ' '\n' | grep -v '^$' > "$factory_dir/.runs/.violation-lockout"
  fi

  python3 -c "
import json
msg = (
  'WARNING: Source files were modified on the default branch. '
  'This violates the factory workflow.\\n\\n'
  'Modified files: $source_files\\n\\n'
  'To undo: git checkout -- <files>\\n'
  'Then use ./factory/resolve to create a proper worktree.\\n\\n'
  'Full workflow docs: factory/CLAUDE.md'
)
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': msg
  }
}))
"

  exit 0
}

main "$@"
