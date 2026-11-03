# Red Flags in Plans

## Too Large
"Implement complete schema hash calculation" - This is the whole project, not a slice.

## Not Testable
"Add infrastructure" - How do you know it works? What specific tests?

## Unordered Dependencies
Slice 3: "Add recursion"
Slice 4: "Handle direct children"

Wrong order - can't recurse before handling direct children.

## Vague Requirements
"Make it work in development" - What does "work" mean? Be specific: "Hash recalculates on code reload"

## Multiple Concepts
"Add recursion and handle sealed subclasses" - Split into two slices.

## Half-Moved Seam
A PR bundle ending with `coverage.ts` kept only as a formatter awaiting its rename, or `entityViolations.ts` left as a conversion-only residual. The reviewer needs the next PR to understand this one. Move the seam.

## Late Closing Items
"Do the PR admin once the PRs are up." Every bundle above the one you touch then needs a restack. Put the chore in the bundle's last slice.

## Layer Cut
Slice 1 "schema", Slice 2 "mutation", Slice 3 "handler, the first slice a client can observe". Every slice is green and nothing works until the last one. See [../examples/layer-cut-vs-vertical.md](../examples/layer-cut-vs-vertical.md).
