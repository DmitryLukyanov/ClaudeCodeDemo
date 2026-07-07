# C4 — L2 Container

This view zooms inside the ClaudeCodeDemo boundary. Because there is no traditional
application, the "containers" are **execution contexts and runnable units**: the Claude Code
session that hosts everything, the `/reverse-engineer` orchestrator command, the six
background subagents, the three rendering skills, the four lifecycle hook subprocesses, the
shared file-based state, and the standalone Python Agent SDK driver that can start the whole
thing headlessly. Relationships are labelled with the mechanism that connects them (Agent
tool spawn, Skill invocation, hook event, file I/O, SDK query).

```
People / Actors
  [ Person Name ]           Human user or role

System / Container / Component boxes
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |   ← technology tag only at L2+
  |  Short responsibility      |   ← responsibility line only at L3
  +---------------------------+

Relationships (inside system boundary)
  ──────────────────────>   label: protocol or action

Relationships crossing the system boundary
  ====================>   label: protocol or action

External systems (outside boundary)
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+
```

```
+==================+                          +=========================+
|  CI / Caller     |                          |  Anthropic API          |
|  [External]      |                          |  [External SaaS]        |
+==================+                          +=========================+
     |                                             ^
     | runs (CLI)                                  | agent loop (HTTPS)
     v                                             |
+-------------------------------------------------------------------------+
|  ClaudeCodeDemo (System boundary)                                       |
|                                                                         |
|  +---------------------------+     SDK query()     +------------------+ |
|  |  Python Agent SDK Driver  | ──────────────────> |  Claude Code     | |
|  |  [Process: Python asyncio]|                     |  Session         | |
|  +---------------------------+                     |  [Runtime]       | |
|                                                    +------------------+ |
|                                                          | loads/runs   |
|                                                          v              |
|                                            +---------------------------+|
|   [ Developer ] ──uses──────────────────>  |  /reverse-engineer        ||
|                                            |  Orchestrator Command     ||
|                                            |  [Command: Markdown]      ||
|                                            +---------------------------+|
|                                              |  spawn (Agent tool)      |
|                                              |  background:true          |
|                                              v                          |
|                                +----------------------------------+     |
|                                |  6 Fact-Gathering Subagents      |     |
|                                |  [Agents: haiku/sonnet, RO]      |     |
|                                +----------------------------------+     |
|                                              |  return summaries        |
|                                              v                          |
|                                +----------------------------------+     |
|                                |  3 Rendering Skills              |     |
|                                |  [Skills: Markdown]              | ──┐  |
|                                +----------------------------------+   |  |
|                                                                       |  |
|   +---------------------------+   fires on lifecycle events           |  |
|   |  4 Lifecycle Hooks        | <────────────────── (Claude Code)     |  |
|   |  [Hooks: Bash + node -e]  |                                       |  |
|   +---------------------------+                                       |  |
|            |  append / read (file I/O)          write docs (file I/O) |  |
|            v                                            v             v  |
|   +---------------------------+           +---------------------------+  |
|   |  Shared File State        |           |  docs/ output tree        |  |
|   |  [Files: logs + tracker]  |           |  [Files: Markdown]        |  |
|   +---------------------------+           +---------------------------+  |
|                                                                         |
|   +---------------------------+                                         |
|   |  helpers.sh               |  (Phase 1 orientation, command check)   |
|   |  [Script: Bash]           |                                         |
|   +---------------------------+                                         |
+-------------------------------------------------------------------------+
```

## Element & Relationship Key

| Container | Description |
|---|---|
| Python Agent SDK Driver | `scripts/run-reverse-engineer.py` — single asyncio-loop process; calls `claude_agent_sdk.query()` with `setting_sources=["project"]`, `max_budget_usd=6.00`, `effort="medium"`; maps `ResultMessage.subtype` to exit codes. |
| Claude Code Session | The hosting runtime (interactive or SDK-driven). Loads `CLAUDE.md`, `.claude/settings.json`, rules, commands, skills, agents. Crosses the boundary to the Anthropic API for inference. |
| /reverse-engineer Orchestrator Command | `.claude/commands/reverse-engineer.md` — 4-phase pipeline. The **only** component permitted to spawn subagents or invoke skills. |
| 6 Fact-Gathering Subagents | `.claude/agents/{tech-stack,module-map,external-integrations,data-flows,deployment-infra,runtime-process}.md`. Read-only (Read/Glob/Grep), `background:true`, run in parallel; each returns a compact structured summary. Models: haiku (tech-stack, external-integrations, deployment-infra) / sonnet (module-map, data-flows, runtime-process). |
| 3 Rendering Skills | `.claude/skills/{c4-documentation,4plus1-documentation,project-overview}/SKILL.md`. Turn merged facts into docs; never call subagents or each other. |
| 4 Lifecycle Hooks | `.claude/hooks/{log-subagent,guard-reverse-engineer-docs,turn-start,turn-complete}.sh`. Short-lived Bash subprocesses fired by Claude Code events; each spawns `node -e` to parse JSON stdin. |
| Shared File State | `.claude/logs/reverse-engineer-run.tracker` (completion tally), `subagents.log`, `turn-completions.log`, `.turn-start`. Coordination channel between hooks and orchestrator. |
| docs/ output tree | `docs/c4/*`, `docs/4plus1/*`, `docs/overview.md`, `docs/COMPARISON.md` — 11 rendered files. |
| helpers.sh | `.claude/scripts/helpers.sh` — `top-level-listing` (Phase 1 orientation) and `check-commands` subcommands. |

| Relationship | Description |
|---|---|
| Driver → Claude Code Session | `SDK query()` with prompt `/reverse-engineer <path>`; starts the same workflow headlessly. |
| Developer → Orchestrator Command | Interactive slash-command invocation inside the session. |
| Session → Anthropic API | Agent loop / inference over HTTPS (only outbound network path). |
| Command → Subagents | `Agent` tool spawn, `background:true`, six in parallel; barrier waits for all six. |
| Subagents → Command | Return compact structured summaries (Phase 2 → Phase 3 handoff). |
| Command → Skills | `Skill` invocation with merged facts; skills write the docs. |
| Skills → docs/ | File I/O — render Markdown docs. |
| Claude Code events → Hooks | SubagentStop / PreToolUse / UserPromptSubmit / Stop trigger the hook subprocesses. |
| Hooks → Shared File State | Append to logs/tracker; guard hook reads tracker before a guarded doc write. |
| Command → helpers.sh | Phase 1 shells `top-level-listing`; `/create-command` shells `check-commands`. |
