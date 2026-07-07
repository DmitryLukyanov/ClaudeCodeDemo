# 4+1 — Process View

**What it shows:** The runtime concurrency picture — the processes that exist, the six-way
parallel subagent fan-out, the synchronization barrier before synthesis, and the short-lived
hook subprocesses fired by lifecycle events. This is the view C4 compresses away, so it is the
richest here. **Audience:** anyone reasoning about ordering guarantees, the fan-out/join
barrier, or the soft write-gate. Note up front: there are **no cron jobs, no message
queues/brokers, no daemons, and no thread pools** — all concurrency is either Claude Code's
background-subagent fan-out or a single Python asyncio loop.

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
  (( User / SDK ))
       |
       | /reverse-engineer .
       v
 .---------------------------.
 | Orchestrator (main context)|  Phase 1: reset tracker (: > tracker), orient
 | <<process: Claude session>>|
 '---------------------------'
       |  Phase 2: spawn 6 (Agent tool, background:true)  — TRUE PARALLEL
       |----------------+----------------+---------------+---------------+--------------+
       v                v                v               v               v              v
 .-----------.   .-----------.   .-------------.   .-----------.   .-------------.  .-------------.
 | tech-stack|   | module-map|   |external-int.|   | data-flows|   |deploy-infra |  |runtime-proc |
 | <<haiku>> |   | <<sonnet>>|   | <<haiku>>   |   | <<sonnet>>|   | <<haiku>>   |  | <<sonnet>>  |
 '-----------'   '-----------'   '-------------'   '-----------'   '-------------'  '-------------'
       |  SubagentStop  |  SubagentStop  | ...            |               |              |
       ════ append ════> ════ append ════> ════ append ════════════════════════════════>
                                                  v
                                        .-------------------------.
                                        | reverse-engineer-run.   |
                                        | tracker <<shared state>>|  (append-only, no lock)
                                        '-------------------------'
       |  ===== BARRIER: wait for all six to return =====
       v
 .---------------------------.
 | Orchestrator (Phase 3/4)  |  merge facts -> invoke 3 skills -> write docs -> verify
 '---------------------------'
       |  each guarded Write
       v
 .---------------------------.   reads tracker; if any of 6 missing => permissionDecision:"ask"
 | guard hook (PreToolUse)   |   (SOFT gate, per-write, only docs/c4|4plus1|overview|COMPARISON)
 '---------------------------'

  Independent per-turn timing (any turn):
  (( UserPromptSubmit )) --> turn-start.sh  ════ stamp ════> .turn-start
  (( Stop ))             --> turn-complete.sh <== read ==   .turn-start  ══> turn-completions.log
```

## Element & Relationship Key

| Process / Element | Description |
|---|---|
| Orchestrator (main context) | The single top-level process: a Claude Code session (interactive) or the Python asyncio process (headless). Runs Phases 1–4 sequentially. |
| 6 subagents (`<<haiku>>`/`<<sonnet>>`) | Launched via the `Agent` tool with `background:true`; run **in true parallel** against the same codebase. Read-only, so no write races among them. |
| reverse-engineer-run.tracker `<<shared state>>` | Plain-text, append-only completion tally. Reset in Phase 1 to avoid stale completions. Written concurrently by independent short-lived hook processes — POSIX small-append-safe but **unlocked** (risky if agent count grows). |
| guard hook (PreToolUse) | Fires before every `Write`/`Edit`; for guarded doc paths, checks the tracker for all six agent names and emits `permissionDecision:"ask"` if any are missing. |
| turn-start.sh / turn-complete.sh | Per-turn timing subprocesses (UserPromptSubmit / Stop); independent of the reverse-engineer workflow. |

| Mechanism | Description |
|---|---|
| Fan-out (`------+------`) | Phase 2 spawns exactly six background subagents at once. |
| `════ append ════>` (SubagentStop) | Each finishing agent triggers `log-subagent.sh`, which appends its name to the tracker + `subagents.log`. |
| BARRIER | Phase 3 must not begin until all six summaries return; orchestrator must not re-scan the codebase afterward. |
| Soft gate | The guard is enforced **per-write**, not as a true blocking barrier — a backstop, overridable by approval. |

## Concurrency notes & latent fragilities

- **Two loosely-coupled barrier mechanisms:** (a) the orchestrator's own "wait for all six" instruction and (b) the guard hook's tracker check. If the orchestrator writes early, only the guard backstops it — and only for the four guarded doc-path globs.
- **Python driver:** a single asyncio event loop with one `async for message in query(...)` consumer; no threads. A FIFO `deque` correlates tool-call requests to results, assuming strict request/response ordering (latent fragility if ever violated).
- **Resource limiter:** `max_budget_usd=6.00` can stop the run mid-flight; `effort="medium"` is chosen deliberately because `"high"` exhausts context before Phase 3 completes.
