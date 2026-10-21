# Phase dispatch recipes

Concrete `subagent({...})` call shapes for each phase. The conductor dispatches; the subagent owns its phase end-to-end.

`<slug>` is the run slug from pre-flight (branch name or PR number). All paths are absolute; expand `~` before passing.

## Shared conventions

- **Use the dedicated phase agent** for each phase. Each agent wraps its skill, pins its model, and carries the right tool set.
- **No `context:` override needed.** User agents default to fresh context.
- **Phase 1 runs both subagents async and concurrently.** Do not await one before launching the other.
- **Phase 3 runs in a fresh subagent** — never in the conductor's own context.
- **Leaf agents have no user channel.** Never write "ask the user" or "present to the user" into a leaf task; they return output to you, and you talk to the user.

## Phase 1a — Adversarial review loop

```js
subagent({
  agent: "adversarial-review-loop-agent",
  async: true,
  task: `Run the adversarial-review-loop against the code changes in <branch-or-diff>.

Repo root: <absolute-path>
Diff: <path-or-branch> at commit <head-sha> (not the drifted working tree — use git show <head-sha>:<path> and git grep <pattern> <head-sha> if needed)
PR description: <resolved-text-or-path>

FINDINGS-ONLY MODE: the artifact under review is someone else's code. Do NOT edit or
write any file in the repo. Where your skill says "apply accepted fixes in place",
instead record the accepted finding in your report and move on. Nothing changes
between rounds, so expect the loop to terminate via "repeated findings" — that is
the normal exit here, not a failure.

Focus on correctness defects, missing test coverage for new behaviour, and unsafe
assumptions. Label each finding nit / minor / major / question.

Return your full findings report as your output.`,
  output: "<home>/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-adversarial-output.md",
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
Diff: <path-or-branch> at commit <head-sha> (same commit as the parallel reviewer)
PR description: <resolved-text-or-path>

Run all three passes in order: mechanical sweeps → precedent diff → adversarial hunt.
Return as your output: verdict, summary, line comments, and sweep log appendix.`,
  output: "<home>/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-mihai-output.md",
  outputMode: "file-only"
})
```

## Phase 2 — Merge (conductor, not a subagent)

Read both output files. Apply the skill's merge rules. Write to:

```
~/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-merged-draft.md
```

## Phase 3 — Shape comments

```js
subagent({
  agent: "shape-review-comments-agent",
  task: `Shape the raw merged review findings at <home>/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-merged-draft.md
into postable comments.

Repo root: <absolute-path>
Head commit: <head-sha> (branch <branch>)
PR: <pr-url-or-org/repo#number> — use this to build GitHub links for cross-file references.

Follow the shape-review-comments skill. You have no user channel: where the skill
says "present for approval", return the shaped comments AND the triage log as your
output instead. Do not post anything.`,
  output: "<home>/.ai/wip/review-pipeline-<slug>-<YYYY-MM-DD>-shaped-comments.md",
  outputMode: "file-only"
})
```

After it returns, read the shaped-comments file and present it to the user at the checkpoint.
