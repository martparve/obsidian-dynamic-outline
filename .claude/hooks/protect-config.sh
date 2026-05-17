#!/usr/bin/env bash
set -euo pipefail

# Blocks modification of enforcement infrastructure:
# .claude/hooks/, .claude/settings.json, .git/hooks/

# --- functions ---

die() { echo "ERROR: $*" >&2; exit 1; }
die_block() { echo "$*" >&2; exit 2; }

is_protected_path() {
  local path="$1"
  [[ "$path" == *".claude/hooks/"* ]] && return 0
  [[ "$path" == *".claude/settings.json"* ]] && return 0
  [[ "$path" == *".git/hooks/"* ]] && return 0
  [[ "$path" == *".runs/.commit-token"* ]] && return 0
  [[ "$path" == *".commit-token"* ]] && return 0
  return 1
}

# --- main ---

main() {
  local input
  input=$(cat)

  local tool_name
  tool_name=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(data.get('tool_name', ''))
" <<< "$input" 2>/dev/null || echo "")

  if [[ "$tool_name" == "Edit" ]] || [[ "$tool_name" == "Write" ]]; then
    local file_path
    file_path=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(data.get('tool_input', {}).get('file_path', ''))
" <<< "$input" 2>/dev/null || echo "")

    if is_protected_path "$file_path"; then
      die_block "BLOCKED: Cannot modify enforcement infrastructure (.claude/hooks/, .claude/settings.json, .git/hooks/).

These files are managed by the factory. To update them, modify the factory upstream and run ./factory/install --update.

Full workflow docs: factory/CLAUDE.md"
    fi
  fi

  if [[ "$tool_name" == "Bash" ]]; then
    local command
    command=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(data.get('tool_input', {}).get('command', ''))
" <<< "$input" 2>/dev/null || echo "")

    if echo "$command" | grep -qE '(\.claude/hooks|\.claude/settings\.json|\.git/hooks|\.commit-token)' 2>/dev/null; then
      if echo "$command" | grep -qE '(rm|mv|cp\s|chmod|tee|sed\s+-i|>\s)' 2>/dev/null; then
        die_block "BLOCKED: Cannot modify enforcement infrastructure via Bash.

These files are managed by the factory. To update them, modify the factory upstream and run ./factory/install --update.

Full workflow docs: factory/CLAUDE.md"
      fi
    fi
  fi

  exit 0
}

main "$@"
