---
name: create-implementation-plan
description: Create an implementation plan with incremental slices using story splitting patterns
license: MIT
compatibility: opencode
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

### Example 1: iTerm Profile Generation

Excellent plan structure for dynamic iTerm profile generation:

```
1. Create a new profile that's a copy of the current default (no colour changes, no auto switch, overrides existing generated profiles)
2. Allow the user to pass a colour preset name and use it when creating the profile
3. Add shell integration to automatically switch to the profile based on a path that's passed in
4. Include worktree name in profile name and badge text
5. Find the current worktree if no path is passed in and use that
6. Allow for multiple generated profiles (don't override, add to existing)
7. Persist which preset was assigned to which worktree (so re-running doesn't change it)
8. Pick a random colour preset from a list if none is passed in
9. Check other profiles when deciding colour preset so there aren't clashes (don't reuse until we've used all available)
10. List/view command to see generated profiles (optional - we'll see if iTerm's UI is sufficient)
11. Remove/cleanup command (optional - we'll see if needed)
```

**What makes this excellent**:
- Slice 1 proves the core mechanism (profile creation) works
- Each slice adds one new capability
- Early slices deliver value even if later slices are skipped
- Optional features clearly marked (slices 10-11)
- Each slice is testable and demoable
- Natural progression from simple to complex

**Pattern analysis**:
- **SIMPLE/COMPLEX**: Slice 1 is bare-bones profile creation. Slices 2-9 add sophistication.
- **OPERATIONS**: Slices 1-9 are "create/configure", slice 10 is "read/list", slice 11 is "delete".
- **BUSINESS RULES**: Slice 2 (manual color) → slice 8 (random color) → slice 9 (avoid clashes) adds progressively smarter behavior.
- **VARIATIONS IN DATA**: Slice 3 (path-based switching) → slice 5 (auto-detect worktree) handles different input types.

Notice how multiple patterns can apply simultaneously. Good plans often combine patterns.

### Example 2: Automatic Schema Hash for Cache Keys

Simplified plan for adding automatic schema hash to Rails cache keys (this project):

**Context**: Rails cache doesn't invalidate when Ruby class schemas change (new fields added). Need automatic detection.

```
Slice 1: Basic schema hash for Task only
Goal: Prove Sorbet introspection works, validate cache invalidation mechanism
Tests: Hash is deterministic, cache key includes hash, HACK workaround removed

Slice 2: Hot reload support
Goal: Make dev-friendly by supporting code reloading
Tests: Hash accessible via Rails.config, calculated during initialization
Note: Limited automated testing - requires manual verification

Slice 3: Discover direct child types
Goal: Catch changes to Task's immediate dependencies
Tests: Hash includes ConfigField/Port/ReturnField, hash changes when child field changes

Slice 4: Handle Array and Union types
Goal: Correctly extract types from complex type declarations
Tests: Extracts element type from T::Array[X], handles T.nilable(X)

Slice 5: Recursive type discovery
Goal: Complete the solution by discovering deeply nested types
Tests: Hash includes SelectConfigFieldOption (the original bug!), prevents infinite loops

Slice 6: Sealed subclass discovery
Goal: Zero maintenance when new ConfigField types added
Tests: Hash includes all ~20+ ConfigField subclasses, count matches expected
```

**What makes this excellent**:
- Slice 1 validates entire approach (biggest risk: does introspection work?)
- Each slice adds exactly one new concept (children, arrays, recursion, sealed classes)
- Each slice has concrete, testable success criteria
- Can stop after any slice and still have value
- Pattern: **SIMPLE/COMPLEX** - start with bare-bones (hash one class), layer on complexity

## Key Principles

### 1. Apply Story Splitting Patterns

Multiple patterns exist for breaking down large stories. Choose the one that best fits your situation:

#### WORKFLOW STEPS Pattern
Split by the natural flow of work - do beginning and end first, then enhance with middle steps.

**Example**: For a checkout flow, slice 1 might be "add to cart and pay" (skipping address validation, shipping options, discounts). Later slices add those middle steps.

**When to use**: When there's a clear sequence of steps and you can take a thin slice through the entire flow.

#### OPERATIONS Pattern
Split by distinct operations, especially CRUD operations or different actions on the same entity.

**Example iTerm plan**: Slices 1-9 are "create/configure profiles", slice 10 is "list profiles", slice 11 is "delete profiles". Create comes first because it proves the core value.

**When to use**: Story involves "managing" something (create, read, update, delete).

#### BUSINESS RULES / VARIATIONS Pattern
Start with simplest rule or most common variation, add complexity later.

**Example**: Payment processing - slice 1 handles credit cards only, slice 2 adds PayPal, slice 3 adds crypto. Or validation rules - slice 1 has basic required field checks, slice 2 adds format validation, slice 3 adds cross-field validation.

**Example iTerm plan**: Slice 2 is "user specifies color", slice 8 is "pick random color", slice 9 is "avoid color clashes". Each adds business rule sophistication.

**When to use**: Story has multiple variations or rules that build on each other.

#### VARIATIONS IN DATA Pattern
Handle one kind of data first, add other data types later.

**Example**: Import feature - slice 1 handles CSV, slice 2 adds JSON, slice 3 adds XML. Each data format is independent.

**When to use**: Same operation applies to different data types or sources.

#### SIMPLE/COMPLEX Pattern
Build simple core that provides most value/learning, then enhance with complexity.

**Example (this project)**: Slice 1 hashes one class with no recursion. This proves Sorbet introspection works. Slices 3-6 progressively add complexity (children, arrays, recursion, sealed classes).

**Example iTerm plan**: Slice 1 is "create basic profile" (no colors, no auto-switch). This proves profile creation works. Slices 2-9 layer on sophistication.

**When to use**: When validating an approach is the biggest risk, or when core functionality can work without all the bells and whistles.

#### DEFER PERFORMANCE Pattern
Make it work first with acceptable performance, then optimize for non-functional requirements.

**Example**: Search feature - slice 1 does simple string matching, slice 2 adds indexes for performance, slice 3 adds caching.

**When to use**: Performance/scalability adds significant complexity but basic functionality is valuable.

#### MAJOR EFFORT Pattern
When an obvious split leaves one slice much harder than others, group the later slices and defer the decision about which to do first.

**Example**: If slices 2-5 are all complex, group them as "enhancements" and decide priority after slice 1 proves the concept.

**When to use**: Can't predict which enhancement will be most valuable until you've built the foundation.

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

Each slice should satisfy INVEST (from the story splitting framework):

**I - Independent**: Can be implemented without being blocked by other slices. Some dependencies are unavoidable (slice 5 needs slice 1), but minimize coupling.

**N - Negotiable**: Could discuss different approaches to achieve the slice's goal. Not so detailed that implementation is prescribed.

**V - Valuable**: Delivers learning, risk mitigation, or actual functionality. Ask "what do we gain from completing this slice?"

**E - Estimable**: Can understand and assess the scope and complexity. If you can't gauge the complexity or understand what's involved, the slice is too vague or depends on unknown complexity.

**S - Small**: Roughly 1/8 to 1/4 of your velocity. Each slice should take hours, not days.

**T - Testable**: Has concrete success criteria. Not "works well" but "hash is deterministic", "cache key includes hash", etc.

**Applying INVEST to this project's Slice 1**:
- ✅ Independent: Can be done first, no dependencies
- ✅ Negotiable: Could use different hashing algorithms, different cache key formats
- ✅ Valuable: Proves Sorbet introspection works (biggest risk)
- ✅ Estimable: Clear scope - single file creation, one method, basic tests - complexity is well understood
- ✅ Small: Single file creation, one method, basic tests
- ✅ Testable: "Hash is deterministic", "cache key includes hash"

If a slice violates INVEST, split it further or reorder.

## Red Flags in Plans

### Too Large
"Implement complete schema hash calculation" - This is the whole project, not a slice.

### Not Testable
"Add infrastructure" - How do you know it works? What specific tests?

### Unordered Dependencies
Slice 3: "Add recursion"
Slice 4: "Handle direct children"

Wrong order - can't recurse before handling direct children.

### Vague Requirements
"Make it work in development" - What does "work" mean? Be specific: "Hash recalculates on code reload"

### Multiple Concepts
"Add recursion and handle sealed subclasses" - Split into two slices.

## Example Thought Process (This Project)

**Question**: How do I split automatic schema hash implementation?

**Answer**:
1. What's the simplest proof? → Hash Task only, no children
2. What infrastructure do we need? → Rails config, initializer for hot reload
3. What's the next increment? → Add direct children (Port, ConfigField)
4. What complexity comes next? → Arrays and Unions (T::Array[ConfigField])
5. What completes the solution? → Recursion (find SelectConfigFieldOption)
6. What makes it maintainable? → Sealed subclass auto-discovery

**Result**: 6 slices, each building on the previous, each testable, each delivering value.

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

### Example of Presenting a Single Slice

Here's what presenting a single slice should look like:

---

**Slice 1: Basic schema hash for Task only**

**Goal**: Prove Sorbet introspection works and validate the cache invalidation mechanism. This is the critical risk - if we can't introspect class schemas, the entire approach fails.

**Approach**:
- Create a SchemaHasher class that uses Sorbet's decorator introspection to access the props defined on a class
- Extract field names and their type signatures from the Task class
- Sort these signatures alphabetically to ensure deterministic ordering
- Generate a SHA-256 hash from the concatenated signatures
- Modify the Task cache key generation to include this schema hash
- Remove the existing HACK workaround that manually increments version numbers

**Tests**:
- Hash is deterministic: calling hash_schema twice on the same class returns the same hash
- Cache key includes the schema hash in the expected format
- Adding a new field to Task changes the hash value
- Removing the HACK workaround doesn't break existing functionality

---

*[Wait for user approval before presenting Slice 2]*

## Quick Reference: From Flowchart to Plan

The story splitting flowchart asks these questions in order:

1. **Does the story satisfy INVEST?** (If yes, no splitting needed)
2. **Does it describe a workflow?** → WORKFLOW STEPS pattern
3. **Can you take a thin slice and enhance later?** → SIMPLE/COMPLEX pattern
4. **Multiple operations?** → OPERATIONS pattern
5. **Variety of business rules?** → BUSINESS RULES pattern
6. **Same thing to different data?** → VARIATIONS IN DATA pattern
7. **Complex interface?** → Start with simple version
8. **Satisfying non-functional requirements?** → DEFER PERFORMANCE pattern
9. **Obvious split leaves one slice much harder?** → MAJOR EFFORT pattern

Work through these questions with your story to identify the right pattern, then apply the planning process above.
