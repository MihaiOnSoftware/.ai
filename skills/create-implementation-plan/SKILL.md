---
name: create-implementation-plan
description: >-
  Breaks a settled design or investigation document into vertical slices
  grouped into PR bundles, so implementation ends in a stack of PRs. Use when
  the approach is settled and the work needs cutting before code exists:
  "plan this feature", "turn this design into slices", "what are the PRs for
  this". Not for ticket
  intake from Linear or Jira (plan-linear-issue, plan-ticket), for creating
  Linear sub-issues (slice-issue), or for re-splitting a change that already
  exists as a branch or PR (stacking-prs).
metadata:
  category: planning
---

# Create Implementation Plan

Someone else implements the slices you write; the plan has to carry everything they need.

## Modes

- **Interactive**: a live user is present. Present one slice at a time in the conversation and wait for approval before the next; once the stack table is approved, write the assembled plan to the path the user names and report it.
- **Batch**: dispatched without a user. Write the whole plan in one pass to the path the caller names and return that path; decisions you would have asked about go under "Open questions" at the bottom.

## Stop and ask when

- There is no design or investigation document to plan from, or the document states no outcome to plan toward; a ticket title is not enough. Batch: return without a plan and say what is missing.
- The base is unknown: the branch and commit the plan is written against (the default branch, or another ticket's branch when the work stacks on it). The first slice starts there. Batch: use the named branch's current head as the SHA and record it as an assumption; when no base is named, use the default branch's head; when the named branch cannot be resolved, return without a plan and name it.
- A slice hinges on a decision the user has not made (which API shape, which storage). Interactive: ask before presenting that slice. Batch: record it and plan on the stated assumption.
- The user rejects a presented slice: revise and re-present it before moving on; if the rejection changes the proof slice (Principle 2), restart from it.

## Process

1. **Read the inputs.** The design or investigation document in full, the base, and what "done" looks like. Done when:
   - the base branch and SHA are stated;
   - the acceptance criteria are listed one line each, taken from the document's Problem, Design and Scope sections, or from whichever section states the intended outcome (for an investigation, what it recommends building);
   - in Batch, the derived criteria and any assumed SHA are recorded as assumptions.
2. **Find the proof slice** (Principle 2). Done when the killing assumption, the boundary behaviour that exercises it and, when a spike comes first, the decision the spike settles are written down.
3. **Map the path to the acceptance criteria.** List the spike when there is one, the proof slice, and every behaviour, rule or mechanical change to add after it along the axes in Principle 4, applying Principle 3 to each entry. Order by dependencies between standalone behaviours (Principle 7), then complexity. Done when every acceptance criterion from step 1 maps to at least one entry and the plan names its splitting pattern (Principle 1); a design the proof slice satisfies on its own needs no further entries. [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md) is a plan that came out of this mapping.
4. **Write each slice** as goal, approach in words, and tests, in the shape of [examples/presenting-a-slice.md](examples/presenting-a-slice.md). Check it against INVEST ([references/invest-criteria.md](references/invest-criteria.md), with Principle 3's exemptions) and the [references/red-flags.md](references/red-flags.md); split or reorder what fails. Done when the slice passes INVEST, trips no red flag, and lists its goal, approach in words, and the tests or evidence Principle 5 asks of its kind. Interactive: present it and wait. Batch: move on.
5. **Cut the PR stack** (Principle 9).
   1. Name the best cut with two or more bundles.
   2. Test each of its seams against the admissibility list in Principle 9; move or drop a seam that fails, and settle on one bundle only after the candidate has failed a named test.
   3. Add each bundle's closing items to its last slice.
   4. Write the PR stack table at the top of the plan and tag every slice header with `**Bundle:** PRn (position)`.

   Interactive: propose the table after the last slice is approved, then place it at the top. Done when the candidate stack is written down with its verdict, each rejected seam names the test it fails, and each bundle names its base.

## Principles

### 1. Apply a story splitting pattern

Pick the pattern that fits the work and name it in the plan with one sentence of reasoning: WORKFLOW STEPS, OPERATIONS, BUSINESS RULES, VARIATIONS IN DATA, SIMPLE/COMPLEX, DEFER PERFORMANCE, MAJOR EFFORT. Consult [references/story-splitting-patterns.md](references/story-splitting-patterns.md) for the definitions and [references/flowchart.md](references/flowchart.md) when the choice is not obvious.

### 2. The proof slice

The first behaviour slice is the proof slice. Name the assumption that, if false, kills the whole approach, then pick something stupid: the most embarrassingly thin behaviour at the task's boundary that still exercises that assumption end to end. Start there and let later slices make it less stupid. A guard, a filter, a fallback, a result type or an edge case belongs in the proof slice only when the assumption cannot be exercised without it; "the feature would be incorrect without it" is the reason for a later slice, not for a fatter first one. The proof runs through the boundary, not through an unwired component. When the assumption needs a spike before any behaviour can be built, the spike is slice 1 and the proof slice follows it. An all-mechanical plan has no proof slice; its parity check (Principle 3) stands in. [examples/thought-process.md](examples/thought-process.md) shows the framing.

### 3. Each slice stands alone

A slice stands alone when the behaviour the task promises works through the boundary that uses it, with no later slice needed to wire it in. The boundary is whatever the task delivers: a route, a command, a service or library contract with no in-repo caller yet. Layers and producers are items inside a slice, never a slice of their own; compiling and passing its own unit tests is not standing alone.

Three kinds of slice are exempt and say so in the plan: a **spike** (names the uncertainty and the decision it settles, ships no behaviour), a **mechanical** move or refactor (its parity check proves preserved behaviour), and a **contract-only task** whose whole deliverable is a producer with no consumer in scope.

### 4. One new concept per slice, ordered by complexity

A concept is a capability or rule (Principle 3). Widen along one axis at a time: scope of data (one case → common cases → the full set), edge cases (happy path → known edges → recursive or cyclic shapes), automation (hard-coded → discovered), entry points (one way to reach the behaviour → every way). [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md) layers one concept per slice across these axes.

### 5. Name the property you can check

Each slice lists concrete tests: "endpoint returns the expected count", "output is deterministic across runs", not "works correctly" or "handles errors". For a behaviour slice, one of them exercises the behaviour at the slice's boundary; an exempt slice (Principle 3) or one that can't be automated (Principle 8) names its evidence instead.

### 6. Describe the approach in words

Say what is built and how it works in words: the logical steps, the key data structures, the edge cases, the pattern it follows. "Create a function that walks the type graph from a class, collecting field names and types, with a visited set for cycles" is a plan; a code block is not.

### 7. Dependencies order work inside a slice

A consumer needs its producer, a recursive case needs its base case, a composite type needs its element types. These order the items *inside* a slice (Principle 3): the slice that introduces a consumer carries the minimum producer it needs, built first. Consult [examples/layer-cut-vs-vertical.md](examples/layer-cut-vs-vertical.md) to see one feature cut both ways.

### 8. Say when a slice can't be automated

Boot-time code, hot-reload paths, dev-only tooling, third-party UI flows: state it in the slice and give numbered manual verification steps as the slice's evidence.

### 9. Group slices into PR bundles

The plan ends in a stack of PRs, one per **bundle** of consecutive slices. A seam is admissible when the tree at that slice:

- stands alone green, and better than the base; it need not be complete, and an edge case the next bundle closes is fine when the plan names it;
- leaves nothing half-moved by the end of the stack; interim shapes within the stack are fine;
- has one reason to exist;
- is worth its own review;
- depends only on the bundles below it.

A bundle that ends on a producer the next bundle consumes is a valid seam even though a producer-only slice is not. Each bundle's last slice carries the bundle's **closing items**, the administrative work PRs in this repo require (e.g. changelogs, CODEOWNERS), as chore items; find them in the repo's PR template, contributing guide and recent merged PRs, and when there are none, the plan says so. Consult [references/pr-bundles.md](references/pr-bundles.md) if you need the admissibility rules in full, the table columns or a worked example.
