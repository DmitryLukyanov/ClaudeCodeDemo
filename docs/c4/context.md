# C4 L1 — System Context: ClaudeCodeDemo

This view shows ClaudeCodeDemo as a single black box, the one human actor who interacts with it, and the external systems it connects to. ClaudeCodeDemo is a Claude Code configuration repository — not a deployed service — so the "system" is the Claude Code platform configured with the files in this repo. The developer is the only human actor; there are no end users, admins, or operators.

## Diagram

```
Legend:
  [ Person Name ]            Human user or role
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |
  +---------------------------+          Container / node box
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+          External system (outside boundary)
  ──────────────────────>   label        Relationship (inside boundary)
  ====================>   label          Relationship crossing boundary


                    [ Developer ]
                          |
                          | opens repo, invokes slash commands,
                          | views generated docs
                          v
          +------------------------------------------+
          |  ClaudeCodeDemo                          |
          |  [System: Claude Code configuration]     |
          +------------------------------------------+
                  |                      |
                  | all LLM inference    | spec fetch
                  | (HTTPS)             | (HTTPS, on-demand)
                  v                      v
     +====================+    +============================+
     |  Anthropic         |    |  code.claude.com           |
     |  Claude API        |    |  [External: Web Service]   |
     |  [External: API]   |    +============================+
     +====================+

     (Optional — not currently active)
     +====================+    +============================+
     |  superpowers MCP   |    |  Playwright MCP            |
     |  [External: npm]   |    |  [External: User-level]    |
     +====================+    +============================+
```

## Element & Relationship Key

| Element | Type | Description |
|---|---|---|
| Developer | Person | The human who clones this repo, opens it in Claude Code, and invokes commands and skills |
| ClaudeCodeDemo | System | The Claude Code platform as configured by this repository's `.claude/` directory; not a deployed service |
| Anthropic Claude API | External System | Hosted LLM inference; all Claude Code CLI and subagent processes communicate with it over HTTPS during every session |
| code.claude.com | External System | Claude Code documentation site; fetched over HTTPS by `/create-command` to get the current slash-command spec |
| superpowers MCP | External System (optional) | Open-source MCP framework (`@obra/superpowers`); provides cross-session memory; not currently registered in `.claude/settings.json` |
| Playwright MCP | External System (optional) | Browser automation MCP; `.playwright-mcp` directory present at repo root from user-level config; not in project `settings.json` |
| Developer → ClaudeCodeDemo | Relationship | Opens the repo in Claude Code, invokes slash commands (`/reverse-engineer`, `/create-command`), views output docs |
| ClaudeCodeDemo → Anthropic Claude API | Relationship | All LLM inference, HTTPS; fires on every turn including agent and skill invocations |
| ClaudeCodeDemo → code.claude.com | Relationship | Spec fetch, HTTPS; fires only when `/create-command` is invoked |
