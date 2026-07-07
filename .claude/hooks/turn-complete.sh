#!/usr/bin/env bash
# Stop hook: compute this turn's duration from the stamp turn-start.sh left,
# and append it (plus the prompt that started the turn) to a durable log
# independent of the UI.
root=$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '\\' '/')
start_file="$root/.claude/logs/.turn-start"
[ -f "$start_file" ] || exit 0

start=$(sed -n '1p' "$start_file")
prompt=$(sed -n '2p' "$start_file")
end=$(date -u +%s)
duration=$((end - start))

mkdir -p "$root/.claude/logs"
printf '%s\t%ss\t%s\n' "$(date -u +%FT%TZ)" "$duration" "${prompt:-(no prompt captured)}" >> "$root/.claude/logs/turn-completions.log"
