# Story Splitting Patterns

Multiple patterns exist for breaking down large stories. Choose the one that best fits your situation:

## WORKFLOW STEPS Pattern
Split by the natural flow of work - do beginning and end first, then enhance with middle steps.

**Example**: For a checkout flow, slice 1 might be "add to cart and pay" (skipping address validation, shipping options, discounts). Later slices add those middle steps.

**When to use**: When there's a clear sequence of steps and you can take a thin slice through the entire flow.

## OPERATIONS Pattern
Split by distinct operations, especially CRUD operations or different actions on the same entity.

**Example iTerm plan**: Slices 1-9 are "create/configure profiles", slice 10 is "list profiles", slice 11 is "delete profiles". Create comes first because it proves the core value.

**When to use**: Story involves "managing" something (create, read, update, delete).

## BUSINESS RULES / VARIATIONS Pattern
Start with simplest rule or most common variation, add complexity later.

**Example**: Payment processing - slice 1 handles credit cards only, slice 2 adds PayPal, slice 3 adds crypto. Or validation rules - slice 1 has basic required field checks, slice 2 adds format validation, slice 3 adds cross-field validation.

**Example iTerm plan**: Slice 2 is "user specifies color", slice 8 is "pick random color", slice 9 is "avoid color clashes". Each adds business rule sophistication.

**When to use**: Story has multiple variations or rules that build on each other.

## VARIATIONS IN DATA Pattern
Handle one kind of data first, add other data types later.

**Example**: Import feature - slice 1 handles CSV, slice 2 adds JSON, slice 3 adds XML. Each data format is independent.

**When to use**: Same operation applies to different data types or sources.

## SIMPLE/COMPLEX Pattern
Build simple core that provides most value/learning, then enhance with complexity.

**Example (this project)**: Slice 1 hashes one class with no recursion. This proves Sorbet introspection works. Slices 3-6 progressively add complexity (children, arrays, recursion, sealed classes).

**Example iTerm plan**: Slice 1 is "create basic profile" (no colors, no auto-switch). This proves profile creation works. Slices 2-9 layer on sophistication.

**When to use**: When validating an approach is the biggest risk, or when core functionality can work without all the bells and whistles.

## DEFER PERFORMANCE Pattern
Make it work first with acceptable performance, then optimize for non-functional requirements.

**Example**: Search feature - slice 1 does simple string matching, slice 2 adds indexes for performance, slice 3 adds caching.

**When to use**: Performance/scalability adds significant complexity but basic functionality is valuable.

## MAJOR EFFORT Pattern
When an obvious split leaves one slice much harder than others, group the later slices and defer the decision about which to do first.

**Example**: If slices 2-5 are all complex, group them as "enhancements" and decide priority after slice 1 proves the concept.

**When to use**: Can't predict which enhancement will be most valuable until you've built the foundation.
