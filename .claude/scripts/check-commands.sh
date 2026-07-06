#!/usr/bin/env bash
echo "[check-commands] Scanning .claude/commands/ for existing commands..."
files=$(ls .claude/commands/*.md 2>/dev/null)
if [ -z "$files" ]; then
  echo "[check-commands] No existing commands found."
else
  echo "[check-commands] Found:"
  echo "$files"
fi
