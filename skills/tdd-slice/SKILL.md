---
name: tdd-slice
description: Implement a complete TDD slice with multiple micro-tdd cycles and validation
license: MIT
metadata:
  category: tdd
---

Implement a complete slice by orchestrating multiple micro-tdd-agent cycles, validating each cycle, and aggregating results.

## Subagents Used

This command delegates work to subagents:
- `micro-tdd-agent` - for test behaviors
- `micro-refactor-agent` - for refactorings
- `commit-agent`
- `tdd-validation-agent`
- `micro-fix-agent` - for fixing trivial validation issues
- `investigator-agent` - for analyzing repeated validation failures

## What This Command Does

**Input**: Slice requirements document containing:
- Slice number and name
- Slice goal
- Features to implement
- Tests to write (list of test behaviors)
- Commit message (for reference, not used - micro commits kept)

**Output**: Path to tdd-agent report referencing all micro and validation reports

**Does**:
- Analyze requirements and create execution plan
- Call micro-tdd-agent for test behaviors
- Call micro-refactor-agent for refactorings
- Call commit-agent to create commits for each cycle
- Validate each commit with tdd-validation-agent
- Attempt to fix trivial validation issues (commit message, comments, one-liners) with micro-fix-agent
- Retry failed steps with context (full reset if fixes fail or issues are substantial)
- Call investigator-agent after second validation failure to determine root cause
- Analyze and report on repeated failures with investigation findings
- Create summary report with references to child reports

**Does NOT**:
- Write tests or code directly (delegates to agents)
- Squash commits (keeps individual micro commits)
- Run cleanup (micro agents handle that)

## Input Format

Slice requirements should be provided as:

```markdown
# Slice [N]: [Slice Name]

## Goal
[What this slice achieves]

## Features
- Feature 1
- Feature 2

## Tests to Write
1. Test behavior 1 description
2. Refactor: [refactoring description]
3. Test behavior 2 description

## Commit Message
[Reference message - not used, micro commits kept]
```

**Note**: Items may be prefixed with "Refactor:" to explicitly indicate refactorings, but the agent will analyze each item to determine if it's a behavioral change (test) or structural change (refactor).

## Workflow

### Phase 1: Read Rules

Read ALL files in `~/.ai/rules/*` in order:
1. `1_running_into_problems.md`
2. `2_approaching_work.md`
3. `3_quality.md`
4. `4_testing.md`
5. `5_cleanup.md`
6. `6_commit.md`
7. `7_writing_style.md`
8. `8_let_me_just.md`

Post "✅ Rules loaded"

### Phase 2: Analyze & Plan

**Step 1: Read slice requirements**
- Parse slice number, name, goal
- Extract list of test behaviors
- Note features to implement

Post "✅ Slice requirements parsed: [slice name]"

**Step 2: Analyze codebase**
- Examine relevant test files and production code
- Understand existing patterns and conventions
- Identify dependencies and structure

Post "✅ Codebase analyzed"

**Step 3: Create execution plan**
- Review items from "Tests to Write" section
- For each item, analyze whether it's a behavioral change or structural change:
  - **Test behavior** (use micro-tdd-agent): Adds new functionality, changes behavior, adds assertions about system behavior
  - **Refactoring** (use micro-refactor-agent): Improves code structure without changing behavior (extract method, rename, reorganize)
  - Items explicitly prefixed with "Refactor:" are refactorings, but also identify refactorings without the prefix
- Ensure test behaviors are specific and atomic (one behavior per test)
- Ensure refactorings are specific and atomic (one structural change)
- If items are too broad, break them down further
- Create ordered list with type annotations (test/refactor) and descriptions

Post "✅ Execution plan created: [N] items ([X] tests, [Y] refactors)"

### Phase 3: Execute Micro Cycles

For each item in the execution plan:

**Step 1: Call appropriate agent**

Based on the execution plan's type annotation for this item:

**If item is a test behavior:**
Delegate to `micro-tdd-agent` with the test behavior description.

**If item is a refactoring:**
Delegate to `micro-refactor-agent` with the refactoring description (remove "Refactor:" prefix if present).

Track:
- Attempt number (1 or 2)
- Agent type used (micro-tdd or micro-refactor)
- Micro report path
- Commit hash created

**If agent fails:**

1. **First failure**: Retry once with additional context
   - Analyze the failure (error messages, what went wrong)
   - Provide context: "Previous attempt failed because [reason]. Consider [suggestion]."
   - Delegate to the same agent type again with enhanced prompt

2. **Second failure**: Stop and report
   - Analyze what went wrong (examine errors, code state, test output)
   - Write failure analysis report using write-agent-report skill
   - Include: slice info, failed item, both attempts, error details, possible causes
   - Return the failure report path and STOP

**If agent succeeds:**

Post "✅ Micro cycle [N/Total] complete: [item description]"

**Step 2: Create commit**

Delegate to `commit-agent` to create a commit for the changes.

Track:
- Commit hash created

Post "✅ Commit created: [commit hash]"

**Step 3: Validate the micro commit**

Delegate to `tdd-validation-agent` with context about the slice and current item.

Format the prompt as:
```
Validate this commit for slice [N]: [Slice Name]

Slice goal: [Goal from requirements]
Current item: [Item description from execution plan]
Item type: [test/refactor]

Micro report: [micro report path]
Commit: [commit hash]
```

Track:
- Validation attempt number (1 or 2)
- Validation report path
- Validation verdict (pass/fail)

**If validation fails:**

1. **First validation failure**: Analyze and attempt fix

   **Step A: Categorize issues**

   Read validation report and categorize issues:

   **Trivial issues** (try fix path):
   - Commit message only (passive voice, process description, missing note)
   - Comments that should be methods
   - One-line code issues (unused variable, dead code)
   - Simple duplication
   - Formatting/whitespace

   **Substantial issues** (use reset path):
   - Test quality (branching, multiple behaviors, weak assertions)
   - Multi-line logic changes
   - Coverage problems
   - Behavior changes needed

   **Step B: If ONLY trivial issues, attempt fix**

   **For commit message issues only:**
   - Soft reset: `git reset --soft HEAD~1`
   - Delegate to `commit-agent` to create new commit
   - Track new commit hash
   - Validate again with new commit hash (include same slice context)
   - If validation passes → continue
   - If validation fails → proceed to Step C (reset path)

   **For code issues (with or without commit message issues):**
   - Delegate to `micro-fix-agent` with validation report path
   - If micro-fix-agent succeeds:
     - Amend commit: `git commit --amend --no-edit`
     - Track commit hash (stays same after amend)
     - Validate again with same commit hash (include same slice context)
     - If validation passes → continue
     - If validation fails → proceed to Step C (reset path)
   - If micro-fix-agent fails → proceed to Step C (reset path)

   **Step C: If substantial issues OR fix failed, use reset path**

   - Read validation report to understand issues
   - Provide context: "Previous attempt didn't meet quality standards: [issues from validation report]"
   - Revert the commit: `git reset --hard HEAD~1`
   - Delegate to the same agent type (micro-tdd or micro-refactor) again with validation feedback
   - If succeeds, call commit-agent again to create new commit
   - Validate again with new commit hash (include same slice context)

2. **Second validation failure**: Investigate and stop

   **Step A: Call investigator-agent**

   Delegate to `investigator-agent` with:
   - Validation report path (from second failure)
   - Micro agent report path
   - Commit hash

   The investigator will:
   - Apply problem-solving discipline
   - Determine root cause
   - Analyze what went wrong in both attempts
   - Provide recommendations for what should have been done

   **Step B: Write failure analysis report**

   - Include: slice info, item description, both validation reports, quality issues, fix attempts
   - Include: investigator report path and key findings
   - Include: investigator's root cause analysis and recommendations
   - Write failure analysis report using write-agent-report skill
   - Return the failure report path and STOP

**If validation passes:**

Post "✅ Validation [N/Total] passed: [test name]"

**Step 4: Continue to next test behavior**

Repeat Steps 1-3 for each test behavior in the execution plan.

### Phase 4: Final Report

After all micro cycles complete successfully:

**Step 1: Collect report paths**
- Gather all micro-tdd-agent report paths
- Gather all tdd-validation-agent report paths

**Step 2: Create summary report**

Use skill `write-agent-report` with:
- `agent_name`: `tdd-slice`
- `report_content`: the markdown below

```markdown
# TDD Slice Report - Slice [N]: [Slice Name]

## Slice Info
- Slice: [N] - [Name]
- Goal: [Goal from requirements]
- Items implemented: [Count] ([X] tests, [Y] refactors)

## Execution Summary
[High-level summary of what was built]

## Micro Cycles
[For each cycle, include:]
- Cycle [N]: [Type: Test/Refactor] [Description]
  - Agent used: [micro-tdd-agent or micro-refactor-agent]
  - Micro report: [path to micro report]
  - Validation report: [path to validation report]
  - Commit: [commit hash]
  - Status: ✅ Success

## Statistics
- Total cycles: [N]
- Tests: [X]
- Refactorings: [Y]
- Total commits: [N]
- Retries (micro): [N]
- Retries (validation): [N]
- All tests passing: ✅ Yes

## Status
✅ Slice complete
```

**Step 3: Return report path**

Return only the path to the tdd-slice report:

```
[full path to tdd-slice report]
```

For detailed retry logic for micro agents and validation, see [references/retry-logic.md](references/retry-logic.md).

For the failure analysis report format, see [references/failure-report-format.md](references/failure-report-format.md).

## Quality Standards

All quality standards come from `~/.ai/rules/*` and are enforced by:
- micro-tdd-agent (during execution)
- tdd-validation-agent (after each cycle)

The tdd-slice skill's job is orchestration, not quality enforcement.

## Success Criteria

- ✅ All items from slice requirements implemented (tests + refactors)
- ✅ Each micro cycle completed successfully with appropriate agent
- ✅ Each commit validated and passed
- ✅ Summary report created with child report references
- ✅ All micro commits preserved in history
- ✅ Retries attempted when appropriate
- ✅ Clear failure analysis if stopped early

For a worked example session showing cycles with retries and fixes, see [examples/session.md](examples/session.md).

## Anti-Patterns to AVOID

**DO NOT**:
- Write tests or code directly (use micro agents)
- Skip validation steps
- Give up after first failure without retry
- Copy contents of child reports into summary
- Squash or modify micro commits
- Run cleanup commands (micro agents do this)
- Make assumptions about failure causes without analysis
- Use micro-tdd-agent for refactorings (use micro-refactor-agent)

**DO**:
- Delegate to micro agents systematically to orchestrate them
- Choose correct agent type (tdd vs refactor)
- Validate every commit
- Provide helpful context on retries
- Analyze failures thoroughly before stopping
- Reference child reports by path
- Keep all micro commits intact
- Trust micro agents to handle cleanup

## Why This Approach

**Benefits**:
- Atomic commits (one change per commit - test or refactor)
- Validation at each step (catch issues early)
- Clear failure isolation (know exactly which item failed)
- Retry logic (handle transient failures)
- Detailed audit trail (all reports preserved)
- Incremental progress (can see work even if interrupted)
- Follows TDD discipline (via micro-tdd-agent) and refactoring discipline (via micro-refactor-agent)
- Separation of concerns (adding behavior vs improving structure)
