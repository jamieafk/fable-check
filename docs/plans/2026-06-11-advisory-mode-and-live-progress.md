# Advisory Mode + Live Progress Implementation Plan

**Goal:** Make fable-check usable for advisory questions (not just reviews) and make it continuously communicative so invoking agents (Codex, Claude Code) never mistake a long review for a stall.

**Architecture:** Switch the headless `claude` invocation from buffered `--output-format json` to `stream-json --verbose` and parse the JSONL event stream. Each tool-use event becomes a progress line; a heartbeat timer fills any gaps. Progress flows to stderr in foreground runs and to the job log + a `progress` field in the job JSON for background runs, which `status` renders. Advisory mode is a new `ask` subcommand reusing the same job machinery with a prose prompt and no output schema.

**Tech Stack:** Node ESM, zero dependencies (unchanged).

**Verified:** `claude -p --output-format stream-json --verbose --json-schema ...` works on the installed CLI; the final `result` event carries `result`, `structured_output`, `session_id`, `total_cost_usd` (tested 2026-06-11 on haiku).

---

### Task 1: Streaming runClaude with progress events

**Files:** Modify `skill/scripts/fable-check.mjs`

- [ ] Replace `--output-format json` with `--output-format stream-json --verbose`; parse stdout line-by-line as JSONL.
- [ ] Synthesize the envelope from the final `{type:"result"}` event (keep all existing fallbacks in `extractStructured`).
- [ ] Emit progress via an `onProgress(text)` callback: session start, each tool use (tool name + concise input summary, e.g. `Read src/foo.js`, `git diff --cached`), tool-call counter.
- [ ] Heartbeat timer (~20s): if no event lately, emit `still working — Xm elapsed, N tool calls, last: ...`.
- [ ] Make the output schema optional (`schema: false` for advisory).

### Task 2: Progress plumbing + live status

**Files:** Modify `skill/scripts/fable-check.mjs`

- [ ] Reporter wired in `runReviewJob`: every progress line → job log; foreground → also stderr; always → update `job.progress` ({phase, toolCalls, lastActivity, lastActivityAt, startedAt}) in the job JSON (throttled writes).
- [ ] Phase tracking: context collection → review pass(es) (deep: per-lens `[correctness] …` prefixes and lens completion counts) → merge → report.
- [ ] Startup banner: target, expected duration range, how progress will appear.
- [ ] `status`: for running jobs show elapsed, phase, tool calls, last activity + age; flag `possibly stalled` if last activity > 5 min and pid alive; keep `failed (worker died)` reconciliation.
- [ ] `--quiet` flag to suppress stderr progress.

### Task 3: Advisory mode (`ask`)

**Files:** Modify `skill/scripts/fable-check.mjs`; create `skill/prompts/advise.md`

- [ ] `ask` subcommand: question from positionals (required), flags `--effort/--model/--cwd/--background/--json/--quiet`. Same read-only tool allowlist.
- [ ] Context: branch, short status, recent commit log — no diff inlining; the advisor explores with tools.
- [ ] `prompts/advise.md`: principal-engineer advisor; explore before answering; concrete file references; one recommendation, not a menu; honest about uncertainty.
- [ ] Output is markdown prose (no schema); report saved through the same job files; `status/result/cancel` work unchanged (kind: `advisory`).

### Task 4: Docs

**Files:** Modify `skill/SKILL.md`, `README.md`

- [ ] SKILL.md: advisory section; progress-reporting section with explicit invoker guidance (heartbeats ~20s, silence >60s abnormal, poll `status` every 30–60s for background jobs).
- [ ] Frontmatter description mentions advisory.
- [ ] Usage text + README updated.

### Task 5: End-to-end verification (real usage, low effort)

- [ ] Temp repo with seeded bug → `review --effort low` foreground: progress lines stream on stderr, report still valid, bug found.
- [ ] `review --background` → `status` shows live phase/tool activity → `result` returns report.
- [ ] `ask --effort low` answers a small advisory question with repo references.
