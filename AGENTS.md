# AGENTS.md

Critical rules for ALL packages. Non-compliance will not be tolerated.

- ALWAYS apply when writing code
- ALWAYS check when reviewing code changes

## Shell

- CRITICAL: do not EVER run git commands, with these exceptions:
  - Read-only inspection is always allowed: `git diff` (any flags/paths) and `git status`.
  - `git add` and `git commit` are allowed only when the user explicitly asks for a commit (e.g. via `/commit`) — never autonomously, never as a side effect of another task.
  - Everything else that mutates history or remotes (`checkout`, `reset`, `rebase`, `push`, `branch -D`, `stash drop`, etc.) stays forbidden.

## Comments

- Default to none: prefer self-explanatory names and structure over comments. Don't restate code, don't add ceremony.
- Be concise: one short line where it genuinely adds something. Explain the why (non-obvious intent, a subtle constraint), not the what the code already states.
- Write timeless comments: a comment describes the code as it is now. Never narrate history, iterations, or transitions ("changed to X", "now resolves instead of...", "previously we...") — that's what git is for.
