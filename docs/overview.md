# ClaudeCodeDemo — Project Overview

---

## 1. Goal / Purpose

ClaudeCodeDemo is a hands-on study guide for Claude Code — Anthropic's AI-powered CLI for software engineering. Instead of documenting features in the abstract, every Claude Code capability is demonstrated with a working example that lives in this repository. Open the repo in Claude Code, run a command, and see the feature in action.

The intended audience is developers and teams who want to adopt Claude Code and need concrete patterns to follow: how to write a `CLAUDE.md`, how to enforce coding rules, how to build reusable slash commands, how to fan out parallel sub-agents over a codebase, and how to wire up lifecycle hooks for audit logging and safety guards. The `/reverse-engineer` command is the capstone — it combines every feature into one orchestrated workflow that produces architecture documentation for any codebase in a single run.

---

## 2. Technologies Used

| Category | Technology | Version / Notes |
|---|---|---|
| Primary language | Markdown | CommonMark; all commands, skills, agents, rules |
| Scripting | Bash | POSIX-compatible; lifecycle hook scripts |
| JSON parsing in hooks | Node.js | Bundled with Claude Code CLI; no separate install |
| Config format | JSON | `.claude/settings.json` |
| Runtime | Claude Code CLI | Anthropic; version not pinned — auto-updates |
| OS | Windows 11 Enterprise | Developer workstation; hooks use bash via Claude Code |
| Version control | Git | Single `master` branch |
| Agent models | claude-haiku | Used for cheap read-only agents (tech-stack, external-integrations, deployment-infra) |
| Agent models | claude-sonnet | Used for analysis-heavy agents (module-map, data-flows, runtime-process) and the orchestrator |

> There are no compiled artifacts, no package manifests (`package.json`, `go.mod`, etc.), and no build step. This is a configuration and documentation repository — the "application" is Claude Code itself.

---

## 3. Runtime / Process Notes

There is no server, daemon, or long-running application process. The Claude Code CLI is the sole persistent process during a session; it reads `.claude/` configuration files at startup and executes Claude turns interactively.

All other runtime activity is short-lived: the four hook scripts (`turn-start.sh`, `turn-complete.sh`, `log-subagent.sh`, `guard-reverse-engineer-docs.sh`) are bash child processes forked by the Claude Code harness on lifecycle events and exit in under a second each. During `/reverse-engineer` Phase 2, six Claude inference sub-agents run concurrently (`background: true`) as independent inference calls — all read-only, no write contention. Phases 1, 3, and 4 of that command are serial in the orchestrator's own context. There are no scheduled jobs, no message queues, and no background workers.

---

## 4. Sequence Schema

### Session Start — Context Loading

Every Claude Code session automatically loads project context before the first user prompt.

```
  Developer    Claude Code CLI    CLAUDE.md    .claude/settings.json
      |               |               |                  |
      |--open repo--->|               |                  |
      |               |--read-------->|                  |
      |               |<- - context --|                  |
      |               |--read rules, skills, commands--->|
      |               |<- - hooks registered, perms set--|
      |               |                                  |
      |<--ready-----  |               |                  |
```

---

### `/reverse-engineer` — 4-Phase Orchestration

The capstone command: produces 11 architecture doc files from a single prompt.

```
  Developer    Orchestrator    6 Agents (×6)    log-subagent.sh    Skills (×3)    docs/
      |              |               |                  |                |            |
      |--/rev-eng--->|               |                  |                |            |
      |              |--truncate tracker--------------->|                |            |
      |              |               |                  |                |            |
      |              |--spawn(×6)--->|                  |                |            |
      |              |  (concurrent) |--read codebase-->|                |            |
      |              |               |  SubagentStop    |                |            |
      |              |               |=================>|                |            |
      |              |               |                  |--append tracker|            |
      |              |<--summaries (×6 return)----------|                |            |
      |              |               |                  |                |            |
      |              |--invoke skills (sequential)------>                |            |
      |              |               |  PreToolUse guard checks tracker  |            |
      |              |               |                  |--Write docs/-->|            |
      |              |               |                  |         (11 files total)    |
      |              |--glob verify  |                  |                |            |
      |<--done-----  |               |                  |                |            |
```

---

### Turn Timing — Background Measurement

Runs silently on every prompt/response cycle; produces a durable timing log.

```
  Developer    Claude Code CLI    turn-start.sh    turn-complete.sh    .claude/logs/
      |               |                |                   |                 |
      |--prompt------->|               |                   |                 |
      |               |--UserPromptSubmit--------------->  |                 |
      |               |                |--write .turn-start--------------->  |
      |               |   (Claude generates response)      |                 |
      |               |--Stop-------------------------------->               |
      |               |                |                   |--read .turn-start
      |               |                |                   |--append duration->
      |<--response----|                |                   |   turn-completions.log
```

---

## 5. External References

**Datastores**

None. All runtime state is local to the developer workstation in `.claude/logs/` (git-ignored).

**Third-party APIs & Services**

| Service | Used for | When |
|---|---|---|
| `code.claude.com` | Fetch current slash-command frontmatter spec | `/create-command` runs only |
| Anthropic Claude API | Powers all Claude inference (implicit via Claude Code CLI) | Every session |

**MCP Servers**

None currently configured in `.claude/settings.json`. Two are documented in `overview.md` as optional:
- **Atlassian MCP** — would enable Jira ticket fetching; not installed.
- **superpowers** (`@obra/superpowers`) — would add persistent cross-session memory and browser automation; not installed.

**Auth**

None. The repo has no authentication integration. Claude Code CLI handles Anthropic API authentication externally (credentials not stored in this repo).

**Related repositories / docs**

| Resource | Notes |
|---|---|
| [Claude Code docs](https://code.claude.com/) | Official documentation for all features demonstrated here |
| [superpowers](https://github.com/obra/superpowers) | Optional MCP integration; install separately if needed |
| `overview.md` (repo root) | Human-readable study guide with run steps for all 9 demos — distinct from this file |

---

## 6. How to Build / Run

### Prerequisites

- **Claude Code CLI** — install from [claude.ai/code](https://claude.ai/code) or via the Anthropic CLI installer. No version pin; use the latest.
- **Bash** — required to execute hook scripts. On Windows, Claude Code bundles a Bash environment.
- **Git** — for cloning the repo.
- No Node.js install needed — it is bundled with Claude Code and used only internally by hook scripts.

### Get the repo

```bash
git clone git@github-bet4u:DmitryLukyanov/ClaudeCodeDemo.git
cd ClaudeCodeDemo
```

### Open in Claude Code

```bash
claude  # or open via the Claude Code desktop app / IDE extension
```

No build step, no `npm install`, no environment variables required. Claude Code reads `CLAUDE.md` and `.claude/settings.json` automatically on startup.

### Run the demos

| Demo | Command | What you see |
|---|---|---|
| CLAUDE.md | Ask: *"What does this project do?"* | Claude answers from CLAUDE.md without scanning files |
| Rules | Ask Claude to create a `*.broken_md` file with a numbered list | List uses ordinal text ("The first.", "The second.") |
| Slash commands | Type `/create-command my-cmd "Does X" "Read,Grep"` | New `.claude/commands/my-cmd.md` written and shown |
| Skills | Ask: *"Produce a C4 overview of this repo"* | `c4-documentation` skill fires; writes to `docs/c4/` |
| Sub-agents | Type `/reverse-engineer .` | Six agents run in parallel (watch the progress) |
| Hooks | Run `/reverse-engineer .`, then check `.claude/logs/subagents.log` | One timestamped entry per completing agent |
| Full capstone | Type `/reverse-engineer .` | Eleven files written to `docs/`; timing in `turn-completions.log` |

### Verify hook logging (optional)

After a `/reverse-engineer` run:

```bash
# Confirm all 6 agents were recorded
cat .claude/logs/subagents.log

# Check turn duration for the run
cat .claude/logs/turn-completions.log
```

### No test suite

This is a documentation repository — there are no automated tests. Correctness is verified by running the demos and inspecting the output files.
