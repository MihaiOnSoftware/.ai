---
name: create-implementation-plan
description: Create an implementation plan with incremental slices using story splitting patterns
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

**Note**: These examples show complete plans for reference and learning. When creating your plan, present slices one at a time to the user, not all at once.

- For an example of a multi-slice plan with pattern analysis, see [examples/iterm-profile-generation.md](examples/iterm-profile-generation.md)
- For an example using the SIMPLE/COMPLEX pattern, see [examples/schema-hash-cache-keys.md](examples/schema-hash-cache-keys.md)

## Key Principles

### 1. Apply Story Splitting Patterns

Multiple patterns exist for breaking down large stories. Choose the one that best fits your situation:

For the full list of patterns (WORKFLOW STEPS, OPERATIONS, BUSINESS RULES, VARIATIONS IN DATA, SIMPLE/COMPLEX, DEFER PERFORMANCE, MAJOR EFFORT), see [references/story-splitting-patterns.md](references/story-splitting-patterns.md).

### Choosing the Right Pattern

For this project, **SIMPLE/COMPLEX** was chosen because:
- Biggest risk was "does Sorbet introspection work?"
- Slice 1 validates the entire approach
- Each subsequent slice adds one new complexity
- Can stop after any slice and still have value

### 2. Think About What Validates the Approach

Slice 1 must prove the core concept works:
- Does Sorbet introspection work at all?
- Can we calculate a hash?
- Does including it in the cache key work?
- Do tests pass?

If Slice 1 fails, the whole approach fails. This is intentional - fail fast.

### 3. Each Slice Must Be Independently Valuable

Ask for each slice:
- **What does this prove?** (learning/risk mitigation)
- **What value does it deliver?** (even if incomplete)
- **Can I test this?** (verify it works)
- **Does it stand alone?** (could stop here if needed)

Example from this project:
- Slice 1: Proves introspection works, delivers basic cache invalidation
- Slice 2: Proves dev workflow works (hot reload)
- Slice 3: Extends to direct children
- Slice 5: Solves the actual bug (SelectConfigFieldOption)

### 4. Build Complexity Incrementally

Order slices by increasing complexity:
1. Single class, no recursion
2. Infrastructure (config, initializer)
3. Direct children only
4. Handle complex types (Array, Union)
5. Full recursion
6. Automatic discovery (sealed subclasses)

Each slice adds exactly one new concept. Don't combine "handle arrays" with "add recursion."

### 5. Make Each Slice Testable

For each slice, identify concrete test cases:
- "Hash is deterministic" (can verify)
- "Hash changes when field added" (can verify)
- "Discovers SelectConfigFieldOption" (can verify)

Avoid vague requirements like "works correctly" - be specific about what correctness means.

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

Some work must happen in order:
- Can't test cache key format until hash calculation exists
- Can't do recursion until you handle direct children
- Can't handle Arrays until you handle Simple types

Order slices so each builds on previous work.

### 8. Acknowledge Untestable Slices

Some things can't be fully automated:
- Rails initializers (boot-time behavior)
- Hot reloading (development mode)
- Manual verification steps

For Slice 2, we explicitly noted: "limited automated testing" and documented manual verification.

## The Planning Process

### Step 1: Understand the Solution Architecture

Read the investigation document to understand:
- What classes are involved?
- What technical approach are we using?
- What are the key challenges?
- What patterns exist in the codebase?

For this project: Sorbet introspection via `decorator.props`, recursive type discovery, sealed subclasses, Rails config patterns.

### Step 2: Identify the Simplest Proof of Concept

Ask: What's the absolute minimum that validates this approach?

For this project: Hash one class (Task) with no children, put it in cache key, verify cache invalidates.

That became Slice 1.

### Step 3: Map the Path from Simple to Complete

List the concepts that need to be added:
- Hot reloading support
- Direct child discovery
- Array/Union type handling
- Recursion
- Sealed subclass handling

Order them by dependency and complexity.

### Step 4: Make Each Step Testable

For each concept, write specific test requirements:
- Not: "discovery works"
- Instead: "discovers expected number of children", "hash includes SelectConfigFieldOption"

### Step 5: Verify Each Slice with INVEST Criteria

Each slice should satisfy INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable). If a slice violates INVEST, split it further or reorder.

For the full breakdown and an applied example, see [references/invest-criteria.md](references/invest-criteria.md).

For common red flags in plans (too large, not testable, unordered dependencies, etc.), see [references/red-flags.md](references/red-flags.md).

For a worked example of the thought process when splitting a task, see [examples/thought-process.md](examples/thought-process.md).

## Using This Process

When creating a new plan:

1. **Read investigation/problem statement thoroughly** - Understand the solution architecture, not just the problem
2. **Evaluate the story against INVEST** - If it doesn't satisfy INVEST (especially Small), it needs splitting
3. **Choose a splitting pattern** - Review the patterns above and pick the one that fits:
   - Is there a simple core to build on? → SIMPLE/COMPLEX
   - Can you take a thin slice through the workflow? → WORKFLOW STEPS
   - Are there distinct operations? → OPERATIONS
   - Multiple variations or rules? → BUSINESS RULES / VARIATIONS
   - Different data types? → VARIATIONS IN DATA
4. **Find the simplest proof of concept** - What's the bare minimum that validates the approach?
5. **Map the incremental path** - List concepts to add, order by dependency and complexity
6. **Make each step specific and testable** - Write concrete test requirements for each slice
7. **Verify each slice with INVEST** - Check all six criteria for each slice
8. **Check the order makes sense** - Each slice should build logically on previous work

### Presenting Your Plan

**Present slices one at a time, not all at once:**

1. **Present Slice 1** with:
   - Goal: What this slice proves or delivers
   - Approach: How to implement it (described in natural language, NO CODE)
   - Tests: Concrete success criteria

2. **Wait for user feedback** - User may approve, ask questions, or request changes

3. **Once approved, present Slice 2** in the same format

4. **Repeat** until all slices are presented and approved

5. **Provide final summary** - After all slices approved, summarize the complete plan

**The goal**: Someone else should be able to implement slice 1 without reading slice 2. Each slice should feel like a complete mini-project that delivers value. Each slice description should be clear enough to implement without including actual code.

For an example of how to present a single slice, see [examples/presenting-a-slice.md](examples/presenting-a-slice.md).

For a quick-reference flowchart to choose the right splitting pattern, see [references/flowchart.md](references/flowchart.md).
