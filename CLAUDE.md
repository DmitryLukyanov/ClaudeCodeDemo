# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

ClaudeCodeDemo is a hands-on study guide demonstrating real-world usage of Claude Code features. Each feature is illustrated with a concrete, practical example. [`overview.md`](./overview.md) is the canonical reference — it indexes every demo with a short scenario, the files involved, and how to run it.

## Features Demonstrated

| Feature | What it controls | Location |
|---|---|---|
| CLAUDE.md | Project context given to every Claude Code session | `CLAUDE.md` |
| Rules | Persistent behavior constraints for Claude | `.claude/rules/*.md` |
| Slash Commands | Custom workflow shortcuts invoked with `/name` | `.claude/commands/*.md` |
| Skills | Reusable agent capabilities with structured prompts | `.claude/skills/*.md` |
| Sub-agents | Spawning specialized or parallel agents via `Agent` tool | `.claude/commands/audit.md` |
| Hooks | Shell commands triggered by Claude Code lifecycle events | `.claude/settings.json` |
| MCP Servers | External tools and context via Model Context Protocol | `.claude/settings.json` |
| External Agents | Third-party agent frameworks (e.g., superpowers) | `overview.md` §8 |

## Repository Layout

```
ClaudeCodeDemo/
├── CLAUDE.md              # This file
├── overview.md            # Master index: one scenario per feature
└── .claude/
    ├── settings.json      # Hooks and MCP server configuration
    ├── commands/          # Slash command definitions (*.md) — invokable with /name
    ├── rules/             # Behavior rules (*.md) — always active
    └── skills/            # Skill definitions (*.md) — always active
```

All commands, rules, and skills are real and active — the demos work by using them, not just reading about them. The repo itself is the subject for demos that need code to analyze.

## The `overview.md` Contract

Every demo section in `overview.md` must follow this structure:

```markdown
## Feature Name

**What it is:** One paragraph — purpose and mechanism.
**When to use it:** Concrete triggering criteria (not vague principles).
**Real-life scenario:** A specific, realistic problem this feature solves.
**Files involved:** Paths to all relevant demo files.
**How to run:** Exact steps to reproduce the demo from a fresh checkout.
```

When adding a new demo: update `overview.md` first, then create the files in `.claude/`. This keeps the guide and the code in sync.

## Working with superpowers

[superpowers](https://github.com/obra/superpowers) integrates via MCP. Install it once globally, then register it in `.claude/settings.json`. See `overview.md` §8 for the exact steps — no extra files needed.
