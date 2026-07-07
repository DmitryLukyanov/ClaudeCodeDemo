# C4 Deployment — ClaudeCodeDemo

ClaudeCodeDemo has no cloud infrastructure, no containers, and no CI/CD pipeline. Everything runs on a single developer workstation. The repository is cloned from a remote git host and opened directly in the Claude Code CLI; no build step is required. The only network path at runtime is an outbound HTTPS fetch from `/create-command` to `code.claude.com`.

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
         | keyboard input
         v
+===================================================+
|  Developer Workstation                             |
|  [Node: Windows 11 Enterprise]                    |
|                                                    |
|  +----------------------------------------------+ |
|  |  Claude Code CLI process                     | |
|  |  [Runtime: Anthropic CLI + bundled Node.js]  | |
|  |  Reads config, executes sessions,            | |
|  |  spawns agents, runs hook scripts            | |
|  +----------------------------------------------+ |
|         |                    |                     |
|  reads / writes (file I/O)  executes (bash fork)  |
|         |                    |                     |
|         v                    v                     |
|  +--------------------+  +---------------------+  |
|  |  ClaudeCodeDemo    |  |  Hook Scripts       |  |
|  |  Repository        |  |  [Runtime: Bash +   |  |
|  |  [Storage: Git     |  |   Node.js JSON]     |  |
|  |   working tree]    |  |  Short-lived child  |  |
|  |  .claude/, docs/,  |  |  processes; write   |  |
|  |  CLAUDE.md,        |  |  to .claude/logs/   |  |
|  |  overview.md       |  +---------------------+  |
|  |                    |           |                |
|  |  .claude/logs/     |<----------+                |
|  |  (git-ignored,     |   append (bash write)      |
|  |  runtime state)    |                            |
|  +--------------------+                            |
+===================================================+
         |
         | HTTPS WebFetch (create-command only)
         v
+===========================+
|  code.claude.com          |
|  [External Web Service]   |
|  Slash-command spec docs  |
+===========================+

         ^
         |  git clone / git push (SSH)
         |
+===========================+
|  Remote Git Host          |
|  [External: GitHub-style] |
|  github-bet4u:            |
|  DmitryLukyanov/          |
|  ClaudeCodeDemo.git       |
+===========================+
```

---

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Developer Workstation | Infrastructure Node | Windows 11 Enterprise; the sole execution environment for all runtime activity |
| Claude Code CLI process | Runtime | Anthropic's CLI with bundled Node.js; reads config, runs Claude sessions, spawns agents, invokes hooks |
| ClaudeCodeDemo Repository | Storage | Git working tree on local disk: all source-controlled config files and generated docs |
| Hook Scripts | Runtime | Short-lived bash child processes forked by the Claude Code harness on lifecycle events; write to `.claude/logs/` |
| code.claude.com | External Web Service | Public docs site; accessed via HTTPS WebFetch only during `/create-command` runs |
| Remote Git Host | External Version Control | SSH-accessible git remote (`git@github-bet4u:DmitryLukyanov/ClaudeCodeDemo.git`); source of truth for the repo |

| Relationship | Protocol / Action |
|---|---|
| Developer → Claude Code CLI | Keyboard input: slash commands and natural-language prompts |
| Claude Code CLI → ClaudeCodeDemo Repository | File I/O: reads CLAUDE.md, settings.json, commands, skills, agents at session start and on demand; writes docs/ via skill Write calls |
| Claude Code CLI → Hook Scripts | Bash fork: spawns hook scripts on lifecycle events (UserPromptSubmit, Stop, SubagentStop, PreToolUse) |
| Hook Scripts → ClaudeCodeDemo Repository (.claude/logs/) | Bash write: appends structured lines to log files |
| ClaudeCodeDemo Repository → code.claude.com | HTTPS WebFetch: `/create-command` fetches current slash-command spec |
| Developer ↔ Remote Git Host | SSH git clone (initial setup) and git push (committing changes) |

---

## Notes

- There is **no staging or production environment** — the repository and its demo workflows run entirely on the developer's local machine.
- There are **no containers** (no Docker, no Kubernetes). The only "process" isolation is the Claude Code CLI forking short-lived bash child processes for hooks.
- **`.claude/logs/` is git-ignored** — all runtime state (tracker, timing logs, subagent audit log) is local and ephemeral; it does not travel with the repo.
- The remote git host URL (`github-bet4u`) suggests a non-standard GitHub hostname alias; the actual remote is SSH-based.
