# fable-check

Extensive code review powered by **Claude Fable 5** — usable as a skill from both **Claude Code** and **Codex**. The inverse of [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc): instead of Claude Code calling Codex for reviews, any agent (or your terminal) calls Fable 5 for reviews.

## What you get

- `review` — a thorough, structured review of your uncommitted changes or your branch vs a base. Verdict (approve / needs-attention), severity-sorted findings with file:line locations, confidence scores, and next steps.
- `review --adversarial [focus text]` — a skeptical review that actively tries to block the change. Steerable: "challenge the retry design", "look for race conditions", etc.
- `review --deep` — three parallel review passes (correctness, security & data safety, design & failure modes) merged and de-duplicated into one report. The most extensive mode.
- `status` / `result` / `cancel` + `--background` — run long reviews in the background.
- `setup` — checks that everything is installed and logged in.

The reviewer runs **read-only**: it can read files, grep, and run read-only git commands to verify findings against the real code, but it can never modify anything.

## Requirements

- [Claude Code](https://claude.com/claude-code) installed and logged in (reviews use your existing Claude subscription — no API key)
- Node.js 18+
- git

## Install

```bash
./install.sh
```

This symlinks the skill into `~/.claude/skills/fable-check` and `~/.codex/skills/fable-check` and runs a setup check. After that:

- In **Claude Code** or **Codex**: say "run a fable check" / "do a fable review of my changes".
- From a **terminal**, directly:

```bash
node skill/scripts/fable-check.mjs review
node skill/scripts/fable-check.mjs review --base main
node skill/scripts/fable-check.mjs review --adversarial question whether this caching design is safe
node skill/scripts/fable-check.mjs review --deep --background
node skill/scripts/fable-check.mjs result
```

## How it works

The script collects your git context (working-tree diff or branch diff against a base; auto-detected like the original plugin). Small diffs are inlined into the prompt; large ones switch the reviewer into self-collect mode, where it explores the repo itself with read-only tools. It then runs the local `claude` CLI headlessly:

```
claude -p --model claude-fable-5 --effort xhigh --output-format json \
  --json-schema <review schema> --allowedTools <read-only set>
```

Structured output is validated against the schema by the CLI itself. Reports are printed, saved under `~/.fable-check/jobs/<repo>/`, and include a `claude -r <session-id>` command to reopen the review session interactively.

## Differences from codex-plugin-cc

| | codex-plugin-cc | fable-check |
|---|---|---|
| Reviewer model | GPT-5.x via Codex | Claude Fable 5 |
| Host | Claude Code (plugin) | Claude Code **and** Codex (skill), or plain terminal |
| Reviewer capabilities | inline diff or self-collect | same, plus agentic read-only repo exploration in every mode |
| Deep mode | — | `--deep`: 3 parallel lenses + merge pass |
| Task delegation (`rescue`) | yes | not included (out of scope: this is a review tool) |
| Stop-hook review gate | optional | not included (plugin-only machinery; drains usage) |

Prompt structure, output schema, and review-target selection are adapted from codex-plugin-cc (Apache-2.0) — see `NOTICE`.
