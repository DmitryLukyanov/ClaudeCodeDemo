# C4 Deployment — ClaudeCodeDemo

This view shows the physical picture: the infrastructure nodes where ClaudeCodeDemo's containers run and the network paths between them. Because this is a developer-local Claude Code repository (not a deployed application), the topology is simple: everything runs on the developer's local workstation except for the Anthropic Claude API and the documentation site, which are remote. There is no cloud infrastructure, CI/CD pipeline, or containerization.

## Diagram

```
Legend:
  [ Person Name ]            Human user or role
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  +---------------------------+          Container / node box
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+          External system (outside boundary)
  ──────────────────────>   label        Relationship (inside boundary)
  ====================>   label          Relationship crossing boundary


+-----------------------------------------------------------------------+
|  Developer's Local Workstation  (Windows 11; also macOS / Linux)      |
|                                                                       |
|  +-----------------------------+                                      |
|  |  Claude Code CLI            |   <- main process                    |
|  |  [Process: Claude Code]     |                                      |
|  +-----------------------------+                                      |
|           |                                                           |
|           | spawns (on-demand, short-lived)                           |
|           v                                                           |
|  +-----------------------------+                                      |
|  |  Subagent Processes (x6)    |   <- during /reverse-engineer        |
|  |  [Process: Claude Code]     |     Phase 2 only                     |
|  +-----------------------------+                                      |
|           |                                                           |
|           | triggers (SubagentStop lifecycle event)                   |
|           v                                                           |
|  +-----------------------------+                                      |
|  |  log-subagent.sh            |   <- transient bash fork             |
|  |  [Script: Bash]             |                                      |
|  +-----------------------------+                                      |
|           |  appends                    |  appends (on failure)       |
|           v                             v                             |
|  +--------------------+    +------------------------+                |
|  |  subagents.log     |    |  subagents-debug.log   |                |
|  |  [File: Log]       |    |  [File: Log]           |                |
|  |  .claude/logs/     |    |  .claude/logs/         |                |
|  +--------------------+    +------------------------+                |
|                                                                       |
|  +-----------------------------+                                      |
|  |  helpers.sh                 |   <- transient bash fork             |
|  |  [Script: Bash]             |     (inline from commands)           |
|  +-----------------------------+                                      |
|                                                                       |
|  (Optional -- not currently active)                                   |
|  +-------------------------+  +----------------------------+          |
|  |  superpowers MCP Server  |  |  Playwright MCP Server    |          |
|  |  [Process: Node.js]      |  |  [Process: Node.js]       |          |
|  |  npm install -g required |  |  user-level config        |          |
|  +-------------------------+  +----------------------------+          |
|                                (.playwright-mcp dir present)          |
|                                                                       |
+-----------------------------------------------------------------------+
         |                                    |
         | all LLM inference (HTTPS)          | spec fetch (HTTPS, on-demand)
         v                                    v
+====================+           +============================+
|  Anthropic         |           |  code.claude.com           |
|  Claude API        |           |  [External: Web Service]   |
|  [External: API]   |           +============================+
+====================+
```

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Developer's Local Workstation | Node | Physical or virtual machine; Windows 11 in this repo's context; also works on macOS/Linux |
| Claude Code CLI | Container on Workstation | Main interactive process; long-lived for the session duration |
| Subagent Processes (x6) | Container on Workstation | Short-lived child processes, present only during `/reverse-engineer` Phase 2 |
| log-subagent.sh | Container on Workstation | Transient bash process forked on each SubagentStop event; exits after writing one log line |
| subagents.log | Container on Workstation | Append-only file at `.claude/logs/subagents.log`; 26 entries recorded |
| subagents-debug.log | Container on Workstation | Fallback log at `.claude/logs/subagents-debug.log`; written on agent_type parse failure; effectively empty |
| helpers.sh | Container on Workstation | Transient bash process forked inline by slash commands; exits after returning output |
| superpowers MCP Server | Container on Workstation (optional) | Node.js process; provides cross-session memory; install with `npm install -g @obra/superpowers`; not currently configured |
| Playwright MCP Server | Container on Workstation (optional) | Node.js process; `.playwright-mcp` directory present at repo root from user-level config; not in project `settings.json` |
| Anthropic Claude API | External System (remote) | Hosted inference API; all LLM calls cross the network over HTTPS |
| code.claude.com | External System (remote) | Claude Code documentation site; accessed over HTTPS only when `/create-command` runs |
| Workstation → Anthropic Claude API | Network path | HTTPS; all reasoning and generation during every session |
| Workstation → code.claude.com | Network path | HTTPS; on-demand spec fetch only |
