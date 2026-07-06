# 4+1 Logical View — ClaudeCodeDemo

The logical view shows the key abstractions that make up ClaudeCodeDemo and the structural relationships between them. The system is composed of two orchestrator commands, six fact-gathering agents, three documentation-rendering skills, one behavioral rule, one audit hook, a utility script, and configuration artifacts. This view is for developers and architects reasoning about how components relate and which one owns what responsibility.

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


(( Developer ))
      |
      | invokes
      v
.----------------------------.       .-------------------------.
| reverse-engineer           |       | create-command          |
| <<slash-command>>          |       | <<slash-command>>       |
'----------------------------'       '-------------------------'
      |                                       |
      | spawns (Phase 2, concurrent)          | calls
      |                                       v
      |   .-------------------.        .---------------------.
      |   | tech-stack        |        | helpers.sh          |
      |   | <<agent>>         |        | <<script>>          |
      |   '-------------------'        '---------------------'
      |   .-------------------.               ^
      |   | module-map        |               |
      |   | <<agent>>         |               | calls (Phase 1)
      |   '-------------------'               |
      +---.----------------------------.-------+
      |   | external-integrations      |
      |   | <<agent>>                  |
      |   '----------------------------'
      |   .-------------------.
      |   | data-flows        |
      |   | <<agent>>         |
      |   '-------------------'
      |   .-------------------.
      |   | deployment-infra  |
      |   | <<agent>>         |
      |   '-------------------'
      |   .-------------------.
      |   | runtime-process   |
      |   | <<agent>>         |
      |   '-------------------'
      |
      | invokes (Phase 3, sequential)
      v
.-------------------------.   .-------------------------.   .-------------------------.
| c4-documentation        |   | 4plus1-documentation    |   | project-overview        |
| <<skill>>               |   | <<skill>>               |   | <<skill>>               |
'-------------------------'   '-------------------------'   '-------------------------'

Always-active abstractions:

.-------------------------.      .-------------------------.
| CLAUDE.md               |      | settings.json           |
| <<context>>             |      | <<config>>              |
| auto-injected into      |      | permissions +           |
| every session           |      | hook registration       |
'-------------------------'      '-------------------------'
                                        |
                                        | triggers on SubagentStop
                                        v
                                 .-------------------------.
                                 | log-subagent.sh         |
                                 | <<hook>>                |
                                 | audits agent            |
                                 | completions             |
                                 '-------------------------'

.-------------------------.      .-------------------------.
| markdown rule           |      | settings.local.json     |
| <<rule>>                |      | <<config: local>>       |
| enforces ordinal text   |      | accumulated debug       |
| in **/*.broken_md       |      | bash permissions        |
'-------------------------'      '-------------------------'
```

## Element & Relationship Key

| Element | Stereotype | Description |
|---|---|---|
| reverse-engineer | `<<slash-command>>` | Primary orchestrator; drives 4-phase reverse-engineering workflow; only component allowed to spawn agents and invoke skills |
| create-command | `<<slash-command>>` | Scaffolds new slash command `.md` files from CLI arguments; fetches live spec; checks for filename collisions |
| tech-stack | `<<agent>>` | Read-only fact-gatherer; returns languages, frameworks, build/run commands, runtime versions; model: haiku |
| module-map | `<<agent>>` | Read-only fact-gatherer; maps internal components, responsibilities, call-graph; model: sonnet |
| external-integrations | `<<agent>>` | Read-only fact-gatherer; identifies external APIs, datastores, auth providers; model: haiku |
| data-flows | `<<agent>>` | Read-only fact-gatherer; traces end-to-end flows through the system; model: sonnet |
| deployment-infra | `<<agent>>` | Read-only fact-gatherer; determines deployment topology, containers, CI/CD; model: haiku |
| runtime-process | `<<agent>>` | Read-only fact-gatherer; analyzes runtime processes, concurrency, scheduled jobs; model: sonnet |
| c4-documentation | `<<skill>>` | Renders C4 L1–L3 + Deployment diagrams into `docs/c4/`; dual-mode (facts-supplied or standalone) |
| 4plus1-documentation | `<<skill>>` | Renders Kruchten 4+1 views into `docs/4plus1/`; dual-mode |
| project-overview | `<<skill>>` | Renders `docs/overview.md`; dual-mode |
| CLAUDE.md | `<<context>>` | Passively injects project purpose and layout into every Claude Code session |
| settings.json | `<<config>>` | Declares allowed bash permissions and registers the SubagentStop hook |
| settings.local.json | `<<config: local>>` | Local-only debug permissions accumulated from interactive sessions; not committed |
| log-subagent.sh | `<<hook>>` | SubagentStop listener for the 6 named agent types; appends TSV audit line to subagents.log |
| markdown rule | `<<rule>>` | Path-scoped to `**/*.broken_md`; enforces ordinal text in ordered lists |
| helpers.sh | `<<script>>` | Two subcommands: `check-commands` (list existing command files) and `top-level-listing` (ls -la on a path) |
| reverse-engineer → 6 agents | Relationship | Spawns all six concurrently (Phase 2, background:true) |
| reverse-engineer → 3 skills | Relationship | Invokes sequentially (Phase 3), passing merged fact set |
| reverse-engineer → helpers.sh | Relationship | Calls `top-level-listing` inline during Phase 1 |
| create-command → helpers.sh | Relationship | Calls `check-commands` inline for collision detection |
| settings.json → log-subagent.sh | Relationship | Triggers on SubagentStop for the 6 named agent types |
