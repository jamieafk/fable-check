# fable-check Skill Implementation Plan

**Goal:** A cross-agent skill (Claude Code + Codex) that runs an extensive code review using Claude Fable 5 — the inverse of openai/codex-plugin-cc.

**Architecture:** A portable skill folder (`skill/`) containing a SKILL.md and a zero-dependency Node script. The script collects git context (working tree or branch diff), builds a review prompt, and invokes the local `claude` CLI headlessly (`claude -p`) with Fable 5, read-only tools, and a JSON schema for structured findings. Auth rides on the user's existing Claude Code login — no API key. An installer symlinks the skill into `~/.claude/skills/` and `~/.codex/skills/`.

**Tech Stack:** Node 18+ (ESM, no deps), `claude` CLI (verified flags: `--model claude-fable-5`, `--effort`, `--json-schema`, `--allowedTools`, `--output-format json`), git.

---

### Task 1: Review schema + prompts

**Files:**
- Create: `skill/schemas/review-output.schema.json` — verdict/summary/findings/next_steps (adapted from codex-plugin-cc, Apache-2.0; adds `category` per finding)
- Create: `skill/prompts/review.md` — thorough standard review template
- Create: `skill/prompts/adversarial-review.md` — adapted adversarial template
- Create: `skill/prompts/merge.md` — deep-mode merge/dedup pass

### Task 2: Companion script

**Files:**
- Create: `skill/scripts/fable-check.mjs`

Subcommands: `setup`, `review` (`--adversarial`, `--deep`, `--base`, `--scope`, `--effort`, `--model`, `--background`, `--json`, focus text), `worker` (internal), `status`, `result`, `cancel`.

Key decisions:
- Diffs ≤ ~400KB are inlined into the prompt (Fable has 1M context); larger changes switch to self-collect mode where the reviewer explores the repo with read-only tools.
- Read-only tool allowlist: `Read,Grep,Glob` + git read subcommands via `Bash(git diff:*)` etc.; `Edit/Write/...` explicitly disallowed.
- Job state under `~/.fable-check/<repo-slug>/` — reports + job JSON; background mode spawns a detached worker.
- `--deep` runs 3 lens passes (correctness / security / design+edge-cases) concurrently, then one merge pass.
- Reports include the Claude session ID so the review can be resumed interactively (`claude -r <id>`).

### Task 3: SKILL.md (portable)

Instructions for the host agent: when to use, exact commands, return output verbatim, never fix code, recommend background for large diffs.

### Task 4: Installer + project docs

**Files:**
- Create: `install.sh` — symlink into both skills dirs
- Create: `README.md`, `CLAUDE.md`, `VISION.md`, `NOTICE`, `.gitignore`

### Task 5: Validation

- `setup` passes on this machine
- End-to-end review of a seeded-bug temp repo returns a structured report with the seeded bug found
- Install + verify both symlinks resolve
