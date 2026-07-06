#!/usr/bin/env bash
# SubagentStop hook: append each finished subagent to an audit log so you can
# confirm which agents actually ran (e.g. all six of the reverse-engineer fan-out).
root="${CLAUDE_PROJECT_DIR:-.}"
input=$(cat)
agent=$(printf '%s' "$input" | grep -o '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"agent_type"[[:space:]]*:[[:space:]]*"//; s/"$//')
mkdir -p "$root/.claude/logs"

case "$agent" in
  tech-stack|module-map|external-integrations|data-flows|deployment-infra|runtime-process)
    printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$agent" >> "$root/.claude/logs/subagents.log"
    ;;
  *)
    # Not one of the six reverse-engineer agents (e.g. no agent_type at all, or a
    # different subagent entirely) — keep it out of the audit log, but keep the
    # raw payload around in case it's worth investigating.
    printf -- '=== %s ===\n%s\n' "$(date -u +%FT%TZ)" "$input" >> "$root/.claude/logs/subagents-debug.log"
    ;;
esac
