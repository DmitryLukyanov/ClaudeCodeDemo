# C4 — L3 Component

This view opens the two containers that have meaningful internal structure: the
**/reverse-engineer Orchestrator Command** (its four phases as logical components) and the
**Lifecycle Hooks** container (its four event handlers). Other containers are trivial or
opaque: the six subagents are near-identical read-only analyzers (described in prose below),
the three skills are self-contained renderers, and the Python driver and shared file state
have no internal component structure worth diagramming.

```
People / Actors
  [ Person Name ]           Human user or role

System / Container / Component boxes
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |   ← technology tag only at L2+
  |  Short responsibility      |   ← responsibility line only at L3
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

## Container: /reverse-engineer Orchestrator Command

```
+--------------------------------------------------------------------------+
|  /reverse-engineer Orchestrator Command                                  |
|                                                                          |
|  +----------------------------+   +----------------------------+         |
|  |  Phase 1: Inventory        |   |  Phase 2: Parallel Deep-   |         |
|  |  [Markdown]                |──>|  Dive                      |         |
|  |  Reset tracker; cheap      |   |  [Markdown]                |         |
|  |  orientation (Glob/Read)   |   |  Spawn 6 subagents; wait   |         |
|  +----------------------------+   +----------------------------+         |
|                                             |                            |
|                                             v                            |
|  +----------------------------+   +----------------------------+         |
|  |  Phase 4: Verify           |<--|  Phase 3: Synthesis        |         |
|  |  [Markdown]                |   |  [Markdown]                |         |
|  |  Glob docs/**; confirm 11  |   |  Merge facts; invoke 3     |         |
|  |  files; re-run if missing  |   |  skills; write COMPARISON  |         |
|  +----------------------------+   +----------------------------+         |
+--------------------------------------------------------------------------+
```

| Component | Responsibility |
|---|---|
| Phase 1: Inventory | Resets `.claude/logs/reverse-engineer-run.tracker`; runs cheap orientation via `helpers.sh top-level-listing`, `Glob`, and a few `Read`s. Produces Phase 1 notes; spawns no subagents. |
| Phase 2: Parallel Deep-Dive | Spawns the six fact-gathering subagents in parallel (`Agent` tool, `background:true`), passing target root + Phase 1 notes. Barrier: waits for all six summaries before continuing. |
| Phase 3: Synthesis | Merges the six summaries into one fact set, resolving contradictions once; invokes `c4-documentation`, `4plus1-documentation`, and `project-overview` skills; directly writes `docs/COMPARISON.md`. |
| Phase 4: Verify | Globs `docs/**`, compares against the expected 11 files, re-invokes any skill whose output is missing, then reports the file list. |

## Container: Lifecycle Hooks

```
+--------------------------------------------------------------------------+
|  Lifecycle Hooks  [Bash + node -e]                                       |
|                                                                          |
|  +----------------------------+   +----------------------------+         |
|  |  log-subagent.sh           |   |  guard-reverse-engineer-   |         |
|  |  On SubagentStop           |   |  docs.sh                   |         |
|  |  Append agent name to      |   |  On PreToolUse (Write|Edit)|         |
|  |  tracker + subagents.log   |   |  Gate doc writes vs tracker|         |
|  +----------------------------+   +----------------------------+         |
|              |                                 |                         |
|              v (append)                        v (read + "ask")          |
|        +---------------------------------------------+                   |
|        |  Shared File State (tracker / logs)         |                   |
|        +---------------------------------------------+                   |
|              ^                                 ^                          |
|  +----------------------------+   +----------------------------+         |
|  |  turn-start.sh             |   |  turn-complete.sh          |         |
|  |  On UserPromptSubmit       |   |  On Stop                   |         |
|  |  Stamp start time + prompt |   |  Compute + log duration    |         |
|  +----------------------------+   +----------------------------+         |
+--------------------------------------------------------------------------+
```

| Component | Responsibility |
|---|---|
| log-subagent.sh | On `SubagentStop` for one of the six agent names: parses `agent_type` via `node -e`, appends `{timestamp, agent}` to `subagents.log` and the agent name to `reverse-engineer-run.tracker`; unmatched agents go to `subagents-debug.log`. |
| guard-reverse-engineer-docs.sh | On `PreToolUse` (`Write`/`Edit`): if the target is a guarded doc path (`docs/c4/*`, `docs/4plus1/*`, `docs/overview.md`, `docs/COMPARISON.md`) and any of the six agent names is missing from the tracker, emits `permissionDecision:"ask"` — a **soft** gate, not a hard block. |
| turn-start.sh | On `UserPromptSubmit`: writes the turn start timestamp + prompt text to `.claude/logs/.turn-start`. |
| turn-complete.sh | On `Stop`: reads `.turn-start`, computes elapsed duration, appends a record to `turn-completions.log`. |

## Prose: containers without diagrammed internals

- **Six Fact-Gathering Subagents** — structurally near-identical: each is a read-only analyzer (Read/Glob/Grep) with a fixed output schema for its domain (tech-stack, module-map, external-integrations, data-flows, deployment-infra, runtime-process). They differ only in prompt focus and model tier (haiku vs sonnet). None call skills or each other.
- **Three Rendering Skills** — each is a self-contained renderer that consumes caller-supplied facts and writes its own document set (`c4-documentation` → `docs/c4/*`; `4plus1-documentation` → `docs/4plus1/*`; `project-overview` → `docs/overview.md`).
- **Python Agent SDK Driver** — a single linear async consumer loop over the SDK message stream; no internal components beyond message-type dispatch and a FIFO `deque` correlating tool calls to results.
- **Shared File State** — plain append-only text files used as a coordination channel; no logic.
