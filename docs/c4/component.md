# C4 Level 3 — Component: ClaudeCodeDemo

At the component level, the Config Repository container breaks into five functional groups: project context, commands (orchestrators), skills (renderers), agents (fact-gatherers), and hooks (side-channel enforcement). Session Logs and Generated Docs have no internal logic worth decomposing — they are passive write targets.

---

## Legend

```
People / Actors
  [ Person Name ]           Human user or role

System / Container / Component boxes
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  |  Short responsibility      |
  +---------------------------+

Relationships (inside system boundary)
  ──────────────────────>   label: protocol or action

Relationships crossing the system boundary
  ====================>   label: protocol or action

External systems (outside boundary)
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+
```

---

## Diagram: Config Repository (internal components)

```
+=====================================================================+
|  Config Repository                                                   |
|                                                                      |
|  +------------------------+   +-----------------------------+        |
|  |  Project Context       |   |  Commands                   |        |
|  |  CLAUDE.md             |   |  [Markdown templates]       |        |
|  |  Injected into every   |   |  User-invoked workflows     |        |
|  |  session as context    |   |                             |        |
|  |                        |   |  reverse-engineer.md        |        |
|  |  overview.md           |   |  4-phase orchestrator:      |        |
|  |  Human-readable study  |   |  inventory → 6 agents →     |        |
|  |  guide, 9 feature demos|   |  3 skills → verify          |        |
|  +------------------------+   |                             |        |
|                                |  create-command.md          |        |
|  +------------------------+   |  Scaffolds new commands     |        |
|  |  Rules                 |   |  from user arguments        |        |
|  |  [Markdown, path-scoped]|  +-----------------------------+        |
|  |  Behavior constraints  |          |             |                 |
|  |  auto-applied by CLI   |   spawns (Agent)   invokes (Skill)      |
|  |                        |          |             |                 |
|  |  markdown.md           |          v             v                 |
|  |  Ordinal list style    |   +----------+  +------------------+     |
|  |  for *.broken_md files |   |  Agents  |  |  Skills          |     |
|  +------------------------+   |  [Markdown|  |  [Markdown]      |     |
|                                |  +bash]  |  |  Documentation   |     |
|  +------------------------+   |          |  |  renderers       |     |
|  |  Hooks                 |   | tech-    |  |                  |     |
|  |  [Bash scripts]        |   | stack    |  | c4-documentation |     |
|  |  Lifecycle enforcement |   | module-  |  | Writes docs/c4/  |     |
|  |  and audit logging     |   | map      |  |                  |     |
|  |                        |   | external-|  | 4plus1-          |     |
|  | log-subagent.sh        |   | integrat.|  | documentation    |     |
|  |   SubagentStop →       |   | data-    |  | Writes           |     |
|  |   writes tracker +     |   | flows    |  | docs/4plus1/     |     |
|  |   subagents.log        |   | deploy-  |  |                  |     |
|  |                        |   | ment-    |  | project-overview |     |
|  | guard-reverse-         |   | infra    |  | Writes           |     |
|  | engineer-docs.sh       |   | runtime- |  | docs/overview.md |     |
|  |   PreToolUse →         |   | process  |  |                  |     |
|  |   reads tracker,       |   |          |  +------------------+     |
|  |   gates docs/ writes   |   +----------+                           |
|  |                        |          |                               |
|  | turn-start.sh          |   SubagentStop event                     |
|  |   UserPromptSubmit →   |          |                               |
|  |   stamps .turn-start   |          v                               |
|  |                        |   +--------------------------+           |
|  | turn-complete.sh       |   |  Session Logs            |           |
|  |   Stop →               |   |  (passive write target)  |           |
|  |   appends timing log   |   +--------------------------+           |
|  +------|--^--------------+                                          |
|         |  |                                                          |
|  write  |  | read tracker                                            |
|         v  |                                                          |
|   +--------------------------+                                        |
|   |  Session Logs            |                                        |
|   |  (passive write target)  |                                        |
|   +--------------------------+                                        |
|                                                                      |
+=====================================================================+
         |
         | skills write (Write tool)
         v
  +--------------------------+
  |  Generated Docs          |
  |  (passive write target)  |
  +--------------------------+
```

---

## Element & Relationship Key

| Component | Location | Responsibility |
|---|---|---|
| Project Context (CLAUDE.md) | `CLAUDE.md` | Injected as system context into every Claude Code session; describes project purpose and conventions |
| Project Context (overview.md) | `overview.md` | Human-readable study guide indexing all 9 feature demos with scenario and run steps |
| Rules (markdown.md) | `.claude/rules/markdown.md` | Path-scoped behavior constraint: enforces ordinal list style for `*.broken_md` files |
| reverse-engineer command | `.claude/commands/reverse-engineer.md` | 4-phase orchestrator: inventory, spawn 6 agents, invoke 3 skills, verify 11 output files |
| create-command command | `.claude/commands/create-command.md` | Scaffolds new slash commands from user arguments; fetches current spec from code.claude.com |
| tech-stack agent | `.claude/agents/tech-stack.md` | Read-only fact gatherer: languages, frameworks, build/run, runtime versions (model: haiku) |
| module-map agent | `.claude/agents/module-map.md` | Read-only fact gatherer: internal components, responsibilities, call graph (model: sonnet) |
| external-integrations agent | `.claude/agents/external-integrations.md` | Read-only fact gatherer: DBs, queues, third-party APIs, auth (model: haiku) |
| data-flows agent | `.claude/agents/data-flows.md` | Read-only fact gatherer: end-to-end request/transaction paths (model: sonnet) |
| deployment-infra agent | `.claude/agents/deployment-infra.md` | Read-only fact gatherer: containers, CI/CD, IaC, startup topology (model: haiku) |
| runtime-process agent | `.claude/agents/runtime-process.md` | Read-only fact gatherer: processes, concurrency, scheduled jobs (model: sonnet) |
| c4-documentation skill | `.claude/skills/c4-documentation/SKILL.md` | Renders C4 diagrams; writes 4 files to `docs/c4/` |
| 4plus1-documentation skill | `.claude/skills/4plus1-documentation/SKILL.md` | Renders Kruchten 4+1 views; writes 5 files to `docs/4plus1/` |
| project-overview skill | `.claude/skills/project-overview/SKILL.md` | Renders standalone project overview; writes `docs/overview.md` |
| log-subagent hook | `.claude/hooks/log-subagent.sh` | Fires on SubagentStop for the 6 named agent types; appends to `subagents.log` and `reverse-engineer-run.tracker` |
| guard hook | `.claude/hooks/guard-reverse-engineer-docs.sh` | Fires on PreToolUse (Write/Edit) for `docs/` paths; reads tracker and issues `permissionDecision: ask` if any agent is missing |
| turn-start hook | `.claude/hooks/turn-start.sh` | Fires on UserPromptSubmit; writes Unix timestamp + prompt to `.turn-start` |
| turn-complete hook | `.claude/hooks/turn-complete.sh` | Fires on Stop; reads `.turn-start`, computes elapsed time, appends TSV row to `turn-completions.log` |
| helpers.sh | `.claude/scripts/helpers.sh` | Shared bash utility: `top-level-listing` (ls on path) and `check-commands` (list existing commands) |
| settings.json | `.claude/settings.json` | Registers all 4 hooks with matchers and grants Bash permissions for helpers.sh |

| Relationship | Protocol / Action |
|---|---|
| reverse-engineer → agents (×6) | Agent tool spawn, concurrent (background:true) |
| reverse-engineer → skills (×3) | Skill tool invocation, sequential |
| reverse-engineer → Session Logs | Bash: truncates tracker at Phase 1 start |
| log-subagent hook → Session Logs | Bash append: writes agent name to tracker and subagents.log |
| guard hook → Session Logs | Bash read: reads tracker to verify all 6 agents present |
| guard hook → Generated Docs | Guards Write/Edit to docs/ paths; blocks (ask) if tracker incomplete |
| skills → Generated Docs | Write tool: creates Markdown files under docs/ |
| turn-start hook → Session Logs | Bash write: stamps .turn-start per prompt |
| turn-complete hook → Session Logs | Bash read+append: computes duration, appends to turn-completions.log |
| create-command → code.claude.com | HTTPS WebFetch: retrieves latest slash-command spec |
