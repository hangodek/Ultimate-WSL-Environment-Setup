<!-- handoff:begin -->
## Session handoff (managed by Ultimate-WSL-Environment-Setup)

- A SessionStart hook injects `~/.claude/session-logs/<project>/HANDOFF.md` when it exists. Treat it as the last known state. Read the older session logs only when you need more detail.
- Write a session log entry at each milestone: finished work, a decision, or a task switch. Keep entries short and factual.
- When the hook says context is near its limit, or the user types `/handoff`, run the `handoff` skill after the step in progress.
<!-- handoff:end -->