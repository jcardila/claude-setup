#!/bin/bash
# Claude Code statusline — Catppuccin Mocha colors via ANSI
# Receives JSON session data on stdin from Claude Code
input=$(cat)

# Extract fields
MODEL=$(echo "$input" | jq -r '.model.display_name // "—"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Shorten directory: /var/www/magento2 → M2, home → ~
DIR=$(echo "$DIR" | sed "s|^$HOME|~|; s|/var/www/magento2|M2|")

# Catppuccin Mocha ANSI 256 approximations
LAVENDER='\033[38;2;180;190;254m'  # #b4befe
MAUVE='\033[38;2;203;166;247m'     # #cba6f7
GREEN='\033[38;2;166;227;161m'     # #a6e3a1
YELLOW='\033[38;2;249;226;175m'    # #f9e2af
RED='\033[38;2;243;139;168m'       # #f38ba8
PEACH='\033[38;2;250;179;135m'     # #fab387
SKY='\033[38;2;137;220;235m'       # #89dceb
TEAL='\033[38;2;148;226;213m'      # #94e2d5
SURFACE1='\033[38;2;69;71;90m'     # #45475a
DIM='\033[2m'
RESET='\033[0m'

# Progress bar with color coding
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=20
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Duration
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# Git branch (cached)
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_MAX_AGE=5
NEED_REFRESH=1
if [ -f "$CACHE_FILE" ]; then
  AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  [ "$AGE" -le "$CACHE_MAX_AGE" ] && NEED_REFRESH=0
fi
if [ "$NEED_REFRESH" -eq 1 ]; then
  ORIG_DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
  if [ -n "$ORIG_DIR" ] && git -C "$ORIG_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$ORIG_DIR" branch --show-current 2>/dev/null)
    STAGED=$(git -C "$ORIG_DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$ORIG_DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    echo "$BRANCH|$STAGED|$MODIFIED" > "$CACHE_FILE"
  else
    echo "||" > "$CACHE_FILE"
  fi
fi
IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE_FILE"

# Line 1: Model | Directory | Git
LINE1="${MAUVE}${MODEL}${RESET} ${SURFACE1}│${RESET} ${SKY}${DIR}${RESET}"
if [ -n "$BRANCH" ]; then
  GIT_EXTRA=""
  [ "$STAGED" -gt 0 ] && GIT_EXTRA=" ${GREEN}+${STAGED}${RESET}"
  [ "$MODIFIED" -gt 0 ] && GIT_EXTRA="${GIT_EXTRA} ${PEACH}~${MODIFIED}${RESET}"
  LINE1="${LINE1} ${SURFACE1}│${RESET} ${TEAL}${BRANCH}${RESET}${GIT_EXTRA}"
fi

# Line 2: Context bar | Duration
LINE2="${BAR_COLOR}${BAR}${RESET} ${LAVENDER}${PCT}%${RESET} ${SURFACE1}│${RESET} ${DIM}${MINS}m ${SECS}s${RESET}"

echo -e "$LINE1"
echo -e "$LINE2"
