# 4+1 Development View — ClaudeCodeDemo

The development view shows how the repository is organized as source units and how those units depend on each other. ClaudeCodeDemo has no build system — there are no compiled artifacts or package manifests. The "build units" are directories of Markdown files and Bash scripts, layered by how Claude Code consumes them: foundational configuration at the bottom, feature artifacts (commands, skills, agents, hooks) in the middle, and generated output at the top. Understanding this layering is important because editing a lower layer affects all higher layers that depend on it.

---

## Legend

```
Actors / External Agents
  (( Actor Name ))              human user, external system, or timer

Component / Object / Subsystem
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
```

---

## Diagram

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Output Layer (generated; not source-controlled) ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .-------------------------.     .-------------------------.     .-------------------------.
  | docs/c4/                |     | docs/4plus1/            |     | docs/overview.md        |
  | <<output>>              |     | <<output>>              |     | <<output>>              |
  | 4 C4 diagram files      |     | 5 Kruchten 4+1 files    |     | Standalone overview     |
  '-------------------------'     '-------------------------'     '-------------------------'
  .------------------------------.
  | docs/COMPARISON.md           |
  | <<output>>                   |
  | C4 vs 4+1 comparison         |
  '------------------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                ^ written by skills                      ^ written by orchestrator

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Feature Layer ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  ┌ ─ ─ ─ Commands ─ ─ ─ ─ ─ ┐  ┌ ─ ─ ─ Skills ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
    .---------------------.         .-------------------------.
    | .claude/commands/   |         | .claude/skills/         |
    | <<package>>         |         | c4-documentation/       |
    |                     |         | <<package>>             |
    | reverse-engineer.md |         | SKILL.md                |
    | create-command.md   |         '-------------------------'
    '---------------------'         .-------------------------.
                                    | .claude/skills/         |
                                    | 4plus1-documentation/   |
                                    | <<package>>             |
                                    | SKILL.md                |
                                    '-------------------------'
                                    .-------------------------.
                                    | .claude/skills/         |
                                    | project-overview/       |
                                    | <<package>>             |
                                    | SKILL.md                |
                                    '-------------------------'
  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

  ┌ ─ ─ ─ Agents ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐  ┌ ─ ─ ─ Hooks ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
    .-------------------------.                                  .-------------------------.
    | .claude/agents/         |                                  | .claude/hooks/          |
    | <<package>>             |                                  | <<package>>             |
    |                         |                                  |                         |
    | tech-stack.md           |                                  | log-subagent.sh         |
    | module-map.md           |                                  | guard-reverse-          |
    | external-integrations.md|                                  |   engineer-docs.sh      |
    | data-flows.md           |                                  | turn-start.sh           |
    | deployment-infra.md     |                                  | turn-complete.sh        |
    | runtime-process.md      |                                  '-------------------------'
    '-------------------------'
  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

  ┌ ─ ─ ─ Rules ─ ─ ─ ─ ─ ─ ─ ┐  ┌ ─ ─ ─ Shared Scripts ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
    .---------------------.          .-------------------------.
    | .claude/rules/      |          | .claude/scripts/        |
    | <<package>>         |          | <<lib>>                 |
    | markdown.md         |          | helpers.sh              |
    '---------------------'          | (top-level-listing,     |
                                     |  check-commands)        |
                                     '-------------------------'
  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
     |           |            |              |              |
     | depend on the Foundation Layer (all feature layer dirs implicitly read foundation config)

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Foundation Layer ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .-------------------------.     .-------------------------.     .-------------------------.
  | CLAUDE.md               |     | .claude/settings.json  |     | overview.md             |
  | <<context>>             |     | <<config>>             |     | <<guide>>               |
  | Session context for     |     | Hook registrations,    |     | Human-readable study    |
  | every turn              |     | bash permissions       |     | guide                   |
  '-------------------------'     '-------------------------'     '-------------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

---

## Element & Relationship Key

| Package / Unit | Stereotype | Contents |
|---|---|---|
| CLAUDE.md | `<<context>>` | Project context injected into every session |
| settings.json | `<<config>>` | Hook registrations, bash permissions — read by Claude Code at startup |
| overview.md | `<<guide>>` | Master study guide; not read by Claude Code programmatically |
| .claude/commands/ | `<<package>>` | `reverse-engineer.md`, `create-command.md` — user-invokable slash commands |
| .claude/skills/c4-documentation/ | `<<package>>` | `SKILL.md` — skill invoked to render C4 docs |
| .claude/skills/4plus1-documentation/ | `<<package>>` | `SKILL.md` — skill invoked to render 4+1 docs |
| .claude/skills/project-overview/ | `<<package>>` | `SKILL.md` — skill invoked to render project overview |
| .claude/agents/ | `<<package>>` | Six agent definition files — each defines a background sub-agent |
| .claude/hooks/ | `<<package>>` | Four bash scripts — forked by Claude Code on lifecycle events |
| .claude/rules/ | `<<package>>` | `markdown.md` — path-scoped behavioral constraint |
| .claude/scripts/ | `<<lib>>` | `helpers.sh` — shared bash library used by commands and hooks |
| docs/c4/ | `<<output>>` | Generated C4 diagrams (4 files); not source-controlled by convention |
| docs/4plus1/ | `<<output>>` | Generated 4+1 views (5 files) |
| docs/overview.md | `<<output>>` | Generated project overview |
| docs/COMPARISON.md | `<<output>>` | C4 vs 4+1 comparison written by orchestrator directly |

| Dependency | Direction | Description |
|---|---|---|
| commands → foundation | commands depend on | `reverse-engineer.md` reads CLAUDE.md context; `create-command.md` reads settings-permitted helpers.sh |
| commands → agents | commands spawn | `reverse-engineer.md` spawns all 6 agents in Phase 2 |
| commands → skills | commands invoke | `reverse-engineer.md` invokes 3 skills in Phase 3 |
| commands → scripts | commands use | `create-command.md` calls `helpers.sh check-commands`; `reverse-engineer.md` calls `helpers.sh top-level-listing` |
| hooks → scripts | hooks use | `guard-reverse-engineer-docs.sh` and `log-subagent.sh` use Node.js JSON parsing (bundled in CLI) |
| hooks → foundation | hooks registered by | `settings.json` registers all 4 hooks |
| skills → output | skills write | Each skill uses the Write tool to produce files in `docs/` |
| commands → output | commands write | `reverse-engineer.md` writes `docs/COMPARISON.md` directly |

---

## Notes

- There is **no enforced layering boundary** at the file system level — nothing prevents a skill from importing a hook or a command from bypassing the foundation. Layering is a design convention, not a technical constraint.
- `docs/` is **committed to the repo** — generated output is source-controlled, unlike `.claude/logs/` which is git-ignored.
- External dependency: the `create-command` command has a soft runtime dependency on `code.claude.com` (spec fetch); this is not declared in any manifest.
