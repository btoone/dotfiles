#!/bin/bash

# Read JSON input from Claude Code
input=$(cat)

# Extract useful stats using jq
model=$(echo "$input" | jq -r '.model.display_name // "?"')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

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

# Calculate context usage percentage
if [ "$context_size" -gt 0 ] 2>/dev/null; then
  pct=$((input_tokens * 100 / context_size))
else
  pct=0
fi

# Format cost (show cents if under $1)
if (( $(echo "$cost < 1" | bc -l) )); then
  cost_fmt=$(printf "%.0f¢" "$(echo "$cost * 100" | bc -l)")
else
  cost_fmt=$(printf "$%.2f" "$cost")
fi

# Format tokens (k for thousands)
if [ "$input_tokens" -ge 1000 ]; then
  tokens_fmt="$((input_tokens / 1000))k"
else
  tokens_fmt="$input_tokens"
fi

# Output: Model | Cost | Tokens (Context%) | Task
# Colors: cyan for model, green for cost, yellow for tokens, magenta for task
if [ -n "$current_task" ]; then
  printf "\033[36m%s\033[0m | \033[32m%s\033[0m | \033[33m%s (%d%%)\033[0m | \033[35m%s\033[0m" "$model" "$cost_fmt" "$tokens_fmt" "$pct" "$current_task"
else
  printf "\033[36m%s\033[0m | \033[32m%s\033[0m | \033[33m%s (%d%%)\033[0m" "$model" "$cost_fmt" "$tokens_fmt" "$pct"
fi
