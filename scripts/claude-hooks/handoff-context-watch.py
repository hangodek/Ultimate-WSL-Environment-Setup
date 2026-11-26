#!/usr/bin/env python3
"""
Claude Code PostToolUse/UserPromptSubmit hook for auto-handoff. No user action.

1. Save request: once the context estimate crosses HANDOFF_THRESHOLD (default
   130000 tokens), it injects one instruction, mid-task, to save HANDOFF.md
   and keep going. The estimate is the last API usage PLUS what was added
   after it (tool results, images), so one big tool result cannot jump past
   the threshold and straight into a compact unseen.
2. Re-inject fallback: if a compact happened and HANDOFF.md was not injected
   for it yet (the SessionStart hook does not always fire), it injects
   HANDOFF.md itself.

Claude Code's own auto-compact (CLAUDE_CODE_AUTO_COMPACT_WINDOW in
settings.json) does the actual shrinking; handoff-pre-compact.py feeds
HANDOFF.md into its summary. Always exits 0; any error gives an empty payload.
"""

import json
import os
import re
import sys
from pathlib import Path

LOG_ROOT = Path.home() / ".claude" / "session-logs"
STATE_DIR = LOG_ROOT / ".state"
DEFAULT_THRESHOLD = 130_000
MAX_HANDOFF_CHARS = 6000
TAIL_BYTES = 4_000_000
IMAGE_TOKENS = 1600  # rough cost of one screenshot; base64 size says nothing
USAGE_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")


def project_slug(cwd: str) -> str:
    start = Path(cwd).resolve()
    root = start
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            root = candidate
            break
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", root.name).strip("-.")
    return slug or "default"


def _content_tokens(node) -> int:
    """Rough token count of message content, images counted flat."""
    if isinstance(node, str):
        return len(node) // 4
    if isinstance(node, list):
        return sum(_content_tokens(item) for item in node)
    if isinstance(node, dict):
        if node.get("type") == "image":
            return IMAGE_TOKENS
        return sum(_content_tokens(v) for k, v in node.items() if k not in ("type", "id", "tool_use_id", "source"))
    return 0


def scan(transcript: Path):
    """Return (estimated context tokens or None, uuid of the latest compact boundary or None)."""
    with transcript.open("rb") as handle:
        handle.seek(0, os.SEEK_END)
        size = handle.tell()
        handle.seek(max(0, size - TAIL_BYTES))
        chunk = handle.read().decode("utf-8", errors="replace")

    added = 0
    base = None
    for line in reversed(chunk.splitlines()):
        if base is not None:
            # Usage found; only look further back for the latest compact boundary.
            if '"compact_boundary"' not in line:
                continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue  # the first line of the tail chunk may be cut mid-record
        if entry.get("subtype") == "compact_boundary":
            if base is None:  # no API call since the compact yet
                base = int((entry.get("compactMetadata") or {}).get("postTokens") or 0)
            return base + added, entry.get("uuid")
        if base is not None:
            continue
        message = entry.get("message") or {}
        usage = message.get("usage") if entry.get("type") == "assistant" else None
        if usage:
            base = sum(int(usage.get(key) or 0) for key in USAGE_KEYS)
        elif entry.get("type") in ("user", "assistant"):
            added += _content_tokens(message.get("content"))
    return (None if base is None else base + added), None


def main() -> None:
    data = json.load(sys.stdin)
    event = data.get("hook_event_name") or "PostToolUse"
    session_id = re.sub(r"[^A-Za-z0-9_-]", "", str(data.get("session_id") or ""))
    transcript = data.get("transcript_path")
    if not session_id or not transcript:
        return print("{}")

    tokens, boundary = scan(Path(transcript).expanduser())
    parts = []

    # Re-inject HANDOFF.md once per compact if SessionStart did not.
    seen_file = STATE_DIR / f"{session_id}.compact"
    if boundary:
        seen = seen_file.read_text(encoding="utf-8").strip() if seen_file.exists() else ""
        if seen != boundary:
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            seen_file.write_text(boundary, encoding="utf-8")
            handoff = LOG_ROOT / project_slug(str(data.get("cwd") or Path.cwd())) / "HANDOFF.md"
            if handoff.is_file():
                text = handoff.read_text(encoding="utf-8", errors="replace")[:MAX_HANDOFF_CHARS]
                parts.append(
                    "[handoff] The chat was just auto-compacted. Last saved state "
                    "(HANDOFF.md) follows; continue the task from it:\n\n" + text
                )

    threshold = int(os.environ.get("HANDOFF_THRESHOLD") or DEFAULT_THRESHOLD)
    flag = STATE_DIR / session_id
    if tokens is not None and tokens < threshold:
        flag.unlink(missing_ok=True)  # fresh, or just auto-compacted
    elif tokens is not None and not flag.exists():
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        flag.write_text(str(tokens), encoding="utf-8")
        when = "now, between steps" if event == "PostToolUse" else "after you answer this prompt"
        parts.append(
            f"[handoff] Context is about {tokens // 1000}k tokens. Auto-compact "
            f"will run soon. Silently save the `handoff` skill files {when} "
            "(session log + HANDOFF.md: goal, user's rules, what is done, exact "
            "next step). Then KEEP WORKING on the current task. Do not stop, do "
            "not ask the user anything, do not suggest /clear or a new session."
        )

    if not parts:
        return print("{}")
    print(json.dumps({
        "hookSpecificOutput": {"hookEventName": event, "additionalContext": "\n\n".join(parts)}
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
    sys.exit(0)
