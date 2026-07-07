# C4 vs 4+1 — Comparison for ClaudeCodeDemo

This document compares the two architecture-notation sets just produced for **this specific
system** — the C4 docs in `docs/c4/` and the Kruchten 4+1 docs in `docs/4plus1/`. Both were
rendered from the same merged fact set, so any difference below is a difference in what the
*notation* surfaces, not in the underlying facts. The verdict matters here because
ClaudeCodeDemo is an unusual subject: a self-referential Claude Code config toolkit with no
servers, database, or classes — its "architecture" is an orchestration pipeline plus a set of
declarative lifecycle hooks.

## At a glance

| Dimension | C4 did it better | 4+1 did it better |
|---|---|---|
| Static structure / who-owns-what | ✅ Container + Component views | |
| Runtime concurrency & the fan-out barrier | | ✅ Process view (double-arrow IPC, explicit barrier) |
| End-to-end flows / failure paths | | ✅ Scenarios view (4 sequence diagrams incl. guard override) |
| Skimmability for a newcomer | ✅ L1 Context fits one screen | |
| Code/build organization & the SDK GAP | | ✅ Development view (layered packages + deps) |
| External dependency picture | ✅ Context view (boundary-crossing arrows) | partially (Logical + Physical split it) |
| Handling "no infrastructure" gracefully | tie (Deployment ≈ Physical) | tie |

## Where C4 was stronger

- **Static structure and ownership.** The C4 Container and Component views made the enforced
  acyclic dependency (`command → agents`, `command → skills`, peers never calling each other)
  immediately legible as nested boxes. The rule that *only* the orchestrator spawns agents or
  invokes skills reads naturally as a containment hierarchy — exactly what C4's box-in-box
  notation is for.
- **Skimmability at the top.** The C4 L1 Context diagram compresses the whole system to one box
  with three external systems (Anthropic API, superpowers, MCP) and two actors. For a newcomer
  asking "what talks to what," it fits on a single screen and answers the question before any
  detail arrives. 4+1 has no single equivalent "one-box" altitude.
- **The external boundary.** C4's distinction between in-boundary (`──>`) and boundary-crossing
  (`==>`) arrows made "the only outbound network is the Anthropic API" visually obvious in one
  glance — the boundary is a first-class concept in C4, whereas 4+1 spreads externals across
  the Logical and Physical views.

## Where 4+1 was stronger

- **Runtime concurrency — the standout difference.** C4 has no native home for the six-way
  parallel fan-out; the Container view could only *list* the six subagents as a box. The 4+1
  **Process view** showed them as concurrent lifelines, drew the `SubagentStop → tracker`
  appends as async double-arrows, and — critically — drew the **barrier** ("wait for all six")
  as an explicit synchronization line. For this system, whose single most interesting property
  *is* the fan-out/join, that is the difference between mentioning concurrency and actually
  depicting it.
- **Failure and override paths.** The 4+1 **Scenarios view** dedicated a full sequence diagram
  to the guard hook firing (`permissionDecision:"ask"`) and the soft-gate override — the exact
  "skipped Phase 2, wrote stale docs" failure mode this repo's hooks exist to catch. C4 has no
  scenario/behavioral level, so this risk is invisible in the C4 set. Likewise the budget-cap
  mid-run stop appears only in the 4+1 headless-run scenario.
- **Code organization and the dependency GAP.** The 4+1 **Development view** laid the repo out
  as dependency-ordered layers (Entry/Docs → Orchestration → Worker/Renderer) and surfaced the
  unpinned `claude-agent-sdk` as an explicit external-dependency GAP. C4 (by design) stops at
  runtime containers and never addresses build-unit layering.

## What a reader would miss by reading only one

- **Only C4:** you would understand the component hierarchy and external boundary, but you would
  **not** know that six agents run in parallel, that there is a join barrier, that a soft
  write-gate can be overridden, or that the Python driver enforces a budget cap. You would also
  miss the unpinned-SDK gap. In short: the entire *dynamic* and *risk* picture.
- **Only 4+1:** you would understand the runtime behavior and flows richly, but the five views
  spread the static picture thin — there is no single "system in one box" diagram, and the
  clean containment story (orchestrator owns everything) is less immediately obvious than in
  C4's nested boxes. A newcomer would take longer to get the 30-second orientation.

## Recommendation for this system

Because ClaudeCodeDemo's essence is an **orchestration pipeline with concurrency and guard
hooks**, the **4+1 Process + Scenarios views carry the most signal** — they capture what makes
this system interesting and where it can go wrong. But the **C4 Context view is the best single
artifact for onboarding**: hand a newcomer `docs/c4/context.md` first for the 30-second picture,
then `docs/4plus1/process.md` and `docs/4plus1/scenarios.md` for how it actually runs. The C4
Component and 4+1 Logical views largely overlap for this repo; if you standardized on one
notation, keep C4 for the structural docs and borrow 4+1's Process/Scenarios views to cover the
runtime dimension C4 cannot express.
