#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dir=$(basename "$cwd")
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
style=$(echo "$input" | jq -r '.output_style.name // empty')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

parts=()

if [ -n "$dir" ]; then
  parts+=("$(printf '\033[0;34m%s\033[0m' "$dir")")
fi

if [ -n "$branch" ]; then
  parts+=("$(printf '\033[0;33m(%s)\033[0m' "$branch")")
fi

if [ -n "$model" ]; then
  parts+=("$(printf '\033[0;36m%s\033[0m' "$model")")
fi

if [ -n "$style" ]; then
  parts+=("$(printf '\033[0;32m%s\033[0m' "$style")")
fi

if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  parts+=("$(printf '\033[0;35mctx:%s%%\033[0m' "$used_int")")
fi

if [ -n "$rate_5h" ]; then
  rate_5h_int=$(printf "%.0f" "$rate_5h")
  parts+=("$(printf '\033[0;33m5h:%s%%\033[0m' "$rate_5h_int")")
fi

if [ -n "$rate_7d" ]; then
  rate_7d_int=$(printf "%.0f" "$rate_7d")
  parts+=("$(printf '\033[0;31m7d:%s%%\033[0m' "$rate_7d_int")")
fi

printf "%s" "$(IFS=" "; echo "${parts[*]}")"
