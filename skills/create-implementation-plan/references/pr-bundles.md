# PR Bundles

A **bundle** is an ordered, consecutive run of slices that becomes exactly one PR on its own branch. The **stack** is the ordered list of bundles: bundle 1 sits on the base the user supplied (the default branch, or another ticket's branch), bundle N+1 sits on bundle N's branch. A plan with no admissible seam is one bundle; a stack of one is a valid outcome. Never force a seam.

## Seam admissibility

A seam after slice k is admissible when the tree at slice k's last commit:

1. **Stands alone green**: passes the bundle's tip gate against its base with nothing from later bundles.
2. **Leaves nothing half-moved**: no module kept only as temporary scaffolding or a conversion-only residual, no owner under a stale name whose rename is pending, no dangling import. A reviewer must not have to read the next PR to understand why a file exists.
3. **Has one reason to exist**: the headline is one sentence a reviewer can verify, and it maps to a design section or a known reviewer concern. Keep a behaviour change out of a bundle that is mostly moves; isolate it in its own bundle.
4. **Is worth a review**: each bundle costs a CI run, an approval, and a restack whenever anything below it changes. Pure moves (renames, spec relocation) weigh less than logic when judging size. If a bundle would not earn its approval, merge it into a neighbour.
5. **Depends only downward**: bundle N+1 may build on bundles ≤ N; nothing in bundle N needs bundle N+1 to be correct.

Stack order is plan order. Do not reorder slices to create parallel seams; that produces trees nobody validated.

## Closing items

Any administrative work PRs in this repo require (e.g. changelogs, CODEOWNERS, docs, regenerated files). They are **chore items in the bundle's last slice**, never a post-pipeline step. Adding them after the branches exist forces a restack of every bundle above.

## What the plan records

Before the slices, a **PR stack** table:

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
