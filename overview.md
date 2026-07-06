# Claude Code Feature Overview

This file is the study guide for the ClaudeCodeDemo repository. Each section covers one Claude Code feature with a concrete, runnable example. Read sections in order — later features build on earlier ones.

---

## 1. CLAUDE.md

**What it is:** A markdown file at the repository root that Claude Code reads at the start of every session. It gives Claude persistent context: project purpose, architecture, conventions, and anything a new contributor would need to be productive. Think of it as an onboarding doc written for an AI collaborator.

**When to use it:** Always. Every project that uses Claude Code should have one. Add to it whenever you discover something that took time to figure out and would slow down a future session.

**Real-life scenario:** You are onboarding a new developer to a Node.js REST API. Instead of writing a wiki page that goes stale, you write a `CLAUDE.md` that describes the API's structure, how to run migrations, and which environment variables are required. Claude Code reads this automatically and never asks questions that are already answered there.

**Files involved:**
- `CLAUDE.md` — the live example (this repo's own CLAUDE.md)

**How to run:**
1. Open this repo in Claude Code.
2. Ask: *"What does this project do and how is it structured?"*
3. Claude answers from `CLAUDE.md` without reading every file first.

---

## 2. Rules

**What it is:** Markdown files in `.claude/rules/`. Each file contains a focused constraint or policy that Claude follows in every interaction for this project. Rules are injected alongside `CLAUDE.md` automatically. Unlike `CLAUDE.md` (which gives context), rules explicitly shape behavior — they tell Claude what to do or not do.

**When to use it:** When you have team-wide standards that must never slip: coding style, security policies, commit message format, or prohibited patterns. Rules enforce these without repeating them in every prompt.

**Real-life scenario:** Your team requires all SQL queries to use parameterized statements (no string interpolation). You add `.claude/rules/sql-safety.md` stating this. Now Claude will always write parameterized queries in this project, even if a prompt asks for a quick prototype.

**Files involved:**
- `.claude/rules/markdown.md` — active rule scoped to `**/*.broken_md` files: ordered lists must use ordinal text ("The first.", "The second.") instead of numeric bullets

**How to run:**
1. Open the repo in Claude Code.
2. Ask Claude to create or edit a `*.broken_md` file containing a numbered list.
3. Claude writes the list as "The first. / The second. / …" — proof the path-scoped rule fired.

---

## 3. Slash Commands

**What it is:** Markdown files in `.claude/commands/`. Each file defines a custom slash command invoked as `/command-name` in the Claude Code prompt. The file body is a prompt template — with optional frontmatter and arguments — that Claude executes when you type the command.

**When to use it:** When you repeat the same multi-step workflow: scaffolding files, running a review checklist, or orchestrating a larger task. Commands package the workflow so anyone on the team invokes it with one word.

**Real-life scenario:** Your team keeps hand-writing new slash commands and getting the frontmatter wrong. You create `.claude/commands/create-command.md` — a command that scaffolds *other* commands: it fetches the latest spec, checks for name collisions, and writes a correct command file from a single prompt.

**Files involved:**
- `.claude/commands/create-command.md` — scaffolds new slash commands (used to build `/reverse-engineer`)
- `.claude/commands/reverse-engineer.md` — a larger, real command (see §9)

**How to run:**
1. Open the repo in Claude Code.
2. Type: `/create-command my-command "What it does" "Read, Grep"`
3. Claude writes `.claude/commands/my-command.md`, ready to use.

---

## 4. Skills

**What it is:** Directories under `.claude/skills/`, each with a `SKILL.md` (frontmatter `name` + `description`, then a body). Skills are reusable, named capabilities invoked via the `Skill` tool — by Claude, by a command, or by another agent. Claude auto-engages a skill when a request matches its `description`. Unlike slash commands (user-typed), skills are building blocks that get composed together.

**When to use it:** When you want a consistent, reusable procedure for a subtask: a review dimension, test generation, or — as here — rendering documentation in a fixed format.

**Real-life scenario:** You want architecture docs written the same way every time. You build `c4-documentation` (renders C4 diagrams) and `project-overview` (writes a structured overview). Any command or agent now produces consistent docs by engaging the skill instead of re-inventing the format.

**Files involved:**
- `.claude/skills/c4-documentation/SKILL.md` — renders C4 architecture docs
- `.claude/skills/4plus1-documentation/SKILL.md` — renders Kruchten 4+1 docs
- `.claude/skills/project-overview/SKILL.md` — writes a structured project overview

**How to run:**
1. Open the repo in Claude Code.
2. Ask: *"Produce a C4 architecture overview of this repo."*
3. Claude engages the `c4-documentation` skill (matched by its description) and writes the docs.

---

## 5. Sub-agents

**What it is:** Claude Code can spawn independent sub-agents via the `Agent` tool. Each gets its own context, tools, model, and prompt, and returns only a summary to the parent — keeping large intermediate output out of the parent's context. Reusable sub-agents are defined as files in `.claude/agents/` (frontmatter: `name`, `description`, `tools`, `model`, `background`); the parent invokes them by `subagent_type`. With `background: true` they run in parallel.

**When to use it:** When you need multiple independent perspectives at once, or when a task is too large for one context window — e.g., fanning out several read-only investigators across a big codebase.

**Real-life scenario:** Reverse-engineering a legacy codebase, you fan out six specialized readers — tech stack, module map, external integrations, data flows, deployment, runtime — all at once. Each returns a compact summary; the parent merges them. This is the fact-gathering phase of the `/reverse-engineer` capstone (§9).

**Files involved:**
- `.claude/agents/tech-stack.md`, `module-map.md`, `external-integrations.md`, `data-flows.md`, `deployment-infra.md`, `runtime-process.md` — six read-only sub-agents
- `.claude/commands/reverse-engineer.md` — orchestrates them in parallel (Phase 2)

**How to run:**
1. Open the repo in Claude Code.
2. Type: `/reverse-engineer .`
3. Watch the six agents run in parallel; check `.claude/logs/subagents.log` to confirm all six fired.

---

## 6. Hooks

**What it is:** Shell commands that Claude Code executes automatically at lifecycle events — `PreToolUse`, `PostToolUse`, `SubagentStop`, `Stop`, `Notification`, and more. The **registration** (event → command) lives in `.claude/settings.json` under `hooks`; the **script** it runs is a plain file you keep wherever you like (`.claude/hooks/` is the conventional spot). Hooks run outside Claude at the harness level, so they fire regardless of what Claude decides to do.

**When to use it:** When side effects must happen unconditionally: audit logging, auto-formatting after a write, blocking a dangerous command before it runs, or recording facts you don't want to depend on Claude self-reporting.

**Real-life scenario:** You run the `/reverse-engineer` capstone (§9) and want deterministic proof that all six fact-gathering sub-agents actually ran — not just Claude's word for it. A `SubagentStop` hook appends each finishing agent's `agent_type` to a log at the harness level, giving you an independent audit trail.

**Files involved:**
- `.claude/settings.json` — registers the `SubagentStop` hook (matched to the six reverse-engineer agents), referencing the script via `${CLAUDE_PROJECT_DIR}`
- `.claude/hooks/log-subagent.sh` — the script the hook runs; appends `{timestamp, agent_type}` to `.claude/logs/subagents.log`

**How to run:**
1. Open the repo in Claude Code (hooks load from `.claude/settings.json` automatically).
2. Run `/reverse-engineer .` so the six sub-agents fire.
3. Open `.claude/logs/subagents.log` — it lists each agent with a timestamp, confirming all six ran.

---

## 7. MCP Servers

**What it is:** Model Context Protocol (MCP) is an open standard for connecting Claude to external tools and data sources. An MCP server exposes resources and tools that Claude calls just like built-in tools. Servers are registered in `.claude/settings.json` under `mcpServers`.

**When to use it:** When Claude needs live data from outside the filesystem: issue trackers, databases, REST APIs, internal wikis. MCP replaces copy-pasting external content into the prompt — Claude fetches it on demand.

**Real-life scenario:** Your team tracks work in Jira. You register the Atlassian MCP server. Claude can now fetch a ticket's description and acceptance criteria, then generate implementation code — without you copying anything from Jira.

**Status in this repo:** No MCP server is registered yet — `.claude/settings.json` currently defines only the hook from §6. The steps below show how to add one; the server name and launch command depend on the specific MCP server you choose.

**Files involved:**
- `.claude/settings.json` — where the `mcpServers` block goes (not present until you add it)

**How to run:**
1. Add an `mcpServers` block to `.claude/settings.json`, for example:
   ```json
   "mcpServers": {
     "my-server": {
       "command": "npx",
       "args": ["-y", "<mcp-server-package>"]
     }
   }
   ```
2. Restart Claude Code.
3. Ask a question that needs the server's data; Claude calls the MCP tool and returns live results.

---

## 8. External Agents — superpowers

**What it is:** [superpowers](https://github.com/obra/superpowers) is an open-source framework that extends Claude Code via MCP with additional capabilities: persistent cross-session memory, headless browser automation, and sandboxed code execution. Its tools appear alongside built-in Claude Code tools once registered.

**Status in this repo:** Not installed or registered by default — the steps below are the optional setup. Once registered it appears as an `mcpServers` entry in `.claude/settings.json`, exactly like §7.

**When to use it:** When you need capabilities beyond the default toolset — especially persistent memory that survives across sessions, or browser automation for tasks that involve web UIs.

**Real-life scenario:** You want Claude to remember architectural decisions across sessions (e.g., "we chose Zustand over Redux for state management"). With superpowers' memory tool, Claude stores that decision and recalls it next session automatically — no re-explaining required.

**Files involved:**
- `.claude/settings.json` — `mcpServers` entry for superpowers (added after install)

**How to run:**
1. Install superpowers globally:
   ```
   npm install -g @obra/superpowers
   ```
2. Register it in `.claude/settings.json`:
   ```json
   "mcpServers": {
     "superpowers": {
       "command": "superpowers",
       "args": ["mcp"]
     }
   }
   ```
3. Restart Claude Code.
4. Ask: *"Remember that we use Zustand for state management in this project."*
5. Close Claude Code, reopen it, and ask: *"What state management library did we decide on?"*
6. Claude recalls the decision without any prompt from you.

---

## 9. Reverse-Engineering a Codebase (capstone: command + sub-agents + skills + hook)

**What it is:** A single slash command, `/reverse-engineer`, that orchestrates the other features end-to-end. It gathers facts about an unfamiliar codebase once (via six parallel sub-agents), then renders them through three documentation skills into two architecture notations (C4 and Kruchten 4+1) plus a standalone overview — so both notations describe the *same* facts and can be compared. A SubagentStop hook logs which agents ran.

**When to use it:** When you inherit a legacy or undocumented system and need architecture docs fast, or when you want to compare how C4 vs 4+1 describe the same system.

**Real-life scenario:** You take over a legacy service with no docs. You run one command and get `docs/c4/`, `docs/4plus1/`, an `overview.md`, and a `COMPARISON.md` — enough to onboard and to decide which diagram style your team should standardize on.

**Files involved:**
- `.claude/commands/reverse-engineer.md` — the orchestrator (4 phases)
- `.claude/agents/{tech-stack,module-map,external-integrations,data-flows,deployment-infra,runtime-process}.md` — six read-only fact-gathering sub-agents (`background: true`, haiku/sonnet tiers)
- `.claude/skills/{c4-documentation,4plus1-documentation,project-overview}/SKILL.md` — the three rendering skills
- `.claude/settings.json` + `.claude/hooks/log-subagent.sh` — SubagentStop hook that records which agents fired to `.claude/logs/subagents.log`

**How to run:**
1. Open the repo (or any target project) in Claude Code.
2. Type: `/reverse-engineer .`
3. Watch the six agents run in parallel, then the three skills render docs.
4. Review the eleven files under `docs/`, and `.claude/logs/subagents.log` to confirm all six agents ran.
