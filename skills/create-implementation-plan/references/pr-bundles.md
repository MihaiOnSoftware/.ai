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

The artifacts a PR needs to be mergeable on its own: changelog entry, CODEOWNERS line, docs, regenerated files. They are **chore items in the bundle's last slice**, never a post-pipeline step. Adding them after the branches exist forces a restack of every bundle above.

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
| Tip gate | checks beyond the slice gate: full build and tests for the touched workspaces, lockfile immutability, parity oracles, changelog or docs checks the repo enforces. The last bundle's tip gate covers the union of every bundle's touched workspaces and their consumers |
| Closing items | which chores the last slice carries |

Under the table, the **slice gate** every slice must pass (the repo's typecheck, lint and tests for the touched workspaces unless the plan says otherwise) and the **base SHA** the plan was written against.

Each slice header gets one line: `**Bundle:** PR2 (first | middle | last | only)`.

## Example (API-911, 16 slices, 3 bundles)

| Bundle | Headline | Branch | Base | Slices | Stands alone because | Tip gate | Closing items |
|---|---|---|---|---|---|---|---|
| PR1 | Scaffold the coverage package and move the shared reconciler utilities | `api-911-extract-rest-graphql-coverage-engine` | API-910 stack top `9b83f93b` | 1–3 | package builds and tests alone; backend-rest imports the moved utilities; byte-identical report | standard gate, charter grep, `yarn install --immutable` | changelog (slice 3) |
| PR2 | Move the engine leaf modules and comparators into the package | `api-911-pr2-engine-leaves` | PR1 branch | 4–9 | every moved module's importers are migrated; report builder still in backend-rest imports the package, a legal direction | standard gate, charter grep, `yarn install --immutable`, design-writer parity | changelog (slice 9) |
| PR3 | Move the report builder, regeneration and formatter; backend-rest keeps consumer wiring | `api-911-pr3-engine-core` | PR2 branch | 10–16 | final package inventory; end-to-end byte parity | cumulative: all gates, both workspaces, full parity | changelog (slice 16) |

In the real run the changelog entries were added after all three branches existed, which forced one new commit on PR1 and a restack of PR2 and PR3. With the chores in slices 3, 9 and 16 that restack does not happen.
