# C4 vs 4+1 — Comparison for ClaudeCodeDemo

This document compares the C4 and Kruchten 4+1 outputs produced by `/reverse-engineer` for this specific system. The goal is not to evaluate the notations in the abstract but to identify what each approach surfaced well, compressed away, or expressed more clearly given the nature of a Claude Code configuration repository.

---

## What C4 surfaced well

**External boundary legibility.** The C4 diagrams make the "inside vs outside" distinction immediately visible. `docs/c4/context.md` shows at a glance that ClaudeCodeDemo has two external systems (Anthropic Claude API, code.claude.com), two optional external systems (superpowers MCP, Playwright MCP), and one human actor (Developer). The `+===+` notation for external systems creates a strong visual contrast with `+---+` internal boxes. A reader scanning for "what does this system call externally?" gets the answer in five seconds.

**Technology tags at L2.** The container diagram's `[type: Technology]` tags — `[Process: Claude Code]`, `[Script: Bash]`, `[File: Log]` — make it easy to distinguish processes from scripts from data stores without reading prose. For a system where all files look similar (they're all Markdown or Bash), this disambiguation is genuinely useful.

**Altitude discipline.** The L1 → L2 → L3 zoom structure gives readers a controlled entry point. L1 shows the system as a black box, L2 opens it into runnable units, L3 zooms into the CLI's internal components. A reader can stop at whatever level of detail they need. The 4+1 views don't offer this graduated zoom — a reader has to know which view to start with.

**Two-log detail.** This run's C4 container diagram is the only view that distinguishes `subagents.log` from `subagents-debug.log` as separate containers, making the fallback audit path visible at the structural level.

---

## What 4+1 surfaced well

**Concurrency and runtime ordering.** The Process view (`docs/4plus1/process.md`) makes the fan-out/sync-point pattern visible in a way no C4 diagram can. The six concurrent subagent processes, the explicit sync point between Phase 2 and Phase 3, the sequential ordering constraint within Phase 3, and the async SubagentStop sidecar — all of these are architectural decisions with correctness implications, and all are invisible in C4's structural diagrams.

**Layer dependencies.** The Development view (`docs/4plus1/development.md`) shows the layered structure of `.claude/`: orchestration at the top, fact-gathering and rendering in the middle, utility and monitoring below, constraint layer at the base. The layer diagram makes forbidden dependencies explicit (fact-gathering agents never invoke rendering skills; rendering skills never spawn agents). C4 shows what calls what; the Development view shows what is allowed to call what.

**Scenario 3 exposed the hook bug.** The Scenarios (+1) view (`docs/4plus1/scenarios.md`) traced the SubagentStop flow end-to-end and surfaced the known bug: 26 events fired, only 2 resolved `agent_type`, 24 logged "unknown", and `subagents-debug.log` is effectively empty despite being the intended fallback — meaning the `[ -z "$agent" ]` guard is not triggering as expected. This bug is invisible in all four structural views; it only becomes visible when you trace an actual flow through the hook's parsing logic.

**Model-tier distinction.** The Logical view's `<<agent>>` stereotypes with model labels (haiku vs sonnet) surfaced the deliberate cost/depth tradeoff embedded in the agent definitions — haiku for fast structural scans, sonnet for deeper reasoning. This distinction appears nowhere in the C4 container diagram.

---

## What each hid or compressed

| C4 | 4+1 |
|---|---|
| Concurrency invisible — no way to show 6 concurrent processes or the sync point | No external boundary notation — "what is outside the system?" is not a first-class 4+1 concern |
| Phase 3 sequential ordering constraint is not expressible | Development view requires the reader to know which directories constitute "layers" — not self-explaining |
| SubagentStop async sidecar is invisible in all four C4 levels | Physical view is sparse for a local-only system — adds little new information here |
| Optional external systems (MCP) require prose footnotes rather than first-class diagram elements | Scenarios require significant background knowledge to write well; easy to pick the wrong three |
| Model-tier difference (haiku vs sonnet) between agents is not representable | UML-flavored notation is unfamiliar to readers who only know C4 |

---

## Which was more skimmable

**C4 is more skimmable for "what is this system?"** The L1 context diagram answers "who uses it, what does it call externally" in under five seconds. The `+---+` box notation is visually clean.

**4+1 is more skimmable for "how does this system behave?"** The Process view answers questions about ordering, concurrency, and fault modes that a C4 container diagram cannot. The Scenarios view is the fastest entry point for a developer who wants to understand the system by example rather than by structure.

---

## What a reader would miss reading only one

**Reading only C4:** You would miss the concurrency model entirely. You would not know that Phase 2 is a fan-out of 6 independent processes, that there is a hard sync point before Phase 3, that Phase 3 runs sequentially, or that the SubagentStop hook fires asynchronously. You would also miss the layering constraints (what is forbidden to call what) and the hook bug.

**Reading only 4+1:** You would have a less clear picture of the external boundary — which systems are inside the operator's control and which are not. The `+===+` external system notation in C4 has no direct equivalent in 4+1. You would also miss the clean L1/L2/L3 zoom that lets a reader enter at the right altitude.

---

## Recommended reading order

For a developer new to this codebase:

1. **C4 L1 (context.md)** — understand the external boundary in 30 seconds
2. **4+1 Process (process.md)** — understand the concurrency model and Phase ordering
3. **4+1 Scenarios (scenarios.md)** — trace the three main flows end-to-end
4. **C4 L3 (component.md)** — understand the internal components of the CLI
5. **4+1 Development (development.md)** — understand layer dependencies and what is forbidden
6. **C4 Deployment + 4+1 Physical** — both say "everything local except Anthropic API"; either one suffices
