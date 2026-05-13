---
name: create-implementation-plan
description: Break a large task into incremental slices using story splitting patterns. Use when planning a feature, breaking down a complex task, or turning an investigation document into a slice-by-slice plan.
license: MIT
metadata:
  category: planning
---

# Create Implementation Plan Command

You are tasked with creating an excellent implementation plan that breaks down a large task into small, incremental slices.

## Your Role

**You are a planner, not an implementer.** Your job is to break down complex tasks into incremental slices that someone else will implement. You design the strategy, not the code.

### Critical Rules

1. **NO CODE IN PLANS** - Code-in-a-doc is unacceptable. Describe algorithms and approaches in natural language. Instead of writing code, explain what needs to happen.
   - ❌ BAD: "Add this function: `function calculateHash() { return crypto.hash(...) }`"
   - ✅ GOOD: "Create a function that calculates a deterministic hash of the class schema using SHA-256"

2. **Iterative Presentation** - Present slices one at a time for user approval, not all at once. After each slice is approved, present the next.

## Your Instructions

1. **Ask the user for context**: What task needs to be planned? Is there an investigation document, issue, or problem statement to read?

2. **Read and understand the context**: Read any provided documents thoroughly.

3. **Apply the methodology below**: Use the story splitting patterns and planning process to create a plan.

4. **Present slices iteratively**:
   - Present **Slice 1 only** with its goal, implementation approach (no code!), and tests
   - Wait for user approval or feedback
   - Once approved, present **Slice 2**
   - Repeat until all slices are approved
   - After all slices approved, provide a summary of the complete plan

---

# Planning Methodology

This methodology explains how to create excellent implementation plans.

## Required Inputs

Before creating a plan, you need:

1. **Complete investigation document** - Understanding the problem, explored solutions, chosen approach, and technical details
2. **Story splitting framework** - Patterns for breaking down large stories
3. **Concrete example** - A reference plan showing desired style and granularity
4. **End goal clarity** - Know exactly what "done" looks like

## Reference Examples

**Note**: These examples cover both complete multi-slice plans and the format of a single slice. When creating your plan, present slices one at a time to the user, not all at once.

- For an example of a multi-slice plan with pattern analysis, see [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md)
- For an example using the SIMPLE/COMPLEX pattern, see [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md)
- For the format of a single slice (goal/approach/tests), see [examples/presenting-a-slice.md](examples/presenting-a-slice.md)

## Key Principles

### 1. Apply Story Splitting Patterns

Multiple patterns exist for breaking down large stories. Choose the one that best fits your situation:

For the full list of patterns (WORKFLOW STEPS, OPERATIONS, BUSINESS RULES, VARIATIONS IN DATA, SIMPLE/COMPLEX, DEFER PERFORMANCE, MAJOR EFFORT), see [references/story-splitting-patterns.md](references/story-splitting-patterns.md).

### Choosing the Right Pattern

Use the decision tree in [references/flowchart.md](references/flowchart.md) to pick a pattern. For two worked examples of pattern selection, see [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md) (multi-pattern) and [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md) (SIMPLE/COMPLEX).

### 2. Think About What Validates the Approach

Slice 1 must prove the core concept works. List the assumption that, if false, kills the whole approach - and design Slice 1 to test it. If Slice 1 fails, the whole approach fails. This is intentional - fail fast.

See [examples/thought-process.md](examples/thought-process.md) for the Q&A framing.

### 3. Each Slice Must Be Independently Valuable

Ask for each slice:
- **What does this prove?** (learning/risk mitigation)
- **What value does it deliver?** (even if incomplete)
- **Can I test this?** (verify it works)
- **Does it stand alone?** (could stop here if needed)

### 4. Build Complexity Incrementally

Order slices by increasing complexity. Typical axes to layer along:

- **Scope of data**: one case → a few common cases → the full set
- **Edge cases**: happy path → known edge cases → recursive / nested / cyclic shapes
- **Automation**: hard-coded list → discovered automatically
- **Surrounding infrastructure**: bare function → wired into config / initialization / hot reload

Each slice adds exactly one new concept. Don't combine two axes (e.g. "handle nested types" plus "add automatic discovery") in the same slice.

See [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md) for a six-slice plan that layers exactly one new concept per slice across these axes.

### 5. Make Each Slice Testable

For each slice, identify concrete test cases. Specific over vague:

- ❌ "works correctly" / "handles errors"
- ✅ "endpoint returns the expected count", "output is deterministic across runs", "response body matches the schema", "discovers the known fixture item"

Name the property you can check, not the feeling you want.

### 6. Describe, Don't Implement

**Remember: You are a planner, not an implementer.** Describe what needs to be built, not how to build it in code.

✅ **Good descriptions**:
- "Create a function that walks the Sorbet type graph starting from a given class, collecting field names and types"
- "Use SHA-256 to generate a deterministic hash from the sorted list of field signatures"
- "Store the hash in Rails.configuration during initialization so it persists across requests"
- "Implement cycle detection using a Set to track visited class names and skip classes we've already processed"

❌ **Bad (includes code)**:
- "Add this code: `def hash_schema; fields.map(&:signature).sort.join.hash; end`"
- "Use this implementation: `visited = Set.new; return if visited.include?(klass.name)`"
- Writing out actual Ruby/JavaScript/Python/etc. code blocks

**How to describe algorithms**:
- Focus on the logical steps: "First do X, then check Y, finally return Z"
- Mention key data structures: "Use a Set to track visited items", "Store results in a Hash keyed by class name"
- Describe edge cases: "If the field is nil, skip it. If we encounter a cycle, stop recursing"
- Reference patterns: "Use the Visitor pattern", "Apply memoization to avoid redundant calculations"

The implementer will figure out the exact syntax. Your job is to clearly explain the approach and logic.

### 7. Consider Dependencies

Some work must happen in order. Common shapes:

- A consumer can't be exercised until the producer it reads from exists (e.g. can't test a route handler until the request parser it depends on exists)
- A recursive case can't be exercised until the base case works
- A composite type (Array, Union, nested record) can't be handled until its element types are handled

Order slices so each builds on previous work.

### 8. Acknowledge Untestable Slices

Some behavior can't be fully automated - boot-time code, hot-reload paths, anything that depends on a real process restart, dev-only tooling, third-party UI flows.

When a slice falls into this bucket, state it explicitly in the slice's plan and document the manual verification steps the implementer should run. Don't pretend a half-test covers it.

## The Planning Process

### Step 1: Understand the Solution Architecture

Read the investigation document to understand:
- What classes are involved?
- What technical approach are we using?
- What are the key challenges?
- What patterns exist in the codebase?

### Step 2: Identify the Simplest Proof of Concept

Ask: What's the absolute minimum that validates this approach?

### Step 3: Map the Path from Simple to Complete

List every concept that has to be added on top of the proof of concept to reach the end goal. Concepts typically fall into a few buckets:

- Broader data scope (more inputs, more types, more cases)
- Edge cases (nesting, recursion, cycles, nulls, empty collections)
- Surrounding infrastructure (config, initialization, hot reload, persistence)
- Automation (discovery, defaults, cleanup) replacing hand-maintained lists

Order them by dependency (Principle 7) and complexity (Principle 4). For a finished plan that came out of this kind of mapping, see [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md).

### Step 4: Make Each Step Testable

For each concept, write specific test requirements (Principle 5):

- ❌ "discovery works"
- ✅ "discovers the expected number of items", "output includes the known fixture item that motivated the work"

### Step 5: Verify Each Slice with INVEST Criteria

Each slice should satisfy INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable). If a slice violates INVEST, split it further or reorder.

For the full breakdown and an applied example, see [references/invest-criteria.md](references/invest-criteria.md).

For common red flags in plans (too large, not testable, unordered dependencies, etc.), see [references/red-flags.md](references/red-flags.md).
