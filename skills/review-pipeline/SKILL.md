---
name: review-pipeline
description: "Parallel code review pipeline: run adversarial-review-loop and mihai-code-review simultaneously, merge their findings, shape into postable comments, and present for user approval. Trigger on 'review pipeline', 'full review', 'pipeline review', or when the user asks for both adversarial and Mihai-style review of a branch or PR."
license: MIT
metadata:
  category: review
---

# Review Pipeline

End-to-end code review orchestration. Two independent reviewers run in parallel — one adversarial, one Mihai-style — so neither anchors on the other's framing. Their findings merge into a single draft, shaped by a fresh-context comment shaper, then presented to the user for approval before anything is posted.

## Scope

This skill is loaded by `review-pipeline-agent` only. It is not self-selected — if this skill is running, the user has already decided to run the full review pipeline.

You are the conductor. You do not review code yourself. You do not write comments yourself. You dispatch, wait, merge, and present.

## What You Need Before Starting

Before dispatching any subagents, confirm you have:

1. **Target** — a branch name, PR number, or diff path. If missing, ask the user before proceeding.
2. **Repo root** — the absolute path to the checked-out repo. Needed by reviewers for `git grep`, `git show`, and precedent lookups.
3. **Head commit SHA** — resolve it yourself from the target (e.g. `git rev-parse`). Both reviewers must review the same pinned commit, and the shaper needs it to verify lines and build links.
4. **PR description as text** — the reviewers work offline and must not fetch URLs. If the user gives a PR URL or number, resolve it to text yourself (e.g. `gh pr view`) before dispatching. If nothing is available, tell the reviewers to treat the commit messages as the description.
5. **Run slug** — a short identifier for this run (branch name or PR number). All wip file names include it so two same-day runs don't collide.

If any of these is missing and cannot be inferred, stop and ask the user. Do not start with incomplete inputs.

## Pipeline

```
target (branch / PR / diff)
  → [Phase 1a] adversarial-review-loop     (parallel, async)  → adversarial findings
  → [Phase 1b] mihai-code-review           (parallel, async)  → mihai findings + sweep log
  → wait for both to complete
  → [Phase 2]  merge findings              (conductor)        → raw merged draft
  → [Phase 3]  shape-review-comments       (fresh subagent)   → shaped comments
  → PRESENT to user — wait for approval before doing anything else
```

## Phase 1: Parallel Review Dispatch

Dispatch **both** reviewers simultaneously as async, fresh-context subagents. Do not wait for one to finish before launching the other.

### Phase 1a — Adversarial review loop

Dispatch the adversarial-review-loop reviewer. Pass:
- The diff or branch under review (at the pinned commit, not a drifted working tree)
- The repo root path
- The PR description (or commit messages)
- **Findings-only mode**: the artifact under review is someone else's code. The reviewer must NOT apply fixes to the repo. Accepted findings accumulate in its report instead of being fixed in place. Because nothing changes between rounds, the loop will terminate via "repeated findings"; that is expected, not a failure.

Expect back: a list of findings labelled with the shaper's severity vocabulary (nit / minor / major / question).

### Phase 1b — Mihai-style code review

Dispatch the mihai-code-review reviewer. Pass:
- The diff or branch under review (same commit as Phase 1a)
- The repo root path
- The PR description (or commit messages)

Expect back: verdict, summary, line comments, and sweep log appendix.

### Async discipline

Both subagents run concurrently. The conductor must not begin Phase 2 until both have returned. If one fails or times out, stop, surface the failure to the user, and ask how to proceed — do not continue with only one reviewer's output.

## Phase 2: Merge Findings (Conductor Work)

Read both outputs. Produce a single raw draft in this format for every surviving finding:

```
`path/to/file.ts:LINE` — severity: finding text (source: adversarial | mihai | both)
```

Merge rules:
- **Both reviewers flag the same issue**: collapse into one entry, mark source as `both`, use the sharper phrasing.
- **Only one reviewer flags it**: keep as-is, note the source.
- **Adversarial finding is a superset of a mihai finding on the same line**: keep the adversarial text, note source as `both`.
- **Contradicting verdicts on severity**: use the higher severity; note the disagreement in the finding text.

Do not triage or drop findings at this step — that is the shaper's job. Pass everything through.

Write the merged draft to `~/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-merged-draft.md`.

## Phase 3: Shape Comments

Dispatch a **fresh-context** comment shaper. Pass:
- The path to the merged draft (`~/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-merged-draft.md`)
- The repo root path (for line-number verification via `grep -n`)
- The head commit SHA and branch name
- The PR URL (or org/repo + PR number) so cross-file references become GitHub links at the head commit

The shaper is a leaf subagent with no user channel: for it, "present for approval" means **return the shaped comments and the triage log as its output**. It posts nothing and asks nobody. The conductor presents to the user at the checkpoint below.

## Checkpoint: Surface and Wait

After Phase 3 completes, the conductor surfaces to the user:
- The shaped comments (or a path to them if the shaper wrote a file)
- The verdicts from both reviewers (Phase 1a termination reason + Phase 1b verdict)
- A brief summary: total findings going in, how many survived triage, source breakdown

**Stop here.** Wait for explicit user direction before doing anything else. The user decides whether to post, revise, or discard.

## Failure Handling

| Failure | Action |
|---|---|
| Missing target / repo / PR description | Ask the user before dispatching any subagent |
| A Phase 1 subagent fails or times out | Stop pipeline, surface the error, ask the user how to proceed |
| Phase 2 merged draft is empty | Tell the user; ask whether to close or re-run |
| Phase 3 shaper cannot read both reference files | Stop and report; the shaper's own skill handles this — do not bypass it |
| Any phase subagent is missing from the harness | Stop and surface to the user; do not fall back to a generic subagent |

## Anti-Patterns

- **Sequential review dispatch.** The whole point of parallel dispatch is that neither reviewer anchors on the other's framing. Never wait for Phase 1a before starting Phase 1b.
- **Conductor doing review work.** If you find yourself reading the diff and writing findings, stop — that belongs to the phase subagents.
- **Conductor doing shaping work.** Triage and voice decisions belong to the shaper. Pass the full merged draft; let the shaper drop what isn't worth saying.
- **Posting without user approval.** The pipeline ends at "present for approval." Posting is always the user's call.
- **Reusing reviewer context.** Each phase subagent starts fresh. Never pass one reviewer's output into another reviewer's context.
