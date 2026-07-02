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
- `.claude/rules/sql-safety.md` — active rule in this repo

**How to run:**
1. Open the repo in Claude Code.
2. Ask: *"Write a function that fetches a user by ID from the database."*
3. Claude writes a parameterized query and explains why string interpolation was avoided.

---

## 3. Slash Commands

**What it is:** Markdown files in `.claude/commands/`. Each file defines a custom slash command invoked as `/command-name` in the Claude Code prompt. The file body is a prompt template that Claude executes when you type the command.

**When to use it:** When you repeat the same multi-step workflow: generating a PR summary, scaffolding a new module, running a specific review checklist. Commands package the workflow so anyone on the team invokes it with one word.

**Real-life scenario:** Your team always writes PR descriptions in the same format (summary, motivation, test plan). You create `.claude/commands/pr-summary.md`. Any developer types `/pr-summary` and gets a fully formatted PR description for the current diff — no copy-pasting a template.

**Files involved:**
- `.claude/commands/pr-summary.md` — active command in this repo

**How to run:**
1. Make any small edit to a file in this repo (so there is a diff).
2. Type: `/pr-summary`
3. Claude generates a structured PR description from the staged changes.

---

## 4. Skills

**What it is:** Markdown files in `.claude/skills/`. Skills are reusable, named capabilities invoked programmatically via the `Skill` tool — by Claude itself or by other agents. Unlike slash commands (user-typed), skills are building blocks that agents compose together.

**When to use it:** When you want a consistent, reusable procedure for a subtask: a specific review dimension, test generation, documentation extraction. Any command or agent can delegate to a skill by name.

**Real-life scenario:** You build a skill called `check-accessibility` that checks a React component for missing `aria-*` attributes, missing `alt` text, and keyboard navigation issues. Any review command or sub-agent can invoke it without duplicating the logic.

**Files involved:**
- `.claude/skills/check-accessibility.md` — active skill in this repo

**How to run:**
1. Open the repo in Claude Code.
2. Ask: *"Use the check-accessibility skill on CLAUDE.md"* (or any file).
3. Claude invokes the skill and reports findings with line references.

---

## 5. Sub-agents

**What it is:** Claude Code can spawn independent sub-agents using the `Agent` tool. Each sub-agent gets its own context, tools, and prompt. The parent agent coordinates results. Forked sub-agents run in parallel — their tool output stays out of the parent's context.

**When to use it:** When you need multiple independent perspectives simultaneously (e.g., security review + performance review), or when a task is too large for one context window.

**Real-life scenario:** You want to audit this repo for two concerns at once: rules/commands that have gaps in their documentation, and any inconsistency between `CLAUDE.md` and `overview.md`. You fork two agents — one checks documentation completeness, the other checks cross-file consistency — and they run in parallel.

**Files involved:**
- `.claude/commands/audit.md` — slash command that orchestrates the two parallel agents

**How to run:**
1. Open the repo in Claude Code.
2. Type: `/audit`
3. Watch two agents run in parallel; the parent synthesizes a single findings report.

---

## 6. Hooks

**What it is:** Shell commands registered in `.claude/settings.json` under `hooks`. Claude Code executes them automatically at lifecycle events: `PreToolUse`, `PostToolUse`, `Stop`, `Notification`. Hooks run outside Claude — they are plain shell commands that fire regardless of what Claude does.

**When to use it:** When side effects must happen unconditionally: audit logging every file edit, auto-formatting after a write, blocking a dangerous command before it runs, notifying a teammate when a long task finishes.

**Real-life scenario:** Your team wants an immutable audit log of every file Claude edits. A `PostToolUse` hook appends `{timestamp, tool, file}` to `audit.log` on every `Edit` or `Write` call. No trust in Claude required — the hook runs at the harness level.

**Files involved:**
- `.claude/settings.json` — contains the `PostToolUse` hook definition

**How to run:**
1. Open the repo in Claude Code (hooks load from `.claude/settings.json` automatically).
2. Ask Claude to make any small edit to `overview.md`.
3. A new line appears in `audit.log` at the repo root with the timestamp and file path.

---

## 7. MCP Servers

**What it is:** Model Context Protocol (MCP) is an open standard for connecting Claude to external tools and data sources. An MCP server exposes resources and tools that Claude calls just like built-in tools. Servers are registered in `.claude/settings.json` under `mcpServers`.

**When to use it:** When Claude needs live data from outside the filesystem: issue trackers, databases, REST APIs, internal wikis. MCP replaces copy-pasting external content into the prompt — Claude fetches it on demand.

**Real-life scenario:** Your team tracks work in Jira. You register the Atlassian MCP server. Claude can now fetch a ticket's description and acceptance criteria, then generate implementation code — without you copying anything from Jira.

**Files involved:**
- `.claude/settings.json` — `mcpServers` block with the Atlassian MCP server entry

**How to run:**
1. Add your Atlassian credentials to `.claude/settings.json` (see the commented template in the file).
2. Restart Claude Code.
3. Ask: *"Summarize the open tickets assigned to me in project X."*
4. Claude calls the MCP tool and returns live Jira data.

---

## 8. External Agents — superpowers

**What it is:** [superpowers](https://github.com/obra/superpowers) is an open-source framework that extends Claude Code via MCP with additional capabilities: persistent cross-session memory, headless browser automation, and sandboxed code execution. Its tools appear alongside built-in Claude Code tools once registered.

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
