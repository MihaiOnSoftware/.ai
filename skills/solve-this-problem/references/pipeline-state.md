# Pipeline state file format

The pipeline's state lives in a single markdown file at `~/.ai/wip/<feature>-pipeline-<YYYY-MM-DD>.md`. Update it at every phase boundary. If the session dies, this file is enough to resume.

## Template

```markdown
# Pipeline: <feature name>

## Status

- **Current phase**: <1–6 or "Complete" or "Paused at <point>">
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

## PR stack

- **Current base tip**: <the plan's base SHA; advanced only after a base restack>
- **Base branch**: <default branch, or the upstream ticket branch PR1 sits on>

| Bundle | Headline | Branch | Base | Slices | Validated tip | Tip gate | PR URL | Remote head | Base SHA (remote) | Checks | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| PR1 | <one sentence> | <branch> | <base branch> | 1–3 | <sha when last slice passed its tip gate> | <pass\|fail\|pending> | <url or empty> | <sha> | <sha> | <green\|red [checks]\|waiting on <gate>> | <building\|validated\|published\|stale\|merged> |
| PR2 | … | … | PR1 branch | 4–8 | … | … | … | … | … | … | … |

`stale` = remote head differs from the validated tip after a restack; republish before publishing anything above. Old tips from a restack stay in the row as `(was <sha>)` for forensics.

## Phase 5 — TDD per slice (`tdd-slice`)

| # | Slice | Bundle | Status | Pre-slice SHA | Commits (SHAs) | Slice tip | Boundary validation | Tests added | Ran mode | Report path | Checkpoint decision |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | <slice 1 name> | PR1 (first) | <pending\|in-progress\|done\|skipped\|paused\|rewritten> | <previous slice tip, or the bundle's base tip — used for Re-run reset> | <SHA1,SHA2,…> | <last SHA> | <slice gate pass\|fail; tip gate pass\|fail\|n/a> | <N> | <real_subagents\|inline_simulation> | <path> | <Proceed\|Open PR now\|Skip next\|Pause\|Re-run\|Repair bundle K> |
| 2 | <slice 2 name> | PR1 (middle) | … | … | … | … | … | … | … | … | … |
| … | | | | | | | | | | | |

---

## Open follow-ups (across phases)

- <bullet from Phase 1: e.g. "bulk import support, out of v1, revisit in v2">
- <bullet from Phase 3: e.g. "slice 7 deferred, depends on the auth service change ETA Q3">

---

## Phase 6 — Open the stack

- **Status**: <not started | partial (PRs opened at bundle close) | complete | stack ready to open (no submission specialist)>
- **Final refresh**: <timestamp; all PRs re-read and accepted>
- **Merge order and cascade**: PR1 → PR2 → …; after each merge restack every remaining bundle predecessor-by-predecessor (`pr-stack.md`)
- **Human steps**: <ready flips, manual gates such as approval-only checks>

## Completion

- **Pipeline status**: <Active | Paused at Phase X | Complete>
- **Completed at**: <YYYY-MM-DD HH:MM, when done>
- **Total commits**: <N>
- **Total tests added**: <N>
- **Stack**: <N> bundles, <N> draft PRs
```

## Update discipline

- Write the file once at pipeline start (with Phase 1 marked "in progress" or "skipped").
- Copy the plan's PR stack table in when Phase 3 completes; update a bundle's row when its last slice passes the tip gate, when it is published, and after any restack.
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
