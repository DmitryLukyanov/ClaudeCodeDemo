# 4+1 Scenarios (+1) — ClaudeCodeDemo

The scenarios view traces three architecturally significant use cases through the system. These are the cases that exercise the most cross-cutting interaction — not the most common, but the ones that make the concurrency model, orchestration constraints, and lifecycle hooks visible. Reading these three scenarios together gives a more complete picture of the architecture than any of the four structural views alone. They also validate consistency: each scenario touches multiple views and exposes gaps that structural diagrams compress away.

## Scenario 1 — `/reverse-engineer` (primary use case)

Exercises the complete 4-phase workflow: self-inventory, parallel agent fan-out, sequential skill rendering, and file verification. Touches Logical (which components), Process (concurrency + sync point), Development (layer traversal), and Physical (all LLM calls cross network).

```
  Developer    Claude CLI   AgentSpawner   Subagents(x6)  SkillInvoker  docs/
      |              |             |              |              |          |
      |--/reverse-   |             |              |              |          |
      |  engineer--->|             |              |              |          |
      |              |             |              |              |          |
      |              |=Phase 1: self-inventory (Read/Glob inline; no subagents)=|
      |              |             |              |              |          |
      |              |--Phase 2--->|              |              |          |
      |              |             |--spawn all-->|              |          |
      |              |             |   6 at once  |              |          |
      |              |             |              |              |          |
      |              |         [6 background agents running concurrently]   |
      |              |             |              |              |          |
      |              |             |<--summary 1--|              |          |
      |              |             |<--summary 2--|              |          |
      |              |             |<--summary 3--|              |          |
      |              |             |<--summary 4--|              |          |
      |              |             |<--summary 5--|              |          |
      |              |             |<--summary 6--|              |          |
      |              |<-merged set-|              |              |          |
      |              |             |              |              |          |
      |              |=======[SYNC POINT: all 6 done; Phase 3 begins]======|
      |              |             |              |              |          |
      |              |--Phase 3A: c4-documentation skill-------->|          |
      |              |             |              |              |--write-->|
      |              |             |              |              |  docs/c4/|
      |              |<- - - - - - - - - - - done- - - - - - - - |          |
      |              |             |              |              |          |
      |              |--Phase 3B: 4plus1-documentation skill---->|          |
      |              |             |              |              |--write-->|
      |              |             |              |              |docs/4+1/ |
      |              |<- - - - - - - - - - - done- - - - - - - - |          |
      |              |             |              |              |          |
      |              |--Phase 3C: project-overview skill-------->|          |
      |              |             |              |              |--write-->|
      |              |             |              |              | overview |
      |              |<- - - - - - - - - - - done- - - - - - - - |          |
      |              |             |              |              |          |
      |              |=Phase 4: Glob verify 11 files=========================|
      |<- - result - |             |              |              |          |
```

Views: Logical (all components exercised), Process (fan-out + sync point + sequential Phase 3), Development (orchestration → fact-gather → render → output), Physical (LLM calls cross network).

Key property: the sync point between Phase 2 and Phase 3 is enforced by Agent tool semantics. No skill starts until all six summaries are in.

---

## Scenario 2 — `/create-command` (simpler orchestration, one external call)

Exercises a lighter workflow: spec fetch from an external service, collision check via utility script, file write. No subagents spawned. Touches Logical (command calls script), Physical (HTTPS to code.claude.com), Development (orchestration → utility).

```
  Developer    Claude CLI    helpers.sh    code.claude.com  .claude/commands/
      |              |             |              |                 |
      |--/create-    |             |              |                 |
      |  command---->|             |              |                 |
      |              |             |              |                 |
      |              |=fetch spec (HTTPS)========>|                 |
      |              |<- - spec markdown - - - - -|                 |
      |              |             |              |                 |
      |              |--check-commands----------->|                 |
      |              |<- - existing files - - - - |                 |
      |              |             |              |                 |
      |              |=compose frontmatter + body=|                 |
      |              |             |              |                 |
      |              |--Write new command file-------------------->|
      |              |<- - - - - - - - - - done - - - - - - - - - -|
      |<- - result - |             |              |                 |
```

Views: Logical (slash-command → script dependency), Physical (one HTTPS edge to code.claude.com), Development (orchestration → utility layer).

Key property: even a "simple" scaffolding command crosses the network boundary — the live spec fetch is the only on-demand external dependency outside of LLM inference.

---

## Scenario 3 — SubagentStop hook (background audit, known bug exposed)

Exercises the async lifecycle hook that fires after every subagent completion during Phase 2. Touches Process (async sidecar), Physical (entirely local), Development (config layer triggers utility/monitoring layers). Also exposes the known hook bug: the hook fires correctly, but the `agent_type` extraction fails for most events.

```
  Claude CLI    Agent runtime   log-subagent.sh   subagents.log  subagents-debug.log
      |               |               |               |                |
      |<--agent done--|               |               |                |
      |               |               |               |                |
      |═SubagentStop══════════════>   |               |                |
      |               |   JSON piped to stdin         |                |
      |               |               |               |                |
      |               |               |--grep agent_type               |
      |               |               |  (often fails — bug)           |
      |               |               |               |                |
      |    (happy path: type resolved)|               |                |
      |               |               |--append TSV-->|                |
      |               |               |  timestamp +  |                |
      |               |               |  agent_type   |                |
      |               |               |               |                |
      |    (bug path: type empty)     |               |                |
      |               |               |- - - - - - - - - - append---->|
      |               |               |  raw JSON     |    (rarely     |
      |               |               |  payload      |    fires)      |
      |               |               |               |                |
      |               |               |<- - exit - - -|                |
      |               |               |               |                |
      |  [Phase 3 continues unblocked — hook is async] |               |
```

Views: Process (async sidecar does not block Phase 3), Physical (entirely local), Development (settings.json → log-subagent.sh → .claude/logs/).

Key property (bug): 26 SubagentStop events fired; only 2 resolved `agent_type` (tech-stack, module-map). 24 logged as "unknown" — the hook's `grep -o '"agent_type"...'` pattern doesn't match the actual JSON payload structure Claude Code sends. `subagents-debug.log` exists but is effectively empty, meaning the `[ -z "$agent" ]` guard branch is not triggering as expected despite the empty extractions.

---

## Coverage Map

| View | Scenario 1 (/reverse-engineer) | Scenario 2 (/create-command) | Scenario 3 (SubagentStop) |
|---|---|---|---|
| Logical | All 14 components exercised | command + script only | hook + logs |
| Process | Fan-out, sync point, sequential Phase 3 | Single-process, no concurrency | Async sidecar, non-blocking |
| Development | Orch → fact-gather → render → output | Orch → utility | Config → utility → monitoring |
| Physical | All LLM calls cross to Anthropic API | spec fetch crosses to code.claude.com | Entirely local |
| Scenarios | **This is Scenario 1** | **This is Scenario 2** | **This is Scenario 3** |
