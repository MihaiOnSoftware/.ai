# Pipeline state file format

The pipeline's state lives in a single markdown file at `~/.ai/wip/<feature>-pipeline-<YYYY-MM-DD>.md`. Update it at every phase boundary. If the session dies, this file is enough to resume.

## Template

```markdown
# Pipeline: <feature name>

## Status

- **Current phase**: <1–5 or "Complete" or "Paused at <point>">
- **Started**: <YYYY-MM-DD>
- **Last update**: <YYYY-MM-DD HH:MM>
- **Wip file**: <path to self>
- **Mid-phase user-input mode**: <via-supervisor | direct> — `via-supervisor` if the dispatched agent lacks `ask_user_question` and must escalate via `contact_supervisor`; `direct` if the agent variant includes `ask_user_question`.

## Feature

<One paragraph problem statement. Verbatim from the user when possible.>

---

## Phase 1 — Design (`explore-and-design`)

- **Status**: <not started | in progress | complete | skipped (user-supplied)>
- **Subagent run id**: <if available>
- **Ran mode**: <real_subagents | inline_simulation | n/a>
- **Design doc path**: <path>
- **Notable decisions surfaced during design**:
  - <bullet>
- **Open questions deferred to plan or implementation**:
  - <bullet>

## Phase 2 — Design review (`adversarial-review-loop`)

- **Status**: <not started | in progress | complete | skipped>
- **Ran mode**: <real_subagents | inline_simulation>
- **Review log path**: <path>
- **Iterations**: <N>
- **Accept / Reject(weak) / Reject(invalid) / Repeat / Defer**: <counts>
- **Termination**: <Weak | Repeated | Invalid | Hard-cap (5)>
- **Notable accepted findings** (top 3):
  - <bullet>
- **Deferred findings**:
  - <bullet>

### CHECKPOINT 1 — user decision

- **Asked at**: <timestamp>
- **User decision**: <Approve | Edit | Pause>
- **Edits requested** (if any): <bullet list>

---

## Phase 3 — Plan (`create-implementation-plan`)

- **Status**: <not started | in progress | complete | skipped>
- **Ran mode**: <real_subagents | inline_simulation | n/a>
- **Plan doc path**: <path>
- **Slice count**: <N>
- **Slices**:
  1. <slice id / one-line description>
  2. …

## Phase 4 — Plan review (`adversarial-review-loop`)

- **Status**: …
- **Ran mode**: <real_subagents | inline_simulation>
- **Review log path**: <path>
- **Iterations, counts, termination**: <as in Phase 2>
- **Notable accepted findings**:
  - <bullet>
- **Plan changes resulting from review**:
  - <bullet>

### CHECKPOINT 2 — user decision

- **Asked at**: <timestamp>
- **User decision**: <Approve | Edit | Pause>

---

## Phase 5 — TDD per slice (`tdd-slice`)

| # | Slice | Status | Pre-slice SHA | Commits (SHAs) | Tests added | Ran mode | Report path | Checkpoint decision |
|---|---|---|---|---|---|---|---|---|
| 1 | <slice 1 name> | <pending\|in-progress\|done\|skipped\|paused> | <pre-slice HEAD SHA, captured before dispatch — used for Re-run revert> | <SHA1,SHA2,…> | <N> | <real_subagents\|inline_simulation> | <path> | <Proceed\|Skip next\|Pause\|Re-run> |
| 2 | <slice 2 name> | … | … | … | … | … | … | … |
| … | | | | | | | | |

---

## Open follow-ups (across phases)

- <bullet from Phase 1: e.g. "metafield value typing — out of v1, revisit in v2">
- <bullet from Phase 3: e.g. "slice 7 deferred — depends on Flow change ETA Q3">

---

## Completion

- **Pipeline status**: <Active | Paused at Phase X | Complete>
- **Completed at**: <YYYY-MM-DD HH:MM, when done>
- **Total commits**: <N>
- **Total tests added**: <N>
```

## Update discipline

- Write the file once at pipeline start (with Phase 1 marked "in progress" or "skipped").
- After each subagent returns, before any checkpoint: fill in the phase block.
- After each user checkpoint: fill in the checkpoint block + advance the Status block.
- **One update per phase boundary.** Don't accumulate batches of updates.

## What goes in `Open follow-ups`

Things the pipeline discovered that aren't blocking but should not be lost:

- Non-goals named in the design doc that may become goals later
- Findings the adversarial review accepted as "valid but out of scope"
- Slices the user chose to skip
- TODOs surfaced in `tdd-slice` reports

This section is what a future "what was deferred?" question reads from.
