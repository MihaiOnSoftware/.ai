# Phase dispatch recipes

Concrete `subagent({...})` call shapes for each phase. The conductor dispatches; the subagent owns its phase end-to-end.

## Shared conventions

- **Use the dedicated phase agent** for each phase. Each agent wraps its skill, pins its model, and carries the right tool set.
- **No `context:` override needed.** User agents default to fresh context.
- **Phase 1 runs both subagents async and concurrently.** Do not await one before launching the other.
- **Phase 3 runs in a fresh subagent** — never in the conductor's own context.

## Phase 1a — Adversarial review loop

```js
subagent({
  agent: "adversarial-review-loop-agent",
  async: true,
  task: `Run the adversarial-review-loop against the code changes in <branch-or-diff>.

Repo root: <absolute-path>
Diff: <path-or-branch> (at commit <sha>, not the drifted working tree — use git show <sha>:<path> if needed)
PR description: <inline-or-path>

Treat the code changes as the artifact under review. Focus on correctness defects,
missing test coverage for new behaviour, and unsafe assumptions.

Return a structured findings list with severity signals (blocker / major / minor / weak).`,
  output: "~/.ai/wip/review-pipeline-<YYYY-MM-DD>-adversarial-output.md",
  outputMode: "file-only"
})
```

## Phase 1b — Mihai-style code review

```js
subagent({
  agent: "mihai-code-review-agent",
  async: true,
  task: `Review the code changes in <branch-or-diff> using the mihai-code-review skill.

Repo root: <absolute-path>
Diff: <path-or-branch> (same commit as Phase 1a)
PR description: <inline-or-path>

Run all three passes in order: mechanical sweeps → precedent diff → adversarial hunt.
Return: verdict, summary, line comments, and sweep log appendix.`,
  output: "~/.ai/wip/review-pipeline-<YYYY-MM-DD>-mihai-output.md",
  outputMode: "file-only"
})
```

## Phase 2 — Merge (conductor, not a subagent)

Read both output files. Apply the skill's merge rules. Write to:

```
~/.ai/wip/review-pipeline-<YYYY-MM-DD>-merged-draft.md
```

## Phase 3 — Shape comments

```js
subagent({
  agent: "shape-review-comments-agent",
  task: `Shape the raw merged review findings at ~/.ai/wip/review-pipeline-<YYYY-MM-DD>-merged-draft.md
into postable comments.

Repo root: <absolute-path>
HEAD commit / branch: <ref>

Follow the shape-review-comments skill exactly. Present the shaped comments to the user
and wait for their approval before doing anything else.`,
})
```
