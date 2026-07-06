# C4 L2 — Container: ClaudeCodeDemo

This view zooms into the ClaudeCodeDemo system boundary and shows every separately runnable unit. Because this is a Claude Code configuration repository rather than a deployed application, the "containers" are the runtime processes the Claude Code platform creates: the main CLI process, the short-lived subagent child processes it spawns, and the bash scripts it forks as lifecycle hooks and inline helpers. The two append-only audit logs are included as data stores.

## Diagram

```
Legend:
  [ Person Name ]            Human user or role
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  +---------------------------+          Container box
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+          External system (outside boundary)
  ──────────────────────>   label        Relationship (inside boundary)
  ====================>   label          Relationship crossing boundary


[ Developer ]
      |
      | invokes commands / views output
      v
+--------------------------------------------------------------------+  (System boundary)
|                                                                    |
|  +--------------------------------+                               |
|  |  Claude Code CLI               |                               |
|  |  [Process: Claude Code]        |                               |
|  +--------------------------------+                               |
|       |              |        |                                   |
|       | spawns       | forks  | forks (bash inline)               |
|       | (Agent tool) | on     |                                   |
|       | 6 concurrent | Subagt |                                   |
|       |              | Stop   v                                   |
|       |              |  +--------------------+                   |
|       |              |  |  helpers.sh        |                   |
|       |              |  |  [Script: Bash]    |                   |
|       |              |  +--------------------+                   |
|       |              v                                            |
|       |       +--------------------+                             |
|       |       |  log-subagent.sh   |                             |
|       |       |  [Script: Bash]    |                             |
|       |       +--------------------+                             |
|       |             |          |  appends                        |
|       |             |          v                                  |
|       |             |  +--------------------+                   |
|       |             |  |  subagents.log     |                   |
|       |             |  |  [File: Log]       |                   |
|       |             |  |  26 entries        |                   |
|       |             |  +--------------------+                   |
|       |             |                                            |
|       |             | appends (on parse failure)                 |
|       |             v                                            |
|       |     +----------------------+                             |
|       |     |  subagents-debug.log |                             |
|       |     |  [File: Log]         |                             |
|       |     |  (effectively empty) |                             |
|       |     +----------------------+                             |
|       |                                                          |
|       | spawns 6 concurrently (Phase 2)                          |
|       v                                                          |
|  +--------------------------------+                              |
|  |  Subagent Process (×6)         |                              |
|  |  [Process: Claude Code child]  |                              |
|  |  haiku: tech-stack,            |                              |
|  |         external-integrations, |                              |
|  |         deployment-infra       |                              |
|  |  sonnet: module-map,           |                              |
|  |          data-flows,           |                              |
|  |          runtime-process       |                              |
|  +--------------------------------+                              |
|       |  returns compact summaries                               |
|       +---------> Claude Code CLI                                |
|                                                                  |
+--------------------------------------------------------------------+
          |                             |
          | all LLM calls (HTTPS)       | spec fetch (HTTPS)
          v                             v
  +====================+    +==========================+
  |  Anthropic         |    |  code.claude.com         |
  |  Claude API        |    |  [External: Web Service] |
  |  [External: API]   |    +==========================+
  +====================+
```

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Claude Code CLI | Container [Process: Claude Code] | Main interactive process; reads `CLAUDE.md` + `settings.json` at startup; executes slash commands, invokes agents and skills, applies rules, dispatches hooks |
| Subagent Process (×6) | Container [Process: Claude Code child] | Short-lived child processes spawned via the Agent tool; during `/reverse-engineer` Phase 2, six run concurrently; haiku model for fast structural scans, sonnet for deep analysis |
| log-subagent.sh | Container [Script: Bash] | Bash child process forked by the SubagentStop lifecycle hook; reads agent completion JSON from stdin and appends an audit line to subagents.log; exits immediately after |
| helpers.sh | Container [Script: Bash] | Bash child process forked by slash commands; two subcommands: `check-commands` (lists existing command files) and `top-level-listing` (ls -la on a path) |
| subagents.log | Container [File: Log] | Append-only audit trail at `.claude/logs/subagents.log`; 26 entries as of 2026-07-07; one TSV line per agent completion: `<ISO8601>\t<agent_type>` (24 show "unknown" due to hook parse bug) |
| subagents-debug.log | Container [File: Log] | Fallback log at `.claude/logs/subagents-debug.log`; written when `agent_type` extraction fails; effectively empty (parse failure branch not triggering as expected) |
| Anthropic Claude API | External System | All LLM inference; CLI and all subagent processes communicate with it over HTTPS |
| code.claude.com | External System | Slash-command spec documentation; fetched by CLI only when `/create-command` runs |
| CLI → Subagent Process | Relationship | Spawns 6 concurrently via Agent tool; passes codebase root + orientation; receives compact summaries |
| CLI → log-subagent.sh | Relationship | Forks on SubagentStop for the 6 named agent types; pipes event JSON to stdin |
| CLI → helpers.sh | Relationship | Forks as bash-inline call; passes subcommand argument; receives stdout |
| log-subagent.sh → subagents.log | Relationship | Appends one TSV audit line per invocation |
| log-subagent.sh → subagents-debug.log | Relationship | Appends raw JSON payload when agent_type extraction yields empty string |
| Subagent Process → CLI | Relationship | Returns compact summary text to main context |
| CLI → Anthropic Claude API | Relationship | All LLM calls over HTTPS (command execution, agent reasoning, skill rendering) |
| CLI → code.claude.com | Relationship | Spec fetch over HTTPS; invoked only by `/create-command` |
