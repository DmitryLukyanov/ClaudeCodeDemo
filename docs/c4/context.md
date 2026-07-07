# C4 — L1 System Context

This is the highest-altitude view of **ClaudeCodeDemo**, a self-referential Claude Code
feature-demonstration repository. Its "system" is a documentation/automation toolkit built
entirely from Claude Code configuration artifacts (commands, skills, agents, hooks, rules)
plus one Python Agent SDK driver. It has no traditional application code, database, or queue.
The system reads a target codebase and renders architecture documentation from it; its only
outbound dependency is the Anthropic API (reached through the Claude Agent SDK / Claude Code
runtime). Actors drive it either interactively or headlessly.

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
[ Developer / User ]                       [ CI / Automation Caller ]

     | uses (slash commands in Claude Code)      | runs (python CLI, headless)
     v                                           v
+----------------------------------------------------------------+
|  ClaudeCodeDemo                                                 |
|  [System: Claude Code config toolkit + Python Agent SDK driver] |
+----------------------------------------------------------------+
     |                         |                          |
     | agent loop + inference  | loads workflow skills    | (documented, not
     | (HTTPS via Agent SDK)   | (plugin registry)        |  configured)
     v                         v                          v
+==================+   +=========================+   +==================+
|  Anthropic API   |   |  superpowers plugin     |   |  MCP Servers     |
|  [External SaaS] |   |  [External Plugin]      |   |  [External: none]|
+==================+   +=========================+   +==================+
```

## Element & Relationship Key

| Element | Description |
|---|---|
| `[ Developer / User ]` | Human who opens the repo in Claude Code (`claude .`) and types slash commands such as `/reverse-engineer .` or `/create-command`. |
| `[ CI / Automation Caller ]` | Non-interactive caller that runs `python scripts/run-reverse-engineer.py [path]` headlessly (CI, nightly jobs, cost-gated automation). |
| `ClaudeCodeDemo` | The system itself: a Claude Code configuration toolkit (commands, skills, agents, hooks, rules) plus a Python Agent SDK driver that reverse-engineers a target codebase into architecture docs. |
| `Anthropic API` | External SaaS providing Claude model inference; reached via the Claude Agent SDK / Claude Code runtime. Auth via `ANTHROPIC_API_KEY` or `claude auth`. |
| `superpowers plugin` | External Claude Code plugin (`superpowers@claude-plugins-official`) enabled in `.claude/settings.json`; supplies ~14 reusable workflow skills. |
| `MCP Servers` | External tool/data integration pattern documented in `overview.md` §7 but **not configured** in this repo (`[unknown]`/absent — shown for completeness). |

| Relationship | Description |
|---|---|
| Developer → System | Interactive use: types slash commands inside a Claude Code session. |
| CI Caller → System | Headless use: invokes the Python driver, which runs the same workflow via the Agent SDK. |
| System ⇒ Anthropic API | Sends prompts / agent-loop turns and receives model output over HTTPS. |
| System ⇒ superpowers plugin | Loads external workflow skills on demand when a skill name matches. |
| System ⇒ MCP Servers | Documented extension point only; no server is registered, so no live call occurs today. |
