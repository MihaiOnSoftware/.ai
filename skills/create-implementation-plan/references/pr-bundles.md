# PR Bundles

A **bundle** is an ordered, consecutive run of slices that becomes exactly one PR on its own branch. The **stack** is the ordered list of bundles: bundle 1 sits on the base the user supplied (the default branch, or another ticket's branch), bundle N+1 sits on bundle N's branch. A plan with no admissible seam is one bundle; a stack of one is a valid outcome once the candidate stack below has been tried and rejected.

## Seam admissibility

A seam after slice k is admissible when the tree at slice k's last commit:

1. **Stands alone green, and better than the base**: passes the bundle's tip gate against its base with nothing from later bundles, and leaves the system better than it was for the cases the task is about. It does not have to be complete. Walking-skeleton style: a bundle that fixes the common path and leaves an edge case for the bundle above is admissible, as long as the gap is named in the plan and that next bundle closes it. Judge a seam by "better than before", not by "as good as the finished design"; the design's rejection of a partial state as the final state is not a rejection of it as an interim one.
2. **Leaves nothing half-moved by the end of the stack**: at the top bundle, no module kept only as temporary scaffolding or a conversion-only residual, no owner under a stale name whose rename is pending, no forwarding shim. Within the stack, interim shapes are fine: a bundle may ship a fail-fast version of a function the next bundle makes attempt-all, or a module the next bundle renames, as long as the bundle is green, has no dangling import, and its reviewer can see what it does without opening the next PR. A contract the next bundle extends is not half-moved.
3. **Has one reason to exist**: the headline is one sentence a reviewer can verify, and it maps to a design section or a known reviewer concern. Keep a behaviour change out of a bundle that is mostly moves; isolate it in its own bundle.
4. **Is worth a review, and about the same size as its neighbours**: each bundle costs a CI run, an approval, and a restack whenever anything below it changes. Size is the number of tests the bundle's slices write or change (their "Tests to Write" lists), not lines of code; do not estimate code. Bundles of similar test counts are the target. One with a fraction of its neighbours' tests is not earning its approval, merge it; one with several times theirs is hiding a seam, look again.
5. **Depends only downward**: bundle N+1 may build on bundles ≤ N; nothing in bundle N needs bundle N+1 to be correct.

Stack order is plan order. Do not reorder slices to create parallel seams; that produces trees nobody validated.

The slice rule and the bundle rule differ. A producer with no consumer is a layer, not a slice (Principle 3), because nothing observable works after it. A bundle that ends on a producer the next bundle consumes is a normal seam: the reviewer of PR1 sees a complete, tested client or module with one reason to exist, and PR2 sits right above it. "No caller yet" rejects a slice; on its own it does not reject a seam. Likewise "the design chose a stronger guarantee" rejects a final state, not a seam: a bundle that stops recipes before deleting but does not yet verify they stopped is a seam when the verification is the next bundle.

## Candidate stack

Before settling on the bundle count, name the best cut with two or more bundles and score each of its seams against the five tests above. Keep it when every seam passes. When one fails, say which test and why, then try the next best cut. Land on one bundle only after the best candidate has been written down and rejected on a named test; "one bundle" is a conclusion the plan shows, not a default it starts from. Record the candidate and its verdict under the PR stack table.

## Closing items

Any administrative work PRs in this repo require (e.g. changelogs, CODEOWNERS, docs, regenerated files). They are **chore items in the bundle's last slice**, never a post-pipeline step. Adding them after the branches exist forces a restack of every bundle above.

## What the plan records

The written plan opens with a **PR stack** table (filled in once the slices are settled; interactive: proposed after the last slice is approved):

| Column | Content |
|---|---|
| Bundle | `PR1`, `PR2`, … in stack order |
| Headline | one sentence; the PR title candidate |
| Branch | the branch name the implementer will create |
| Base | the user-supplied base for PR1 (branch and SHA); `PR(N-1) branch` otherwise |
| Slices | the consecutive slice numbers |
| Stands alone because | the admissibility argument for this tip |
| Tip gate | checks beyond the slice gate: full build and tests for the touched workspaces, lockfile immutability, parity oracles, whatever PR-level checks the repo enforces. The last bundle's tip gate covers the union of every bundle's touched workspaces and their consumers |
| Closing items | the administrative work the last slice carries |

Under the table, the **slice gate** every slice must pass (the repo's typecheck, lint and tests for the touched workspaces unless the plan says otherwise) and the **base SHA** the plan was written against.

Each slice header gets one line: `**Bundle:** PR2 (first | middle | last | only)`.

## Example (extracting an engine into its own package: 16 slices, 3 bundles)

| Bundle | Headline | Branch | Base | Slices | Stands alone because | Tip gate | Closing items |
|---|---|---|---|---|---|---|---|
| PR1 | Scaffold the package and move the shared utilities | `extract-engine-scaffold` | `main` @ `<sha>` | 1–3 | the package builds and its tests pass alone; the app imports the moved utilities; output is byte-identical | package build and tests, app typecheck, lockfile check | repo admin for a new package (slice 3) |
| PR2 | Move the leaf modules into the package | `extract-engine-leaves` | PR1 branch | 4–9 | every moved module's importers are migrated; the core still in the app imports the package, a legal direction | PR1's gate plus the app's full test suite | repo admin (slice 9) |
| PR3 | Move the core and keep the app as a thin consumer | `extract-engine-core` | PR2 branch | 10–16 | final package inventory; end-to-end output parity | cumulative: every gate above, both workspaces, full parity | repo admin (slice 16) |

No seam inside PR2 earns its own review: each slice is one leaf move, and six PRs of leaf moves would be six approvals for one idea.
