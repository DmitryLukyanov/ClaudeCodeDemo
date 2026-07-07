# 4+1 — Physical View

**What it shows:** The deployment topology. ClaudeCodeDemo runs entirely on a single **local
machine** — a developer workstation or a CI runner — with no servers, containers, or cloud
infrastructure. The only network edge leaves the machine to reach the Anthropic API. There are
two execution modes (interactive and headless) that share the same on-disk state.
**Audience:** anyone setting up or automating the repo; there is no ops/security surface beyond
the local machine and one HTTPS egress.

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
  Local Zone (developer workstation / CI runner — tested Windows 11)
  ───────────────────────────────────────────────────────────────────
  (( Developer ))            (( CI / Automation ))
        |  claude .                |  python run-reverse-engineer.py
        v                          v
  [[ Claude Code Runtime        ]]      [[ Python Process (asyncio)   ]]
     runs: Orchestrator session,          runs: SDK driver
     6 subagents, 4 hook subprocs          (setting_sources=["project"])
        |         ^                               |
        |         | reads/writes                  | in-process (SDK query)
        |         v                               |
        |   [[ On-disk State            ]]        |
        |     .claude/ (settings, cmds,           |
        |     skills, agents, hooks, rules,       |
        |     logs), docs/, scripts/              |
        |                                         |
  ──────|─────────────────────────────────────────|─── Network boundary ───
        |  HTTPS :443 (agent loop)                 |  HTTPS :443 (SDK)
        v                                          v
  [[ Anthropic API (Claude models)                                    ]]
     external SaaS — auth via ANTHROPIC_API_KEY or `claude auth`
```

## Element & Relationship Key

| Node | Description |
|---|---|
| `[[ Claude Code Runtime ]]` | Interactive host process started with `claude .`. Loads `CLAUDE.md`, `settings.json` (hooks + `enabledPlugins`), rules, commands, skills, agents. Hosts the orchestrator session, the six subagents, and the four hook subprocesses. superpowers plugin installed once via `/plugin install`. |
| `[[ Python Process (asyncio) ]]` | Headless entry point `run-reverse-engineer.py`. Requires `pip install claude-agent-sdk` + `ANTHROPIC_API_KEY`/`claude auth`. Runs with `setting_sources=["project"]`, `$6` budget cap; exit code 0/1 per `ResultMessage.subtype`. |
| `[[ On-disk State ]]` | The repo working tree: `.claude/` (config, hooks, rules, logs), `docs/` (rendered output), `scripts/`. Shared by both runtimes — concurrent runs could interleave `.claude/logs/*` writes (no locking). |
| `[[ Anthropic API ]]` | The single remote node; Claude model inference over HTTPS. |

| Network Edge | Description |
|---|---|
| Claude Code Runtime → Anthropic API | HTTPS agent-loop traffic (interactive mode). |
| Python Process → Anthropic API | HTTPS via `claude_agent_sdk.query()` (headless mode). |
| Runtimes ↔ On-disk State | Local file I/O (config load, doc writes, log/tracker updates). |

## Notes / Gaps

- **No servers, containers, orchestration, CI/CD, or IaC** — confirmed absent. "Deployment" means *loading project settings on a local machine*.
- **Windows 11 tested** — hook scripts normalize `\` → `/` via `tr` for path matching.
- **MCP servers** are a documented physical-integration extension point (`overview.md` §7) but none are configured.
