#!/bin/bash
# Git branch for tmux catppuccin module
# Usage: tmux-git-branch.sh <pane_current_path>
DIR="${1:-$HOME}"
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  [ ${#BRANCH} -gt 25 ] && BRANCH="${BRANCH:0:22}..."
  echo " $BRANCH"
fi
