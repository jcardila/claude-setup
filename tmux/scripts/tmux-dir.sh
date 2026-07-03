#!/bin/bash
# Shortened directory for tmux catppuccin module
DIR="${1:-$HOME}"
DIR=$(echo "$DIR" | sed "s|^$HOME|~|; s|/var/www/magento2|M2|")
echo " $DIR"
