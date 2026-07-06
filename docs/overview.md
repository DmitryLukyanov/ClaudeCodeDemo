# ClaudeCodeDemo — Project Overview

## 1. Goal / Purpose

ClaudeCodeDemo is a hands-on study guide for Claude Code — Anthropic's AI-powered CLI for software engineering. Its purpose is to make every major Claude Code feature tangible: instead of describing features in the abstract, each one is illustrated with a working demo that the reader can run directly from a fresh checkout. The repo itself is the subject — every demo works by invoking the actual commands, rules, skills, and hooks defined in `.claude/`.

The primary audience is developers who already know how to use Claude Code at a basic level and want to build more sophisticated workflows: custom slash commands, multi-agent orchestration, lifecycle hooks, and reusable skills. The capstone demo — `/reverse-engineer` — orchestrates 6 concurrent specialist agents and 3 documentation-rendering skills to produce C4 diagrams, 4+1 architecture views, and a project overview from any codebase, including this one.

---

## 2. Technologies Used

| Category | Technology | Version / Notes |
|---|---|---|
| Platform | Claude Code CLI | claude.ai/code — install once globally |
| LLM (commands) | Claude Sonnet | claude-sonnet-5 (specified in command frontmatter) |
| LLM (agents, fast) | Claude Haiku | tech-stack, external-integrations, deployment-infra agents |
| LLM (agents, deep) | Claude Sonnet | module-map, data-flows, runtime-process agents |
| Command format | Markdown | `.claude/commands/*.md` with YAML frontmatter |
| Agent format | Markdown | `.claude/agents/*.md` with YAML frontmatter (`background: true`) |
| Skill format | Markdown | `.claude/skills/*/SKILL.md` with YAML frontmatter |
| Rule format | Markdown | `.claude/rules/*.md` with path-glob frontmatter |
| Hook scripts | Bash | `.claude/hooks/*.sh` — executed on lifecycle events |
| Helper scripts | Bash | `.claude/scripts/*.sh` — forked inline by commands |
| Configuration | JSON | `.claude/settings.json` (permissions + hooks) |
| Local config | JSON | `.claude/settings.local.json` (local debug permissions; not committed) |
| Version control | Git | standard; no CI/CD pipeline |
| Optional MCP | superpowers | `npm install -g @obra/superpowers` — not currently installed |
| Optional MCP | Playwright | User-level config; `.playwright-mcp/` dir present at repo root |

No build step, no package manager, no compiled artifacts. Opening the repo in Claude Code is the only setup required.

---

## 3. Runtime / Process Notes

The only runtime is the Claude Code CLI itself — a single interactive process per session that starts when the developer opens the repo and ends when they close it. At startup, Claude Code automatically reads `CLAUDE.md` (project context) and `.claude/settings.json` (permissions and hook configuration).

When the developer invokes `/reverse-engineer`, Claude Code runs a 4-phase workflow. Phase 2 spawns six independent background child processes concurrently (the specialist agents in `.claude/agents/`), using haiku for fast structural scans and sonnet for deeper analysis. After the sync point, Phase 3 runs three documentation-rendering skills sequentially in the main process to avoid write conflicts. After each of the six agents completes, a `SubagentStop` lifecycle event forks a transient bash child (`log-subagent.sh`) that appends an audit line to `.claude/logs/subagents.log`. As of this writing, 26 events have been recorded; 24 show "unknown" agent_type due to a known bug in the hook's JSON parsing pattern.

There are no scheduled jobs, no message queues, and no long-running background services.

---

## 4. Sequence Schema

**Flow 1 — `/reverse-engineer` (capstone use case)**

6 agents scan the codebase concurrently, then 3 skills render documentation from the merged facts.

```
  Developer   Claude CLI   Subagents(x6)  Skills(x3)  docs/
      |             |             |            |          |
      |--/reverse-->|             |            |          |
      |             |=Phase 1: self-inventory (inline)=|  |
      |             |--spawn all->|            |          |
      |             |   6 at once |            |          |
      |             |<--summaries-|            |          |
      |             |   (all 6)   |            |          |
      |             |=[sync point]============>|          |
      |             |--Phase 3A: c4-documentation------->|
      |             |--Phase 3B: 4plus1-documentation--->|
      |             |--Phase 3C: project-overview------->|
      |<- - result -|             |            |          |
```

**Flow 2 — `/create-command` (command scaffolding)**

Fetches live spec, checks for filename collisions, writes a new command file.

```
  Developer   Claude CLI   helpers.sh   code.claude.com  commands/
      |             |            |             |               |
      |--/create--->|            |             |               |
      |             |=fetch spec===============>               |
      |             |<- - spec - |             |               |
      |             |--check-commands--------->|               |
      |             |<- - existing files - - - |               |
      |             |--Write .md file------------------------>|
      |<- - result -|            |             |               |
```

**Flow 3 — SubagentStop hook (background audit)**

Fires asynchronously after each agent completes; does not block the main workflow.

```
  Claude CLI   Agent runtime   log-subagent.sh   subagents.log
      |              |               |                 |
      |<--done-------|               |                 |
      |═SubagentStop event ════════> |                 |
      |              |               |--append TSV---->|
      |              |               |<- - exit - - - -|
      |  [Phase 3 unblocked]         |                 |
```

---

## 5. External References

**Datastores**
- `subagents.log` — append-only TSV at `.claude/logs/subagents.log`; one line per agent completion; 26 entries as of 2026-07-07 (24 show "unknown" agent_type due to hook bug)
- `subagents-debug.log` — fallback at `.claude/logs/subagents-debug.log`; captures raw JSON when agent_type extraction fails; effectively empty (branch not triggering as expected)

**Third-party APIs & Services**
- **Anthropic Claude API** — all LLM inference; accessed by Claude Code CLI and all subagent processes over HTTPS; credentials managed by the Claude Code CLI at installation time (no separate API key in this repo)
- **code.claude.com** — Claude Code documentation site; fetched over HTTPS on-demand by `/create-command` to retrieve the current slash-command spec; no credentials required

**Auth**
None. Claude Code CLI authenticates to the Anthropic API automatically using credentials stored at CLI installation time. No tokens, secrets, or environment variables are managed in this repository.

**Related repositories / docs**
- [claude.ai/code](https://claude.ai/code) — Claude Code product page and download
- [overview.md](../overview.md) — Master feature guide in this repo; one scenario per feature
- [CLAUDE.md](../CLAUDE.md) — Session context file; defines repo purpose and layout for every Claude Code session
- [superpowers MCP](https://github.com/obra/superpowers) — Optional external agent framework; see `overview.md §8` for setup steps

---

## 6. How to Build / Run

### Prerequisites
1. Install Claude Code CLI: [claude.ai/code](https://claude.ai/code)
2. Git (any recent version)

### Setup
```
git clone <repo-url>
cd ClaudeCodeDemo
```
No `npm install`, no `pip install`, no build step.

### Open in Claude Code
```
claude .
```
Or open the folder from the Claude Code desktop app or IDE extension (VS Code, JetBrains).

### Run the demos

| Demo | How to invoke |
|---|---|
| Reverse-engineer this repo into architecture docs | `/reverse-engineer` |
| Scaffold a new slash command | `/create-command my-cmd "What it does" "Read, Grep"` |
| Engage the C4 documentation skill | Ask: "Produce a C4 architecture overview of this repo" |
| Engage the 4+1 documentation skill | Ask: "Produce a 4+1 architecture view of this repo" |
| Trigger the markdown rule | Create any file matching `*.broken_md` and write a numbered list |
| Inspect the SubagentStop hook | Run `/reverse-engineer`, then check `.claude/logs/subagents.log` |
| See the hook bug | Open `.claude/logs/subagents.log` — most entries show "unknown" agent_type |

### Optional: enable superpowers MCP
```
npm install -g @obra/superpowers
```
Then register it in `.claude/settings.json` — see `overview.md §8` for the exact steps.

### Tests
None. This is a configuration demo repository; there is no application code to test. Correctness is verified by running the demos and observing their outputs.
