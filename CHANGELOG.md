# Changelog

## 2026-06-11 — Advisory mode + live progress

**TL;DR: fable-check can now answer questions, not just review code — and it's impossible to mistake a running job for a dead one.**

- **New `ask` command (advisory mode).** Ask Fable an architecture, design, or "is this plan sound?" question. It explores the repo with the same read-only tools and answers in prose, leading with one clear recommendation. No diff required.
- **Runs are never silent.** Every run streams live progress: a line per tool call (`tool #14: reading src/foo.js`), phase changes, and a heartbeat at least every ~20s with elapsed time and current activity (`FABLE_CHECK_HEARTBEAT_MS` to tune).
- **Live `status` for background jobs.** Shows elapsed time, phase, tool-call count, last activity and its age, plus an explicit healthy/possibly-stalled verdict. Stall detection keys off the model's actual events (including thinking ticks), so it only warns on real silence (5+ min).
- **Invoker guidance in SKILL.md.** Typical durations, "don't kill a run that's emitting heartbeats," and a recommended 30–60s `status` polling cadence — so agents like Codex no longer abandon long reviews as stalled.
- **Reliability hardening** (from an adversarial review of the change): atomic job-state writes (safe to poll), cancellation now actually terminates the underlying `claude` processes instead of orphaning them, and cancel/complete races can no longer resurrect or clobber a job's final state.

## 2026-06-10 — Initial public release

- `review` (standard / `--adversarial` / `--deep` three-lens), `setup`, background jobs with `status`/`result`/`cancel`.
- Read-only reviewer via the local `claude` CLI on the user's existing login; reports saved under `~/.fable-check/jobs/`.
- Apache-2.0, with prompt/schema design adapted from openai/codex-plugin-cc (see NOTICE).
