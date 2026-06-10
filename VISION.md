# Vision — fable-check

## Product goal

Give any coding agent (Claude Code, Codex) and any terminal a one-command, extensive code review by Claude Fable 5 — the strongest reviewer model available — before work ships. The mirror image of OpenAI's codex-plugin-cc.

## Target user

Builders who do most of their development through coding agents and want an independent, high-quality second opinion on changes without leaving their workflow or setting up API keys.

## Success criteria

- One command produces a review a senior engineer would respect: real findings with file:line evidence, no style noise, honest "approve" when the change is sound.
- Works identically from Claude Code and Codex.
- Zero configuration beyond an existing Claude Code login.
- Reviews are provably read-only.

## Constraints

- No API key flows — subscription auth via the local `claude` CLI only.
- Zero npm dependencies in the skill (must run anywhere Node 18+ exists).
- Findings must be schema-validated; a malformed model response surfaces as an explicit failure, never a fabricated report.

## Non-goals (for now)

- Fixing the issues it finds (the host agent can do that as a follow-up).
- Task delegation to Claude ("rescue"-style) — separate product.
- Stop-hook review gates.
- PR/GitHub integration (inline comments, CI) — possible later.
