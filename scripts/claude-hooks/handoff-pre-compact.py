#!/usr/bin/env python3
"""
Claude Code PreCompact hook for auto-handoff.

Claude Code passes this hook's stdout to the compaction summarizer as custom
instructions. It asks the summary to keep what a handoff keeps (goal, user's
rules, done/remaining, exact next step, files, errors) and hands it the latest
HANDOFF.md as ground truth, so the compact summary is as detailed as a handoff.
Always exits 0; on any error it prints nothing and compaction runs as usual.
"""

import json
import re
import sys
from pathlib import Path

LOG_ROOT = Path.home() / ".claude" / "session-logs"
MAX_HANDOFF_CHARS = 4000

INSTRUCTIONS = """Write the summary as a work handoff, so work continues with no loss:
- The user's goal and every rule or preference they gave, in their own words.
- Task list: what is done (with outcomes) and what remains, in order.
- The exact step in progress and the next concrete action.
- Files, paths, commands and tool usage that matter, with their current state.
- Decisions made and why; errors hit and how they were fixed.
- Keep: work autonomously, do not stop or ask the user to /clear."""


def project_slug(cwd: str) -> str:
    start = Path(cwd).resolve()
    root = start
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            root = candidate
            break
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", root.name).strip("-.")
    return slug or "default"


def main() -> None:
    data = json.load(sys.stdin)
    out = [INSTRUCTIONS]
    handoff = LOG_ROOT / project_slug(str(data.get("cwd") or Path.cwd())) / "HANDOFF.md"
    if handoff.is_file():
        text = handoff.read_text(encoding="utf-8", errors="replace")[:MAX_HANDOFF_CHARS]
        out.append(
            "Latest saved HANDOFF.md (treat as ground truth; merge newer progress "
            "from the chat into it):\n\n" + text
        )
    print("\n\n".join(out))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
