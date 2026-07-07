# 4+1 Scenarios (+1) — ClaudeCodeDemo

Scenarios are the glue view: each trace validates that the logical, process, development, and physical views work together coherently. Three scenarios cover the architecturally significant workflows in ClaudeCodeDemo. The first — `/reverse-engineer` — is the capstone: it exercises every subsystem. The second — turn timing — is the background side-channel that runs on every prompt. The third — `/create-command` — is the only workflow with an outbound network call.

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

## Scenario 1: `/reverse-engineer` — Full Codebase Documentation Run

*Touches all five views: logical (subsystems), process (6 concurrent agents + hooks), development (commands → agents → skills → output), physical (local file system writes), and the tracker gate (cross-cutting invariant).*

```
  Developer   Claude Code   rev-eng.md   6 Agents (×6,     log-subagent   guard-rev-  skills (×3)   docs/
              CLI           (orchestrator) concurrent)       .sh (hook)     eng-docs.sh (sequential)
      |           |              |               |                |              |            |          |
      |--/reverse-engineer------>|               |                |              |            |          |
      |           |--load cmd--->|               |                |              |            |          |
      |           |              |               |                |              |            |          |
      |           |              |- truncate tracker ---------------------------->|            |          |
      |           |              |  (Phase 1: inventory)          |              |            |          |
      |           |              |               |                |              |            |          |
      |           |              |-spawn(×6)---->|                |              |            |          |
      |           |              |  (Phase 2: all concurrent)     |              |            |          |
      |           |              |               |                |              |            |          |
      |           |              |               |--read codebase->              |            |          |
      |           |              |               |  (×6 independently)          |            |          |
      |           |              |               |                |              |            |          |
      |           |  SubagentStop|               |                |              |            |          |
      |           |=============>|               |                |              |            |          |
      |           |              |               |-SubagentStop-->|              |            |          |
      |           |              |               |  (each of 6)   |--append name->            |          |
      |           |              |               |                |  tracker +   |            |          |
      |           |              |               |                |  subagents.log            |          |
      |           |              |               |                |              |            |          |
      |           |              |<--summary (×6 return)----------'              |            |          |
      |           |              |  (Phase 3: merge facts, invoke skills)        |            |          |
      |           |              |               |                |              |            |          |
      |           |              |--invoke c4-documentation-------|------------->|            |          |
      |           |  PreToolUse  |               |                |              |            |          |
      |           |=============>|               |                |              |            |          |
      |           |              |               |                |-read tracker->            |          |
      |           |              |               |                |  (all 6 present? yes)     |          |
      |           |              |               |                |              |            |          |
      |           |              |               |                |         permissionDecision:ok        |
      |           |              |               |                |              |--Write docs/c4/------>|
      |           |              |               |                |              |            | (4 files) |
      |           |              |               |                |              |            |          |
      |           |              |--invoke 4plus1-documentation--->              |            |          |
      |           |              |  (same guard fires per Write)  |              |            |          |
      |           |              |               |                |              |--Write docs/4plus1/-->|
      |           |              |               |                |              |            | (5 files) |
      |           |              |               |                |              |            |          |
      |           |              |--invoke project-overview------->              |            |          |
      |           |              |               |                |              |--Write docs/overview->|
      |           |              |               |                |              |            |          |
      |           |              |--Write docs/COMPARISON.md----->               |            |--------->|
      |           |              |  (Phase 4: glob verify 11 files)              |            |          |
      |           |              |               |                |              |            |          |
      |<--done----|              |               |                |              |            |          |
```

**What this scenario reveals:**
- The tracker file is the central ordering invariant: truncated at Phase 1, written by hooks at Phase 2, read by the guard at Phase 3.
- The guard hook fires on every Write call to `docs/` — it is a cross-cutting enforcement that touches the process, logical, and physical views simultaneously.
- Phase 2 parallelism is real concurrency: 6 agents run simultaneously; SubagentStop hooks may fire concurrently.

---

## Scenario 2: Turn Timing — Every Prompt, Every Response

*Touches the process view (two hooks) and the physical view (local file system). Runs in parallel with every other scenario — it is always active.*

```
  Developer   Claude Code   turn-start.sh   turn-complete.sh   .turn-start    turn-completions.log
      |           |               |                |                |                  |
      |--prompt-->|               |                |                |                  |
      |           |               |                |                |                  |
      |           |--UserPromptSubmit------------->|                |                  |
      |           |               |--write epoch + prompt--------->|                  |
      |           |               |                |                |                  |
      |           |  (Claude generates response)   |                |                  |
      |           |               |                |                |                  |
      |           |--Stop------------------------->|                |                  |
      |           |               |                |--read-------->|                  |
      |           |               |                |                |                  |
      |           |               |                |--compute elapsed seconds          |
      |           |               |                |--append ISO + duration + prompt-->|
      |           |               |                |                |                  |
      |<--response|               |                |                |                  |
```

**What this scenario reveals:**
- `.turn-start` is ephemeral (overwritten each prompt); `turn-completions.log` is durable (append-only).
- If Stop fires without a preceding UserPromptSubmit (e.g., harness restart), `turn-complete.sh` exits silently — a deliberate guard.
- This scenario demonstrates why the Physical view matters: both files are local, git-ignored, and lost if the workstation is wiped.

---

## Scenario 3: `/create-command` — Scaffolding a New Slash Command

*Touches the logical view (scaffolder component), the process view (inline execution in CLI), the physical view (outbound HTTPS + local write), and the development view (output lands in `.claude/commands/`).*

```
  Developer   Claude Code   create-command.md   code.claude.com   helpers.sh   .claude/commands/
      |           |                |                   |               |                |
      |--/create-command name desc tools->             |               |                |
      |           |--load cmd----->|                   |               |                |
      |           |                |                   |               |                |
      |           |                |--WebFetch spec--->|               |                |
      |           |                |<--slash-cmd spec--|               |                |
      |           |                |                   |               |                |
      |           |                |--bash check-commands------------->|                |
      |           |                |<--existing command list-----------|                |
      |           |                |                   |               |                |
      |           |  (name collision check; if conflict → ask user)    |                |
      |           |                |                   |               |                |
      |           |                |--Write .claude/commands/<name>.md---------------->|
      |           |                |                   |               |                |
      |<--done, file path shown----|                   |               |                |
```

**What this scenario reveals:**
- This is the only workflow with an outbound network call (`code.claude.com`) — all others are purely local.
- The new command file is immediately available as `/<name>` in the same session — no restart needed.
- The guard hook (`guard-reverse-engineer-docs.sh`) does **not** fire here because the target path is `.claude/commands/`, not `docs/` — the guard is narrowly scoped.
