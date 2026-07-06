# 4+1 Physical View — ClaudeCodeDemo

The physical view shows the infrastructure topology: the real nodes where processes run, the network zones between them, and which processes from the process view are hosted on each node. ClaudeCodeDemo has one of the simplest possible physical topologies — everything runs on the developer's local workstation except for the Anthropic Claude inference API and the documentation site, which are remote and not operator-managed. There is no cloud infrastructure, no containers (in the Docker/OCI sense), no CI/CD pipeline, and no multi-environment deployment. This view is for DevOps and security reviewers asking "where does each piece actually run and what crosses the network?"

## Diagram

```
Legend:
  (( Actor Name ))              human user, external system, or timer

  .-----------------------.
  | Name                  |
  | <<stereotype>>        |    stereotype: service, module, subsystem, controller, etc.
  '-----------------------'

  Infrastructure Node  (Physical view only)
  [[ Node Name                ]]

  Relationships
  ─────────────────>   label          synchronous call / association
  - - - - - - - - ->   label          dependency / uses / sends-to (async)
  ════════════════>   label          IPC / queue message / event


═══════════════════════════════════════════════════════════════
  Developer's Local Machine  (Windows 11; also macOS / Linux)
═══════════════════════════════════════════════════════════════

  [[ Developer Workstation                                     ]]
  |                                                             |
  |   .-----------------------------------.                     |
  |   | Claude Code CLI                   |                     |
  |   | <<process: Claude Code>>          |    long-lived,      |
  |   | Main session process              |    one per session  |
  |   '-----------------------------------'                     |
  |           |                    |                            |
  |           | spawns (Agent)     | forks (bash inline /       |
  |           |   6 concurrent     |   SubagentStop event)      |
  |           v                    v                            |
  |   .----------------.   .-----------------.                  |
  |   | Subagent (x6)  |   | log-subagent.sh |                  |
  |   | <<process:     |   | <<process: Bash>|   transient;     |
  |   | Claude child>> |   | Audit writer    |   one fork per   |
  |   '----------------'   '-----------------'   agent event    |
  |                               |         |                   |
  |                        appends|         | appends (failure) |
  |                               v         v                   |
  |                    .------------.  .----------------.        |
  |                    |subagents   |  |subagents-debug |        |
  |                    |.log        |  |.log            |        |
  |                    '------------'  '----------------'        |
  |                                                             |
  |   .-----------------------------------.                     |
  |   | helpers.sh                        |                     |
  |   | <<process: Bash>>                 |    transient;       |
  |   | CLI inline helper                 |    exits after      |
  |   '-----------------------------------'    one call         |
  |                                                             |
  |   (Optional — not currently active)                         |
  |   .--------------------.  .--------------------.           |
  |   | superpowers MCP     |  | Playwright MCP     |          |
  |   | <<process: Node.js>>|  | <<process: Node.js>|          |
  |   | npm install -g      |  | .playwright-mcp/   |          |
  |   | not installed       |  | dir present at root|          |
  |   '--------------------'  '--------------------'           |
  |                                                             |
  [[___________________________________________________________]]

              |                              |
              | All LLM inference            | Spec fetch
              | (HTTPS)                      | (HTTPS, on-demand)
              | [always active in session]   | [/create-command only]
              v                              v

═══════════════════════════════════════════════════════════════════════
  Remote Infrastructure  (Anthropic-managed; not operator-managed)
═══════════════════════════════════════════════════════════════════════

  [[ Anthropic Claude API                         ]]
  |   Hosted LLM inference                         |
  |   All Claude Code models run here              |
  [[_______________________________________________]]

  [[ code.claude.com                              ]]
  |   Claude Code documentation site              |
  |   HTTPS only, on-demand                       |
  [[_______________________________________________]]
```

## Element & Relationship Key

| Element | Node | Description |
|---|---|---|
| Developer Workstation | Local | Windows 11 Enterprise in this repo's context; also macOS/Linux |
| Claude Code CLI | Workstation | Main session process; long-lived; reads CLAUDE.md + settings.json at startup |
| Subagent (×6) | Workstation | Short-lived child processes; Phase 2 of /reverse-engineer only; isolated context windows |
| log-subagent.sh | Workstation | Transient bash child; fires per SubagentStop; writes one line then exits |
| subagents.log | Workstation | `.claude/logs/subagents.log`; 26 entries; 24 with "unknown" agent_type (hook bug) |
| subagents-debug.log | Workstation | `.claude/logs/subagents-debug.log`; fallback for parse failures; effectively empty |
| helpers.sh | Workstation | Transient bash child; forked inline by command templates |
| superpowers MCP | Workstation (optional) | Node.js; `npm install -g @obra/superpowers`; not currently installed or registered |
| Playwright MCP | Workstation (optional) | Node.js; `.playwright-mcp/` directory present at repo root (user-level config); not in project `settings.json` |
| Anthropic Claude API | Remote (Anthropic-managed) | Hosted LLM inference; all CLI and subagent processes use it over HTTPS |
| code.claude.com | Remote (Anthropic-managed) | Documentation site; HTTPS; on-demand by `/create-command` only |
| Workstation → Anthropic API | Network | HTTPS; always active during a session; all LLM calls |
| Workstation → code.claude.com | Network | HTTPS; on-demand; `/create-command` only |
| No CI/CD | — | No pipeline, no cloud deployment, no multi-environment config |
| No containers | — | No Docker or OCI containers; all processes are native OS processes |
