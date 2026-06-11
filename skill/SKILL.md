---
name: fable-check
description: Run an extensive code review or get advisory input from Claude Fable 5 (Anthropic's most capable model). Use when the user asks for a code review, a fable check, a second opinion on changes, a pre-ship review, an adversarial/deep review of the working tree or a branch — or wants Fable's advice on an architecture choice, design tradeoff, plan, or technical decision about the codebase. Read-only — it never modifies code.
---

# fable-check — Fable 5 code review & advisory

Run a structured, read-only code review — or ask an advisory question — using the Claude Fable 5 model via the local `claude` CLI. The reviewer/advisor gets read-only tools (Read/Grep/Glob plus read-only git commands), so it verifies its claims against the real code instead of guessing.

All commands below run from the repository being reviewed. `<skill-dir>` is this skill's directory (the folder containing this SKILL.md).

## Core constraint

- This skill is **read-only**. Never fix issues, apply patches, or imply you are about to make changes as part of running it.
- Return the script's output to the user **verbatim** — do not paraphrase, summarize, or filter the findings or the advisory answer.
- After presenting the output, you may offer to act on it as a separate follow-up if the user wants.

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

Advisory — ask Fable a question instead of requesting a review (architecture choices, design tradeoffs, "is this plan sound?", second opinions on a decision, "how should X work?"). The advisor explores the repo with read-only tools and answers in prose with one clear recommendation:

```bash
node "<skill-dir>/scripts/fable-check.mjs" ask "should the job runner move to worker threads, or is the detached-process design right?"
```

Other flags (both `review` and `ask`): `--effort low|medium|high|xhigh|max` (default `xhigh`), `--model <model>` (default `claude-fable-5`), `--background`, `--json`, `--quiet` (suppress progress stream). `review` also takes `--scope auto|working-tree|branch` and `--base <ref>`.

## Progress reporting — IMPORTANT for invoking agents

Runs take minutes, but they are **never silent**. While running, the script streams continuous progress to **stderr** (stdout stays clean for the final report):

- a startup banner with the target and an expected duration range,
- a line for every tool call the reviewer makes (`tool #14: reading src/foo.js`),
- phase changes (`phase: review pass running`, `phase: lens passes: 2/3 complete`, `phase: merging ...`),
- a heartbeat at least every ~20 seconds during thinking stretches (`still working — 3m40s elapsed, 14 tool call(s) so far, last: ...`).

Interpretation rules:

- **Do not kill or abandon a run that is emitting progress lines or heartbeats — it is healthy.** Typical durations: standard review 2–8 min, deep review 5–15 min, advisory 1–6 min (longer for big diffs or `max` effort).
- Silence for more than ~60 seconds is abnormal; only then check on it. The script itself flags a job as `possibly stalled` in `status` after 5 minutes without any model events (its own heartbeats don't count as activity).
- If your execution harness has a command timeout shorter than ~15 minutes, run with `--background` instead of stretching the timeout.

## Foreground vs background

- Small change (1–3 files) or a quick advisory question → run in the foreground and wait; relay the streamed progress if your harness shows it.
- Anything larger, unclear size, or `--deep` → run in the background.

Background options (either works):

1. Use your own background-execution facility to run the foreground command, then report results when it completes.
2. Or use the built-in job runner:

```bash
node "<skill-dir>/scripts/fable-check.mjs" review --background     # or: ask --background "..."
node "<skill-dir>/scripts/fable-check.mjs" status                  # live progress: phase, elapsed, tool calls, last activity
node "<skill-dir>/scripts/fable-check.mjs" result                  # final report (latest job)
node "<skill-dir>/scripts/fable-check.mjs" cancel                  # stop an active job
```

`status` on a running job shows elapsed time, current phase, tool-call count, the last activity with its age, and an explicit healthy/possibly-stalled verdict — poll it every 30–60 seconds. You can also `tail -f` the job's log file (path shown at launch and in `status`).

When you launch a background job, tell the user the job id and that they can ask for status/results at any time.

## Setup / troubleshooting

If a run fails because the `claude` CLI is missing or logged out:

```bash
node "<skill-dir>/scripts/fable-check.mjs" setup
```

It reports what is missing and the exact next step (installing Claude Code or logging in). Runs use the user's existing Claude subscription — no API key is needed.

## Notes

- For reviews there must be something to review: uncommitted changes, or commits ahead of the base branch. If the script reports nothing to review, relay that — do not invent a review. (`ask` has no such requirement.)
- Reports and answers are saved under `~/.fable-check/jobs/<repo>/` and each includes a `claude -r <session-id>` command to reopen the session interactively.
- Focus text is most effective with `--adversarial`; the standard review intentionally takes no steering so its judgment stays neutral. For steered questions, prefer `ask`.
