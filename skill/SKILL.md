---
name: fable-check
description: Run an extensive code review with Claude Fable 5 (Anthropic's most capable model). Use when the user asks for a code review, a fable check, a second opinion on changes, a pre-ship review, or an adversarial/deep review of the working tree or a branch. Read-only — it never modifies code.
---

# fable-check — Fable 5 code review

Run a structured, read-only code review of the current git work using the Claude Fable 5 model via the local `claude` CLI. The reviewer gets read-only tools (Read/Grep/Glob plus read-only git commands), so it verifies findings against the real code instead of guessing from the diff.

All commands below run from the repository being reviewed. `<skill-dir>` is this skill's directory (the folder containing this SKILL.md).

## Core constraint

- This skill is **review-only**. Never fix issues, apply patches, or imply you are about to make changes as part of running it.
- Return the script's output to the user **verbatim** — do not paraphrase, summarize, or filter the findings.
- After presenting the review, you may offer to address the findings as a separate follow-up if the user wants.

## Commands

Standard review of current work (auto-detects: dirty working tree → working-tree diff; clean tree → branch vs default branch):

```bash
node "<skill-dir>/scripts/fable-check.mjs" review
```

Review a branch against a base:

```bash
node "<skill-dir>/scripts/fable-check.mjs" review --base main
```

Adversarial review (skeptical, tries to block the change; accepts steering text):

```bash
node "<skill-dir>/scripts/fable-check.mjs" review --adversarial challenge the caching and retry design
```

Deep review (three parallel lens passes — correctness, security/data-safety, design/failure-modes — merged into one report; the most extensive and most expensive mode):

```bash
node "<skill-dir>/scripts/fable-check.mjs" review --deep
```

Other flags: `--scope auto|working-tree|branch`, `--effort low|medium|high|xhigh|max` (default `xhigh`), `--model <model>` (default `claude-fable-5`), `--json`.

## Foreground vs background

Reviews of multi-file changes can take several minutes. Choose the mode:

- Small change (1–3 files) → run in the foreground and wait.
- Anything larger, unclear size, or `--deep` → run in the background.

Background options (either works):

1. Use your own background-execution facility to run the foreground command, then report results when it completes.
2. Or use the built-in job runner:

```bash
node "<skill-dir>/scripts/fable-check.mjs" review --background
node "<skill-dir>/scripts/fable-check.mjs" status          # progress / job list
node "<skill-dir>/scripts/fable-check.mjs" result          # final report (latest job)
node "<skill-dir>/scripts/fable-check.mjs" cancel          # stop an active job
```

When you launch a background review, tell the user the job id and that they can ask for status/results at any time.

## Setup / troubleshooting

If a review fails because the `claude` CLI is missing or logged out:

```bash
node "<skill-dir>/scripts/fable-check.mjs" setup
```

It reports what is missing and the exact next step (installing Claude Code or logging in). Reviews use the user's existing Claude subscription — no API key is needed.

## Notes

- There must be something to review: uncommitted changes, or commits ahead of the base branch. If the script reports nothing to review, relay that — do not invent a review.
- Reports are also saved under `~/.fable-check/jobs/<repo>/` and each report includes a `claude -r <session-id>` command to reopen the review session interactively.
- Focus text is most effective with `--adversarial`; the standard review intentionally takes no steering so its judgment stays neutral.
