#!/usr/bin/env python3
"""
Claude Code UserPromptSubmit hook for auto-handoff.

Reads the latest assistant usage from the session transcript. When the context
crosses HANDOFF_THRESHOLD (default 100000 tokens), it injects a one-time
instruction asking Claude to run the handoff skill. A flag file per session
keeps the instruction from repeating; the flag clears once usage drops back
under the threshold (for example after /compact or /clear).

Always exits 0. Any error results in an empty payload, never a blocked prompt.
"""

import json
import os
import re
import sys
from pathlib import Path

LOG_ROOT = Path.home() / ".claude" / "session-logs"
STATE_DIR = LOG_ROOT / ".state"
DEFAULT_THRESHOLD = 100_000
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


def emit(context: str = "") -> None:
    if not context:
        print("{}")
        return
    payload = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": context,
        }
    }
    print(json.dumps(payload))


def main() -> None:
    data = json.load(sys.stdin)
    session_id = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id") or ""))
    transcript = data.get("transcript_path")
    if not session_id or not transcript:
        return emit()

    threshold = int(os.environ.get("HANDOFF_THRESHOLD") or DEFAULT_THRESHOLD)
    tokens = last_context_tokens(Path(transcript).expanduser())
    if tokens is None:
        return emit()

    flag = STATE_DIR / session_id
    if tokens < threshold:
        flag.unlink(missing_ok=True)
        return emit()
    if flag.exists():
        return emit()

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    flag.write_text(str(tokens), encoding="utf-8")
    emit(
        f"[handoff] This session's context is about {tokens // 1000}k tokens "
        f"(limit {threshold // 1000}k). Finish the step in progress, then run the "
        "`handoff` skill now: append the session log and overwrite HANDOFF.md. "
        "Then tell the user: \"Handoff saved. Run /clear; the new session picks "
        "this up automatically.\""
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
    sys.exit(0)
