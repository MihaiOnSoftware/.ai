# Phase dispatch recipes

Concrete `subagent({...})` call shapes for each phase. The conductor's job is to dispatch; the subagent's job is to load the skill, do the phase, and write a summary back. The conductor then reads that summary file and merges the relevant fields into the pipeline state file (`~/.ai/wip/<feature>-pipeline-<date>.md`).

## Shared conventions

- **Always `agent: "worker"`**. Use `worker` (the general-purpose subagent) for every phase. Don't try to use `planner` for Phase 3 or `tdd-slice-agent` for Phase 5 — those agents have their own framings that conflict with the skill-loading pattern.
- **Always `context: "fresh"`**. The `worker` agent ships with `defaultContext: fork`. If you omit `context: "fresh"`, the worker inherits the conductor's context, which silently violates this skill's load-bearing fresh-context-per-phase guarantee. The fresh-context requirement is the entire point of dispatching out.
- **Always `outputMode: "file-only"`**. The conductor's context shouldn't absorb the subagent's full output; the summary file is the handoff. (With `outputMode: "file-only"`, the call returns only a concise file reference — so the conductor MUST then `read` the summary file to learn the artifact path and key fields.)
- **Always pass the wip file path** so the subagent can read prior phases' notes.
- **Always tell the subagent which skill to load by absolute path**. Symlinks at `~/.pi/agent/skills/<name>/` work but the canonical source is `/Users/mihaip/src/github.com/MihaiOnSoftware/.ai/skills/<name>/`.
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

## Agent-capability gotcha (Phases 2, 4, 5)

The `worker` agent as shipped (`/Users/mihaip/.local/share/pnpm/global/5/node_modules/pi-subagents/agents/worker.md`) has `tools: read, grep, find, ls, bash, edit, write, contact_supervisor`. **No `subagent` tool.** But:

- Phase 2 / Phase 4 dispatch `adversarial-review-loop`, which is supposed to spawn one fresh-context subagent per iteration.
- Phase 5 dispatches `tdd-slice`, which is supposed to spawn micro-tdd-agent, micro-refactor-agent, commit-agent, tdd-validation-agent, micro-fix-agent, and investigator-agent.

Phase 1 (`explore-and-design`) also expects subagent capability when it follows its own Critical Rule 4 / 4a ("pause and refute conclusions from a fresh context... use the sibling skills `adversarial-review` and `adversarial-review-loop`"). So all four of Phase 1, 2, 4, and 5 may need the dispatched agent to be able to spawn its own subagents.

If the worker (or whichever agent you dispatch) lacks the `subagent` tool, those inner loops cannot run as designed. Options:

1. **Project-specific agent variant** with `subagent` added to `tools:` (and `defaultContext: fresh` to drop the override). This is the cleanest fix if the user controls the agent definitions.
2. **Inline fallback with fresh-context discipline.** The dispatched skill's worker runs the inner cycles inline in its own context, simulating fresh context per inner iteration by re-deriving from artifacts on disk rather than session memory. This is the documented workaround in this user's history when pi-subagents is unavailable (see `~/.pi/memory/` 2026-05-11 entry: "pi-subagents harness lock-in: when the global pnpm package upgrades mid-session, pi keeps the old extension path cached. Workaround: continue inline with disciplined red→green→blue"). Acceptable but loses the genuine isolation property.

Name which workaround you used in the wip file's Phase N entry. Future pipeline runs benefit from knowing whether the loop ran with real fresh contexts or inline simulation.

## Phase 1 — Design

```js
subagent({
  agent: "worker",
  context: "fresh",
  task: `Load the skill at ~/.pi/agent/skills/explore-and-design/SKILL.md.
Read its references (design-doc-shape.md, investigation-tactics.md, anti-patterns.md) and examples too.

Problem statement:
<verbatim from user>

Pipeline state file: <wip-path>

Follow the skill: investigate before asking, read source over docs, scope is the design, etc. Talk to the user via ask_user_question when the skill says to (or escalate via contact_supervisor if you lack that tool). Produce a committed design doc at design/<topic>.md (or ~/.ai/wip/<topic>-<date>.md for personal scratch).

The skill's Critical Rules 4 / 4a may prompt you to run adversarial-review or adversarial-review-loop against your design conclusion. If your harness can't spawn fresh subagents for that, run the loop inline with fresh-context discipline (note this in your summary).

When done, write a summary to <wip-summary-path> with:
- design_doc_path: <path>
- one-paragraph TL;DR of what the design covers
- notable_decisions (bullet list)
- open_questions_deferred (bullet list)
- ran_mode: <real_subagents | inline_simulation | n/a (no inner adversarial loop run)>
- status: complete

Return briefly.`,
  output: "<wip-summary-path>",
  outputMode: "file-only"
})
```

## Phase 2 — Design review

```js
subagent({
  agent: "worker",
  context: "fresh",
  task: `Load skills at ~/.pi/agent/skills/adversarial-review/SKILL.md and ~/.pi/agent/skills/adversarial-review-loop/SKILL.md. Read their references too.

Run the adversarial-review-loop against the design doc at <design-doc-path>.

Ground-truth pointers (the doc's claims should hold up against these):
- Problem statement: <verbatim>
- Source code paths the design references: <list>
- Any prior-art or fixture files: <list>
- Pipeline state file: <wip-path>

Apply the loop protocol: fresh-context subagent per iteration, triage findings per the rubric, apply Accepted fixes IN PLACE in the design doc, stop on the principled termination condition (weak / repeated / invalid / hard-cap-5). If your harness can't spawn fresh subagents, run the loop inline with fresh-context discipline (note this in your summary).

When done, write a summary to <wip-summary-path> with:
- review_log_path: <path>
- iterations: <N>
- counts: { accept: A, reject_weak: W, reject_invalid: I, repeat: R, defer: D }
- termination: <weak | repeated | invalid | hard_cap>
- ran_mode: <real_subagents | inline_simulation>
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
  agent: "worker",
  context: "fresh",
  task: `Load the skill at ~/.pi/agent/skills/create-implementation-plan/SKILL.md. Read its references and examples too.

Design doc to plan against: <design-doc-path>
Pipeline state file: <wip-path>

IMPORTANT — BATCH MODE: produce the FULL plan in this run as a single committed doc. Do NOT iterate slice-by-slice with the user. The user will review the whole plan at the next pipeline checkpoint. The iterative-presentation pattern in the create-implementation-plan skill (its Critical Rule 2) is suspended for this batch invocation; you commit all slices at once.

If you would have asked the user for ack between slices, instead: write the slice, move on. If a slice depends on a real decision the user must make (e.g. "which API style?"), surface that as an open question at the bottom of the plan doc rather than blocking.

Output the plan to plans/01-<topic>.md (or wherever the project convention says). Use the format from create-implementation-plan's reference examples.

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
  agent: "worker",
  context: "fresh",
  task: `Load adversarial-review + adversarial-review-loop skills.

Run the loop against the plan at <plan-doc-path>. The plan must serve the design at <design-doc-path>; deviations from the design are a load-bearing finding.

Ground truth: <as above + the design doc>.
Pipeline state file: <wip-path>.

Apply the loop protocol. If your harness can't spawn fresh subagents, run the loop inline with fresh-context discipline (note this in your summary). Write summary to <wip-summary-path> with the same shape as Phase 2.

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
  agent: "worker",
  context: "fresh",
  task: `Load the skill at ~/.pi/agent/skills/tdd-slice/SKILL.md. Read its references too.

Slice requirements doc (extracted from the plan, in tdd-slice's documented input format): <slice-spec-path>
Full plan doc (for cross-slice context): <plan-doc-path>
Design doc (for context only; may be omitted if user entered the pipeline at plan-already-reviewed without a design doc): <design-doc-path or "n/a">
Pipeline state file: <wip-path>

Run the tdd-slice protocol against the slice requirements doc. tdd-slice will dispatch its own internal agents per item (micro-tdd-agent for test behaviors, micro-refactor-agent for refactors, commit-agent for each commit, tdd-validation-agent per commit, with micro-fix-agent / investigator-agent on retry). It commits per its own conventions.

If your harness can't spawn the inner subagents, run the cycles inline with fresh-context discipline (note this in your summary).

When done, write a summary to <wip-summary-path> with:
- tdd_slice_report_path: <path>
- commits: [{ sha, one_line_summary }]
- tests_added: <N>
- tests_total: <N>
- gates_status: { tsc: ok|fail, lint: ok|fail, tests: ok|fail }
- ran_mode: <real_subagents | inline_simulation>
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
