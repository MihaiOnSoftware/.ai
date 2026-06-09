# Phase dispatch recipes

Concrete `subagent({...})` call shapes for each phase. The conductor's job is to dispatch; the subagent's job to run the phase and write a summary back. The conductor then reads that summary file and merges the relevant fields into the pipeline state file (`~/.ai/wip/<feature>-pipeline-<date>.md`).

## Shared conventions

- **Use the dedicated phase agent** for each phase (`explore-and-design-agent`, `adversarial-review-loop-agent`, `create-implementation-plan-agent`, `tdd-slice-agent`). Each agent wraps its skill, pins its model, and carries the `subagent` tool so inner loops run as real fresh-context dispatches.
- **No `context:` override needed.** User agents default to fresh context. Omit `context: "fresh"` — it was only required for `worker`, which defaulted to fork.
- **Always `outputMode: "file-only"`**. The conductor's context shouldn't absorb the subagent's full output; the summary file is the handoff. (With `outputMode: "file-only"`, the call returns only a concise file reference — so the conductor MUST then `read` the summary file to learn the artifact path and key fields.)
- **Always pass the wip file path** so the subagent can read prior phases' notes.
- **No skill-path injection needed.** The agent's own system prompt loads its skill. Don't repeat "Load the skill at..." in the task.
- **Always ask for a structured summary** with the artifact path, status, and key numbers — that's what you merge into the pipeline state file.

## Summary-file convention

Each phase writes a per-phase summary at:

```
~/.ai/wip/<feature>-pipeline-<YYYY-MM-DD>-phase<N>-summary.md
```

Sibling to the main pipeline state file. The conductor:

1. After the subagent returns, `read` the summary file.
2. Parse the structured fields the recipe asked for.
3. Update the matching block in the pipeline state file (Phase N's row/section).
4. Leave the summary file in place as audit trail.

Never overwrite the main pipeline state file with the summary — the state file accumulates across phases; summary files are per-phase.

## Phase 1 — Design

```js
subagent({
  agent: "explore-and-design-agent",
  task: `Problem statement:
<verbatim from user>

Pipeline state file: <wip-path>

Investigate, scope, and produce a committed design doc at design/<topic>.md (or ~/.ai/wip/<topic>-<date>.md for scratch). Talk to the user when the skill says to.

When done, write a summary to <wip-summary-path> with:
- design_doc_path: <path>
- one-paragraph TL;DR of what the design covers
- notable_decisions (bullet list)
- open_questions_deferred (bullet list)
- status: complete

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 2 — Design review

```js
subagent({
  agent: "adversarial-review-loop-agent",
  task: `Run the adversarial-review-loop against the design doc at <design-doc-path>.

Ground-truth pointers (the doc's claims should hold up against these):
- Problem statement: <verbatim>
- Source code paths the design references: <list>
- Any prior-art or fixture files: <list>
- Pipeline state file: <wip-path>

Apply Accepted fixes IN PLACE in the design doc. Stop on the principled termination condition (weak / repeated / invalid / hard-cap-5).

When done, write a summary to <wip-summary-path> with:
- review_log_path: <path>
- iterations: <N>
- counts: { accept: A, reject_weak: W, reject_invalid: I, repeat: R, defer: D }
- termination: <weak | repeated | invalid | hard_cap>
- notable_accepts (top 3, with brief context)
- deferred (bullets)
- status: complete

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 3 — Plan

```js
subagent({
  agent: "create-implementation-plan-agent",
  task: `Design doc to plan against: <design-doc-path>
Pipeline state file: <wip-path>

IMPORTANT — BATCH MODE: produce the FULL plan in this run as a single committed doc. Do NOT iterate slice-by-slice with the user. The user will review the whole plan at the next pipeline checkpoint. The iterative-presentation pattern in the create-implementation-plan skill (its Critical Rule 2) is suspended for this batch invocation; commit all slices at once.

If you would have asked the user for ack between slices, instead: write the slice, move on. If a slice depends on a real decision the user must make (e.g. "which API style?"), surface that as an open question at the bottom of the plan doc rather than blocking.

Output the plan to plans/01-<topic>.md (or wherever the project convention says).

When done, write a summary to <wip-summary-path> with:
- plan_doc_path: <path>
- slice_count: <N>
- slices: [{ id, one_line_description, depends_on_previous }]
- open_questions_for_user (if any)
- status: complete

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 4 — Plan review

Same shape as Phase 2 but pointed at the plan doc. Pass the design doc as ground truth — "the plan should serve the design, not contradict it."

```js
subagent({
  agent: "adversarial-review-loop-agent",
  task: `Run the adversarial-review-loop against the plan at <plan-doc-path>. The plan must serve the design at <design-doc-path>; deviations from the design are a load-bearing finding.

Ground truth: design doc at <design-doc-path> + <any other ground-truth pointers>.
Pipeline state file: <wip-path>.

Apply Accepted fixes IN PLACE in the plan doc. Write summary to <wip-summary-path> with the same shape as Phase 2.

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 5 — TDD per slice (one dispatch per slice)

Before dispatching: the conductor must extract slice N from the plan into tdd-slice's documented input format (see `tdd-slice/SKILL.md` "Input Format" — it expects `# Slice [N]: [Name] / ## Goal / ## Features / ## Tests to Write / ## Commit Message`). Write the extracted slice spec to a scratch file (e.g. `~/.ai/wip/<feature>-pipeline-<date>-slice<N>-spec.md`) and pass that path to the dispatch.

Also: capture the current branch HEAD SHA as the **pre-slice SHA** and record it in the wip file before dispatching — needed for the "Re-run slice N" checkpoint option.

```js
subagent({
  agent: "tdd-slice-agent",
  task: `Slice requirements doc (in tdd-slice's documented input format): <slice-spec-path>
Full plan doc (for cross-slice context): <plan-doc-path>
Design doc (for context only; omit if not supplied at resume): <design-doc-path or "n/a">
Pipeline state file: <wip-path>

Run the tdd-slice protocol. It will dispatch micro-tdd-agent, micro-refactor-agent, commit-agent, tdd-validation-agent, micro-fix-agent, and investigator-agent per item. It commits per its own conventions.

When done, write a summary to <wip-summary-path> with:
- tdd_slice_report_path: <path>
- commits: [{ sha, one_line_summary }]
- tests_added: <N>
- tests_total: <N>
- gates_status: { tsc: ok|fail, lint: ok|fail, tests: ok|fail }
- notes (anything tdd-slice surfaced: deferred refactors, brief deviations, etc.)
- status: complete | failed | partial

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Failure handling

If a subagent's summary says `status: failed` or it returns with no summary file:

1. Do not silently retry.
2. Read whatever the subagent did manage to produce.
3. Update the wip file with the failure (which phase, what's known).
4. Surface to the user with: what failed, what's recoverable, what the options are (retry / edit / pause / skip).
5. Wait for the user's decision before any next dispatch.

## Why fresh context per phase

- `explore-and-design` says "you are an investigator, not an implementer."
- `tdd-slice` says implement.
- `create-implementation-plan` says "no code in plans."
- `adversarial-review` requires the reviewer have no context from the author.

Loading these in the same session creates instruction conflicts. Fresh context per phase is load-bearing, not stylistic.
