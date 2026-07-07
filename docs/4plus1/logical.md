# 4+1 Logical View — ClaudeCodeDemo

The logical view decomposes ClaudeCodeDemo into its key functional abstractions: the configuration artifacts that govern Claude Code behavior. The system has five conceptual subsystems — context, orchestration, analysis, rendering, and enforcement — each made up of specific files that Claude Code reads and acts on. There are no classes or services in the traditional sense; the "components" are prompt templates, skill definitions, agent definitions, and bash scripts, bound together by the Claude Code runtime.

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
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Context Subsystem ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .-----------------------.     .-----------------------.
  | CLAUDE.md             |     | overview.md           |
  | <<context>>           |     | <<guide>>             |
  | Project context;      |     | Master study guide;   |
  | injected into every   |     | indexes 9 feature     |
  | session automatically |     | demos with run steps  |
  '-----------------------'     '-----------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Orchestration Subsystem ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .-------------------------.     .-------------------------.
  | reverse-engineer.md     |     | create-command.md       |
  | <<orchestrator>>        |     | <<scaffolder>>          |
  | 4-phase workflow:       |     | Generates new slash     |
  | inventory → agents →    |     | command files from      |
  | skills → verify         |     | user arguments          |
  '------------|------------'     '--------------------------|'
               |                                             |
  spawns (×6)  |                invokes (×3)   fetches spec  |
               |                      |                      |
└ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
               |                      |
               v                      v
┌ ─ ─ Analysis Subsystem ─ ─ ┐  ┌ ─ ─ Rendering Subsystem ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .---------------------.        .-------------------------.
  | tech-stack agent    |        | c4-documentation        |
  | <<agent: haiku>>    |        | <<skill>>               |
  | Languages, builds,  |        | Writes docs/c4/ (4 files)|
  | frameworks, runtimes|        '-------------------------'
  '---------------------'
  .---------------------.        .-------------------------.
  | module-map agent    |        | 4plus1-documentation    |
  | <<agent: sonnet>>   |        | <<skill>>               |
  | Internal structure  |        | Writes docs/4plus1/     |
  | and call graph      |        | (5 files)               |
  '---------------------'        '-------------------------'
  .---------------------.
  | external-integrations        .-------------------------.
  | <<agent: haiku>>    |        | project-overview        |
  | DBs, APIs, queues   |        | <<skill>>               |
  '---------------------'        | Writes docs/overview.md |
  .---------------------.        '-------------------------'
  | data-flows agent    |
  | <<agent: sonnet>>   |
  | End-to-end request  |
  | paths               |
  '---------------------'
  .---------------------.
  | deployment-infra    |
  | <<agent: haiku>>    |
  | Containers, CI/CD,  |
  | infra topology      |
  '---------------------'
  .---------------------.
  | runtime-process     |
  | <<agent: sonnet>>   |
  | Processes, threads, |
  | concurrency model   |
  '---------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                                └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Enforcement Subsystem ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  .-------------------------.     .-------------------------.
  | log-subagent.sh         |     | guard-reverse-          |
  | <<hook: SubagentStop>>  |     | engineer-docs.sh        |
  | Appends agent name to   |     | <<hook: PreToolUse>>    |
  | tracker + subagents.log |     | Gates docs/ writes;     |
  '-------------------------'     | reads tracker           |
                                  '-------------------------'
  .-------------------------.     .-------------------------.
  | turn-start.sh           |     | turn-complete.sh        |
  | <<hook: PromptSubmit>>  |     | <<hook: Stop>>          |
  | Stamps .turn-start      |     | Appends timing to       |
  | with epoch + prompt     |     | turn-completions.log    |
  '-------------------------'     '-------------------------'

  .-------------------------.
  | markdown.md             |
  | <<rule: path-scoped>>   |
  | Ordinal list style for  |
  | *.broken_md files only  |
  '-------------------------'
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

---

## Element & Relationship Key

| Element | Stereotype | Responsibility |
|---|---|---|
| CLAUDE.md | `<<context>>` | Persistent project context injected into every Claude Code session |
| overview.md | `<<guide>>` | Human-readable study guide; indexes all 9 feature demos |
| reverse-engineer.md | `<<orchestrator>>` | 4-phase command: inventory → 6 agents → 3 skills → verify 11 files |
| create-command.md | `<<scaffolder>>` | Generates new slash command files from user-supplied name, description, and tool list |
| tech-stack agent | `<<agent: haiku>>` | Read-only fact gatherer: languages, frameworks, build/run, runtimes |
| module-map agent | `<<agent: sonnet>>` | Read-only fact gatherer: internal structure and call graph |
| external-integrations agent | `<<agent: haiku>>` | Read-only fact gatherer: databases, queues, third-party APIs, auth |
| data-flows agent | `<<agent: sonnet>>` | Read-only fact gatherer: end-to-end request/transaction paths |
| deployment-infra agent | `<<agent: haiku>>` | Read-only fact gatherer: containers, CI/CD, IaC, startup topology |
| runtime-process agent | `<<agent: sonnet>>` | Read-only fact gatherer: processes, concurrency, scheduled jobs |
| c4-documentation skill | `<<skill>>` | Renders C4-model diagrams; writes 4 files to `docs/c4/` |
| 4plus1-documentation skill | `<<skill>>` | Renders Kruchten 4+1 views; writes 5 files to `docs/4plus1/` |
| project-overview skill | `<<skill>>` | Renders standalone project overview; writes `docs/overview.md` |
| log-subagent.sh | `<<hook: SubagentStop>>` | Appends completing agent's name to tracker and subagents.log |
| guard-reverse-engineer-docs.sh | `<<hook: PreToolUse>>` | Reads tracker; issues `permissionDecision: ask` if any of the 6 agents are missing |
| turn-start.sh | `<<hook: PromptSubmit>>` | Records start timestamp and prompt text to `.turn-start` |
| turn-complete.sh | `<<hook: Stop>>` | Computes elapsed time; appends TSV row to `turn-completions.log` |
| markdown.md | `<<rule: path-scoped>>` | Constrains list formatting in `*.broken_md` files |

| Relationship | Description |
|---|---|
| reverse-engineer → agents (×6) | Spawns six agents concurrently via Agent tool |
| reverse-engineer → skills (×3) | Invokes skills sequentially via Skill tool |
| create-command → code.claude.com | Fetches current slash-command spec via WebFetch |
| log-subagent.sh → tracker | Writes (appends) completing agent name |
| guard hook → tracker | Reads tracker to enforce completeness before doc writes |
