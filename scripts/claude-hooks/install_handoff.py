#!/usr/bin/env python3
"""
Idempotent merge of the auto-handoff integration into a Claude config dir.

Usage: install_handoff.py <configs/CLAUDE.md> <claude_dir>

- CLAUDE.md: replaces the block between the handoff markers, or appends it.
  Anything the user wrote outside the markers is kept as is.
- settings.json: drops hook entries we installed earlier (matched by the
  `/hooks/handoff-` path), then adds the current ones. Other keys are kept.
  The previous file is copied to settings.json.bak before any change.
"""

import json
import shutil
import sys
from pathlib import Path

BEGIN = "<!-- handoff:begin -->"
END = "<!-- handoff:end -->"
SESSION_START_MATCHER = "startup|resume|clear|compact"


def merge_claude_md(block_file: Path, target: Path) -> None:
    block = block_file.read_text(encoding="utf-8").strip() + "\n"
    existing = target.read_text(encoding="utf-8") if target.exists() else ""

    if BEGIN in existing and END in existing:
        head, _, rest = existing.partition(BEGIN)
        _, _, tail = rest.partition(END)
        new = head + block.rstrip("\n") + tail
    else:
        prefix = existing.rstrip("\n") + "\n\n" if existing.strip() else ""
        new = prefix + block

    if new != existing:
        target.write_text(new, encoding="utf-8")


def merge_settings(claude_dir: Path) -> None:
    settings_path = claude_dir / "settings.json"
    original = settings_path.read_text(encoding="utf-8") if settings_path.exists() else ""
    data = json.loads(original) if original.strip() else {}

    hooks_dir = claude_dir / "hooks"
    ours = {
        "SessionStart": {
            "matcher": SESSION_START_MATCHER,
            "hooks": [
                {
                    "type": "command",
                    "command": f"python3 {hooks_dir / 'handoff-session-start.py'}",
                }
            ],
        },
        "UserPromptSubmit": {
            "hooks": [
                {
                    "type": "command",
                    "command": f"python3 {hooks_dir / 'handoff-context-watch.py'}",
                }
            ],
        },
    }

    hooks = data.setdefault("hooks", {})
    for event, entry in ours.items():
        kept = []
        for group in hooks.get(event, []):
            remaining = [
                hook
                for hook in group.get("hooks", [])
                if "/hooks/handoff-" not in hook.get("command", "")
            ]
            if remaining:
                group["hooks"] = remaining
                kept.append(group)
        kept.append(entry)
        hooks[event] = kept

    new = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    if new != original:
        if original:
            shutil.copy2(settings_path, claude_dir / "settings.json.bak")
        settings_path.write_text(new, encoding="utf-8")


def main() -> None:
    block_file = Path(sys.argv[1])
    claude_dir = Path(sys.argv[2])
    claude_dir.mkdir(parents=True, exist_ok=True)
    merge_claude_md(block_file, claude_dir / "CLAUDE.md")
    merge_settings(claude_dir)


if __name__ == "__main__":
    main()
