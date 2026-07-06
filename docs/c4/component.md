# C4 L3 — Component: ClaudeCodeDemo

This view zooms into the Claude Code CLI container — the only container with significant internal structure. It shows the major logical components that make up Claude Code's runtime behavior for this repository: the parts that execute commands, spawn agents, invoke skills, enforce rules, dispatch hooks, and load configuration. The other containers (subagent processes, bash scripts, log files) are simple enough to be fully described by their L2 entries.

## Diagram — Claude Code CLI (internal components)

```
Legend:
  [ Person Name ]            Human user or role
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  |  Short responsibility      |
  +---------------------------+          Component box
  ──────────────────────>   label        Relationship (inside boundary)
  ====================>   label          Relationship crossing boundary


+--------------------------------------------------------------------------+
|  Claude Code CLI                                                         |
|                                                                          |
|  +---------------------------+     +------------------------------+     |
|  |  Settings Loader          |     |  Slash Command Executor      |     |
|  |  reads CLAUDE.md +        |     |  parses /command-name,       |     |
|  |  settings.json at startup |     |  substitutes $ARGUMENTS,     |     |
|  +---------------------------+     |  runs command body           |     |
|           |                        +------------------------------+     |
|           | config                        |              |              |
|           v                               |              |              |
|  +---------------------------+            |              |              |
|  |  Rule Engine              |            |              |              |
|  |  injects rules when path  |<-- active  |              |              |
|  |  matches glob             |    file    |              |              |
|  +---------------------------+            |              |              |
|                                           |              |              |
|           +------------------------------>+              |              |
|           |  /reverse-engineer (Phase 2)                 |              |
|           v                                              |              |
|  +---------------------------+                           |              |
|  |  Agent Spawner            |                           |              |
|  |  fans out 6 background    |                           |              |
|  |  subagents concurrently   |                           |              |
|  +---------------------------+                           |              |
|           |  6 compact summaries                         |              |
|           v                              /reverse-engineer|              |
|  +---------------------------+          (Phase 3)        |              |
|  |  Skill Invoker            |<--------------------------+              |
|  |  sequentially invokes 3   |                                          |
|  |  documentation skills     |                                          |
|  +---------------------------+                                          |
|                                                                          |
|  +---------------------------+                                          |
|  |  Hook Dispatcher          |                                          |
|  |  fires log-subagent.sh    |                                          |
|  |  on SubagentStop events   |                                          |
|  +---------------------------+                                          |
|                                                                          |
+--------------------------------------------------------------------------+
            |                    |                  |
            | LLM calls          | spec fetch       | SubagentStop
            | (HTTPS)            | (HTTPS)          | hook fork
            v                    v                  v
      Anthropic API        code.claude.com    log-subagent.sh
```

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Settings Loader | Component | Reads `CLAUDE.md` (project context) and `.claude/settings.json` (permissions + hooks) automatically at session start; makes config available to all other components |
| Slash Command Executor | Component | Parses `/command-name [args]` invocations; loads the matching `.claude/commands/*.md` file; substitutes `$ARGUMENTS` placeholder; hands the rendered prompt to Claude for execution |
| Rule Engine | Component | Monitors the active file path; when it matches a glob in a rule's frontmatter (e.g. `**/*.broken_md`), injects the rule body into Claude's context to constrain output |
| Agent Spawner | Component | Used by `/reverse-engineer` Phase 2; issues six concurrent `Agent` tool calls with `background: true`; collects all six compact summaries before Phase 3 begins |
| Skill Invoker | Component | Used by `/reverse-engineer` Phase 3; sequentially invokes `c4-documentation`, `4plus1-documentation`, and `project-overview` skills, passing the merged fact set; enforces facts-supplied mode (no re-scan) |
| Hook Dispatcher | Component | Watches for `SubagentStop` lifecycle events matching the regex `tech-stack\|module-map\|external-integrations\|data-flows\|deployment-infra\|runtime-process`; forks `log-subagent.sh` with event JSON piped to stdin |
| Settings Loader → all | Relationship | Provides CLAUDE.md context and settings.json permissions/hooks config to all runtime components at startup |
| Slash Command Executor → Agent Spawner | Relationship | `/reverse-engineer` delegates Phase 2 fan-out |
| Agent Spawner → Skill Invoker | Relationship | Passes six compact summaries (merged into one fact set) for Phase 3 rendering |
| Slash Command Executor → Skill Invoker | Relationship | `/reverse-engineer` drives the Skill Invoker for Phase 3 steps A, B, C |
| Hook Dispatcher → log-subagent.sh | Relationship | Forks the bash hook script with event JSON on each matching SubagentStop |
| Rule Engine ← active file | Relationship | Activates when the file being written/edited matches the rule's path glob |
