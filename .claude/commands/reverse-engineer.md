---
allowed-tools: Agent, Read, Glob, Grep, Write, Skill
argument-hint: "[path-to-codebase] (defaults to current working directory)"
description: Reverse-engineer a codebase into C4 + 4+1 architecture docs and an overview
model: sonnet
---

## Context

- Target codebase root: `$ARGUMENTS` (if empty, use the current working directory)
- Top-level listing: !`bash .claude/scripts/helpers.sh top-level-listing "$ARGUMENTS"`

## Mission

Orchestrate reverse-engineering of the codebase at the target root into architecture documentation. Gather the facts about the system **once**, then render three complementary documentation sets from that single shared fact set — so the C4 docs, the 4+1 docs, and the overview all describe the *same* system consistently, not three independently-researched (and possibly inconsistent) views.

This command is the **only orchestrator** in this workflow:
- Skills do not call subagents.
- Subagents do not call skills.
- All fan-out (spawning agents) and all skill invocation happens here, in this command.

Do not skip phases and do not let a later phase re-scan the codebase from scratch — each phase builds strictly on the outputs of the phase before it.

---

## PHASE 1 — Inventory (do this yourself, in main context — cheap, no subagents)

Before anything else, reset this run's agent-completeness tracker so stale completions from
a previous run can't satisfy this run's guard later in Phase 3:

```
mkdir -p .claude/logs && : > .claude/logs/reverse-engineer-run.tracker
```

Then get cheap orientation directly:

1. Detect languages and build tooling — look for manifest files (`package.json`, `go.mod`, `*.csproj`, `pom.xml`, `requirements.txt`, `Cargo.toml`, etc.), lockfiles, and CI config.
2. Locate entry points and top-level structure — use `Glob` for top-level directories and likely entry files (`main.*`, `index.*`, `Program.*`, `cmd/`, `src/`), and `Read` a handful of the most obviously important files (README, top-level config).
3. Sketch a rough module list — enough to scope the fan-out in Phase 2, not a full map. This is a working hypothesis the deep-dive agents will confirm or correct, not a final answer.

Keep this phase fast. Its only job is to give the six agents in Phase 2 enough shared orientation (root path, rough module boundaries, obvious tech signals) that they don't waste their first turns rediscovering what you already found.

---

## PHASE 2 — Parallel deep-dive (six concurrent agents)

Spawn **all six** of the following subagents to run **in parallel** — one `Agent` tool call per `subagent_type` below. Each agent is defined with `background: true`, so they execute concurrently against the same codebase; you don't need to manage the concurrency yourself.

For each, pass the target codebase root and your Phase 1 orientation notes so they don't redo that work, and ask for a **compact structured summary** (not prose essays — bullet facts, named things, file paths) suitable for feeding directly into a documentation-writing step.

1. **`subagent_type: tech-stack`** — languages, frameworks, dependencies, build & run commands, runtime versions.
2. **`subagent_type: module-map`** — internal components/modules, their responsibilities, and their relationships/call graph.
3. **`subagent_type: external-integrations`** — databases, queues, third-party APIs, auth providers, outbound calls.
4. **`subagent_type: data-flows`** — key end-to-end request/transaction paths through the system.
5. **`subagent_type: deployment-infra`** — containers, orchestration, CI/CD, IaC, startup/deploy topology.
6. **`subagent_type: runtime-process`** — processes, threads, scheduled jobs, message consumers, concurrency model.

Wait for all six to return before continuing. Do **not** re-read the codebase yourself after this point — every fact used in Phase 3 must trace back to one of these six summaries (or your Phase 1 notes). If a downstream phase seems to need something none of the six covered, that's a signal to note the gap explicitly rather than to go re-scan files.

---

## PHASE 3 — Synthesis (merge facts, then render three outputs + a comparison)

First, merge the six summaries into one shared fact set in your own context — resolve any contradictions between agents (e.g., if `module-map` and `runtime-process` disagree about what a component does, reconcile it now, once, rather than letting the disagreement leak into multiple docs differently).

Then produce the following, **each as its own distinct step**, so the right skill is engaged for each:

### Step A — C4-model architecture documentation
Use the **`c4-documentation`** skill to produce context, container, component, and deployment diagrams, written to `docs/c4/`. Base this on the merged facts from `module-map`, `external-integrations`, `tech-stack`, and `deployment-infra`. Do not re-scan the codebase — hand the skill the relevant facts from the merged set.

### Step B — Kruchten 4+1 architecture documentation
Use the **`4plus1-documentation`** skill to produce logical, process, development, physical, and scenarios views, written to `docs/4plus1/`. Base this on the merged facts from `module-map`, `runtime-process`, `tech-stack`, `deployment-infra`, and `data-flows`. The process and scenarios views should draw especially heavily on `runtime-process` and `data-flows` — that's the detail C4 tends to compress away.

### Step C — Project overview
Use the **`project-overview`** skill to produce a goal/technologies/sequence-flows/external-references/build-run document, written to `docs/overview.md`. Base this on **all six** summaries — this is the one document meant to stand alone for a reader who won't look at the C4 or 4+1 sets at all.

### Step D — Comparison
Write `docs/COMPARISON.md`: a short side-by-side of what the C4 output and the 4+1 output each surfaced well, hid or compressed, or expressed more clearly than the other — for *this specific system*, using the actual diagrams you just produced, not generic notation trivia. Useful angles: which view made the runtime/concurrency picture clearer, which made the static structure clearer, which was more skimmable, what a reader would miss if they only read one.

---

## PHASE 4 — Confirm & verify completeness

First, verify that every expected output file was actually written. The complete set is
**eleven files**:

- `docs/c4/`: `context.md`, `container.md`, `component.md`, `deployment.md`
- `docs/4plus1/`: `logical.md`, `process.md`, `development.md`, `physical.md`, `scenarios.md`
- `docs/overview.md`
- `docs/COMPARISON.md`

Use `Glob` on `docs/**` and compare against this list. If any file is missing, the
corresponding skill did not run or did not finish — re-invoke that specific skill to produce
the missing file(s) before finishing. **Do not report success until all eleven files exist.**

Then report the full list of files written under `docs/` (paths only, one per line), grouped by `docs/c4/`, `docs/4plus1/`, and the two top-level files (`docs/overview.md`, `docs/COMPARISON.md`). Flag anything you deliberately left as `[unknown]` in the docs because none of the six agents surfaced it.
