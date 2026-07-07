# 4+1 — Scenarios (+1)

**What it shows:** Key use cases traced across the other four views. These scenarios are the
glue that validates the Logical, Process, Development, and Physical views work together — and
they expose the two most architecturally significant behaviors of this system: the six-way
parallel fan-out with a synchronization barrier, and the soft write-gate that backstops it.
**Audience:** everyone — this is the most readable entry point to the architecture.

```
Actors / External Agents
  (( Actor Name ))              human user, external system, or timer

Component / Object / Subsystem
  .-----------------------.
  | Name                  |
  | <<stereotype>>        |    stereotype: service, module, subsystem, controller, etc.
  '-----------------------'

Relationships
  ─────────────────>   label          synchronous call / association
  - - - - - - - - ->   label          dependency / uses / sends-to (async)
  ════════════════>   label          IPC / queue message / event
```

---

## Scenario 1 — Full reverse-engineer run (happy path)

Touches all four views: the orchestrator (Logical) fans out six parallel agents (Process),
which read the tree (Physical) and drive the three renderers (Development) to write docs.

```
 User        Orchestrator     6 Subagents     log-subagent    tracker      3 Skills     guard hook
   |              |                |               |             |             |             |
   |--/rev-eng .->|               |               |             |             |             |
   |              |--Phase1: reset tracker------------------------>(: > )      |             |
   |              |--Phase2: spawn 6 (parallel)-->|               |             |             |
   |              |               |--SubagentStop->|--append----->|             |             |
   |              |               |--SubagentStop->|--append----->|  (x6)       |             |
   |              |<= = barrier: all six returned = |             |             |             |
   |              |--Phase3: merge facts------------------------------------->  |             |
   |              |--invoke c4 / 4+1 / overview----------------------------->   |             |
   |              |               |               |               | each Write->|--check----->|
   |              |               |               |               |             |<- all 6 ok -|
   |              |               |               |               |             |--writes doc |
   |              |--write COMPARISON.md (direct)------------------------------------------->  |
   |              |--Phase4: Glob docs/** verify 11 files          |             |             |
   |<- - report - |               |               |               |             |             |
```

Meanwhile, independently: `UserPromptSubmit → turn-start.sh` stamps start time; `Stop →
turn-complete.sh` appends the turn duration to `turn-completions.log`.

---

## Scenario 2 — Guard hook fires (failure / override path)

Touches Process + Logical. Shows the **soft gate**: the guard is a backstop, not a hard lock.

```
 Orchestrator      guard hook (PreToolUse)      tracker            User / Harness
   |                     |                         |                    |
   |--Write docs/c4/... ->|                        |                    |
   |                     |--read completeness----->|                    |
   |                     |<- missing: e.g. data-flows                   |
   |                     |--permissionDecision:"ask" (names missing)--->|
   |                     |                         |    approve anyway? -|
   |                     |                    (a) YES => write proceeds on incomplete basis
   |                     |                    (b) NO  => orchestrator spawns missing agent first
   |<- - - - - - - - - - |                         |                    |
```

This happens when the tracker was truncated or an agent never completed. Because the gate is
per-write and overridable, correctness ultimately depends on the orchestrator honoring its own
"wait for all six" barrier.

---

## Scenario 3 — Headless CI run

Touches Physical + Process. The Python driver runs the identical Phase 1–4 flow via the SDK,
with a hard budget cap that can terminate mid-run.

```
 CI Shell      run-reverse-engineer.py     SDK query()       Claude session     ResultMessage
   |                  |                        |                   |                 |
   |--python ...  --->|                        |                   |                 |
   |                  |--query(/rev-eng .)----->|                   |                 |
   |                  |                        |--drives Phase1-4-->|                 |
   |                  |<==stream Assistant/User/System messages=====|                 |
   |                  |                        |                   |--terminal------>|
   |                  |<- - - - - - - - - - - - subtype - - - - - - - - - - - - - - -|
   |                  |  success        => print cost/turns/session; exit 0          |
   |                  |  error_max_budget_usd => print resume hint (session_id); exit 1
   |<- - exit code - -|  error_max_turns => resume hint; exit 1                       |
```

---

## Scenario 4 — /create-command scaffolding

Touches Logical + Development. Shows the secondary command and its live-docs dependency.

```
 User        /create-command      code.claude.com     helpers.sh(check-cmds)   commands/
   |              |                     |                     |                    |
   |--/create-command name "desc" ---->|                     |                    |
   |              |--WebFetch docs----->|                     |                    |
   |              |<- - frontmatter/syntax                    |                    |
   |              |--check-commands---------------------------->|                  |
   |              |<- - existing commands (echoed verbatim) - -|                    |
   |              |--collision? ask before overwrite --------------------->(User)  |
   |              |--compose frontmatter + body                |                    |
   |              |--Write <name>.md (guard hook passes: not under docs/**)-------->|
   |<- - report path + contents - -|    |                     |                    |
```

---

## Scenario coverage

| Scenario | Happy path | Async/parallel | Failure/boundary | Views exercised |
|---|---|---|---|---|
| 1 — Full run | ✓ | ✓ (6-way fan-out + barrier) | | Logical, Process, Development, Physical |
| 2 — Guard fires | | | ✓ (soft gate override) | Process, Logical |
| 3 — Headless CI | ✓ | | ✓ (budget cap mid-run) | Physical, Process |
| 4 — /create-command | ✓ | | ✓ (collision check) | Logical, Development |
