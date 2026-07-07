# C4 vs 4+1 — Comparison for ClaudeCodeDemo

This comparison is grounded in the actual diagrams produced for this specific system. Generic notation trivia is omitted — the focus is on what each approach revealed, compressed, or made harder to see when applied to ClaudeCodeDemo.

---

## What C4 did well

**Static structure at a glance.** The L1–L3 diagrams give a clean read of what exists and how things are bounded. For a reader unfamiliar with Claude Code, `context.md` immediately answers "what is this and who uses it?" in a single screen. `container.md` answers "what are the storage units?" The box-and-boundary notation makes the Config Repository / Session Logs / Generated Docs split obvious without any prior knowledge of Claude Code conventions.

**The guard hook as a relationship.** The `component.md` diagram surfaced the `guard-reverse-engineer-docs.sh ←→ tracker file ←→ log-subagent.sh` triangle as a named relationship, not just an implementation detail. This was easy to express as labeled arrows between named component boxes — C4 is well suited to showing which components share state.

**Deployment is unambiguous.** `deployment.md` makes the "single workstation, no cloud" topology immediately obvious. For this system, that's the most important infrastructure fact, and C4 delivers it in one diagram.

**Skimmability.** A reader can pick up any of the four C4 files independently and understand it. The fixed legend and consistent box notation reduce cognitive load across files.

---

## What C4 compressed or hid

**Phase 2 parallelism is invisible.** The six agents appear as six identical boxes in `component.md` with arrows from the orchestrator. Nothing in the diagram conveys that all six fire simultaneously or that the SubagentStop hook fires once per completing agent. A reader could easily misread this as sequential execution.

**Hook firing order and lifecycle is absent.** `component.md` shows hooks as boxes with labels, but the triggering events (UserPromptSubmit, Stop, SubagentStop, PreToolUse) are only in the key table, not the diagram itself. The sequencing that makes the tracker gate work — truncate → agents run → hooks append → guard reads — is not visible in any C4 diagram.

**The tracker gate mechanism.** The most fragile coupling in the system (tracker truncated at Phase 1, written by hooks in Phase 2, read by guard in Phase 3) requires prose explanation in the component key. C4 boxes and arrows cannot express temporal ordering.

**Skills running serially inside the orchestrator context** vs. agents running in parallel as separate processes — this distinction is absent from C4. Both appear as similar-looking arrows from the same orchestrator box.

---

## What 4+1 did well

**The process view made concurrency explicit.** `process.md` is the diagram that most clearly shows the two tiers of the system: six concurrent agent processes in Phase 2, three sequential skill invocations in Phase 3. The lifetime annotations (minutes vs. < 1s) and the `background:true` note for agents give a reader an accurate mental model of what actually runs and for how long.

**Scenarios are the most readable entry point.** `scenarios.md` traces the full `/reverse-engineer` workflow as a sequence diagram that crosses logical, process, physical, and enforcement concerns simultaneously. A reader who only reads one file from either architecture doc set will get the most complete picture from `scenarios.md` — more than from any single C4 diagram.

**Hook lifecycle is a first-class citizen.** `process.md` shows every hook as a named process box with its triggering event and its output, in a diagram that makes the event-driven model legible. The guard hook's `permissionDecision: ask` behavior — soft enforcement, not hard block — is visible in the process view in a way it never is in any C4 diagram.

**Logical view captured stereotypes.** Tagging components as `<<orchestrator>>`, `<<agent: haiku>>`, `<<skill>>`, `<<hook: SubagentStop>>` surfaced the heterogeneity of the system's "modules" in a way C4's uniform boxes did not. Knowing that three agents run on haiku and three on sonnet matters for cost and latency reasoning — it fits naturally in a stereotype tag.

---

## What 4+1 compressed or hid

**Harder to skim.** The five 4+1 files require more context to read independently. `logical.md` makes little sense without knowing what Claude Code is. `development.md` describes a layering that is entirely conventional (not technically enforced), which may mislead a reader into thinking there is a real build boundary. C4's context-first ordering is more forgiving.

**Physical view is thin for this system.** With a single workstation and no cloud, `physical.md` is mostly a restatement of "everything is local." The Physical view shines on distributed systems; for ClaudeCodeDemo, it added less than C4's deployment diagram (which made the same point more concisely).

**Scenarios require effort to write correctly.** The sequence diagrams in `scenarios.md` require careful lifeline alignment and notation discipline. They are the most valuable artifact in the 4+1 set, but also the most expensive to produce and maintain.

---

## Side-by-side: what a reader would miss reading only one

| Question | C4 alone | 4+1 alone |
|---|---|---|
| "What are the storage units?" | Fully answered in `container.md` | Only in `logical.md` and `development.md`, less cleanly |
| "How does the guard hook work?" | Key table only; no diagram | `process.md` + `scenarios.md` make it clear |
| "Do the 6 agents run in parallel?" | Not visible | Explicit in `process.md` |
| "What is the deployment topology?" | `deployment.md` answers directly | `physical.md` answers, but more verbosely |
| "What is the end-to-end flow?" | No sequence diagrams | `scenarios.md` traces it fully |
| "What model does each agent use?" | Not surfaced | `logical.md` stereotypes show haiku vs. sonnet |
| "What connects to external services?" | `context.md` and `component.md` key | `scenarios.md` Scenario 3 shows it in flow |

---

## Recommendation for this system

For ClaudeCodeDemo specifically, the **4+1 process view and scenarios view** are the most informative artifacts — they reveal the runtime behavior that makes the repo unusual (concurrent agents, hook-driven ordering, tracker gate). The **C4 context and container diagrams** are the most skimmable entry points for a reader who knows nothing about the project.

A reader who only has time for two files should read: `docs/c4/context.md` (orientation) and `docs/4plus1/scenarios.md` (how it actually works).
