#!/bin/bash

# Read JSON input from Claude Code
input=$(cat)

# Detect profile from CLAUDE_CONFIG_DIR
profile=$(basename "${CLAUDE_CONFIG_DIR:-}" | sed 's/^\.claude-//')

# Extract stats using jq
branch=$(git branch --show-current 2>/dev/null)
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Extract current task (first in_progress todo, or current tool activity)
current_task=$(echo "$input" | jq -r '
  (.todos // [] | map(select(.status == "in_progress")) | .[0].activeForm // null) //
  (.current_tool.name // null) //
  empty
')

# Truncate task if too long (max 40 chars)
if [ -n "$current_task" ] && [ ${#current_task} -gt 40 ]; then
  current_task="${current_task:0:37}..."
fi

# Build output: profile | branch | ctx% | task
# Colors: blue for profile, cyan for branch, yellow for context, magenta for task
parts=()

if [ -n "$profile" ]; then
  parts+=("$(printf '\033[34m%s\033[0m' "$profile")")
fi

if [ -n "$branch" ]; then
  parts+=("$(printf '\033[36m%s\033[0m' "$branch")")
fi

parts+=("$(printf '\033[33m%d%%\033[0m' "$pct")")

if [ -n "$current_task" ]; then
  parts+=("$(printf '\033[35m%s\033[0m' "$current_task")")
fi

# Join with " | "
first=true
for part in "${parts[@]}"; do
  if $first; then first=false; else printf ' | '; fi
  printf '%s' "$part"
done
