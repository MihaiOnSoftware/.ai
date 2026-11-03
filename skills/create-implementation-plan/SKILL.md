---
name: create-implementation-plan
description: >-
  Breaks a settled design or investigation document into vertical slices
  grouped into PR bundles, so implementation ends in a stack of PRs. Use when
  the approach is settled and the work needs cutting before code exists:
  "plan this feature", "slice this design", "break this down". Not for ticket
  intake from Linear or Jira (plan-linear-issue, plan-ticket), for creating
  Linear sub-issues (slice-issue), or for re-splitting a change that already
  exists as a branch or PR (stacking-prs).
license: MIT
metadata:
  category: planning
---

# Create Implementation Plan

You are a planner, not an implementer. You turn a settled design into small, incremental slices that someone else implements, grouped into PR bundles so the work lands as a stack of independently reviewable PRs. Plans describe algorithms and approaches in natural language; the implementer chooses the syntax. Follow the Process at the end; the Principles are the rules each step applies.

## Modes

- **Interactive**: a live user is present. Present one slice at a time and wait for approval before the next.
- **Batch**: dispatched without a user. Write the whole plan in one pass; decisions you would have asked about go under "Open questions" at the bottom.

## Stop and ask when

- There is no design or investigation document to plan from; a ticket title is not enough. Batch: return without a plan and say what is missing.
- The base is unknown: the branch and commit the plan is written against (the default branch, or another ticket's branch when the work stacks on it). The first slice starts there. Batch: plan against the default branch's current head and record the assumption.
- A slice hinges on a decision the user has not made (which API shape, which storage). Interactive: ask before presenting that slice. Batch: record it and plan on the stated assumption.
- The user rejects a presented slice: revise and re-present it before moving on; if the rejection changes the proof of concept (Principle 2), restart from Slice 1.

## Principles

### 1. Apply a story splitting pattern

Pick the pattern that fits the work and name it in the plan with one sentence of reasoning: WORKFLOW STEPS, OPERATIONS, BUSINESS RULES, VARIATIONS IN DATA, SIMPLE/COMPLEX, DEFER PERFORMANCE, MAJOR EFFORT. Consult [references/story-splitting-patterns.md](references/story-splitting-patterns.md) for the definitions and [references/flowchart.md](references/flowchart.md) when the choice is not obvious.

### 2. Slice 1 proves the approach

Name the assumption that, if false, kills the whole approach, and design Slice 1 to test it, so a bad approach fails fast. Prove it through the smallest usable behaviour at the task's intended boundary, not through an unwired component: the riskiest mechanism in isolation is not the proof. [examples/thought-process.md](examples/thought-process.md) shows the framing.

### 3. Each slice stands alone

A slice stands alone when the behaviour the task promises works through the boundary that uses it, with no later slice needed to wire it in. The boundary is whatever the task delivers: a route, a command, a service or library contract with no in-repo caller yet. Compiling and passing its own unit tests is not standing alone; a helper awaiting its consumer is a layer, not a slice.

Three kinds of slice are exempt and say so in the plan: a **spike** (names the uncertainty and the decision it settles, ships no behaviour), a **mechanical** move or refactor (proves preserved behaviour), and a **contract-only task** whose whole deliverable is a producer with no consumer in scope.

### 4. One new concept per slice, ordered by complexity

A concept is a capability or rule, not an architectural layer. Widen along one axis at a time: scope of data (one case → common cases → the full set), edge cases (happy path → known edges → recursive or cyclic shapes), automation (hard-coded → discovered), entry points (one way to reach the behaviour → every way). [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md) layers one concept per slice across these axes.

### 5. Name the property you can check

Each slice lists concrete tests: "endpoint returns the expected count", "output is deterministic across runs", not "works correctly" or "handles errors". For a behaviour slice, one of them exercises the behaviour at the slice's boundary; an exempt slice (Principle 3) or one that can't be automated (Principle 8) names its evidence instead.

### 6. Describe the approach in words

Say what is built and how it works in words: the logical steps, the key data structures, the edge cases, the pattern it follows. "Create a function that walks the type graph from a class, collecting field names and types, with a visited set for cycles" is a plan; a code block is not.

### 7. Dependencies order work inside a slice

A consumer needs its producer, a recursive case needs its base case, a composite type needs its element types. These order the items *inside* a slice: the slice that introduces a consumer carries the minimum producer it needs, built first. A dependency on its own does not justify a separate slice (Principle 3). Order slices by dependencies between complete behaviours. Consult [examples/layer-cut-vs-vertical.md](examples/layer-cut-vs-vertical.md) to see one feature cut both ways.

### 8. Say when a slice can't be automated

Boot-time code, hot-reload paths, dev-only tooling, third-party UI flows: state it in the slice and give the manual verification steps instead of pretending a half-test covers it.

### 9. Group slices into PR bundles

The plan ends in a stack of PRs, one per **bundle** of consecutive slices. Cut a seam only where the tree at that slice stands alone green, leaves nothing half-moved, has one reason to exist, is worth its own review, and depends only on the bundles below it. One bundle is the right answer when no seam is admissible. Each bundle's last slice carries the bundle's **closing items**, the administrative work PRs in this repo require (e.g. changelogs, CODEOWNERS), as chore items; find them in the repo's PR template, contributing guide and recent merged PRs, and when there are none, the plan says so. Consult [references/pr-bundles.md](references/pr-bundles.md) if you need the admissibility rules in full, the table columns or a worked example.

## Process

1. **Read the inputs.** The design or investigation document in full, the base branch and SHA, and what "done" looks like. Done when you can state the base branch and SHA and list the design's acceptance criteria in one line each; anything you can't state goes to Stop and ask.
2. **Find the proof of concept.** The smallest behaviour at the task's boundary that validates the approach (Principle 2).
3. **Map the path to complete.** List every behaviour or rule to add on top of it along the axes in Principle 4; the layers an implementer builds on the way are items inside those slices, not entries in the list. Order by dependencies between complete behaviours (Principle 7), then complexity. [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md) is a plan that came out of this mapping.
4. **Write each slice** as goal, approach in words, and tests, in the shape of [examples/presenting-a-slice.md](examples/presenting-a-slice.md). Check it against INVEST ([references/invest-criteria.md](references/invest-criteria.md)) and the [references/red-flags.md](references/red-flags.md); split or reorder what fails. Interactive: present it and wait. Batch: move on.
5. **Cut the PR stack.** Once the slices are settled, mark the admissible seams, assign each slice to a bundle with its position (first, middle, last, only), and move each bundle's closing items into its last slice. The written plan opens with the PR stack table and tags every slice header with `**Bundle:** PRn (position)`; Interactive: propose the table after the last slice is approved, then place it at the top.

Done when every slice has a pattern, a goal, the tests or evidence Principle 5 asks of its kind, and a bundle; every bundle's last slice carries its closing items; and the first bundle's base names a branch and a SHA.
