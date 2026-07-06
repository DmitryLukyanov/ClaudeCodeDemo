---
allowed-tools: WebFetch, Write, Read, Bash, Glob
argument-hint: <command-name> <description> [allowed-tools] [prompt-body]
description: Scaffold a new slash command file in .claude/commands/ from arguments
model: claude-sonnet-4-6
---

## Your task

Create a new Claude Code slash command based on the arguments provided.

Arguments received: $ARGUMENTS

Parse the arguments as follows:
- **$0** — command name (no slashes, just the name, e.g. `review-pr`)
- **$1** — short description (quoted string)
- **$2** — comma-separated allowed-tools list (quoted, e.g. `"Read,Grep,Bash(git diff *)"`) — optional, defaults to `Read, Grep, Glob, Bash`
- **$3 and beyond** — the body/prompt text for the command — optional, you will generate a sensible default if omitted

## Step 1 — Fetch the latest slash command spec

Fetch the latest documentation so your output is always up to date:

Use WebFetch to retrieve the latest spec:
https://code.claude.com/docs/en/agent-sdk/slash-commands#advanced-features

Use the fetched spec to confirm the correct frontmatter keys, placeholder syntax (`$0`, `$1`, `$ARGUMENTS`), bash-inline syntax (`!`backtick`...`backtick``), and any new features added since your training cut-off.

## Step 2 — Check the existing commands directory

Run the check script:

!`bash .claude/scripts/check-commands.sh`

**You MUST start your response to the user with this exact block (fill in the real output):**

```
[check-commands] <paste the full stdout from the script here>
```

Then check: if a file named `<command-name>.md` already exists, report it and ask whether to overwrite before proceeding.

## Step 3 — Compose the command file

Build the markdown file content following this structure (adjust based on what the fetched spec says):

```markdown
---
allowed-tools: <tools from $2, or sensible defaults>
argument-hint: <generate a concise hint from the command purpose>
description: <$1>
model: claude-sonnet-4-6
---

<body: use $3+ if provided, otherwise generate a clear, actionable prompt.
Include bash-inline blocks (using the bang-backtick syntax from the fetched spec) where useful for context gathering. On Windows, target bash-compatible commands only — avoid PowerShell cmdlets in inline blocks since they run under bash.
Use $ARGUMENTS placeholder if the new command should accept further arguments.
Follow all best practices from the fetched spec.>
```

## Step 4 — Write the file

Write the composed content to `.claude/commands/<command-name>.md`.

## Step 5 — Confirm

Report the full path of the created file and show the final file contents so the user can review it.
