"""
Run /reverse-engineer programmatically via the Claude Agent SDK.

Usage:
    pip install claude-agent-sdk
    python scripts/run-reverse-engineer.py [path]

If path is omitted, runs against the current working directory.
"""

import asyncio
import sys
from claude_agent_sdk import query, ClaudeAgentOptions, ResultMessage, SystemMessage


async def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "."

    print(f"Running /reverse-engineer {target}")
    print("Budget cap: $2.00  |  Effort: high")
    print("-" * 40)

    session_id = None

    try:
        async for message in query(
            prompt=f"/reverse-engineer {target}",
            options=ClaudeAgentOptions(
                allowed_tools=["Read", "Glob", "Grep", "Write", "Agent", "Skill", "Bash"],
                setting_sources=["project"],  # loads CLAUDE.md, skills, hooks
                max_budget_usd=2.00,          # hard stop — no surprise bills
                effort="high",                # thorough reasoning for architecture work
            ),
        ):
            if isinstance(message, SystemMessage) and message.subtype == "init":
                session_id = message.data.get("session_id")

            if isinstance(message, ResultMessage):
                session_id = message.session_id
                print(f"Cost:    ${message.total_cost_usd:.4f}")
                print(f"Turns:   {message.num_turns}")
                print(f"Session: {session_id}")
                print()

                if message.subtype == "success":
                    print("✓ Done — docs written to docs/")
                    sys.exit(0)

                elif message.subtype == "error_max_budget_usd":
                    print("✗ Hit $2.00 budget cap — partial run")
                    print(f"  Resume: python scripts/run-reverse-engineer.py  (session_id={session_id})")
                    sys.exit(1)

                elif message.subtype == "error_max_turns":
                    print("✗ Hit turn limit — partial run")
                    print(f"  Resume: python scripts/run-reverse-engineer.py  (session_id={session_id})")
                    sys.exit(1)

                elif message.subtype == "error_during_execution":
                    print("✗ Agent crashed mid-run — check logs and retry")
                    sys.exit(1)

    except Exception as e:
        print(f"✗ Session ended with error: {e}")
        sys.exit(1)


asyncio.run(main())
