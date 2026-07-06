#!/usr/bin/env bash
# Shared helper for .claude slash commands. Dispatches on the first argument.
# Usage:
#   helpers.sh check-commands
#   helpers.sh top-level-listing [path]
case "$1" in
  check-commands)
    echo "[check-commands] Scanning .claude/commands/ for existing commands..."
    files=$(ls .claude/commands/*.md 2>/dev/null)
    if [ -z "$files" ]; then
      echo "[check-commands] No existing commands found."
    else
      echo "[check-commands] Found:"
      echo "$files"
    fi
    ;;
  top-level-listing)
    target="${2:-.}"
    ls -la "$target"
    ;;
  *)
    echo "Unknown subcommand: $1" >&2
    echo "Usage: helpers.sh {check-commands|top-level-listing [path]}" >&2
    exit 1
    ;;
esac
