---
name: review-pipeline
description: "Orchestrates a four-reviewer parallel code review of a branch or PR, merges and shapes the findings, and presents the comments for the user's approval. Loaded by review-pipeline-agent when the user asks for the full review pipeline, adversarial and Mihai-style review together. Not for a single-reviewer pass; use mihai-code-review or adversarial-review-loop directly."
license: MIT
metadata:
  category: review
---

# Review Pipeline

Four independent reviewers run in parallel, their findings merge into one draft, a fresh shaper turns the draft into postable comments, and the user decides what gets posted.

## Scope

`review-pipeline-agent` loads this skill once the user has chosen the full pipeline. You are the conductor: you dispatch, wait, merge and present. The reviewers produce every finding and the shaper writes every comment.

The four reviewers, by the names used throughout:

| Phase | Reviewer | Skill | Source tag | Verdict it returns |
|---|---|---|---|---|
| 1a | adversarial loop | `adversarial-review-loop` | `adversarial` | termination reason |
| 1b | Mihai review | `mihai-code-review`, full | `mihai` | APPROVE / APPROVE-WITH-COMMENTS / CHANGES_REQUESTED |
| 1c | pattern lens | `mihai-code-review`, patterns and conventions only | `patterns` | same as 1b |
| 1d | rules lens | `mihai-code-review`, Mihai's quality, testing and cleanup rules only | `rules` | same as 1b |

"The four verdicts" below means that last column. [references/phase-dispatch.md](references/phase-dispatch.md) has the dispatch call for each phase.

## What You Need Before Starting

1. **Target**: a branch name, PR number, or diff path.
2. **Repo root**: the absolute path to the checked-out repo, for `git grep`, `git show` and precedent lookups.
3. **Head commit SHA**: resolve it yourself from the target (e.g. `git rev-parse`). Every reviewer reviews this pinned commit, and the shaper uses it to verify lines and build links.
4. **PR description as text**: reviewers work offline, so resolve a PR URL or number to text yourself (e.g. `gh pr view`). With nothing available, tell the reviewers to treat the commit messages as the description.
5. **Run slug**: a short identifier (branch name or PR number). Every file this run writes is `<wip>-<name>.md`, where `<wip>` is `~/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>`, so two same-day runs don't collide.

On a `monitor-gh-pr` re-review wake (the request carries its `## Re-review` block), read [references/delta-rereview.md](references/delta-rereview.md) before Phase 1.

## Pipeline

```
target (branch / PR / diff)
  → [Phase 1a] adversarial loop   (parallel, async)  → <wip>-adversarial-output.md
  → [Phase 1b] Mihai review       (parallel, async)  → <wip>-mihai-output.md
  → [Phase 1c] pattern lens       (parallel, async)  → <wip>-patterns-output.md
  → [Phase 1d] rules lens         (parallel, async)  → <wip>-rules-output.md
  → wait for all four
  → [Phase 2]  merge findings     (conductor)        → <wip>-merged-draft.md
  → [Phase 3]  shaper             (fresh subagent)   → <wip>-shaped-comments.md
  → checkpoint: present to the user and wait
```

## Phase 1: Parallel Review Dispatch

Launch all four reviewers in one turn, as async, fresh-context subagents, so none anchors on another's framing. Each gets the same three inputs (the diff at the pinned commit, the repo root, the PR description) and writes its output to its `<wip>` file. No reviewer sees another reviewer's output.

- **1a, adversarial loop.** Findings-only mode: the code is someone else's, so it reports accepted findings and leaves the repo unchanged. Nothing changes between rounds, so the loop ends on "repeated findings"; that is the normal exit. Returns findings labelled `nit` / `minor` / `major` / `question`.
- **1b, Mihai review.** Returns verdict, summary, line comments and the sweep log.
- **1c, pattern lens.** Only fit with the codebase: does the diff use existing patterns, introduce new ones, cleave to existing conventions (documented and unwritten). Returns verdict, answers to the three questions, line comments with precedent links, and a conformance table classifying every construct FOLLOWS / DEVIATES / NEW.
- **1d, rules lens.** Only Mihai's code quality, testing and cleanup rules (`~/.ai/rules`, the files his `AGENTS.md` is built from). Returns verdict, summary, line comments each citing the rule it breaks, and a rule log listing every rule with its findings or why it is clean.

Done when all four `<wip>` output files exist and each holds its verdict and its artifact (1b sweep log, 1c conformance table, 1d rule log). Only then start Phase 2.

## Phase 2: Merge Findings

Read all four outputs and write one raw draft, one line per finding:

```
`path/to/file.ts:LINE` — severity: finding text (source: adversarial | mihai | patterns | rules)
```

The source lists every reviewer that raised it, comma-separated (e.g. `source: mihai, rules`).

- **Same issue from several reviewers:** one entry, every source, the sharper phrasing.
- **One finding is a superset of another on the same line:** keep the fuller text, list both sources.
- **Lens evidence stays attached:** a patterns finding keeps its precedent `file:line`; a rules finding keeps the rule it cites.
- **Severity disagreement:** the higher severity, with the disagreement noted in the text.

After the findings, add the four verdicts so the shaper sees where reviewers disagree, and link the sweep log, conformance table and rule log by their output paths. Pass every finding through; dropping is the shaper's call.

Done when every line comment from the four outputs appears in `<wip>-merged-draft.md`, as its own entry or as a listed source on a merged one, and the four verdicts follow.

## Phase 3: Shape Comments

Dispatch a fresh-context shaper (`shape-review-comments`) with `<wip>-merged-draft.md`, the repo root (for `grep -n` line checks), the head SHA and branch, and the PR URL or `org/repo#number` so cross-file references become GitHub links at the head commit.

The shaper has no user channel: it returns the shaped comments and its triage log as output, posts nothing and asks nobody.

Done when `<wip>-shaped-comments.md` exists and its triage log accounts for every merged-draft entry as kept, merged or dropped.

## Checkpoint: Surface and Wait

Surface to the user:
- The shaped comments, or the path to `<wip>-shaped-comments.md`
- The four verdicts
- Findings going in, how many survived triage, and the source breakdown

Then wait for the user's direction. The user decides whether to post, revise or discard, and posting happens only on the user's word.

Once the user's review is up, you may offer the `monitor-gh-pr` re-review watch (its `references/rereview.md`), and start it only when the user asks.

## Failure Handling

| Failure | Action |
|---|---|
| A required input is missing and cannot be inferred, or the target or head SHA does not resolve | Ask the user before dispatching anything |
| A phase agent is missing from the harness | Stop and tell the user; a generic subagent is no substitute |
| A Phase 1 reviewer fails or times out | Stop, surface the error, and ask the user how to proceed; a partial set of outputs does not go to Phase 2 |
| The merged draft is empty | Tell the user and ask whether to close or re-run |
| The shaper fails, times out, or cannot read `triage-rules.md` and `voice-guide.md` | Stop and report the error with the merged draft's path; the comments stay unwritten until the user decides |
