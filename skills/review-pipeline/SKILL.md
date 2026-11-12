---
name: review-pipeline
description: "Parallel code review pipeline: run adversarial-review-loop, mihai-code-review and two lens-scoped Mihai reviewers (patterns, rules) simultaneously, merge their findings, shape into postable comments, and present for user approval. Trigger on 'review pipeline', 'full review', 'pipeline review', or when the user asks for both adversarial and Mihai-style review of a branch or PR."
license: MIT
metadata:
  category: review
---

# Review Pipeline

End-to-end code review orchestration. Four independent reviewers run in parallel so none anchors on another's framing: one adversarial, one full Mihai-style review, and two Mihai reviewers that each look through a single lens (patterns and conventions; Mihai's quality, testing and cleanup rules). A broad reviewer spreads its budget across everything; a lens reviewer spends all of it on one question, so it catches what the broad passes skim. Their findings merge into a single draft, shaped by a fresh-context comment shaper, then presented to the user for approval before anything is posted.

## Scope

This skill is loaded by `review-pipeline-agent` only. It is not self-selected — if this skill is running, the user has already decided to run the full review pipeline.

You are the conductor. You do not review code yourself. You do not write comments yourself. You dispatch, wait, merge, and present.

## What You Need Before Starting

Before dispatching any subagents, confirm you have:

1. **Target** — a branch name, PR number, or diff path. If missing, ask the user before proceeding.
2. **Repo root** — the absolute path to the checked-out repo. Needed by reviewers for `git grep`, `git show`, and precedent lookups.
3. **Head commit SHA** — resolve it yourself from the target (e.g. `git rev-parse`). All reviewers must review the same pinned commit, and the shaper needs it to verify lines and build links.
4. **PR description as text** — the reviewers work offline and must not fetch URLs. If the user gives a PR URL or number, resolve it to text yourself (e.g. `gh pr view`) before dispatching. If nothing is available, tell the reviewers to treat the commit messages as the description.
5. **Run slug** — a short identifier for this run (branch name or PR number). All wip file names include it so two same-day runs don't collide.

If any of these is missing and cannot be inferred, stop and ask the user. Do not start with incomplete inputs.

On a `monitor-gh-pr` re-review wake (the request carries its `## Re-review` block), read [references/delta-rereview.md](references/delta-rereview.md) before Phase 1.

## Pipeline

```
target (branch / PR / diff)
  → [Phase 1a] adversarial-review-loop     (parallel, async)  → adversarial findings
  → [Phase 1b] mihai-code-review           (parallel, async)  → mihai findings + sweep log
  → [Phase 1c] Mihai pattern lens          (parallel, async)  → patterns findings + conformance table
  → [Phase 1d] Mihai rules lens            (parallel, async)  → rules findings + rule log
  → wait for all four to complete
  → [Phase 2]  merge findings              (conductor)        → raw merged draft
  → [Phase 3]  shape-review-comments       (fresh subagent)   → shaped comments
  → PRESENT to user — wait for approval before doing anything else
```

## Phase 1: Parallel Review Dispatch

Dispatch **all four** reviewers simultaneously as async, fresh-context subagents. Do not wait for one to finish before launching the next.

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

### Phase 1c — Mihai pattern lens

Dispatch the Mihai pattern reviewer. It looks only at fit with the codebase: does the diff use existing patterns, does it introduce new ones, does it cleave closely to existing conventions (documented and unwritten). Pass the same three inputs as Phase 1b.

Expect back: verdict, answers to the three questions, line comments with precedent links, and a conformance table appendix (every construct classified FOLLOWS / DEVIATES / NEW).

### Phase 1d — Mihai rules lens

Dispatch the Mihai rules reviewer. It looks only for violations of Mihai's code quality, testing and cleanup rules (`~/.ai/rules`, the rules his `AGENTS.md` is built from). Pass the same three inputs as Phase 1b.

Expect back: verdict, summary, line comments each citing the rule it breaks, and a rule log appendix (every rule with its findings or why it is clean).

### Async discipline

All four subagents run concurrently. The conductor must not begin Phase 2 until all four have returned. If any fails or times out, stop, surface the failure to the user, and ask how to proceed — do not continue with a partial set of reviewer outputs.

## Phase 2: Merge Findings (Conductor Work)

Read all four outputs. Produce a single raw draft in this format for every surviving finding:

```
`path/to/file.ts:LINE` — severity: finding text (source: adversarial | mihai | patterns | rules)
```

The source is every reviewer that raised the finding, comma-separated (e.g. `source: mihai, rules`).

Merge rules:
- **Several reviewers flag the same issue**: collapse into one entry, list every source, use the sharper phrasing.
- **Only one reviewer flags it**: keep as-is, note the source.
- **One finding is a superset of another on the same line**: keep the fuller text, list both sources.
- **Keep the evidence a lens attached**: a patterns finding keeps its precedent `file:line`; a rules finding keeps the rule it cites.
- **Contradicting verdicts on severity**: use the higher severity; note the disagreement in the finding text.

After the findings, add the four reviewers' verdicts (Phase 1a termination reason, Phase 1b–1d verdicts) so the shaper sees where they disagree. The sweep log, conformance table and rule log stay in the reviewer output files; reference their paths instead of copying them in.

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
- The verdicts from all four reviewers (Phase 1a termination reason + Phase 1b, 1c and 1d verdicts)
- A brief summary: total findings going in, how many survived triage, source breakdown

**Stop here.** Wait for explicit user direction before doing anything else. The user decides whether to post, revise, or discard.

Once the user's review is up, you may offer the `monitor-gh-pr` re-review watch (its `references/rereview.md`), and start it only when the user asks.

## Failure Handling

| Failure | Action |
|---|---|
| Missing target / repo / PR description | Ask the user before dispatching any subagent |
| A Phase 1 subagent fails or times out | Stop pipeline, surface the error, ask the user how to proceed |
| Phase 2 merged draft is empty | Tell the user; ask whether to close or re-run |
| Phase 3 shaper cannot read both reference files | Stop and report; the shaper's own skill handles this — do not bypass it |
| Any phase subagent is missing from the harness | Stop and surface to the user; do not fall back to a generic subagent |

## Anti-Patterns

- **Sequential review dispatch.** The whole point of parallel dispatch is that no reviewer anchors on another's framing. Launch Phases 1a–1d together; never wait for one before starting the next.
- **Conductor doing review work.** If you find yourself reading the diff and writing findings, stop — that belongs to the phase subagents.
- **Conductor doing shaping work.** Triage and voice decisions belong to the shaper. Pass the full merged draft; let the shaper drop what isn't worth saying.
- **Posting without user approval.** The pipeline ends at "present for approval." Posting is always the user's call.
- **Reusing reviewer context.** Each phase subagent starts fresh. Never pass one reviewer's output into another reviewer's context.
