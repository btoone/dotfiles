#!/bin/bash

# Claude Code statusline. Two rows: identity + context headroom, then budget.
#
#   personal · Opus 4.8 1M · dotfiles:master* · 106k/1M 11%
#   5h 13% · 7d 53% · $5.59

input=$(cat)

# Unit separator, not tab: tab is IFS whitespace, so `read` would collapse the
# runs of empty fields that absent keys produce and shift everything left.
IFS=$'\x1f' read -r session_id current_dir repo model fast pct window used cost five_hour seven_day <<<"$(
  printf '%s' "$input" | jq -j '[
    .session_id // "",
    .workspace.current_dir // .cwd // "",
    .workspace.repo.name // "",
    .model.display_name // "",
    (.fast_mode // false | tostring),
    (.context_window.used_percentage // 0 | floor),
    (.context_window.context_window_size // 0),
    (.context_window.total_input_tokens // 0),
    (.cost.total_cost_usd // 0),
    (.rate_limits.five_hour.used_percentage as $p | if $p == null then "" else ($p | floor) end),
    (.rate_limits.seven_day.used_percentage as $p | if $p == null then "" else ($p | floor) end)
  ] | map(tostring) | join("\u001f")'
)"

profile="${CLAUDE_CONFIG_DIR##*/}"
profile="${profile#.claude-}"

# "Opus 4.8 (1M context)" reads fine in a menu, not in a status bar
model="${model/ (/ }"
model="${model/ context)/}"
[ "$fast" = "true" ] && model="$model ⚡"

paint() { printf '\033[%sm%s\033[0m' "$1" "$2"; }

# Green under 60%, yellow to 85%, red above
heat() {
  [ "$1" -ge 85 ] && { printf '31'; return; }
  [ "$1" -ge 60 ] && { printf '33'; return; }
  printf '32'
}

tokens() {
  [ "$1" -ge 1000000 ] && { printf '%dM' $(( ($1 + 500000) / 1000000 )); return; }
  [ "$1" -ge 1000 ] && { printf '%dk' $(( ($1 + 500) / 1000 )); return; }
  printf '%d' "$1"
}

join_parts() {
  local out=""
  for part in "$@"; do
    [ -n "$out" ] && out+=" · "
    out+="$part"
  done
  printf '%s' "$out"
}

# Git is the only thing here that costs a subprocess, and the statusline
# redraws far faster than a branch changes. Cache per session, 5s TTL.
mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

cache="${TMPDIR:-/tmp}/claude-statusline-git-$session_id"
if [ $(( $(date +%s) - $(mtime "$cache") )) -ge 5 ]; then
  branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
  dirty=""
  if [ -n "$(git -C "$current_dir" status --porcelain 2>/dev/null | head -1)" ]; then
    dirty="*"
  fi
  printf '%s\x1f%s\n' "$branch" "$dirty" > "$cache"
fi
[ -f "$cache" ] && IFS=$'\x1f' read -r branch dirty < "$cache"

identity=()
[ -n "$profile" ] && identity+=("$(paint 34 "$profile")")
[ -n "$model" ] && identity+=("$(paint 35 "$model")")

location="${repo:-${current_dir##*/}}"
[ -n "$branch" ] && location="${location:+$location:}$branch"
[ -n "$location" ] && identity+=("$(paint 36 "$location")$(paint 31 "$dirty")")

if [ "${window:-0}" -gt 0 ]; then
  identity+=("$(paint "$(heat "$pct")" "$(tokens "$used")/$(tokens "$window") $pct%")")
fi

budget=()
[ -n "$five_hour" ] && budget+=("$(paint "$(heat "$five_hour")" "5h $five_hour%")")
[ -n "$seven_day" ] && budget+=("$(paint "$(heat "$seven_day")" "7d $seven_day%")")
budget+=("$(paint 90 "$(printf '$%.2f' "$cost")")")

join_parts "${identity[@]}"
printf '\n'
join_parts "${budget[@]}"
