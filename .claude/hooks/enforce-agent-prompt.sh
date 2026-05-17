#!/usr/bin/env bash
set -euo pipefail

# Blocks Agent tool calls that don't come from factory resolve.
# Checks for structural markers in the prompt and an active in-progress item.

# --- functions ---

die() { echo "ERROR: $*" >&2; exit 1; }
die_block() { echo "$*" >&2; exit 2; }

find_factory_dir() {
  if [[ -d "factory/.runs" ]]; then
    echo "factory"
  elif [[ -d ".runs" ]] && [[ -f "factory.json" ]]; then
    echo "."
  else
    echo ""
  fi
}

# --- main ---

main() {
  local input
  input=$(cat)

  local prompt
  prompt=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(data.get('tool_input', {}).get('prompt', ''))
" <<< "$input" 2>/dev/null || echo "")

  [[ -n "$prompt" ]] || exit 0

  local has_structure=false

  # Factory-assembled prompts from ./resolve contain these markers
  if echo "$prompt" | grep -q "# Agent Definition" && echo "$prompt" | grep -q "Work in the worktree at:"; then
    has_structure=true
  fi

  # Meta-factory prompts from ./meta/resolve
  if echo "$prompt" | grep -q "factory-dev agent" && echo "$prompt" | grep -q "## Item: FM-"; then
    has_structure=true
  fi

  if [[ "$has_structure" == "false" ]]; then
    die_block "BLOCKED: Agent prompts must come from ./factory/resolve.

Do this instead:
1. Create or find a backlog item in factory/backlog/ (status: open)
2. Run: ./factory/resolve <item_id>
3. Copy the ENTIRE output between ---PROMPT-START--- and ---PROMPT-END--- markers
4. Use that exact text as the prompt in the Agent tool (with isolation: worktree)

Never compose agent prompts manually.

Full workflow docs: factory/CLAUDE.md"
  fi

  # Verify an item is actually in progress
  local factory_dir
  factory_dir=$(find_factory_dir)
  if [[ -n "$factory_dir" ]]; then
    local in_progress="$factory_dir/.in-progress"
    if [[ ! -f "$in_progress" ]] || [[ ! -s "$in_progress" ]]; then
      # Also check meta in-progress for meta-factory agents
      local meta_progress="$factory_dir/meta/.in-progress"
      if [[ ! -f "$meta_progress" ]] || [[ ! -s "$meta_progress" ]]; then
        die_block "BLOCKED: No factory item is in progress. Run ./factory/resolve <item_id> first.

Full workflow docs: factory/CLAUDE.md"
      fi
    fi
  fi

  exit 0
}

main "$@"
