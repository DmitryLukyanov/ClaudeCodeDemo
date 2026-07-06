# 4+1 Development View — ClaudeCodeDemo

The development view shows how the codebase is organized into named build units and the dependency relationships between layers. Because ClaudeCodeDemo is a configuration repository (not compiled code), the "build units" are directories of Markdown and Bash files, each with a distinct architectural role. The layering makes the coupling visible: orchestrators at the top depend downward on fact-gatherers and renderers, which depend on utilities and config at the base. There are no upward dependencies and no circular dependencies.

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


┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  Root Context Layer  (auto-loaded into every session)

│  .-------------------------------------.                               │
   | CLAUDE.md                           |
│  | <<context>>                         |   injected into all sessions   │
   | project purpose + layout            |
│  '-------------------------------------'                               │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                          | injected into
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ v ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  Orchestration Layer  (.claude/commands/)

│  .-----------------------------.   .-----------------------------.      │
   | reverse-engineer.md         |   | create-command.md           |
│  | <<slash-command>>           |   | <<slash-command>>           |      │
   | 4-phase orchestrator        |   | command scaffolder          |
│  | model: sonnet               |   | model: claude-sonnet-5      |      │
   '-----------------------------'   '-----------------------------'
│          |              |                    |                           │
           | spawns       | invokes            | calls
│          |              |                    |                           │
└ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
            |              |                    |
     .------+              +---------.          +----------.
     |                               |                     |
     v                               v                     v
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ ┌ ─ ─ ─ ─ ─ ┐
  Fact-Gathering Layer              Rendering Layer           Utility Layer
  (.claude/agents/)                 (.claude/skills/)         (.claude/
│                               │ │                         │ │ scripts/)  │

  .----------------------.         .----------------------.    .---------.
│ | .claude/agents/       |       │ | .claude/skills/      | │ |helpers.sh|│
  | tech-stack.md        |         | c4-documentation/    |   |<<script>>|
│ | module-map.md        |       │ | 4plus1-documentation/| │ '----------'│
  | external-integrations|         | project-overview/    |
│ | data-flows.md        |       │ | <<skill>>            | └ ─ ─ ─ ─ ─ ─ ┘
  | deployment-infra.md  |         | dual-mode renderers  |
│ | runtime-process.md   |       │ '----------------------' │
  | <<agent>>            |
│ | read-only recon      |       └ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ┘
  '----------------------'                      |
│                               │               | writes to
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘               v
                                        ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
                                          Runtime Output Layer  (docs/)

                                        │  .-----------------------.        │
                                           | docs/                  |
                                        │  | <<package: output>>    |       │
                                           | c4/, 4plus1/,          |
                                        │  | overview.md,           |       │
                                           | COMPARISON.md          |
                                        │  '-----------------------'        │
                                        └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  Hooks / Monitoring Layer  (.claude/hooks/ + .claude/logs/)

│  .-------------------------.      .----------------------------.          │
   | .claude/hooks/           |      | .claude/logs/              |
│  | log-subagent.sh          |      | subagents.log              |         │
   | <<hook>>                 |      | subagents-debug.log        |
│  | SubagentStop listener    |      | <<log>>                    |         │
   '-------------------------'      '----------------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  Constraint Layer  (.claude/rules/ + settings.json)

│  .-------------------------.     .------------------------.               │
   | .claude/rules/           |     | .claude/settings.json  |
│  | markdown.md              |     | <<config>>             |              │
   | <<rule>>                 |     | permissions +          |
│  | **/*.broken_md scope     |     | hook registration      |              │
   '-------------------------'     '------------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

## Element & Relationship Key

| Element | Layer | Description |
|---|---|---|
| CLAUDE.md | Root Context | Injected into every Claude Code session; provides project purpose, feature map, layout |
| `reverse-engineer.md` | Orchestration | Top-level orchestrator; depends on fact-gathering agents and rendering skills |
| `create-command.md` | Orchestration | Command scaffolder; depends on helpers.sh (utility) and external spec fetch |
| `.claude/agents/*.md` (6 files) | Fact-Gathering | Read-only discovery modules; no upward dependencies; return summaries to orchestration layer |
| `.claude/skills/*/SKILL.md` (3 dirs) | Rendering | Documentation renderers; consume fact summaries; write to docs/ |
| `docs/` | Runtime Output | Final output directory; written by rendering layer; not versioned with code |
| `helpers.sh` | Utility | Bash helper called inline by commands; no dependencies on other layers |
| `log-subagent.sh` | Hooks/Monitoring | Bash hook triggered by config layer; writes to logs |
| `.claude/logs/` | Hooks/Monitoring | Append-only logs: subagents.log (26 entries, 24 "unknown") + subagents-debug.log (effectively empty) |
| `markdown.md` | Constraint | Path-scoped rule injected automatically by Claude Code on file path match |
| `settings.json` | Constraint | Permissions whitelist + hook registration; configures utility hook layer |
| Layer rule | — | No upward dependencies: fact-gathering never calls rendering; rendering never calls agents; utility never calls orchestration |
