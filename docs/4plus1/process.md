# 4+1 Process View — ClaudeCodeDemo

The process view shows the runtime concurrency picture: which processes exist during a `/reverse-engineer` invocation, how they are spawned, how they communicate, and where the synchronization points are. This is the view where C4 container diagrams fall short for this system — the parallel fan-out of six independent subagent processes, the async hook sidechannel, and the sequential Phase 3 serialization are all invisible in static structural diagrams. This view is for developers reasoning about ordering guarantees, context isolation, and potential race conditions.

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
      | /reverse-engineer (invocation)
      v
.---------------------------------.
| Claude Code CLI                 |
| <<process: Claude Code>>        |   long-lived; one per session
'---------------------------------'
      |
      | PHASE 1: self-runs inventory (Read/Glob inline; no subagents)
      |
      | PHASE 2: spawns 6 concurrently (background: true)
      |          all six start at the same time
      |
      +------+------+------+------+------+------+
      |      |      |      |      |      |      |
      v      v      v      v      v      v      |
.--------. .--------. .--------. .--------. .--------. .--------.
|tech-   | |module- | |ext-    | |data-   | |deploy- | |runtime |
|stack   | |map     | |integr. | |flows   | |infra   | |process |
|<<proc: | |<<proc: | |<<proc: | |<<proc: | |<<proc: | |<<proc: |
| haiku>>| | sonnet>| | haiku>>| | sonnet>| | haiku>>| | sonnet>|
'--------' '--------' '--------' '--------' '--------' '--------'
      |      |      |      |      |      |
      | each returns compact structured summary
      +------+------+------+------+------+
      |
      | [SYNC POINT: all 6 must complete before Phase 3]
      |
      | PHASE 3: sequential (one skill at a time)
      |
      | Step A              Step B               Step C
      v                     v                    v
.-------------.    .----------------.    .-----------------.
| c4-doc      |    | 4plus1-doc     |    | project-overview|
| (in-proc)   |    | (in-proc)      |    | (in-proc)       |
| <<skill>>   |    | <<skill>>      |    | <<skill>>       |
'-------------'    '----------------'    '-----------------'
      |                  |                      |
      | writes           | writes               | writes
      v                  v                      v
   docs/c4/          docs/4plus1/         docs/overview.md

--- Async sidecar (does NOT block Phase 3) ---

Each subagent completion ════> SubagentStop lifecycle event
                                      |
                                      v
                               .-----------------.
                               | log-subagent.sh  |
                               | <<process: Bash>>|
                               | transient; one   |
                               | fork per event   |
                               '-----------------'
                                    |         |
                             appends|         | appends (on parse failure)
                                    v         v
                             subagents.log  subagents-debug.log
                             (26 entries;   (exists; effectively
                             24 "unknown"   empty — branch not
                             — known bug)   triggering as expected)

--- Commands also fork helpers.sh ---

reverse-engineer ──────> helpers.sh (top-level-listing)   [Phase 1]
create-command   ──────> helpers.sh (check-commands)      [on invocation]
```

## Element & Relationship Key

| Element | Description |
|---|---|
| Claude Code CLI `<<process>>` | Main interactive process; orchestrates all phases; long-lived for the session |
| tech-stack `<<process: haiku>>` | Background child process; haiku model; read-only recon; isolated context window |
| module-map `<<process: sonnet>>` | Background child process; sonnet model; deeper analysis; isolated context |
| external-integrations `<<process: haiku>>` | Background child process; haiku model; isolated context |
| data-flows `<<process: sonnet>>` | Background child process; sonnet model; isolated context |
| deployment-infra `<<process: haiku>>` | Background child process; haiku model; isolated context |
| runtime-process `<<process: sonnet>>` | Background child process; sonnet model; isolated context |
| c4-documentation (in-proc) | Skill executing in the main CLI process context; not a separate process |
| 4plus1-documentation (in-proc) | Skill executing in the main CLI process context |
| project-overview (in-proc) | Skill executing in the main CLI process context |
| log-subagent.sh `<<process: Bash>>` | Transient bash child forked per SubagentStop event; exits after one log write |
| helpers.sh `<<process: Bash>>` | Transient bash child forked inline; exits after returning output |
| subagents.log | Append-only file; 26 entries total; 24 show "unknown" agent_type (hook grep pattern mismatch — known bug) |
| subagents-debug.log | Fallback file for parse failures; exists but effectively empty (branch not triggering as expected) |
| Phase 2 fan-out | All 6 subagent processes start simultaneously; isolated context windows; no shared memory |
| Sync point (Phase 2→3) | Agent tool semantics ensure all 6 return before Phase 3; enforced by runtime |
| Phase 3 sequential | Skills run one at a time (A then B then C) to prevent write conflicts on docs/ |
| SubagentStop → log-subagent.sh | Async sidecar; fires after each agent; does not block Phase 3 |
| No scheduled jobs | No cron, no timers, no background polling |
| No message queues | All communication is direct process invocation or filesystem write |
