# 4+1 — Logical View

**What it shows:** The functional decomposition of ClaudeCodeDemo — the key abstractions and
their structural relationships. This system has no application classes; its "components" are
Claude Code configuration artifacts. The design is a **command-orchestrator fan-out/fan-in
pipeline**: one command owns all coordination, while fact-gathering agents and rendering
skills are peers that never call each other (an enforced acyclic dependency: command→agents,
command→skills). Cross-cutting concerns live as declarative hooks. **Audience:** developers
and architects reasoning about the design's structure and maintainability.

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
        (( Developer / User ))                 (( CI / Automation ))
                 |                                      |
                 | invokes                              | drives (SDK)
                 v                                      v
        .------------------------.          .------------------------.
        | /reverse-engineer      |          | run-reverse-engineer.py|
        | <<orchestrator command>>|<- - - - -| <<driver>>            |
        '------------------------'  starts   '------------------------'
           |                 |
           | spawns          | invokes
           v                 v
  .------------------.   .------------------.        .---------------------.
  | 6 Fact-Gathering |   | 3 Rendering      |        | /create-command     |
  | Subagents        |   | Skills           |        | <<orchestrator cmd>>|
  | <<analyzer x6>>  |   | <<renderer x3>>  |        '---------------------'
  '------------------'   '------------------'           |          |
     (read-only)         (write docs/)                  | WebFetch | check-commands
                                                        v          v
  .......... cross-cutting (declarative) ..........  (( code.claude.com ))  helpers.sh
  .------------------.        .------------------.
  | 4 Lifecycle Hooks|- - - ->| Shared Tracker / |
  | <<hook x4>>      | append | Log Files        |
  '------------------'        | <<shared state>> |
                              '------------------'
  .------------------.
  | markdown rule    |  (scoped to *.broken_md — ordinal ordered lists)
  | <<policy>>       |
  '------------------'
```

## Element & Relationship Key

| Element | Description |
|---|---|
| `(( Developer / User ))` | Human invoking slash commands inside a Claude Code session. |
| `(( CI / Automation ))` | Non-interactive caller of the Python driver. |
| `/reverse-engineer <<orchestrator command>>` | The 4-phase pipeline; the **only** component allowed to spawn subagents or invoke skills. |
| `run-reverse-engineer.py <<driver>>` | Starts the orchestrator headlessly via the Agent SDK. |
| `/create-command <<orchestrator cmd>>` | Secondary command that scaffolds new slash commands. |
| `6 Fact-Gathering Subagents <<analyzer>>` | tech-stack, module-map, external-integrations, data-flows, deployment-infra, runtime-process. Read-only; return fixed-schema summaries. |
| `3 Rendering Skills <<renderer>>` | c4-documentation, 4plus1-documentation, project-overview. Consume merged facts; write docs; never call subagents or each other. |
| `4 Lifecycle Hooks <<hook>>` | log-subagent, guard-reverse-engineer-docs, turn-start, turn-complete. Declarative cross-cutting behavior wired in settings.json. |
| `Shared Tracker / Log Files <<shared state>>` | `.claude/logs/` — coordination channel (tracker + logs), not in-process state. |
| `markdown rule <<policy>>` | `.claude/rules/markdown.md` — behavior constraint scoped to `*.broken_md` files (ordered lists as ordinal text). |

| Relationship | Description |
|---|---|
| Driver - -> command | The Python driver starts the orchestrator via SDK `query()`. |
| command → subagents | Spawns the six analyzers (fan-out). |
| command → skills | Invokes the three renderers (fan-in synthesis). |
| /create-command → code.claude.com / helpers.sh | Fetches live docs (WebFetch) and lists existing commands (check-commands). |
| hooks - -> shared state | Hooks append to / read the tracker and logs. |

**Enforced acyclic structure:** agents and skills are siblings; neither depends on the other, and neither calls back into the command. All coordination flows one way (command → peers), with hooks observing lifecycle events out-of-band.
