#!/usr/bin/env python3
"""
Claude Code SessionStart hook for auto-handoff.

Injects the session id, this session's log path, and the project's HANDOFF.md
(if one exists) into the new session's context. Always exits 0 and prints a
valid hook payload, so a failure here never blocks a session.
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

LOG_ROOT = Path.home() / ".claude" / "session-logs"
MAX_HANDOFF_CHARS = 6000


def project_slug(cwd: str) -> str:
    start = Path(cwd).resolve()
    root = start
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            root = candidate
            break
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", root.name).strip("-.")
    return slug or "default"


def emit(context: str) -> None:
    payload = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context,
        }
    }
    print(json.dumps(payload))


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        data = {}

    session_id = str(data.get("session_id") or "")
    short_id = re.sub(r"[^A-Za-z0-9]", "", session_id)[:8] or "nosession"
    slug = project_slug(str(data.get("cwd") or Path.cwd()))
    project_dir = LOG_ROOT / slug

    lines = [
        f"[handoff] session id: {short_id} | project: {slug}",
        f"[handoff] session log for this chat: "
        f"{project_dir / (date.today().isoformat() + '-' + short_id + '.md')}",
    ]

    handoff_file = project_dir / "HANDOFF.md"
    if handoff_file.is_file():
        text = handoff_file.read_text(encoding="utf-8", errors="replace")
        lines += [
            "",
            "[handoff] Last known state from the previous session (HANDOFF.md):",
            "",
            text[:MAX_HANDOFF_CHARS],
        ]

    emit("\n".join(lines))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
    sys.exit(0)
