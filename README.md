# ClaudeCodeDemo

A hands-on study guide demonstrating real-world usage of Claude Code features. Each feature is illustrated with a concrete, practical example.

Read [`overview.md`](./overview.md) for the full index — one section per feature, with scenario, files, and exact steps to reproduce each demo.

## Features covered

| § | Feature | What it shows |
|---|---|---|
| 1 | CLAUDE.md | Project context loaded automatically every session |
| 2 | Rules | Persistent behavior constraints scoped to file patterns |
| 3 | Slash Commands | Custom workflow shortcuts (`/reverse-engineer`, `/create-command`) |
| 4 | Skills | Reusable rendering procedures (`c4-documentation`, `4plus1-documentation`, `project-overview`) |
| 5 | Sub-agents | Six parallel fact-gathering agents with `background: true` |
| 6 | Hooks | `SubagentStop` logging, `PreToolUse` guard, turn timing |
| 7 | MCP Servers | Connecting external tools and data sources |
| 8 | External Skills | superpowers plugin (`/plugin install superpowers@claude-plugins-official`) |
| 9 | Capstone | `/reverse-engineer` — all features end-to-end |
| 10 | Agent SDK | Running agents programmatically from Python |

## Quick start

```
git clone <this-repo>
cd ClaudeCodeDemo
claude .
```

Then type `/reverse-engineer .` to run the capstone demo.

## Agent SDK script

`scripts/run-reverse-engineer.py` runs the `/reverse-engineer` command headlessly via the [Claude Agent SDK](https://code.claude.com/docs/en/agent-sdk/agent-loop) — no terminal UI required. Useful for CI pipelines, cost-gated automation, or nightly doc generation.

### Prerequisites

```
pip install claude-agent-sdk
```

Your `ANTHROPIC_API_KEY` must be set (or you must be logged in via `claude auth`).

### Run

```
python scripts/run-reverse-engineer.py [path]
```

`path` defaults to `.` (current directory). Pass any codebase root you want to reverse-engineer.

### What it does

- Runs `/reverse-engineer <path>` with a **$6.00 budget cap**
- Pre-approves all tools the command needs (no interactive prompts)
- Loads this project's CLAUDE.md, skills, and hooks automatically
- Prints cost, turn count, and session ID when done
- Exits `0` on success, `1` on any error (budget exceeded, turn limit, crash)

> **Note:** `effort="medium"` is used deliberately. `"high"` enables extended thinking which consumes context fast — the agent can exhaust the context window before Phase 3 completes and declare premature success.

### Example output

```
Running /reverse-engineer .
Budget cap: $2.00  |  Effort: high
----------------------------------------
Cost:    $0.8431
Turns:   47
Session: sess_01AbCd...

✓ Done — docs written to docs/
```

### Simulating a budget hit

Lower `max_budget_usd` in the script to `0.01` and re-run. The `error_max_budget_usd` branch fires and prints the session ID for resuming:

```
✗ Hit $2.00 budget cap — partial run
  Resume: python scripts/run-reverse-engineer.py  (session_id=sess_01AbCd...)
```
