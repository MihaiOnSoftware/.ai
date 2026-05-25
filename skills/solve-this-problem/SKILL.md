---
name: solve-this-problem
description: End-to-end orchestration from problem statement to landed commits on a branch. Chains explore-and-design + adversarial-review-loop → create-implementation-plan + adversarial-review-loop → tdd-slice per slice. Use when the user wants a committed design + plan + sliced TDD implementation driven without manually loading each sub-skill. Supports starting partway (design exists → plan, plan exists → ship). See Scope for what this skill does not cover.
license: MIT
metadata:
  category: orchestration
---

# Solve This Problem

End-to-end orchestration of the **design → plan → ship** pipeline, from problem statement to landed commits on a branch. You are the conductor; each phase runs in a fresh-context subagent that owns its phase end-to-end (including talking to the user within the phase).

## Scope

This skill assumes the problem produces a committed design doc and a slice-by-slice plan. It is the right tool when:

- the user wants a new feature / system / SDK / refactor designed, planned, and implemented,
- the output of design is a `design/<topic>.md` (or scratch `~/.ai/wip/<topic>-<date>.md`) — not just an issue comment.

It is the **wrong** tool when:

- the problem is a production investigation whose output is an issue comment + PR description (use `explore-and-design` directly and stop after Phase 4 there),
- the user wants the design or plan only (skip Phase 5),
- there is no plan-able structure (one-shot fixes, single commits — go straight to `tdd-slice` or just edit).

The pipeline ends at **landed commits on a branch**. It does not open PRs, request review, or merge. Those steps are the user's call after the pipeline completes.

## Pipeline

```
problem statement
  → [Phase 1] explore-and-design                (subagent)  → design doc
  → [Phase 2] adversarial-review-loop on design  (subagent)  → review log
  → CHECKPOINT — surface design + review, get approval
  → [Phase 3] create-implementation-plan         (subagent)  → plan doc
  → [Phase 4] adversarial-review-loop on plan    (subagent)  → review log
  → CHECKPOINT — surface plan + review, get approval
  → [Phase 5] for each slice in plan:
      tdd-slice                                 (subagent)  → commits
      → CHECKPOINT — surface slice result, get approval
```

## Your role

You are the conductor. **You do not do design / plan / implementation yourself.** For each phase, dispatch a fresh-context worker subagent with the relevant skill loaded and let it own the phase end-to-end. You re-engage at checkpoints and whenever the phase subagent escalates for a decision.

**Mid-phase user input.** The `worker` agent as shipped does NOT have an `ask_user_question` tool (its `tools:` line is `read, grep, find, ls, bash, edit, write, contact_supervisor`). When the phase subagent's loaded skill says "ask the user", the subagent must instead escalate to you via `contact_supervisor` with `reason: "need_decision"`. The full loop is:

1. Phase subagent calls `contact_supervisor({ reason: "need_decision", message: <question + context> })` and **blocks** waiting for the reply (per worker.md: "stay alive to receive the reply before continuing").
2. You (conductor) receive the escalation. Note the subagent's `run-id`.
3. You call `ask_user_question(...)` with the subagent's question, surfaced to the user with the phase context.
4. User answers.
5. You resume the subagent: `subagent({ action: "resume", id: <run-id>, message: <user's answer> })`.
6. Subagent unblocks with the answer and continues.

If your harness ships a custom worker variant that includes `ask_user_question` directly, the subagent can skip steps 2–5 and ask the user itself — note which mode you're in inside the pipeline state file (template field: "Mid-phase user-input mode: via-supervisor | direct").

When a subagent returns, **read its summary file**, **merge the key fields into the pipeline state file**, surface at the checkpoint if there is one, then proceed. See `references/phase-dispatch.md` for the summary-file convention and the merge step.

## Pipeline state file (the source of truth)

Create `~/.ai/wip/<feature>-pipeline-<YYYY-MM-DD>.md` at the start of a new pipeline. This file holds the pipeline's state across sessions — **don't rely on the memory bank, it isn't always available in every context** (subagent runs, fresh harness, etc.).

Each phase subagent writes a **separate per-phase summary file** (see `references/phase-dispatch.md`); the conductor reads those and merges the fields into this single pipeline state file. The summary files are scratch — the pipeline state file is the durable record.

The file template is in `references/pipeline-state.md`. Update the file at every phase boundary. If the session dies mid-pipeline, the file is enough to resume.

## Starting partway (resume)

The user can hand you an existing artifact and a phase to resume from. Supported entry points:

| User input | Skip phases | Start at | Also needed |
|---|---|---|---|
| "Problem: …" (or no artifact) | (none) | Phase 1 | — |
| "Design doc at X" | 1 | Phase 2 (review the design) | — |
| "Design doc at X, already reviewed" | 1, 2 | Phase 3 (plan) | — |
| "Plan at Y" | 1, 2, 3 | Phase 4 (review the plan) | design doc path (recommended; the plan is reviewed against the design) |
| "Plan at Y, already reviewed, start slicing" | 1–4 | Phase 5 | design doc path is **optional** — if absent, Phase 5 dispatch omits the design-doc field and tdd-slice runs without it |
| "Resume pipeline at `<wip-file-path>`" | (read state from file) | wherever paused | — |

When resuming, create the wip file with skipped phases marked as "skipped (artifact supplied)" linking the user-supplied path. Don't fabricate review logs for skipped reviews — just note "user-supplied; not reviewed by this pipeline." If the user supplies a plan but no design doc, mark Phase 1's `design_doc_path` field as `n/a (not supplied at resume)` and skip the design-doc field in the Phase 5 dispatch task.

## Phase dispatch shape

For each phase, spawn a fresh-context `worker` subagent. Pattern (see `references/phase-dispatch.md` for one-per-phase recipes, the agent-capability gotcha, and the summary-file convention):

```
subagent({
  agent: "worker",
  context: "fresh",          // REQUIRED — worker's defaultContext is "fork"; without this, the worker inherits parent context
  task: "Load skill at ~/.pi/agent/skills/<skill>/SKILL.md (read references too). Then <phase task>. Write a phase-summary to <wip-summary-path> with: artifact_path, status, key counts/numbers, notable findings. Return briefly.",
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

The subagent inherits no context (because of `context: "fresh"`) — it must read the prior phase's artifact from disk. Pass the wip file path so it knows where to read the prior phase's notes if needed.

**Agent-capability prerequisite.** Phases 2, 4, and 5 dispatch skills that themselves spawn subagents, but the shipped `worker` agent lacks the `subagent` tool. See `references/phase-dispatch.md` ("Agent-capability gotcha") for the inline-fallback workaround and which phases are affected.

## Phase 1: Design

Input: a problem statement from the user, OR a `~/.ai/wip/<topic>-<date>.md` scratchpad.

Dispatch a worker loading `explore-and-design`. Pass the problem statement. The subagent investigates, scopes, talks to the user as needed, and commits a design doc (`design/<topic>.md` in the project repo, or `~/.ai/wip/<topic>-<date>.md` for scratch).

After it returns:
1. Read the design doc path from the subagent's summary.
2. Update wip file: Phase 1 complete; design doc at `<path>`.
3. **No checkpoint here.** Proceed to review — the user reviews design + review together at the next checkpoint.

## Phase 2: Design review

Dispatch a worker loading `adversarial-review-loop`. Pass: design doc path, problem statement, and "ground truth" pointers (any source code, prior art docs, real-data probes the design references).

After it returns:
1. Read review log + termination reason.
2. Update wip file: Phase 2 complete; review log at `<path>`; accept/reject/repeat counts; termination reason.
3. **CHECKPOINT.** Surface to user via `ask_user_question`:
   - Design doc path + 3-5 sentence summary
   - Review termination reason + counts (e.g. "5 iters, 18 accepts, hard-cap")
   - 1-3 notable findings the review accepted
   - Options:
     - **Approve, proceed to planning**
     - **Edit and re-review** — the user manually edits the design doc; conductor re-dispatches Phase 2 only against the edited doc
     - **Re-design from scratch** — conductor re-dispatches Phase 1 (then Phase 2) with the user's revised problem framing
     - **Pause pipeline** (mark wip file and exit)

## Phase 3: Plan

Dispatch a worker loading `create-implementation-plan`. Pass: design doc path, wip file path.

**Important — batch mode:** Tell the subagent to produce the *full plan in this run* (committed as a single doc), not iterate slice-by-slice with the user. The user will review the whole plan at the next checkpoint. Iterative-per-slice presentation is for direct user invocations of `create-implementation-plan`; from here, the subagent's only "user" is the wip file.

After it returns:
1. Read plan doc path.
2. Update wip file: Phase 3 complete; plan at `<path>`; slice count + slice names.
3. **No checkpoint.** Proceed to plan review.

## Phase 4: Plan review

Dispatch a worker loading `adversarial-review-loop`. Pass plan doc path, design doc path (the plan is reviewed *against* the design), wip file path.

After it returns:
1. Read review log.
2. Update wip file: Phase 4 complete.
3. **CHECKPOINT.** Surface to user:
   - Plan doc path + slice count + 1-line description per slice
   - Review termination reason + counts
   - Notable accepted findings
   - Options:
     - **Approve, start implementation**
     - **Edit and re-review** — the user manually edits the plan; conductor re-dispatches Phase 4 only against the edited plan
     - **Re-plan from scratch** — conductor re-dispatches Phase 3 (then Phase 4) with the user's revised direction
     - **Pause pipeline**

## Phase 5: TDD per slice

For each slice in the plan, in order:

1. Update wip file: starting slice N. **Capture the current branch HEAD SHA as the pre-slice SHA for slice N** and record it in the wip file before dispatching (`git rev-parse HEAD`). This is needed for the Re-run slice N checkpoint option below.
2. Extract slice N from the plan into tdd-slice's documented input format (see `tdd-slice/SKILL.md` "Input Format": `# Slice [N]: [Name] / ## Goal / ## Features / ## Tests to Write / ## Commit Message`) and write it to `~/.ai/wip/<feature>-pipeline-<date>-slice<N>-spec.md`.
3. Dispatch a worker loading `tdd-slice`. Pass: slice spec path, plan doc path (for cross-slice context), design doc path (omit if not supplied at resume), wip file path. See `references/phase-dispatch.md` for the recipe.
4. `tdd-slice` runs its own internal cycles (per item it dispatches the right micro agent — micro-tdd-agent for test behaviors or micro-refactor-agent for refactors — then commit-agent, then tdd-validation-agent **per micro commit** with micro-fix-agent / investigator-agent on retry). It commits as it goes.
5. After it returns:
   - Read the tdd-slice report path.
   - Update wip file: slice N done; commits (SHAs + one-line summaries); tests added (count); report at `<path>`; ran_mode.
6. **CHECKPOINT.** Surface to user:
   - Slice goal + result
   - Commit SHAs + summaries
   - Test count delta
   - Report path
   - Options:
     - **Proceed to next slice**
     - **Pause pipeline** (mark wip file with paused-at-slice-N+1)
     - **Skip slice N+1** (mark in wip file, proceed to N+2) — ⚠️ `create-implementation-plan` orders slices so each builds on the previous (its Principle 7). Skipping a slice may leave later slices with broken prerequisites. Surface this warning and confirm before proceeding.
     - **Re-run slice N** (e.g. if validation surfaced a real problem) — slice N already produced micro commits. Before re-dispatching tdd-slice, the conductor must:
       1. Verify the working tree is clean (`git status --porcelain` empty). A hard reset will discard any uncommitted changes — if there are any, surface them and confirm with the user first.
       2. Verify that the only commits since the pre-slice SHA are slice-N's micro commits. If later slices (N+1, N+2, ...) have also been committed, a hard reset to pre-slice-N erases them too. In that case, either: (a) confirm with the user that those later slices should be invalidated and reset further back, OR (b) abort the re-run.
       3. Record any commits about to be discarded (SHAs + summaries) in the wip file under "Abandoned commits" for forensics.
       4. `git reset --hard <pre-slice-sha>`.
       5. Re-set the wip file's slice-N row to `pending` and clear the commit list. The new run replaces the old commit list.

       Do NOT just re-dispatch on top of the existing commits — you'll duplicate code or tests.

When all slices are done: update wip file with "pipeline complete", surface a final summary to the user (total commits, total tests, total time roughly, deferred follow-ups from all phases).

## What you do NOT do

- You do **not** load `explore-and-design` / `create-implementation-plan` / `tdd-slice` / `adversarial-review` / `adversarial-review-loop` yourself in your own context. They get loaded by phase subagents in fresh contexts. Loading them in the conductor's context bloats it for no gain.
- You do **not** write design docs / plans / code. The phase subagents own that.
- You do **not** retry a failed phase silently. If a subagent fails or returns ambiguously, surface to the user with the failure and ask for direction.
- You do **not** skip the wip file. It's the source of truth across sessions and contexts.
- You do **not** auto-approve past checkpoints. The user is the gate.

## Anti-patterns

- **Doing a phase inline to save tokens** — defeats the point of fresh-context dispatch. Each skill is designed to run with a clean slate; mixing them in one context creates conflicts (e.g. `explore-and-design` says "you are an investigator, not an implementer"; `tdd-slice` says implement). This is distinct from the **inline-fallback workaround** documented in `references/phase-dispatch.md` for the case where the dispatched agent lacks the `subagent` tool: that workaround runs the inner cycles inline with fresh-context discipline (re-deriving from artifacts on disk) and is acceptable when noted in the wip file's `ran_mode` field. The anti-pattern is skipping fresh-context dispatch for the OUTER phase boundary to save tokens, not running inner cycles inline when no other option exists.
- **Skipping checkpoints when the artifacts look fine** — the user has context you don't (priorities, side projects, half-remembered constraints). Always surface.
- **Letting the wip file lag** — update it at every phase boundary, not "at the end". If a session dies between phases without an updated file, the resume case can't work.
- **Running slice N+1 before checkpointing slice N** — slice N's report may surface a scope change that affects N+1. The serialization is load-bearing.
- **Trying to parallelize slices** — `create-implementation-plan` orders slices so each builds on the previous. Parallel TDD breaks the build-on-previous assumption. (If a future user wants parallel slices, they'll say so and you'll have to think about it.)

