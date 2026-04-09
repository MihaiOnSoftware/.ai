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
