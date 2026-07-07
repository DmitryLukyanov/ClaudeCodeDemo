# ClaudeCodeDemo — Project Overview

## 1. Goal / Purpose

**ClaudeCodeDemo** is a hands-on study guide that demonstrates real-world usage of Claude Code
features, each illustrated with a concrete, runnable example. It is deliberately
*self-referential*: the repository's own configuration — its commands, skills, agents, hooks,
and rules — is both the teaching material and the subject the tools operate on.

The flagship capability is the **`/reverse-engineer` command**, which turns any codebase into a
consistent set of architecture documentation: C4 diagrams, Kruchten 4+1 views, a standalone
overview, and a comparison of the two notations. It does this by gathering facts about the
system **once** (via six parallel sub-agents), then rendering that single fact set through
three documentation skills — so all outputs describe the same system rather than three
independently-researched, possibly inconsistent views. Along the way the repo showcases every
major Claude Code feature: `CLAUDE.md`, rules, slash commands, skills, sub-agents, hooks, MCP
servers (documented pattern only), external skills (the superpowers plugin), and the Agent SDK.

## 2. Technologies Used

| Category | Technology | Version / Notes |
|---|---|---|
| Language | Python | 3.x — `[unknown]` exact version (no `.python-version`/manifest); asyncio; `claude_agent_sdk` |
| Language | Bash / POSIX shell | 4 lifecycle hooks + `helpers.sh` (~200 lines); parse JSON stdin via `node -e` |
| Config language | Markdown + YAML frontmatter | commands, skills (`SKILL.md`), agents, rules (~1000+ lines) |
| Config language | JSON | `.claude/settings.json` (hooks + `enabledPlugins`), `settings.local.json` (permissions) |
| Runtime | Node.js | Bundled with Claude Code; used by hooks for JSON parsing |
| SDK | claude-agent-sdk (PyPI) | **Unpinned** — no `requirements.txt`/`pyproject.toml` (GAP) |
| Plugin | superpowers | `superpowers@claude-plugins-official`; ~14 workflow skills |
| Models | Claude haiku / sonnet | haiku: tech-stack, external-integrations, deployment-infra; sonnet: module-map, data-flows, runtime-process; `/create-command` uses claude-sonnet-5 |
| Database / Queue / Containers / CI / IaC | None | Intentionally absent — this is a config/demo repo, not a deployed service |
| Build system | None | No Makefile or manifest; run interactively or via the Python driver |

## 3. Runtime / Process Notes

At runtime there is a **single top-level process**: either an interactive Claude Code session
(`claude .`) or a headless Python asyncio process (`scripts/run-reverse-engineer.py`), which
drives the same workflow through the Agent SDK. The one place real concurrency appears is
**Phase 2 of `/reverse-engineer`**, where the orchestrator spawns exactly **six read-only
sub-agents in parallel** (`background: true`) that analyze the codebase simultaneously; the
orchestrator then **waits at a barrier** for all six to return before synthesizing. Four
**lifecycle hooks** run as short-lived subprocesses on Claude Code events (they are not
daemons): one logs each finishing sub-agent, one guards documentation writes, and two record
per-turn timing. Coordination between hooks and the orchestrator happens through a plain-text
**tracker file** (`.claude/logs/reverse-engineer-run.tracker`), an append-only completion tally
reset at the start of each run. There are **no cron jobs, message queues, brokers, daemons, or
thread pools**.

## 4. Sequence Schema

### Flow 1 — Full reverse-engineer run (the primary happy path)

Illustrates the fan-out/fan-in pipeline: orient, spawn six agents, join, render, verify.

```
  User        Orchestrator      6 Subagents      Tracker        3 Skills
   |               |                 |              |               |
   |--/rev-eng .-->|                 |              |               |
   |               |--Phase1: reset tracker + orient (Glob/Read)---|
   |               |--Phase2: spawn 6 (parallel)-->|               |
   |               |                 |══SubagentStop: append══>|   |
   |               |<= = barrier: wait for all six = |            |
   |               |--Phase3: merge facts, invoke skills--------->|
   |               |                 |              | (guard hook  |--writes
   |               |                 |              |  checks: 6 ok)|  docs/*
   |               |--write COMPARISON.md (direct)                 |
   |               |--Phase4: Glob docs/** verify 11 files         |
   |<- - report - -|                 |              |               |
```

### Flow 2 — Headless / CI run via the Agent SDK

Same Phase 1–4 flow, driven by Python with a hard budget cap that can stop it mid-run.

```
  CI Shell     run-reverse-engineer.py     SDK query()      ResultMessage
   |                  |                        |                 |
   |--python ...  --->|                        |                 |
   |                  |--query("/rev-eng .")-->|                 |
   |                  |<==stream Assistant/User/System msgs======|
   |                  |<- - - - subtype - - - - - - - - - - - - -|
   |                  |  success              => exit 0          |
   |                  |  error_max_budget_usd => resume hint;exit1|
   |<- - exit code - -|  error_max_turns      => resume hint;exit1|
```

### Flow 3 — Scaffold a new slash command (`/create-command`)

Shows the secondary command and its live-docs dependency.

```
  User      /create-command     code.claude.com    helpers.sh     commands/
   |             |                    |                 |             |
   |--/create-command name "desc"---->|                 |             |
   |             |--WebFetch docs----->|                 |             |
   |             |--check-commands (echo verbatim)------>|             |
   |             |--collision? ask before overwrite                   |
   |             |--Write .claude/commands/<name>.md----------------->|
   |<- - report path + contents - -|   |                 |             |
```

## 5. External References

**Datastores**
None. This repo has no database, cache, or object store.

**Third-party APIs & Services**
- **Anthropic API** (Claude models) — reached via `claude_agent_sdk`; the only outbound network dependency. Provides model inference for the agent loop.
- **superpowers plugin** (`superpowers@claude-plugins-official`) — external Claude Code plugin enabled in `.claude/settings.json`; supplies ~14 reusable workflow skills. Installed once via `/plugin install superpowers@claude-plugins-official`.
- **code.claude.com** — `/create-command` performs a `WebFetch` to the live slash-command documentation when scaffolding new commands.
- **MCP servers** — a documented extension pattern (see `overview.md` §7 in the repo root, the study-guide index) but **none are configured** in this repo.

**Auth**
- **Anthropic authentication** — via the `ANTHROPIC_API_KEY` environment variable or a prior `claude auth` login. Required for the headless Agent SDK driver. No other auth providers.

**Related repositories / docs / tickets**
- Repo-root study guide: `overview.md` (the master feature index), `README.md`, `CLAUDE.md`.
- superpowers plugin: https://github.com/obra/superpowers
- Claude Agent SDK: https://code.claude.com/docs/en/agent-sdk/agent-loop
- Companion architecture docs generated by this workflow: `docs/c4/`, `docs/4plus1/`, `docs/COMPARISON.md`.

## 6. How to Build / Run

There is **no build step**. Two ways to run:

### Interactive (in Claude Code)
1. **Prerequisite:** open the repo in Claude Code — `claude .` (auto-loads `CLAUDE.md`, `.claude/settings.json` hooks + plugins, rules, commands, skills, agents).
2. **One-time:** install the superpowers plugin — `/plugin install superpowers@claude-plugins-official`.
3. **Run the capstone:** type `/reverse-engineer .` (or any target path). Watch the six agents run in parallel, then the three skills render docs.
4. **Or scaffold a command:** `/create-command my-command "What it does" "Read, Grep"`.

### Headless (CI / automation)
1. **Prerequisites:** `pip install claude-agent-sdk`; set `ANTHROPIC_API_KEY` (or run `claude auth`).
2. **Run:** `python scripts/run-reverse-engineer.py [path]` (path defaults to `.`).
   - Enforces a **$6.00 budget cap**; uses `effort="medium"` deliberately (`"high"` exhausts context before Phase 3 completes).
   - Exit code **0** on success; **1** on budget cap / turn limit / error (prints a resume hint with the session ID).

### Helper (optional)
- `bash .claude/scripts/helpers.sh top-level-listing` — cheap orientation listing.
- `bash .claude/scripts/helpers.sh check-commands` — lists existing slash commands.

### Outputs & verification
- **11 generated files:** `docs/c4/{context,container,component,deployment}.md`, `docs/4plus1/{logical,process,development,physical,scenarios}.md`, `docs/overview.md`, `docs/COMPARISON.md`.
- **Verify a run:** `.claude/logs/subagents.log` confirms all six agents fired; `.claude/logs/turn-completions.log` shows the run duration.
- **Platform:** tested on Windows 11 (hook scripts normalize backslashes to forward slashes).
- **Tests:** none in this repo (no automated test suite).
