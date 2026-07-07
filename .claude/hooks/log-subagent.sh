#!/usr/bin/env bash
# SubagentStop hook: append each finished subagent to an audit log so you can
# confirm which agents actually ran (e.g. all six of the reverse-engineer fan-out).
root=$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '\\' '/')
input=$(cat)
# Parse with node (bundled with Claude Code) instead of regex, so quotes/escapes in other fields can't cause a false match.
agent=$(node -e '
  const chunks = [];
  process.stdin.on("data", c => chunks.push(c));
  process.stdin.on("end", () => {
    const raw = chunks.join("");           // full stdin as one string
    let data;
    try { data = JSON.parse(raw); } catch (e) { data = {}; } // parse it
    console.log(data.agent_type || "");    // read the specific field
  });
' <<< "$input")
mkdir -p "$root/.claude/logs"

case "$agent" in
  tech-stack|module-map|external-integrations|data-flows|deployment-infra|runtime-process)
    printf '%s\t%s\n' "$(date -u +%FT%TZ)" "$agent" >> "$root/.claude/logs/subagents.log"
    printf '%s\n' "$agent" >> "$root/.claude/logs/reverse-engineer-run.tracker"
    ;;
  *)
    # Not one of the six reverse-engineer agents (e.g. no agent_type at all, or a
    # different subagent entirely) — keep it out of the audit log, but keep the
    # raw payload around in case it's worth investigating.
    printf -- '=== %s ===\n%s\n' "$(date -u +%FT%TZ)" "$input" >> "$root/.claude/logs/subagents-debug.log"
    ;;
esac
