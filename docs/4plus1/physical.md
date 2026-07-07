# 4+1 Physical View — ClaudeCodeDemo

The physical view shows the infrastructure topology for ClaudeCodeDemo. This is a maximally simple deployment: a single developer workstation, no cloud, no containers, no CI/CD. The Claude Code CLI process runs locally, reads the git working tree, forks bash scripts as hook child processes, and writes output files back to the same working tree. The only outbound network path is HTTPS from the `/create-command` workflow to `code.claude.com`. The remote git host is accessed only during explicit `git clone` and `git push` operations, not during Claude Code sessions.

---

## Legend

```
Actors / External Agents
  (( Actor Name ))              human user, external system, or timer

Component / Object / Subsystem
  .-----------------------.
  | Name                  |
  | <<stereotype>>        |    stereotype: service, module, subsystem, controller, etc.
  '-----------------------'

Infrastructure Node  (Physical view only)
  [[ Node Name                ]]

Relationships
  ─────────────────>   label          synchronous call / association
  - - - - - - - - ->   label          dependency / uses / sends-to (async)
  ════════════════>   label          IPC / queue message / event
```

---

## Diagram

```
  Internet Zone
  ─────────────────────────────────────────────────────────────────────────────
  (( Developer ))
        | keyboard input
        v
  ─────────────────────────────── Developer Workstation (Windows 11) ──────────
  |                                                                            |
  |  [[ Claude Code CLI process                                             ]] |
  |  |  Runs: main Claude turn, sessions, Agent tool (spawns sub-agents),   | |
  |  |         Skill tool (inline), hook script dispatch                     | |
  |  '---------------------------------------------------------------------- | |
  |          |                    |                      |                    | |
  |  fork bash (hook events)  file I/O           spawn Agent calls           | |
  |          |                    |                      |                    | |
  |          v                    v                      v                    | |
  |  [[ Hook Scripts (bash)    ]] [[ Local File System              ]]       | |
  |  |  log-subagent.sh        |  |  .claude/ (config, hooks,       |        | |
  |  |  guard-rev-eng-docs.sh  |  |   agents, skills, commands)     |        | |
  |  |  turn-start.sh          |  |  docs/ (generated output)       |        | |
  |  |  turn-complete.sh       |  |  .claude/logs/ (runtime state,  |        | |
  |  |  (each: <1s lifetime)   |  |   git-ignored)                  |        | |
  |  '--------------------------'  '---------------------------------'        | |
  |                    ^                                                       | |
  |                    | bash read/write (file I/O)                           | |
  |                    '-------------------'                                  | |
  |                                                                            | |
  ──────────────────────────────────────────────────────────────────────────────
        |                                        |
        | HTTPS (create-command only)            | SSH git clone / git push
        v                                        v
  +===========================+        +================================+
  |  code.claude.com          |        |  Remote Git Host               |
  |  [External: Anthropic]    |        |  [External: github-bet4u]      |
  |  Slash-command spec docs  |        |  git@github-bet4u:             |
  +===========================+        |  DmitryLukyanov/               |
                                       |  ClaudeCodeDemo.git            |
                                       +================================+
```

---

## Element & Relationship Key

| Node | Type | Description |
|---|---|---|
| Developer Workstation (Windows 11) | Infrastructure Node | The sole execution environment; everything runs here |
| Claude Code CLI process | Runtime Process | Anthropic's CLI; hosts the main Claude turn, Agent tool sub-processes, and Skill tool execution; dispatches hook scripts |
| Hook Scripts (bash) | Runtime Process | Four short-lived bash child processes (< 1s each) forked by the harness on lifecycle events |
| Local File System | Storage | Holds the git working tree: `.claude/` config, `docs/` output, `.claude/logs/` runtime state |
| code.claude.com | External Web Service | Anthropic's public docs; accessed via HTTPS WebFetch by the `/create-command` command |
| Remote Git Host | External Version Control | SSH-based git remote; used only for `git clone` (setup) and `git push` (commits), not during active sessions |

| Network Path | Protocol | Trigger | Description |
|---|---|---|---|
| Claude Code CLI → Local File System | File I/O | Every session | Reads config; writes docs via skill Write tool; reads/writes logs via hooks |
| Hook Scripts → Local File System | File I/O (bash) | Each lifecycle event | Reads `.turn-start` / tracker; appends to log files |
| Claude Code CLI → code.claude.com | HTTPS | `/create-command` only | WebFetch to retrieve current slash-command frontmatter spec |
| Developer → Remote Git Host | SSH | Manual git operations | Clone on initial setup; push when committing changes |

---

## Notes

- **No network traffic during normal sessions**: The Claude Code CLI communicates with the Anthropic API, but this is handled internally by the CLI process — it is not a network path visible in the repo's config. All config-driven activity is local file I/O.
- **No containers, no cloud, no CI/CD**: The physical view has a single node by design. The project is a demo, not a production system.
- **`.claude/logs/` is git-ignored**: Runtime state (timing, tracker, audit log) exists only on the local workstation and is not replicated to the remote git host.
- **Anthropic API** (used implicitly by Claude Code for all Claude inference) is `[unknown]` as a physical endpoint — it is not referenced in any repo config file, only in the Claude Code CLI binary itself.
