---
name: tdd-slice
description: Implement a complete TDD slice with multiple micro-tdd cycles and validation
license: MIT
compatibility: opencode
metadata:
  category: tdd
---

Implement a complete slice by orchestrating multiple micro-tdd-agent cycles, validating each cycle, and aggregating results.

## Subagents Used

This command uses the Task tool to delegate work to:
- `micro-tdd-agent` - for test behaviors
- `micro-refactor-agent` - for refactorings
- `commit-agent`
- `tdd-validation-agent`
- `micro-fix-agent` - for fixing trivial validation issues
- `investigator-agent` - for analyzing repeated validation failures

See the Task tool's available agents list for their descriptions.

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

**Note**: Items prefixed with "Refactor:" will use micro-refactor-agent instead of micro-tdd-agent.

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
- Identify which are test behaviors vs refactorings (prefix "Refactor:")
- Ensure test behaviors are specific and atomic (one behavior per test)
- Ensure refactorings are specific and atomic (one structural change)
- If items are too broad, break them down further
- Create ordered list with type annotations (test/refactor) and descriptions

Post "✅ Execution plan created: [N] items ([X] tests, [Y] refactors)"

### Phase 3: Execute Micro Cycles

For each item in the execution plan:

**Step 1: Call appropriate agent**

**If item is a test behavior:**
Use Task tool (subagent_type='micro-tdd-agent') with the test behavior description.

**If item is a refactoring (prefix "Refactor:"):**
Use Task tool (subagent_type='micro-refactor-agent') with the refactoring description (without prefix).

Track:
- Attempt number (1 or 2)
- Agent type used (micro-tdd or micro-refactor)
- Micro report path
- Commit hash created

**If agent fails:**

1. **First failure**: Retry once with additional context
   - Analyze the failure (error messages, what went wrong)
   - Provide context: "Previous attempt failed because [reason]. Consider [suggestion]."
   - Use Task tool with same agent type again with enhanced prompt

2. **Second failure**: Stop and report
   - Analyze what went wrong (examine errors, code state, test output)
   - Write failure analysis report using write-agent-report skill
   - Include: slice info, failed item, both attempts, error details, possible causes
   - Return the failure report path and STOP

**If agent succeeds:**

Post "✅ Micro cycle [N/Total] complete: [item description]"

**Step 2: Create commit**

Use Task tool (subagent_type='commit-agent') to create a commit for the changes.

Track:
- Commit hash created

Post "✅ Commit created: [commit hash]"

**Step 3: Validate the micro commit**

Use Task tool (subagent_type='tdd-validation-agent') with: `<micro-report-path> <commit-hash>`

Format the prompt as: "[micro report path] [commit hash]"

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
   - Use Task tool (subagent_type='commit-agent') to create new commit
   - Track new commit hash
   - Validate again with new commit hash
   - If validation passes → continue
   - If validation fails → proceed to Step C (reset path)

   **For code issues (with or without commit message issues):**
   - Use Task tool (subagent_type='micro-fix-agent') with validation report path
   - If micro-fix-agent succeeds:
     - Amend commit: `git commit --amend --no-edit`
     - Track commit hash (stays same after amend)
     - Validate again with same commit hash
     - If validation passes → continue
     - If validation fails → proceed to Step C (reset path)
   - If micro-fix-agent fails → proceed to Step C (reset path)

   **Step C: If substantial issues OR fix failed, use reset path**

   - Read validation report to understand issues
   - Provide context: "Previous attempt didn't meet quality standards: [issues from validation report]"
   - Revert the commit: `git reset --hard HEAD~1`
   - Use Task tool with same agent type (micro-tdd or micro-refactor) again with validation feedback
   - If succeeds, call commit-agent again to create new commit
   - Validate again with new commit hash

2. **Second validation failure**: Investigate and stop

   **Step A: Call investigator-agent**

   Use Task tool (subagent_type='investigator-agent') with:
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

Use the write-agent-report skill to create the summary report:

```bash
cat <<EOF | ~/.ai/scripts/generic/write-agent-report.sh tdd-slice
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
EOF
```

**Step 3: Return report path**

Return only the path to the tdd-slice report:

```
[full path to tdd-slice report]
```

## Retry Logic Details

### Micro Agent Retry

When micro-tdd-agent fails:
1. Analyze failure mode (test didn't fail right, tests not passing, stuck)
2. Extract key information (error messages, test output)
3. Formulate helpful context:
   - "Previous test failed to compile: [error]. Check syntax."
   - "Previous test passed when it should fail. Test may need assertion."
   - "Previous implementation broke existing tests: [failures]. Consider [approach]."
4. Use Task tool (subagent_type='micro-tdd-agent') with: original behavior + failure context

When micro-refactor-agent fails:
1. Analyze failure mode (tests broken, refactoring incomplete, stuck)
2. Extract key information (error messages, test failures)
3. Formulate helpful context:
   - "Previous refactoring broke tests: [failures]. Consider smaller change."
   - "Previous attempt changed behavior. Refactoring must preserve behavior."
   - "Previous refactoring incomplete. Consider [approach]."
4. Use Task tool (subagent_type='micro-refactor-agent') with: original description + failure context

### Validation Retry

When tdd-validation-agent fails:

**Step 1: Categorize issues**
- Read validation report thoroughly
- Determine if issues are trivial (commit message, comments, one-liners) or substantial (test quality, logic)

**Step 2: Try fix approach (if trivial)**
- For commit message only: soft reset + commit-agent
- For code issues: micro-fix-agent + amend commit
- Re-validate
- If passes: continue
- If fails: proceed to Step 3

**Step 3: Use reset approach (if substantial or fix failed)**
1. Extract specific quality issues:
   - Test quality problems (branching, multiple behaviors, weak assertions)
   - Code quality problems (duplication, comments, dead code)
   - Commit message problems (process description, passive voice)
2. Revert the commit: `git reset --hard HEAD~1`
3. Formulate helpful context with specific fixes needed
4. Use Task tool with same agent type (micro-tdd or micro-refactor) with: original description + validation feedback
5. Create new commit with commit-agent
6. Re-validate

## Failure Analysis Report Format

When stopping due to repeated failures:

```markdown
# TDD Slice Failure Report - Slice [N]: [Slice Name]

## Failure Context
- Slice: [N] - [Name]
- Failed item: [Test/Refactor] [Description]
- Agent used: [micro-tdd-agent or micro-refactor-agent]
- Failure type: [Micro execution / Validation]
- Attempt count: 2

## Attempt 1
[What happened, errors, output]

## Attempt 2
[What happened, errors, output, context provided]

## Analysis
[Why it failed, possible causes, what was tried]

## Recommendations
[What should be done to fix this]

## Partial Progress
[List any micro cycles that completed successfully before failure]
- Cycle 1: [test] - ✅ Complete (reports: [paths])
- Cycle 2: [test] - ✅ Complete (reports: [paths])

## Status
❌ Stopped after repeated failures
```

## Quality Standards

All quality standards come from `~/.ai/rules/*` and are enforced by:
- micro-tdd-agent (during execution)
- tdd-validation-agent (after each cycle)

The tdd-slice command's job is orchestration, not quality enforcement.

## Success Criteria

- ✅ All items from slice requirements implemented (tests + refactors)
- ✅ Each micro cycle completed successfully with appropriate agent
- ✅ Each commit validated and passed
- ✅ Summary report created with child report references
- ✅ All micro commits preserved in history
- ✅ Retries attempted when appropriate
- ✅ Clear failure analysis if stopped early

## Example Session

**Input**: Slice 1 with 2 test behaviors and 1 refactoring

**Execution**:
1. Reads rules
2. Parses requirements: Slice 1, 3 items
3. Analyzes codebase
4. Creates execution plan: 2 tests, 1 refactor

**Cycle 1**: "Test loads config when it exists"
- Uses Task tool (micro-tdd-agent) → Success (report at path/to/report1.md)
- Uses Task tool (commit-agent) → commit abc123
- Uses Task tool (validation-agent) with "path/to/report1.md abc123" → Pass
- Posts: ✅ Cycle 1/3 complete

**Cycle 2**: "Refactor: Extract duplicate file validation"
- Uses Task tool (micro-refactor-agent) → Success (report at path/to/report2.md)
- Uses Task tool (commit-agent) → commit def456
- Uses Task tool (validation-agent) with "path/to/report2.md def456" → Fails (comment should be method)
- Categorizes as trivial issue
- Uses Task tool (micro-fix-agent) with validation report → Success (extracted method)
- Amends commit def456
- Re-validates with "path/to/report2.md def456" → Pass
- Posts: ✅ Cycle 2/3 complete (1 fix)

**Cycle 3**: "Test saves config after run"
- Uses Task tool (micro-tdd-agent) → Fails (test has branching)
- Retries with context → Success (report at path/to/report3.md)
- Uses Task tool (commit-agent) → commit ghi789
- Uses Task tool (validation-agent) with "path/to/report3.md ghi789" → Fails (test still has issue)
- Reverts commit, retries with validation feedback → Success (report at path/to/report3b.md)
- Uses Task tool (commit-agent) → commit jkl012
- Uses Task tool (validation-agent) with "path/to/report3b.md jkl012" → Pass
- Posts: ✅ Cycle 3/3 complete (1 retry)

**Final**:
- Creates summary report with references to all micro reports (tdd + refactor) and validation reports
- Returns report path

**Output**:
```
~/.ai/wip/agent_reports/tdd-slice/20250119_150000-2025-01-19.report.md
```

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
- Use Task tool systematically to orchestrate micro agents
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
