# C4 — Deployment

This view shows *where* things run. ClaudeCodeDemo has no servers, containers, or cloud
infrastructure — all execution is **local**, on a developer workstation or a CI runner. There
are two deployment modes: interactive (a human runs `claude .`) and headless (a caller runs
the Python driver). Both load the same on-disk `.claude/` project settings and both reach out
to exactly one external node: the Anthropic API. There is no Dockerfile, no orchestration, and
no IaC in this repo.

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

```
+---------------------------------------------+       +==========================+
|  Local Machine                              |       |  Anthropic Cloud         |
|  [Node: Developer workstation / CI runner]  |       |                          |
|  OS: Windows 11 (paths normalized)          |       |  +====================+  |
|                                             |       |  |  Anthropic API     |  |
|  +--------------------------------------+   |       |  |  [External SaaS]   |  |
|  |  Claude Code Runtime                 |   |       |  +====================+  |
|  |  [Node.js + bundled tooling]         |===========>        ^                 |
|  |   - loads .claude/ project settings  |   | HTTPS |        |                 |
|  |   - hosts /reverse-engineer command  |   | agent |        |                 |
|  |   - spawns 6 subagents, 4 hooks      |   | loop  |        |                 |
|  |   - superpowers plugin (installed    |   |       |        |                 |
|  |     once via /plugin install)        |   |       |        |                 |
|  +--------------------------------------+   |       +==========================+
|                    ^                        |                |
|                    | in-process / SDK       |                |
|  +--------------------------------------+   |                |
|  |  Python Agent SDK Driver             |   |  HTTPS (via    |
|  |  [python + claude-agent-sdk]         |==================================> (same API)
|  |   run-reverse-engineer.py            |   |  SDK query())  |
|  +--------------------------------------+   |                |
|                                             |                |
|  +--------------------------------------+   |                |
|  |  Working Tree (on-disk state)        |   |                |
|  |  [Files]                             |   |                |
|  |   .claude/ (settings, cmds, skills,  |   |                |
|  |     agents, hooks, rules, logs)      |   |                |
|  |   docs/ (rendered output)            |   |                |
|  |   scripts/, CLAUDE.md, overview.md   |   |                |
|  +--------------------------------------+   |                |
+---------------------------------------------+                |
```

## Element & Relationship Key

| Node / Element | Description |
|---|---|
| Local Machine | A single developer workstation or CI runner. All compute happens here; there is no remote deployment target. Tested on Windows 11 (hook scripts normalize `\` → `/` with `tr`). |
| Claude Code Runtime | The interactive host process. Loads the on-disk `.claude/` project settings, hosts the `/reverse-engineer` command, spawns the six subagents and four hook subprocesses, and loads the superpowers plugin (installed once via `/plugin install superpowers@claude-plugins-official`). |
| Python Agent SDK Driver | The headless entry point (`scripts/run-reverse-engineer.py`). Requires `pip install claude-agent-sdk` and `ANTHROPIC_API_KEY` (or `claude auth`). Runs the same workflow with `setting_sources=["project"]`, a `$6.00` budget cap, and exit codes 0/1 driven by `ResultMessage.subtype` (`success` / `error_max_budget_usd` / `error_max_turns` / other). |
| Working Tree | The repository on disk: `.claude/` (settings, commands, skills, agents, hooks, rules, logs), `docs/` (rendered output), `scripts/`, `CLAUDE.md`, `overview.md`. Both runtimes read/write this same tree. |
| Anthropic API | The only remote node. Provides Claude model inference for the agent loop. |

| Network Path | Description |
|---|---|
| Claude Code Runtime ⇒ Anthropic API | HTTPS agent-loop / inference traffic during interactive sessions. |
| Python Driver ⇒ Anthropic API | HTTPS via `claude_agent_sdk.query()` during headless runs. |
| Driver ↔ Claude Code Runtime | The driver starts a Claude Code agent session in-process via the SDK; both share the same on-disk `.claude/logs/*` state (concurrent runs could interleave writes — no locking). |

## Notes / Gaps

- **No containers, orchestration, CI/CD, or IaC exist in this repo** — confirmed absent (no Dockerfile, compose, Kubernetes, Terraform, or `.github/workflows`). The Agent SDK driver is *described* as CI-suitable, but no pipeline is wired up.
- **Python version is unspecified** — no `requirements.txt`, `pyproject.toml`, or `.python-version` (`[unknown]`). `claude-agent-sdk` is a documented prerequisite but not pinned.
- **MCP servers** are a documented deployment extension point (`overview.md` §7) but none are configured.
