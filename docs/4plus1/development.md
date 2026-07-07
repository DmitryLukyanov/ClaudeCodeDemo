# 4+1 — Development View

**What it shows:** How the repository is organized into build units and the dependency
relationships between them. There is no compiled build; the "modules" are directories of
configuration artifacts plus one Python script. The goal is to make the layering
(orchestration → analyzers/renderers → cross-cutting) and the external dependencies visible.
**Audience:** developers navigating the codebase and reviewing dependencies.

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

```
 ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Entry / Docs Layer ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
   .-------------.  .-------------.  .-------------.  .-------------.
 | | CLAUDE.md   |  | README.md   |  | overview.md |  | scripts/    | |
   | <<context>> |  | <<doc>>     |  | <<index>>   |  | *.py driver |
   '-------------'  '-------------'  '-------------'  '-------------' |
 └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                                    | depends on / drives
 ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Orchestration Layer ─ v ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
   .------------------------.   .------------------------.
 | | .claude/commands/      |   | .claude/settings.json  |            |
   | reverse-engineer.md    |   | (wires hooks + plugin) |
 | | create-command.md      |   | <<config>>             |            |
   | <<package>>            |   '------------------------'
 | '------------------------'                                          |
 └ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
          | depends on                            | registers
 ┌ ─ ─ ─ ─ v ─ ─ ─ Worker / Renderer Layer ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
   .------------------.  .------------------.       |
 | | .claude/agents/  |  | .claude/skills/  |       |                  |
   | *.md (6)         |  | <name>/SKILL.md  |       |
 | | <<package>>      |  | (3) <<package>>  |       |                  |
   '------------------'  '------------------'       v
 |                       .------------------.  .------------------.    |
                         | .claude/hooks/   |  | .claude/scripts/ |
 |                       | *.sh (4)         |  | helpers.sh       |    |
                         | <<package>>      |  | <<lib>>          |
 |                       '------------------'  '------------------'    |
                         .------------------.  .------------------.
 |                       | .claude/rules/   |  | .claude/logs/    |    |
                         | *.md <<policy>>  |  | <<generated>>    |
 |                       '------------------'  '------------------'    |
 └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

  External dependencies (all layers):
    scripts/*.py  - - -> claude-agent-sdk (pip, UNPINNED — GAP)
    settings.json - - -> superpowers@claude-plugins-official (plugin, install-time)
    hooks/*.sh    - - -> Node.js (bundled with Claude Code, for `node -e`)
```

## Element & Relationship Key

| Build Unit | Description |
|---|---|
| `CLAUDE.md` `<<context>>` | Project context auto-loaded every session. |
| `README.md` / `overview.md` | Setup doc and the master study-guide index. |
| `scripts/run-reverse-engineer.py` `<<driver>>` | ~95-line Python asyncio driver using `claude_agent_sdk`. |
| `.claude/commands/` `<<package>>` | `reverse-engineer.md` (orchestrator) + `create-command.md` (scaffolder). |
| `.claude/settings.json` `<<config>>` | Wires the four hooks to lifecycle events; enables the superpowers plugin. |
| `.claude/agents/` `<<package>>` | Six read-only subagent definitions (Markdown + YAML frontmatter). |
| `.claude/skills/<name>/SKILL.md` `<<package>>` | Three rendering skills (c4, 4+1, project-overview). |
| `.claude/hooks/` `<<package>>` | Four Bash hook scripts (~200 lines total incl. helpers). |
| `.claude/scripts/helpers.sh` `<<lib>>` | `top-level-listing` + `check-commands` subcommands. |
| `.claude/rules/` `<<policy>>` | `markdown.md`, scoped to `*.broken_md`. |
| `.claude/logs/` `<<generated>>` | Runtime tracker + logs (not source). |

| Dependency | Description |
|---|---|
| driver → `claude-agent-sdk` | pip package, **unpinned** (no `requirements.txt`/`pyproject.toml`/`.python-version` — GAP). |
| settings.json → superpowers plugin | Install-time dependency via `/plugin install superpowers@claude-plugins-official`. |
| hooks → Node.js | Bundled with Claude Code; used for `node -e` JSON parsing. |

## Languages & build

- **Python 3.x** (asyncio, `claude_agent_sdk`) — the driver.
- **Bash/POSIX** — 4 hooks + `helpers.sh`; parse JSON via `node -e`.
- **Markdown + YAML frontmatter** — commands, skills, agents, rules (~1000+ lines).
- **JSON** — `settings.json`, `settings.local.json`.
- **No build system** (no Makefile/manifest). Run interactively with `claude .` then a slash command, or headless with `python scripts/run-reverse-engineer.py [path]`.
- **Model tiers hardcoded in frontmatter:** haiku (tech-stack, external-integrations, deployment-infra), sonnet (module-map, data-flows, runtime-process); `/create-command` uses `claude-sonnet-5`.
