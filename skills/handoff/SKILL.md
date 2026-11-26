---
name: handoff
description: Save a handoff so work continues in a fresh chat without losing state. Use when the handoff hook reports context near its limit (then save silently and keep working), when the user types /handoff or asks to hand off, save progress, or continue later, or before /clear or a new chat while work is unfinished.
---

# Handoff

Keep project state on disk, not in chat. A new session reads what you write here.

## Locations

- Session id and session log path come from the `[handoff]` lines injected at session start. If they are missing, use `nosession` as the id and today's date from `date +%F`.
- Project dir: `~/.claude/session-logs/<slug>/`. The slug is the git root's folder name, or the working directory's name when there is no git root. Keep only `A-Za-z0-9._-`.
- Session log: `<project dir>/<YYYY-MM-DD>-<session id>.md`. Append only.
- Handoff file: `<project dir>/HANDOFF.md`. Overwrite it each time.

## Steps

1. Run `mkdir -p` on the project dir.
2. Append a dated section to the session log with these four headings:
   - `### What was done`: commands, files, features, with outcomes.
   - `### Decisions made`: each decision and why it was made.
   - `### Open threads`: unfinished work to pick up next time.
   - `### Errors`: what went wrong and how it was handled.
   Write facts. Mark guesses as guesses. Write "none" under an empty heading. Do not add drama.
3. Overwrite `HANDOFF.md`, at most 40 lines:
   ```
   # Handoff: <slug>
   Updated: <date and time>, session <session id>

   ## Goal
   ## Status
   ## Next steps (ordered; the first one is concrete enough to start cold)
   ## Open threads
   ## Key files
   ## Watch out for
   ```
   Drop items that are finished. Keep only what the next session needs.
4. Read `HANDOFF.md` once. Check that a reader with no chat history could continue from it.
5. Reply with one line: `Handoff saved to <path>`. When the hook triggered this, write nothing in chat and go straight back to the task. Never stop or ask the user to /clear: Claude Code auto-compacts on its own and the SessionStart hook re-injects HANDOFF.md.

## Rules

- Do not paste the log or the handoff into chat.
- Do not write secrets, tokens, or credentials into either file.
- Write the log entry only for finished work, decisions, errors, and task switches. Do not log every message.
