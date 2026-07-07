"""
Run /reverse-engineer programmatically via the Claude Agent SDK.

Usage:
    pip install claude-agent-sdk
    python scripts/run-reverse-engineer.py [path]

If path is omitted, runs against the current working directory.
"""

import asyncio
import sys
from collections import deque
from claude_agent_sdk import query, ClaudeAgentOptions, ResultMessage, SystemMessage, AssistantMessage, UserMessage


async def main() -> int:
    target = sys.argv[1] if len(sys.argv) > 1 else "."

    print(f"Running /reverse-engineer {target}")
    print("Budget cap: $6.00  |  Effort: medium")
    print("-" * 40)

    exit_code = 0
    pending: deque[str] = deque()  # tool call labels waiting for their result

    try:
        async for message in query(
            prompt=f"/reverse-engineer {target}",
            options=ClaudeAgentOptions(
                allowed_tools=["Read", "Glob", "Grep", "Write", "Agent", "Skill", "Bash"],
                setting_sources=["project"],  # loads CLAUDE.md, skills, hooks
                max_budget_usd=6.00,          # hard stop — no surprise bills
                effort="medium",              # balanced reasoning — "high" exhausts context before Phase 3 completes
            ),
        ):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    btype = type(block).__name__
                    if btype == "TextBlock":
                        text = getattr(block, "text", "").strip()
                        if text:
                            print(f"  {text[:120]}", flush=True)
                    elif btype == "ToolUseBlock":
                        name = getattr(block, "name", "?")
                        inp = getattr(block, "input", {}) or {}
                        arg = next(iter(inp.values()), "") if inp else ""
                        label = f"{name}({str(arg)[:60]})"
                        pending.append(label)
                        print(f"  → {label}", flush=True)

            elif isinstance(message, UserMessage):
                label = pending.popleft() if pending else "?"
                print(f"    ✓ {label}", flush=True)

            elif isinstance(message, SystemMessage) and message.subtype == "informational":
                data = getattr(message, "data", {})
                msg = data.get("message", "") if isinstance(data, dict) else str(data)
                if msg:
                    print(f"  ℹ {msg[:120]}", flush=True)

            elif isinstance(message, ResultMessage):
                session_id = message.session_id
                print()
                print(f"Cost:    ${message.total_cost_usd:.4f}")
                print(f"Turns:   {message.num_turns}")
                print(f"Session: {session_id}")
                print()

                if message.subtype == "success":
                    print("✓ Done — docs written to docs/")
                elif message.subtype == "error_max_budget_usd":
                    print("✗ Hit $6.00 budget cap — partial run")
                    print(f"  Resume with session_id={session_id}")
                    exit_code = 1
                elif message.subtype == "error_max_turns":
                    print("✗ Hit turn limit — partial run")
                    print(f"  Resume with session_id={session_id}")
                    exit_code = 1
                else:
                    print(f"✗ Stopped: {message.subtype}")
                    exit_code = 1

    except KeyboardInterrupt:
        print("\n✗ Interrupted")
        exit_code = 1
    except Exception as e:
        print(f"✗ Session ended with error: {e}")
        exit_code = 1

    return exit_code


sys.exit(asyncio.run(main()))
