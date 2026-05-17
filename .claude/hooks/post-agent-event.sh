#!/usr/bin/env bash
# factory-managed
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -n "$REPO_ROOT" ]] || exit 0

FACTORY_DIR="$REPO_ROOT/factory"
DB="$FACTORY_DIR/db"
IN_PROGRESS="$FACTORY_DIR/.in-progress"
RUNS_DIR="$FACTORY_DIR/.runs"

[[ -x "$DB" ]] || exit 0

input=$(cat)

[[ -f "$IN_PROGRESS" ]] || exit 0
item_id=$(head -1 "$IN_PROGRESS" | cut -f1)
[[ -n "$item_id" ]] || exit 0

runs_file="$RUNS_DIR/${item_id}.json"
[[ -f "$runs_file" ]] || exit 0

run_id=$(python3 -c "import json; print(json.load(open('$runs_file')).get('run_id', 0))" 2>/dev/null || echo 0)
agent=$(python3 -c "import json; print(json.load(open('$runs_file')).get('agent', ''))" 2>/dev/null || echo "")
started_at=$(python3 -c "import json; print(json.load(open('$runs_file')).get('started_at', ''))" 2>/dev/null || echo "")

# Extract model and duration from hook input
# model is in tool_input.model, duration_ms is top-level
hook_data=$(echo "$input" | python3 -c "
import json, sys
try:
  data = json.load(sys.stdin)
  model = data.get('tool_input', {}).get('model', '')
  duration = data.get('duration_ms', 0)
  print(model if model else '')
  print(int(duration) if duration else 0)
except:
  print('')
  print(0)
" 2>/dev/null || echo -e "\n0")

model=$(echo "$hook_data" | sed -n '1p')
duration_ms=$(echo "$hook_data" | sed -n '2p')

# Fallback: get model from agent definition
if [[ -z "$model" ]] && [[ -n "$agent" ]]; then
  agent_def="$FACTORY_DIR/agents/${agent}.md"
  if [[ -f "$agent_def" ]]; then
    model=$(grep -i '^# Model' "$agent_def" -A1 | tail -1 | tr -d '[:space:]' || echo "")
  fi
fi

finished_at=$(date '+%Y-%m-%dT%H:%M:%S')

# Token counts not available from PostToolUse hooks - only duration and model
"$DB" insert-agent-event \
  "$run_id" "$item_id" "$agent" "${model:-unknown}" "${started_at:-$finished_at}" \
  "$finished_at" "${duration_ms:-}" "" "" "" "" "" "" "" "success" \
  2>/dev/null || true

exit 0
