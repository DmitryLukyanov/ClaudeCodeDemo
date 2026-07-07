#!/usr/bin/env bash
# PreToolUse guard: asks for permission if a /reverse-engineer doc gets
# written before all six fan-out agents finished in the current run.
root=$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '\\' '/')
tracker="$root/.claude/logs/reverse-engineer-run.tracker"
# read from stdin (https://code.claude.com/docs/en/hooks#common-input-fields)
# {
  # "session_id": "abc123",
  # "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  # "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  # "cwd": "/home/user/my-project",
  # "permission_mode": "default",
  # "hook_event_name": "PreToolUse",
  # "tool_name": "Write",
  # "tool_input": {
    # "file_path": "docs/overview.md",
    # "content": "# Overview..."
  # }
# }
input=$(cat)

# Parse with node (bundled with Claude Code) instead of regex, so a "content" field containing similar text can't cause a false match.
file_path=$(node -e '
  const chunks = [];
  process.stdin.on("data", c => chunks.push(c));
  process.stdin.on("end", () => {
    const raw = chunks.join("");           // full stdin as one string
    let data;
    try { data = JSON.parse(raw); } catch (e) { data = {}; } // parse it
    console.log((data.tool_input && data.tool_input.file_path) || ""); // read the specific field
  });
' <<< "$input")

# Normalize Windows backslashes to forward slashes for the case match below.
norm_path=$(printf '%s' "$file_path" | tr '\\' '/')

case "$norm_path" in
  */docs/c4/*|*/docs/4plus1/*|*/docs/overview.md|*/docs/COMPARISON.md|docs/c4/*|docs/4plus1/*|docs/overview.md|docs/COMPARISON.md)
    : # guarded path — fall through to the completeness check below
    ;;
  *)
    exit 0 # not a guarded path, nothing to enforce
    ;;
esac

required="tech-stack module-map external-integrations data-flows deployment-infra runtime-process"
completed=""
if [ -f "$tracker" ]; then
  completed=$(sort -u "$tracker" | tr '\n' ' ') # dedup, space-joined for substring checks below
fi

missing=""
for a in $required; do
  case " $completed " in
    *" $a "*) ;;                        # already completed
    *) missing="$missing $a" ;;         # not yet completed
  esac
done

if [ -n "$missing" ]; then
  reason="Not all 6 reverse-engineer subagents completed in the current run. Missing:$missing. Allow this write anyway, or have Claude spawn the missing agents first?"
  
  # https://code.claude.com/docs/en/hooks#decision-control
  printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "%s"}}' "$reason"
fi

exit 0
