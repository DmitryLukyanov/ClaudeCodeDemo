# C4 Level 2 — Container: ClaudeCodeDemo

Zooming into the ClaudeCodeDemo system boundary reveals three logical containers: the configuration repository itself (the git-tracked source), the runtime log store that hooks write to during a session, and the generated documentation output. These containers are not separately deployed services — they are distinct, independently addressable storage units on the developer's workstation, coupled together by the Claude Code CLI at runtime.

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
         | opens / types commands
         v
+================================================================+
|  ClaudeCodeDemo (System boundary)                              |
|                                                                |
|  +---------------------------+                                 |
|  |  Config Repository        |                                 |
|  |  [Container: Markdown +   |                                 |
|  |   Bash + JSON]            |                                 |
|  |  Source-controlled config: |                                |
|  |  CLAUDE.md, commands,     |                                 |
|  |  skills, agents, hooks,   |                                 |
|  |  rules, settings.json     |                                 |
|  +---------------------------+                                 |
|         |                  |                                   |
|  hooks write (bash)   skills write (Write tool)               |
|         |                  |                                   |
|         v                  v                                   |
|  +------------------+  +---------------------------+           |
|  |  Session Logs    |  |  Generated Docs           |           |
|  |  [Container:     |  |  [Container: Markdown]    |           |
|  |   Plaintext /    |  |  Architecture docs        |           |
|  |   JSON append]   |  |  written by skills:       |           |
|  |  .claude/logs/   |  |  docs/c4/, docs/4plus1/,  |           |
|  |  (git-ignored)   |  |  docs/overview.md,        |           |
|  +------------------+  |  docs/COMPARISON.md       |           |
|                         +---------------------------+           |
+================================================================+
         |                                   |
         | reads config (file I/O)           | fetches spec (HTTPS)
         v                                   v
+====================+             +==========================+
|  Claude Code CLI   |             |  code.claude.com         |
|  [External Tool:   |             |  [External Web Service]  |
|   Anthropic]       |             +==========================+
+====================+
```

---

## Element & Relationship Key

| Element | Type | Technology | Description |
|---|---|---|---|
| Config Repository | Container | Markdown, Bash, JSON | Git-tracked source files: CLAUDE.md, overview.md, all `.claude/` artifacts (commands, skills, agents, hooks, rules, settings.json) |
| Session Logs | Container | Plaintext / JSON append-only | Runtime-only log files under `.claude/logs/`; git-ignored. Includes `subagents.log`, `turn-completions.log`, `.turn-start`, `reverse-engineer-run.tracker`, `subagents-debug.log` |
| Generated Docs | Container | Markdown | Output files written by skills during `/reverse-engineer`: `docs/c4/`, `docs/4plus1/`, `docs/overview.md`, `docs/COMPARISON.md` |
| Claude Code CLI | External Tool | Anthropic CLI | Reads config repository and executes Claude sessions, sub-agents, and hook scripts |
| code.claude.com | External Web Service | HTTPS | Slash-command spec page fetched by `/create-command` |

| Relationship | Protocol / Action |
|---|---|
| Developer → Config Repository | Edits config files via IDE or Claude Code tools |
| Claude Code CLI → Config Repository | Reads CLAUDE.md, settings.json, commands, skills, agents, hooks at session start and on demand |
| Config Repository (hooks) → Session Logs | Hook bash scripts append structured lines to log files on lifecycle events |
| Config Repository (skills) → Generated Docs | Skills use the Write tool to create Markdown files under `docs/` |
| Config Repository → code.claude.com | `/create-command` fetches the current slash-command frontmatter spec via HTTPS WebFetch |
