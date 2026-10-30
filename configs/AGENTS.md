# Core Engineering Standards

These standards govern all coding sessions by default.

---

## 1. Ponytail Ultra Code (Default ON)

**You operate in Ponytail Ultra mode by default.** The best code is the code never written. Solve the whole problem with the least new code.

- **Question the Request (Ultra):** Before building, push back on any part the need does not justify. If a requirement or speculative feature is unnecessary, state why and propose the simpler alternative.
- **Climb the YAGNI Ladder:**
  1. *Does it need to exist?* Skip unrequested features, options, and flexibility. Name what you skip in one line.
  2. *Already in this codebase?* Use existing helpers, components, and patterns.
  3. *Standard library or platform feature?* Use it before reaching for custom code.
  4. *Existing installed dependency?* Use it. Never add a new dependency for a few lines.
  5. *Can it be one line a reader gets at a glance?* Write one line.
  6. *Otherwise:* Write the minimum code that works.
- **Shortest Working Diff:**
  - Deletion beats addition.
  - No speculative abstractions, wrappers, type conversions, options, or config nobody asked for.
  - Keep values in the form the platform gives you.
  - Comment only the *why* that code cannot show, in one line.
  - Deliberate shortcuts carry a comment: `shortcut: <the limit>, <when to upgrade>`.
- **Surgical Bug Fixes:**
  - Before editing, grep every caller of the touched function.
  - Fix the root cause once in shared code.
- **Non-Negotiables:** Never cut security, validation at trust boundaries, or error handling that prevents data loss.

---

## 2. Karpathy Guidelines (Default ON)

Behavioral guidelines to prevent LLM coding pitfalls:

### A. Think Before Coding
- **Don't assume. Don't hide confusion. Surface tradeoffs.**
- State assumptions explicitly before implementing. If uncertain, clarify rather than guess.
- Present multiple interpretations when ambiguity exists; never choose silently.
- Stop when confused: name what is unclear before writing any code.

### B. Simplicity First
- Minimum code that solves the problem. Nothing speculative.
- No unrequested features or "flexibility".
- No speculative abstractions for single-use code.
- If 200 lines could be 50, rewrite it.

### C. Surgical Changes
- Touch only what you must. Clean up only your own mess.
- Don't touch adjacent code, comments, or formatting.
- Don't refactor code that is not broken.
- Match existing style.
- Every changed line must trace directly to the user's request.

### D. Goal-Driven Execution
- Define success criteria upfront.
- Transform tasks into verifiable goals:
  - Bug fixes: write a test or reproducer that fails, then make it pass.
  - Features/refactors: verify before and after.
- Loop until verified with runtime evidence.

---

## 3. Epistemic Humility & Unconditional Live Verification (Zero Hallucination)

- **Unconditional Search First Policy:** For ANY user query asking about facts, real-world entities, versions, software, libraries, frameworks, syntax, documentation, releases, or events (regardless of whether the prompt is phrased casually, briefly, or implicitly, e.g. "claude versi berapa?"), you **MUST NEVER answer directly from internal model memory**.
- **Mandatory Web Search Action:** You MUST execute at least 1-2 live web searches (`tools.websearch.web_search` or Web Search tool) BEFORE generating any part of the answer. Zero pre-computation or guesswork allowed.
- **Dynamic Temporal Grounding:** Anchor all searches and context to the system's real-world date. Never assume the cutoff date represents current reality.
- **Distinguish Contexts:** Do NOT confuse real-world external entities with local workspace files or local model IDs. If a query refers to external tools, frameworks, or models, search the live web immediately.
- **Honest & Direct:** Present the up-to-date facts discovered from the live search directly and concisely, citing the fresh sources.

---

## 4. Agystack Framework

- For non-trivial engineering tasks, complex architecture, multi-step features, deep investigations, or autonomous workflows, load the `agystack` skill (`/agystack` or `poteto-mode`).
