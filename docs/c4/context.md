# C4 Level 1 — System Context: ClaudeCodeDemo

ClaudeCodeDemo is a documentation repository that configures and demonstrates Claude Code features. At the system level, a developer opens the repo in the Claude Code CLI; Claude Code reads the project configuration and executes interactive workflows (slash commands, skills, agents, hooks). The only external system actively used at runtime is the Claude Code CLI itself; the Anthropic Claude API is consumed implicitly through it. The `create-command` workflow makes an outbound web fetch to `code.claude.com` to retrieve the latest slash-command specification.

---

## Legend

```
People / Actors
  [ Person Name ]           Human user or role

System / Container / Component boxes
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  |  Short responsibility      |
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

---

## Diagram

```
  [ Developer / Learner ]
         |
         |  opens repo, types commands
         v
+--------------------------------------------+
|                                            |
|  ClaudeCodeDemo                            |
|  [System]                                  |
|                                            |
|  Hands-on study guide that configures      |
|  Claude Code via CLAUDE.md, commands,      |
|  skills, agents, hooks, and rules.         |
|                                            |
+--------------------------------------------+
         |                        |
         | uses (Claude Code API) | fetches spec (HTTPS / WebFetch)
         v                        v
+====================+   +==========================+
|  Claude Code CLI   |   |  code.claude.com         |
|  [External Tool:   |   |  [External Web Service]  |
|   Anthropic]       |   |                          |
|  Executes Claude   |   |  Slash-command spec page |
|  sessions, runs    |   |  used by /create-command |
|  hooks & agents    |   +==========================+
+====================+
```

---

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Developer / Learner | Person | A developer learning Claude Code features, or a practitioner running the demos interactively |
| ClaudeCodeDemo | System | The git repository: configuration files, commands, skills, agents, hooks, and study-guide documentation |
| Claude Code CLI | External Tool | Anthropic's CLI that reads `.claude/` configuration and executes Claude sessions, sub-agents, and hooks |
| code.claude.com | External Web Service | Public documentation site; fetched by `/create-command` to get the current slash-command frontmatter spec |

| Relationship | Protocol / Action |
|---|---|
| Developer → ClaudeCodeDemo | Opens repo in Claude Code, types slash commands and prompts |
| ClaudeCodeDemo → Claude Code CLI | Supplies configuration (CLAUDE.md, settings.json, commands, skills, agents, hooks) that Claude Code consumes and executes |
| ClaudeCodeDemo → code.claude.com | HTTPS WebFetch from the `/create-command` slash command to retrieve the latest spec |
