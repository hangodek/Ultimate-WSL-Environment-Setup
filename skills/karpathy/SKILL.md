---
name: karpathy
aliases: [karpathy-guidelines]
description: Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
license: MIT
source: multica-ai/andrej-karpathy-skills (2026-03)
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- **State assumptions explicitly:** If uncertain, ask rather than guess.
- **Present multiple interpretations:** Don't pick silently when ambiguity exists.
- **Push back when warranted:** If a simpler approach exists, say so.
- **Stop when confused:** Name what is unclear and clarify before writing code.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No speculative abstractions for single-use code.
- No "flexibility" or "configurability" that was not requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

The test: *Would a senior engineer say this is overcomplicated?* If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that are not broken.
- Match existing style, even if you would do it differently.
- If you notice unrelated dead code, mention it — do not delete it.

When changes create orphans:
- Remove imports, variables, and functions that your changes made unused.
- Do not remove pre-existing dead code unless explicitly asked.

The test: *Every changed line should trace directly to the user's request.*

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform imperative tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria enable looping independently. Weak criteria ("make it work") require constant clarification.

## Anti-Patterns Summary

| Principle | Anti-Pattern | Fix |
|---|---|---|
| **Think Before Coding** | Silently assumes file format, fields, scope | List assumptions explicitly, ask for clarification |
| **Simplicity First** | Strategy pattern for single discount calculation | One function until complexity is actually needed |
| **Surgical Changes** | Reformats quotes, adds types while fixing unrelated bug | Only touch lines required for the task |
| **Goal-Driven** | "I'll review and make improvements" | "Write test for bug X → make it pass → verify no regressions" |
