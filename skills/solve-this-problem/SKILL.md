---
name: solve-this-problem
description: "End-to-end: problem → design → plan → TDD slices → a stack of draft PRs. Chains explore-and-design + adversarial-review-loop → create-implementation-plan → tdd-slice per bundle → PR submission per bundle. Supports mid-pipeline entry."
license: MIT
metadata:
  category: orchestration
---

# Solve This Problem

End-to-end orchestration of the **design → plan → ship** pipeline, from problem statement to a stack of draft PRs, one per bundle of slices, each on its own branch stacked on the one below. You are the conductor; each phase runs in a fresh-context subagent that owns its phase end-to-end (including talking to the user within the phase).

## Scope

This skill is loaded by `solve-this-problem-agent` only. It is not self-selected — if this skill is running, the user has already decided to run the full pipeline.

The pipeline assumes the problem produces a design doc and a slice-by-slice plan grouped into PR bundles (both in `~/.ai/wip/`, never committed), and ends at **a stack of draft PRs** opened by a PR-submission specialist, or at "stack ready to open" with a per-bundle recipe when the harness has no such specialist. It never marks PRs ready, requests review, or merges. Those are the user's.

**Prerequisite**: the conductor runs at delegation depth 0 (a top-level session or fleet worker), or the harness's nesting limit is at least 3. `tdd-slice` dispatches specialists of its own; under the default cap of 2, a conductor that is itself a subagent cannot reach them.

## Pipeline

```
problem statement
  → [Phase 1] explore-and-design                (subagent)  → design doc
  → [Phase 2] adversarial-review-loop on design  (subagent)  → review log
  → CHECKPOINT — surface design + review, get approval
  → [Phase 3] create-implementation-plan         (subagent)  → plan doc
  → [Phase 4] adversarial-review-loop on plan    (subagent)  → review log
  → CHECKPOINT — surface plan + review, get approval
  → [Phase 5] for each slice in plan, on its bundle's branch:
      tdd-slice                                 (subagent)  → commits + boundary validation
      → CHECKPOINT — surface slice result, get approval
      → at a bundle's last slice: tip gate passed → optionally open its draft PR now
  → [Phase 6] open the stack                    (PR-submission specialist per bundle, bottom-up) → draft PRs
```

## Your role

You are the conductor. **You do not do design / plan / implementation yourself.** For each phase, dispatch the dedicated phase agent and let it own the phase end-to-end. You re-engage at checkpoints and whenever the phase subagent escalates for a decision.

**Engineering manager principle.** You are an engineering manager who is *less knowledgeable than your reports* — you cannot do design, planning, or implementation work yourself, not even as a shortcut. When a subagent fails, times out, or returns ambiguously, surface the failure to the user and ask for direction; doing the work inline is never the fallback.

**Purpose-built agent per phase.** Each phase has a dedicated agent (explore-and-design, adversarial-review-loop, create-implementation-plan, tdd-slice). Dispatch your harness's purpose-built agent for that phase — never a generic, unnamed, or general-purpose subagent. A dedicated phase agent carries a pinned model, its own skill, and phase-specific framing; a generic subagent silently drops all three and breaks the fresh-context guarantee the pipeline depends on. If a phase's agent is missing from your harness, stop and surface to the user rather than falling back to a generic subagent (same rule as the Engineering manager principle).

**Mid-phase user input.** Phase agents have `ask_user_question` available (they don't restrict their tool set), so when a skill says "ask the user" the agent asks directly. Set the pipeline state file's "Mid-phase user-input mode" field to `direct`.

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

Dispatch the dedicated phase agent per `references/phase-dispatch.md` (one recipe per phase, the summary-file convention, and the fields each summary must carry). Every agent starts with no inherited context and reads the prior phase's artifact from disk, so always pass the wip file path.

## Phase 1: Design

Input: a problem statement from the user, OR a `~/.ai/wip/<topic>-<date>.md` scratchpad.

Dispatch `explore-and-design-agent`. Pass the problem statement. The agent investigates, scopes, talks to the user as needed, and writes a design doc to `~/.ai/wip/<topic>-<date>.md` (never committed to a project repo).

After it returns:
1. Read the design doc path from the subagent's summary.
2. Update wip file: Phase 1 complete; design doc at `<path>`.
3. **No checkpoint here.** Proceed to review — the user reviews design + review together at the next checkpoint.

## Phase 2: Design review

Dispatch `adversarial-review-loop-agent`. Pass: design doc path, problem statement, and "ground truth" pointers (any source code, prior art docs, real-data probes the design references).

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

Dispatch `create-implementation-plan-agent`. Pass: design doc path, wip file path.

**Important — batch mode:** Tell the agent to produce the *full plan in this run* as a single doc written to `~/.ai/wip/` (never committed), not iterate slice-by-slice with the user. The user will review the whole plan at the next checkpoint. Iterative-per-slice presentation is for direct user invocations of `create-implementation-plan`; from here, the agent's only "user" is the wip file.

A plan without the PR stack table is incomplete; send it back.

After it returns:
1. Read plan doc path.
2. Update wip file: Phase 3 complete; plan at `<path>`; slice count + slice names; bundle list.
3. **No checkpoint.** Proceed to plan review.

## Phase 4: Plan review

Dispatch `adversarial-review-loop-agent`. Pass plan doc path, design doc path (the plan is reviewed *against* the design), wip file path.

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

Before the first slice, copy the PR stack table from the **approved** plan into the wip file (the Phase 4 review edits the plan in place, so copy after the checkpoint, not after Phase 3) and set `current base tip` to the plan's base SHA. `references/pr-stack.md` has the tracking rules: where each SHA comes from, how the `## Bundle` section is filled, re-runs, repair slices, restacks.

For each slice in the plan, in order:

1. Update wip file: starting slice N with its pre-slice SHA.
2. Extract slice N from the plan into tdd-slice's input format (`# Slice [N]: [Name] / ## Goal / ## Bundle / ## Features / ## Tests to Write / ## Commit Message`) and write it to `~/.ai/wip/<feature>-pipeline-<date>-slice<N>-spec.md`.
3. Dispatch `tdd-slice-agent` per `references/phase-dispatch.md`, binding `output:` to the slice summary path.
4. After it returns, read the summary and update the wip file: slice N done; commits; slice tip; tests added; boundary validation result. On a bundle's last slice, record the slice tip as the bundle's **validated tip** and the tip-gate result in the PR stack table.
5. **CHECKPOINT.** Surface to user:
   - Slice goal + result
   - Commit SHAs + summaries
   - Test count delta
   - Report path
   - Options:
     - **Proceed to next slice**
     - **Open this bundle's draft PR now** (only at a bundle's last slice with the tip gate passed): run the Phase 6 submission for this bundle, then continue. Default when the user does not choose; the alternative is opening everything at the end.
     - **Pause pipeline** (mark wip file with paused-at-slice-N+1)
     - **Skip slice N+1** (mark in wip file, proceed to N+2) — ⚠️ `create-implementation-plan` orders slices so each builds on the previous (its Principle 7). Skipping a slice may leave later slices with broken prerequisites. Surface this warning and confirm before proceeding.
     - **Re-run slice N** (e.g. if validation surfaced a real problem): follow "Re-run slice N" in `references/pr-stack.md`. Never re-dispatch on top of the existing commits; you'll duplicate code or tests.
     - **Repair an earlier bundle** (a defect a reviewer of bundle K would call K's): follow the repair-slice and restack procedure in `references/pr-stack.md`.

A failed tip gate blocks the next bundle: the options are a repair item, a re-run, or a pause.

When all slices are done, go to Phase 6.

## Phase 6: Open the stack

Dispatch the PR-submission specialist once per unpublished bundle, bottom-up, with the contract in `references/pr-stack.md` § "Phase 6"; apply its acceptance rule, its check-status handling, and its final refresh before declaring completion. When the harness has no specialist implementing the contract, write the per-bundle recipe into the final summary and end at "stack ready to open".

Then update the wip file with "pipeline complete" and surface a final summary: the stack in merge order (bundle, PR URL, base, tip), the merge-cascade recipe from `references/pr-stack.md`, human steps (ready flips, manual gates), total commits, total tests, deferred follow-ups from all phases.

## What you do NOT do

- You do **not** run phase skills in your own context. They run inside dedicated phase agents in fresh contexts. Loading skills in the conductor's context bloats it for no gain.
- You do **not** write design docs / plans / code. The phase subagents own that.
- You do **not** retry a failed phase silently, and you do **not** fill in for a failed phase yourself. If a subagent fails, times out, or returns ambiguously — for any reason — surface the failure to the user (what phase, what happened, what you received) and ask for direction. **Doing the work inline instead is not a valid fallback.**
- You do **not** skip the wip file. It's the source of truth across sessions and contexts.
- You do **not** auto-approve past checkpoints. The user is the gate.
- You do **not** run git or touch the remote: no `rev-parse`, no reset, no rebase, no push, no `gh pr create`, no ready flip, no merge. SHAs come from the plan and specialist summaries; history changes are `commit-agent` dispatches; rewrites are recipes the user runs; PRs are the submission specialist's.

## Anti-patterns

- **Doing a phase inline — for any reason** — the most important anti-pattern, broadened past the original "to save tokens" framing. Temptations: save tokens, fill in for a failed subagent, recover from a communication breakdown, handle a timeout, "just sketch out" a design. All wrong. Each phase skill runs in a clean-slate context; mixing phase work into the conductor creates role conflicts (`explore-and-design` is an investigator, `tdd-slice` an implementer — you can't be both) and breaks the fresh-context guarantee the pipeline depends on. For the failure case, see the Engineering manager principle and the retry bullet above.
- **Skipping checkpoints when the artifacts look fine** — the user has context you don't (priorities, side projects, half-remembered constraints). Always surface.
- **Letting the wip file lag** — update it at every phase boundary, not "at the end". If a session dies between phases without an updated file, the resume case can't work.
- **Running slice N+1 before checkpointing slice N** — slice N's report may surface a scope change that affects N+1. The serialization is load-bearing.
- **Trying to parallelize slices** — `create-implementation-plan` orders slices so each builds on the previous. Parallel TDD breaks the build-on-previous assumption.
- **Fixing an earlier bundle from a later one** — if a reviewer of bundle K would call the change K's, it goes into K as a repair slice and the bundles above are restacked. Patching it in bundle N leaves K wrong on its own.

