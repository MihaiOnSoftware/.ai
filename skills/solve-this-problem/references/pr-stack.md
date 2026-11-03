# PR stack mechanics

How the conductor tracks bundles, handles a restack, and opens the stack. Every SHA below comes from the plan or a specialist's summary; every git or remote operation is a dispatch. The stack itself is managed with `gh stack` (GitHub's CLI extension, `github/gh-stack`): `commit-agent` runs the local commands (see the `commit` skill's orchestrator table), the PR-submission specialist runs the remote ones.

Prerequisites, checked once before Phase 5 by dispatching `commit-agent` "report `gh stack --version` and `gh stack view --json`": the extension is installed, Git is 2.36+, and `remote.pushDefault` is set when the repo has several remotes. `gh stack submit` also needs Stacked PRs enabled on the GitHub repository (it exits 9 otherwise); the fallback is under Phase 6.

## Tracking

The pipeline state file carries a **PR stack** table (template in `pipeline-state.md`) with one row per bundle: branch, base branch, base tip, validated tip, tip gate result, PR URL, remote head, check status. Keep it current:

- **Base tip of PR1** starts as the plan's base SHA (`current base tip`).
- **Pre-slice SHA** for slice N is the previous slice's tip from its `tdd-slice` summary, or the base tip for the first slice.
- **Validated tip** of a bundle is the slice tip of its last slice once that slice's boundary validation (slice gate + tip gate) passed.
- The next bundle's first slice spec names the previous bundle's validated tip as its `Expected tip`. Never start a bundle on a failed tip.
- After any `restack` or `submit`, refresh branch heads and base SHAs from the `gh stack view --json` the specialist returns (`branches[].head`, `branches[].base`, `branches[].pr`).

## Slice spec: the Bundle section

When extracting slice N from the plan, fill in:

```
## Bundle
- Bundle: <id> "<headline>"
- Branch: <branch from the PR stack table>
- Base: <the user-supplied base branch for PR1; the previous bundle's branch otherwise>
- Expected tip: <pre-slice SHA>
- Position: first | middle | last | only
- Slice gate: <from the plan, or "default">
- Tip gate: <from the plan; only when Position is last or only>
```

`tdd-slice` turns this into the `prepare branch` dispatch: `gh stack init` for PR1 (with `--base` when the base is not the default branch), `gh stack add` for each later bundle, `gh stack checkout` for an existing branch.

## Re-run slice N

Slice N already produced micro commits, so before re-dispatching `tdd-slice`:

1. Confirm with the user that the working tree is clean; a hard reset discards uncommitted changes.
2. Verify from the wip file that the only commits since the pre-slice SHA are slice N's. If later slices have also been committed, a reset to the pre-slice SHA erases them too: either confirm with the user that those slices are invalidated and reset further back, or abort the re-run.
3. Record the commits about to be discarded (SHAs + summaries) under "Abandoned commits" in the wip file.
4. Dispatch `commit-agent`: "reset `--hard` from `<slice N tip>` to `<pre-slice SHA>`". A refusal means HEAD is not where the wip file says; surface it.
5. Reset the slice row to `pending` and clear its commit list; the new run replaces it.

## A later slice needs a change in an earlier bundle K

Ask: would a reviewer of bundle K, reading it alone, call the missing change a defect?

- **No**: it belongs to the current bundle. Add it there; no restack.
- **Yes**: it belongs to K. Surface a plan amendment at the checkpoint: a **repair slice** appended to K (its `## Bundle` says branch K, `Expected tip` = K's validated tip, Position `last`, with K's tip gate). `prepare branch` checks K out; the repair commits land on K. After its boundary validation passes, restack.

## Restack

1. Dispatch `commit-agent`: "restack above `<K branch>` at `<K's new tip>`". It runs `gh stack rebase --upstack --no-trunk`, which replays every bundle above K onto the change, and returns `gh stack view --json`. On a conflict it aborts, restores every branch, and returns the conflicting files: pause, hand the user the conflict list, and resume when they confirm the stack is rebased (`gh stack view --json` shows no `needsRebase`).
2. Record each bundle's new head from the view JSON; keep the old tips in the row as `(was <sha>)`. Mark every slice row in the rewritten bundles `rewritten`: their SHAs are no longer on the live branches, "Re-run slice N" is only available from here forward, and a defect in a rewritten slice is a repair slice, never a reset.
3. Set the next slice's pre-slice SHA to the current bundle's new tip.
4. Re-run the tip gate of each rewritten bundle, bottom-up: `commit-agent` "prepare branch `<bundle branch>` at `<new tip>`" (a `gh stack checkout`), then `tdd-validation-agent` with the boundary-validation prompt from `tdd-slice` (expected HEAD = new tip, slice gate "none", the bundle's tip gate).
5. Republish every already-published bundle whose tip changed before publishing anything above it (Phase 6; `gh stack submit` pushes every branch at once). A published bundle whose remote head differs from its validated tip is `stale` and blocks completion.

**Base drift** (the upstream branch PR1 sits on was rebased): the PR-submission specialist runs `gh stack sync`, which fetches, fast-forwards the trunk, cascade-rebases and pushes; on a conflict it restores everything and exits 3, and the conductor pauses as above. When the upstream branch itself has merged, the stack needs re-rooting on the default branch: `gh stack unstack --local` then `gh stack init <PR1 branch> <PR2 branch> …` (existing branches are adopted) and `gh stack sync`; update PR1's base in the table. Recapture any gate baseline (parity oracle) at the new base before tip gates re-run.

## Phase 6: open the stack

Precondition: the harness has a **PR-submission specialist** that runs `gh stack` against the remote. Without one, write the recipe below into the final summary, end at "stack ready to open", and open nothing.

One dispatch publishes or refreshes the whole stack (there is no per-bundle submit):

- **Input**: the PR stack table (bundle, branch, headline, body inputs: headline, slice list, "stands alone because", tip-gate evidence, stack position), the validated tip per bundle.
- **It does**: `gh stack submit --auto` (one atomic force-with-lease push of every branch, then a draft PR per branch that lacks one, each based on the branch below, linked as a GitHub stack); then `gh pr edit <number> --title … --body …` per bundle, since `--auto` titles come from the commit subject or branch name; triggers the repo's review bot; waits for checks to settle. **Exit 9** (Stacked PRs not enabled on the repository): `gh stack push`, then `gh pr create --draft --head <branch> --base <base branch>` per bundle bottom-up with the same titles and bodies.
- **It returns**: `gh stack view --json` (per branch: `head`, `base`, `pr.number`, `pr.url`, `needsRebase`) plus check status per PR.
- **Accept** only when every `head` equals its bundle's validated tip, every `base` is the predecessor's validated tip (`current base tip` for PR1), and no branch `needsRebase`. Anything else is base drift or a stale push: go to Restack, never record it as published.
- **Check status**: `green`; `red` with the failing checks (a checkpoint: repair slice in the bundle a reviewer would blame, then restack and republish, or pause); `waiting on <manual gate>` for approval-only checks only a human can clear (listed as human steps in the final summary).

**Timing** is a checkpoint option when a bundle closes: submit now (default; per-PR checks appear while the bundle is the current context; `submit` is idempotent, later bundles are added to the same stack) or submit once at the end.

**Final refresh**: before declaring completion, have the specialist return a fresh `gh stack view --json` and check status, and re-apply the acceptance rule.

**Complete** when, after the refresh, every bundle has a draft URL, head = validated tip, base matches, nothing `needsRebase`, and no `red` checks. The final summary lists the stack in merge order and the merge cascade: merge bottom-up (`gh stack merge <PR> --yes --squash` merges that PR and everything below it; or the repo's merge queue), then `gh stack sync` to rebase the remaining bundles onto the merged result and push (a squash-merged parent is replayed with `--onto` automatically), re-run tip gates, mark the next PR ready.

The conductor never pushes, opens, marks ready, requests reviewers, merges, retargets, or rebases.
