# Phase dispatch recipes

Concrete `subagent({...})` call shapes for each phase. The conductor's job is to dispatch; the subagent's job to run the phase and write a summary back. The conductor then reads that summary file and merges the relevant fields into the pipeline state file (`~/.ai/wip/<feature>-pipeline-<date>.md`).

## Shared conventions

- **Use the dedicated phase agent** for each phase (`explore-and-design-agent`, `adversarial-review-loop-agent`, `create-implementation-plan-agent`, `tdd-slice-agent`, and the harness's PR-submission specialist for Phase 6). Each agent wraps its skill, pins its model, and carries the `subagent` tool so inner loops run as real fresh-context dispatches.
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

Investigate, scope, and produce a design doc at ~/.ai/wip/<topic>-<date>.md (never committed to a project repo). Talk to the user when the skill says to.

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

IMPORTANT — BATCH MODE: produce the FULL plan in this run as a single doc written to ~/.ai/wip/ (never committed, never written into a project repo). Do NOT iterate slice-by-slice with the user. The user will review the whole plan at the next pipeline checkpoint. The iterative-presentation pattern in the create-implementation-plan skill (its Critical Rule 2) is suspended for this batch invocation; write all slices at once.

If you would have asked the user for ack between slices, instead: write the slice, move on. If a slice depends on a real decision the user must make (e.g. "which API style?"), surface that as an open question at the bottom of the plan doc rather than blocking.

The plan must include the PR stack table (bundle id, headline, branch, base branch and SHA, slices, stands-alone argument, tip gate, closing items) and a **Bundle:** line on every slice. One bundle is a valid answer when no seam is admissible.

Output the plan to ~/.ai/wip/<topic>-plan-<date>.md.

When done, write a summary to <wip-summary-path> with:
- plan_doc_path: <path>
- base: { branch, sha }
- bundles: [{ id, headline, branch, base, slices, tip_gate, closing_items }]
- slice_count: <N>
- slices: [{ id, one_line_description, bundle, position, depends_on_previous }]
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
  task: `Run the adversarial-review-loop against the plan at <plan-doc-path>. The plan must serve the design at <design-doc-path>; deviations from the design are a load-bearing finding. So are the PR bundle seams: a bundle that would be red on its own, leaves a half-moved module at its tip, has no one-sentence reason to exist, or lacks its closing items (the administrative work PRs in this repo require, e.g. changelogs, CODEOWNERS) in its last slice is a defect in the plan.

Ground truth: design doc at <design-doc-path> + <any other ground-truth pointers>.
Pipeline state file: <wip-path>.

Apply Accepted fixes IN PLACE in the plan doc. Write summary to <wip-summary-path> with the same shape as Phase 2.

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 5 — TDD per slice (one dispatch per slice)

Before dispatching: the conductor must extract slice N from the plan into tdd-slice's documented input format (see `tdd-slice/SKILL.md` "Input Format" — it expects `# Slice [N]: [Name] / ## Goal / ## Bundle / ## Features / ## Tests to Write / ## Commit Message`). Fill the `## Bundle` section from the PR stack table (see `pr-stack.md`): branch, expected tip = the pre-slice SHA, position, slice gate, tip gate when the slice closes its bundle. Write the extracted slice spec to a scratch file (e.g. `~/.ai/wip/<feature>-pipeline-<date>-slice<N>-spec.md`) and pass that path to the dispatch.

The **pre-slice SHA** comes from the wip file per `pr-stack.md` § "Tracking"; record it before dispatching.

```js
subagent({
  agent: "tdd-slice-agent",
  task: `Slice requirements doc (in tdd-slice's documented input format): <slice-spec-path>
Full plan doc (for cross-slice context): <plan-doc-path>
Design doc (for context only; omit if not supplied at resume): <design-doc-path or "n/a">
Pipeline state file: <wip-path>

Run the tdd-slice protocol. It prepares the bundle branch through commit-agent, dispatches micro-tdd-agent, micro-refactor-agent, micro-chore-agent, commit-agent, tdd-validation-agent, micro-fix-agent, and investigator-agent per item, and ends with the boundary validation. It commits per its own conventions.

You cannot write files. Your final message IS the summary; it is bound to <wip-summary-path>. Include:
- commits: [{ sha, one_line_summary }]
- slice_tip: <sha of the last commit>
- branch: <bundle branch>
- tests_added: <N>
- tests_total: <N>
- boundary_validation: { slice_gate: pass|fail, tip_gate: pass|fail|n/a, report_path }
- notes (anything tdd-slice surfaced: deferred refactors, brief deviations, etc.)
- status: complete | failed | partial`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 6 — Open the stack (one dispatch for the whole stack)

Precondition: the harness has a PR-submission specialist that runs `gh stack` against the remote (contract in `pr-stack.md` § "Phase 6"). Without one, write the recipe from that section into the final summary and stop at "stack ready to open".

```js
subagent({
  agent: "<pr-submission-specialist>",
  task: `Publish or refresh a stacked series of DRAFT pull requests with gh stack.

Repo: <absolute path>, currently on branch <top bundle branch>.
PR stack table (bottom-up): <bundle, branch, validated tip, headline, body inputs: headline, slices, stands alone because, tip-gate evidence, stack position "PR n of total, base is …; merge bottom-up">
Pipeline state file: <wip-path>

1. gh stack submit --auto   (drafts; on exit 9 fall back to gh stack push, then gh pr create --draft --head <branch> --base <base> per bundle, bottom-up)
2. gh pr edit <number> --title "<headline>" --body "<body>" for every bundle
3. Trigger the repo's review bot on each PR, wait for checks to settle.

Write a summary to <wip-summary-path> with:
- stack: the output of gh stack view --json
- checks per PR: green | red [failing check names] | waiting on <manual gate>
- status: complete | failed

Do not mark any PR ready, request reviewers, or merge. Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

Apply the acceptance rule in `pr-stack.md` § "Phase 6" (heads = validated tips, bases = predecessors, nothing `needsRebase`) before recording bundles as published.

## Failure handling

If a subagent's summary says `status: failed` or it returns with no summary file:

1. Do not silently retry.
2. Read whatever the subagent did manage to produce.
3. Update the wip file with the failure (which phase, what's known).
4. Surface to the user with: what failed, what's recoverable, what the options are (retry / edit / pause / skip). Skip is only available when the branch is at a validated tip (the failing slice's rejected commits were reset by `tdd-slice`); a later slice never builds on a commit the validator rejected.
5. Wait for the user's decision before any next dispatch.

## Why fresh context per phase

- `explore-and-design` says "you are an investigator, not an implementer."
- `tdd-slice` says implement.
- `create-implementation-plan` says "no code in plans."
- `adversarial-review` requires the reviewer have no context from the author.

Loading these in the same session creates instruction conflicts. Fresh context per phase is load-bearing, not stylistic.
