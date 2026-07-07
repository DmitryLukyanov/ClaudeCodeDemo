# 4+1 Process View — ClaudeCodeDemo

The process view shows what actually runs at runtime during a Claude Code session. There is no server or daemon — the Claude Code CLI is the sole persistent process. All other runtime activity happens in short-lived child processes: four hook scripts forked by the harness on lifecycle events, and up to six Claude inference sub-agents running concurrently when `/reverse-engineer` is active. This view is where the concurrency of Phase 2 and the ordering enforcement of the tracker gate are most clearly expressed.

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
(( Developer ))
      |
      | types prompt / slash command
      v
.-----------------------------------------.
| Claude Code CLI                          |
| <<process: persistent>>                  |
| Single long-running process per session; |
| reads config, executes Claude turns,     |
| dispatches lifecycle events to hooks     |
'-----------------------------------------'
      |
      |──── on every UserPromptSubmit ────────────────────────────────>
      |                                                                 |
      |                                                        .------------------------.
      |                                                        | turn-start.sh          |
      |                                                        | <<process: bash, 1s>>  |
      |                                                        | Writes epoch +         |
      |                                                        | prompt to .turn-start  |
      |                                                        '------------------------'
      |
      |──── on every Stop ────────────────────────────────────────────>
      |                                                                 |
      |                                                        .------------------------.
      |                                                        | turn-complete.sh       |
      |                                                        | <<process: bash, 1s>>  |
      |                                                        | Reads .turn-start;     |
      |                                                        | appends TSV row to     |
      |                                                        | turn-completions.log   |
      |                                                        '------------------------'
      |
      |──── on Write/Edit to docs/** (PreToolUse) ───────────────────>
      |                                                                |
      |                                                       .-------------------------.
      |                                                       | guard-reverse-          |
      |                                                       | engineer-docs.sh        |
      |                                                       | <<process: bash, <1s>>  |
      |                                                       | Reads tracker; if any   |
      |                                                       | of the 6 agents absent, |
      |                                                       | returns                 |
      |                                                       | permissionDecision:ask  |
      |                                                       '-------------------------'
      |
      |──── /reverse-engineer Phase 2: spawns 6 agents concurrently ─>
      |
      |   .--------------------.  .--------------------.  .--------------------.
      |   | tech-stack agent   |  | module-map agent   |  | external-integr.   |
      |   | <<agent: haiku>>   |  | <<agent: sonnet>>  |  | <<agent: haiku>>   |
      |   | Read-only scan     |  | Read-only scan     |  | Read-only scan     |
      |   | background:true    |  | background:true    |  | background:true    |
      |   '--------------------'  '--------------------'  '--------------------'
      |         |                       |                        |
      |   .--------------------.  .--------------------.  .--------------------.
      |   | data-flows agent   |  | deployment-infra   |  | runtime-process    |
      |   | <<agent: sonnet>>  |  | <<agent: haiku>>   |  | <<agent: sonnet>>  |
      |   | Read-only scan     |  | Read-only scan     |  | Read-only scan     |
      |   | background:true    |  | background:true    |  | background:true    |
      |   '--------------------'  '--------------------'  '--------------------'
      |         |                       |                        |
      |         | (each on SubagentStop)
      |         v
      |   .------------------------.
      |   | log-subagent.sh        |
      |   | <<process: bash, <1s>> |
      |   | Fired per completing   |
      |   | agent; appends name    |
      |   | to tracker +           |
      |   | subagents.log          |
      |   '------------------------'
      |
      |──── /reverse-engineer Phase 3: skills run sequentially ──────>
      |
      |   .--------------------.   (then)   .--------------------.
      |   | c4-documentation   |            | 4plus1-            |
      |   | <<skill: inline>>  |            | documentation      |
      |   | Writes docs/c4/    |            | <<skill: inline>>  |
      |   | (4 files)          |            | Writes docs/4plus1/|
      |   '--------------------'            | (5 files)          |
      |                                     '--------------------'
      |                         (then)
      |   .--------------------.
      |   | project-overview   |
      |   | <<skill: inline>>  |
      |   | Writes             |
      |   | docs/overview.md   |
      |   '--------------------'
      |
      |   Each skill Write triggers guard-reverse-engineer-docs.sh (see above)
```

---

## Element & Relationship Key

| Process | Type | Lifetime | Description |
|---|---|---|---|
| Claude Code CLI | `<<process: persistent>>` | Entire session | Reads config, executes Claude turns, dispatches lifecycle events to hook scripts |
| turn-start.sh | `<<process: bash>>` | ~1 second | Forked on UserPromptSubmit; writes epoch + prompt to `.turn-start`; exits |
| turn-complete.sh | `<<process: bash>>` | ~1 second | Forked on Stop; reads `.turn-start`, computes elapsed, appends to `turn-completions.log`; exits |
| guard-reverse-engineer-docs.sh | `<<process: bash>>` | < 1 second | Forked on PreToolUse (Write/Edit) targeting `docs/`; reads tracker; returns `permissionDecision:ask` if any agent missing; exits |
| log-subagent.sh | `<<process: bash>>` | < 1 second | Forked on SubagentStop for the 6 named agent types; appends agent name to tracker + `subagents.log`; exits |
| tech-stack agent | `<<agent: haiku>>` | Minutes (async) | Concurrent read-only Claude inference; returns language/framework summary |
| module-map agent | `<<agent: sonnet>>` | Minutes (async) | Concurrent read-only Claude inference; returns component structure summary |
| external-integrations agent | `<<agent: haiku>>` | Minutes (async) | Concurrent read-only Claude inference; returns external dependency summary |
| data-flows agent | `<<agent: sonnet>>` | Minutes (async) | Concurrent read-only Claude inference; returns end-to-end flow summary |
| deployment-infra agent | `<<agent: haiku>>` | Minutes (async) | Concurrent read-only Claude inference; returns infra/deployment summary |
| runtime-process agent | `<<agent: sonnet>>` | Minutes (async) | Concurrent read-only Claude inference; returns process/concurrency summary |
| c4-documentation skill | `<<skill: inline>>` | Minutes | Runs in orchestrator's Claude context; writes 4 Markdown files to `docs/c4/` |
| 4plus1-documentation skill | `<<skill: inline>>` | Minutes | Runs in orchestrator's Claude context; writes 5 Markdown files to `docs/4plus1/` |
| project-overview skill | `<<skill: inline>>` | Minutes | Runs in orchestrator's Claude context; writes `docs/overview.md` |

| Concurrency Notes | |
|---|---|
| Phase 2 parallelism | All 6 agents run simultaneously (`background:true`); orchestrator waits for all before Phase 3 |
| Hook parallelism | Multiple SubagentStop hooks may fire concurrently as agents complete; appends to tracker are not locked (low risk for small writes) |
| Skills are serial | Phases 3 skills run sequentially in the orchestrator's single Claude context |
| No scheduled jobs | There are no cron entries or recurring background tasks |
