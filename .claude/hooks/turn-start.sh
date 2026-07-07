#!/usr/bin/env bash
# UserPromptSubmit hook: stamp the start time of this turn (and the prompt
# that started it) so turn-complete.sh can compute how long it actually took
# and log what it was for (useful for long unattended runs like
# /reverse-engineer, which can take 10-15 minutes).
root=$(printf '%s' "${CLAUDE_PROJECT_DIR:-.}" | tr '\\' '/')
mkdir -p "$root/.claude/logs"
input=$(cat)

# Parse with node (bundled with Claude Code) and collapse newlines, since this file's format assumes the prompt is a single line.
prompt=$(node -e '
  const chunks = [];
  process.stdin.on("data", c => chunks.push(c));
  process.stdin.on("end", () => {
    const raw = chunks.join("");           // full stdin as one string
    let data;
    try { data = JSON.parse(raw); } catch (e) { data = {}; } // parse it
    const value = (data.prompt || "").replace(/\r?\n/g, " "); // read the specific field
    console.log(value);
  });
' <<< "$input")

{
  date -u +%s
  printf '%s\n' "${prompt:-(no prompt captured)}"
} > "$root/.claude/logs/.turn-start"
