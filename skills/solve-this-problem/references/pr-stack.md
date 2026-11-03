# PR stack mechanics

How the conductor tracks bundles, handles a restack, and opens the stack. Every SHA below comes from the plan or a specialist's summary; every git or remote operation is a dispatch or a recipe handed to the user.

## Tracking

The pipeline state file carries a **PR stack** table (template in `pipeline-state.md`) with one row per bundle: branch, base branch, base tip, validated tip, tip gate result, PR URL, remote head, check status. Keep it current:

- **Base tip of PR1** starts as the plan's base SHA (`current base tip`). It advances only after a base restack.
- **Pre-slice SHA** for slice N is the previous slice's tip from its `tdd-slice` summary, or the base tip for the first slice.
- **Validated tip** of a bundle is the slice tip of its last slice once that slice's boundary validation (slice gate + tip gate) passed.
- The next bundle's first slice spec names the previous bundle's validated tip as its `Expected tip`. Never start a bundle on a failed tip.

## Slice spec: the Bundle section

When extracting slice N from the plan, fill in:

```
## Bundle
- Bundle: <id> "<headline>"
- Branch: <branch from the PR stack table>
- Expected tip: <pre-slice SHA>
- Position: first | middle | last | only
- Slice gate: <from the plan, or "default">
- Tip gate: <from the plan; only when Position is last or only>
```

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
- **Yes**: it belongs to K. Surface a plan amendment at the checkpoint: a **repair slice** appended to K (its `## Bundle` says branch K, `Expected tip` = K's validated tip, Position `last`, with K's tip gate). After it passes, every bundle above K must be restacked.

## Restack (pause, hand over the recipe, resume)

Rewriting history is outside the conductor's reach. Pause the pipeline and give the user the exact recipe, bottom-up, each bundle onto its **immediate predecessor's** new tip:

```
git rebase --onto <new tip of K>   <old tip of K>   <branch K+1>
git rebase --onto <new tip of K+1> <old tip of K+1> <branch K+2>
…
```

Using K's pair for every bundle would replay K+1's commits into K+2 and break the ancestry. For **base drift** (the upstream branch was rebased, or a dependency squash-merged) the first line uses the base: `--onto <new base tip> <current base tip> <branch PR1>`; then advance `current base tip`, and if the base was merged, PR1's base branch becomes the default branch in the table. Recapture any gate baseline (parity oracle) at the new base.

On resume, from the user's new tips:

1. Record new tips per bundle; keep the old ones in the row for forensics.
2. Mark every slice row in the rewritten bundles `rewritten`. Their SHAs are no longer on the live branches; "Re-run slice N" is only available for slices after this point. A defect in a rewritten slice is a repair slice, never a reset.
3. Set the next slice's pre-slice SHA to the current bundle's new tip.
4. Re-run the tip gate of each rewritten bundle, bottom-up: dispatch `commit-agent` "prepare branch `<bundle branch>` at `<new tip>`", then `tdd-validation-agent` with the boundary-validation prompt from `tdd-slice` (expected HEAD = new tip, slice gate "none", the bundle's tip gate). Only one branch can be checked out at a time, so the prepare step is what makes each gate run against the right tree.
5. Republish every already-published bundle whose tip changed (below) before publishing anything above it. A published bundle whose remote head differs from its validated tip is `stale` and blocks completion.

## Phase 6: open the stack

Precondition: the harness has a **PR-submission specialist** that implements this contract. If it does not, write the per-bundle recipe (push, `gh pr create --draft --head <branch> --base <base>`, title, body) into the final summary, end at "stack ready to open", and open nothing.

Per bundle, bottom-up, so each base branch exists on the remote before the next PR points at it:

- **Input**: head branch, expected head SHA, base branch, title (the bundle headline), body inputs: headline, slice list, "stands alone because", tip-gate evidence, stack position ("PR 2 of 3, base is PR1; merge bottom-up"). Draft.
- **It does**: pushes the named head (`--force-with-lease` when the remote differs), opens the draft with `--base`, or updates the existing PR for that head; triggers the repo's review bot; waits for checks to settle.
- **It returns**: PR URL, remote head SHA, base branch and base SHA as the remote reports them, check status.
- **Accept** only when remote head = validated tip, base branch = plan, base SHA = `current base tip` (PR1) or the predecessor's validated tip. A base SHA mismatch is base drift: go to Restack.
- **Check status**: `green`; `red` with the failing checks (a checkpoint: repair slice in the bundle a reviewer would blame, then restack and republish above, or pause); `waiting on <manual gate>` for approval-only checks only a human can clear (listed as human steps in the final summary).

**Timing** is a checkpoint option when a bundle closes: open its draft now (default; per-PR checks appear while the bundle is the current context) or open everything at the end.

**Final refresh**: before declaring completion, have the specialist re-read every PR (head, base branch, base SHA, checks) and re-apply the acceptance rule to all of them; a PR published early may have had its base move since.

**Complete** when, after the refresh, every bundle has a draft URL, remote head = validated tip, base SHA matches, and no `red` checks. The final summary lists the stack in merge order and the merge cascade: after bundle J squash-merges, restack **every** remaining bundle predecessor-by-predecessor (`--onto origin/<default> <old tip of J> <branch J+1>`, then `--onto <new tip of J+1> <old tip of J+1> <branch J+2>`, …), re-run tip gates, force-push with lease, confirm each base with `gh pr view`.

The conductor never pushes, opens, marks ready, requests reviewers, merges, retargets, or rebases.
