#!/usr/bin/env bash
# Deploy the auto-handoff integration into ~/.claude. Safe to run repeatedly.
# Usage: install-handoff.sh [repo_dir]
set -euo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR/session-logs" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/commands"

for hook in "$REPO_DIR"/scripts/claude-hooks/handoff-*.py; do
  install -m 755 "$hook" "$CLAUDE_DIR/hooks/"
done

rm -rf "$CLAUDE_DIR/skills/handoff"
cp -r "$REPO_DIR/skills/handoff" "$CLAUDE_DIR/skills/"
cp "$REPO_DIR/commands/handoff.md" "$CLAUDE_DIR/commands/"

python3 "$REPO_DIR/scripts/claude-hooks/install_handoff.py" \
  "$REPO_DIR/configs/CLAUDE.md" "$CLAUDE_DIR"

echo "  ✓ Auto-handoff installed into $CLAUDE_DIR"
