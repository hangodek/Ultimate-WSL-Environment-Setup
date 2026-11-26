#!/usr/bin/env python3
"""
Claude Code PostToolUse/UserPromptSubmit hook for auto-handoff. No user action.

Reads the latest usage from the transcript. Once the context crosses
HANDOFF_THRESHOLD (default 150000 tokens), it injects one instruction, in the
middle of the work, to save HANDOFF.md and keep going. Claude Code's own
auto-compact (window set by CLAUDE_CODE_AUTO_COMPACT_WINDOW in settings.json)
then shrinks the chat without stopping, and the SessionStart(compact) hook
injects HANDOFF.md again. The flag resets when usage drops after the compact.

Always exits 0. Any error results in an empty payload, never a stuck session.
"""

import json
import os
import re
import sys
from pathlib import Path

LOG_ROOT = Path.home() / ".claude" / "session-logs"
STATE_DIR = LOG_ROOT / ".state"
DEFAULT_THRESHOLD = 150_000
TAIL_BYTES = 2_000_000
USAGE_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")


def last_context_tokens(transcript: Path):
    with transcript.open("rb") as handle:
        handle.seek(0, os.SEEK_END)
        size = handle.tell()
        handle.seek(max(0, size - TAIL_BYTES))
        chunk = handle.read().decode("utf-8", errors="replace")

    for line in reversed(chunk.splitlines()):
        if '"usage"' not in line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue  # the first line of the tail chunk may be cut mid-record
        usage = (entry.get("message") or {}).get("usage")
        if usage:
            return sum(int(usage.get(key) or 0) for key in USAGE_KEYS)
    return None


def main() -> None:
    data = json.load(sys.stdin)
    event = data.get("hook_event_name") or "PostToolUse"
    session_id = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id") or ""))
    transcript = data.get("transcript_path")
    if not session_id or not transcript:
        return print("{}")

    threshold = int(os.environ.get("HANDOFF_THRESHOLD") or DEFAULT_THRESHOLD)
    tokens = last_context_tokens(Path(transcript).expanduser())
    if tokens is None:
        return print("{}")

    flag = STATE_DIR / session_id
    if tokens < threshold:
        flag.unlink(missing_ok=True)  # fresh, or just auto-compacted
        return print("{}")
    if flag.exists():
        return print("{}")  # already saved in this compact cycle

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    flag.write_text(str(tokens), encoding="utf-8")
    when = "now, between steps" if event == "PostToolUse" else "after you answer this prompt"
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": (
                f"[handoff] Context is about {tokens // 1000}k tokens. Auto-compact "
                f"will run soon. Silently save the `handoff` skill files {when} "
                "(session log + HANDOFF.md: goal, what is done, exact next step). "
                "Then KEEP WORKING on the current task. Do not stop, do not ask "
                "the user anything, do not suggest /clear or a new session."
            ),
        }
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
    sys.exit(0)
