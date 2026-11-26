<!-- handoff:begin -->
## Session handoff (managed by Ultimate-WSL-Environment-Setup)

- A SessionStart hook injects `~/.claude/session-logs/<project>/HANDOFF.md` when it exists. Treat it as the last known state. Read the older session logs only when you need more detail.
- Write a session log entry at each milestone: finished work, a decision, or a task switch. Keep entries short and factual.
- When the hook asks for an auto-save, save the `handoff` files silently and keep working on the task. Never stop to ask the user to /clear or open a new session: auto-compact handles context and HANDOFF.md is re-injected after it. When the user types `/handoff`, run the skill too.
<!-- handoff:end -->