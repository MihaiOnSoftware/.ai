---
name: tdd-slice
description: Implement a complete TDD slice with multiple micro-tdd cycles and validation, on the slice's PR bundle branch, ending with a boundary validation of the slice (and of the bundle tip on its last slice)
license: MIT
metadata:
  category: tdd
---

Implement a complete slice by orchestrating multiple micro-tdd-agent cycles, validating each cycle, and aggregating results.

## Subagents Used

This command delegates work to subagents:
- `micro-tdd-agent` - for test behaviors
- `micro-refactor-agent` - for refactorings
- `commit-agent` - commits, and every branch, amend or reset (you have no `bash`; never assume you can run git)
- `tdd-validation-agent` - per-commit validation and the boundary validation
- `micro-fix-agent` - for fixing trivial validation issues
- `micro-chore-agent` - for chores (a bundle's closing items: changelog, CODEOWNERS, docs)
- `investigator-agent` - for analyzing repeated validation failures

## What This Command Does

**Input**: Slice requirements document containing:
- Slice number and name
- Slice goal
- Bundle: which PR bundle the slice belongs to, its branch, the expected tip to start from, the slice's position, the slice gate, and the tip gate when the slice closes the bundle
- Features to implement
- Tests to write (list of test behaviors, refactors and chores)
- Commit message (for reference, not used - micro commits kept)

**Output**: The tdd-slice report, returned as your final message (your orchestrator binds it to a file; you have no `write`)

**Does**:
- Prepare the bundle branch through commit-agent before any work
- Analyze requirements and create execution plan
- Call micro-tdd-agent for test behaviors
- Call micro-refactor-agent for refactorings
- Call micro-chore-agent for chores (closing items such as a changelog entry)
- Call commit-agent to create commits for each cycle
- Validate each commit with tdd-validation-agent
- Run the boundary validation (slice gate, plus the bundle tip gate on the bundle's last slice) through tdd-validation-agent
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

## Bundle
- Bundle: PR2 "[headline]"
- Branch: [branch name]
- Expected tip: [SHA the branch must be at before this slice: the previous slice's last commit, or the base SHA]
- Position: first | middle | last | only
- Slice gate: [commands, or "default" for the repo's typecheck, lint and tests of the touched workspaces]
- Tip gate: [commands; present only when Position is last or only]

## Features
- Feature 1
- Feature 2

## Tests to Write
1. Test behavior 1 description
2. Refactor: [refactoring description]
3. Test behavior 2 description
4. Chore: [closing item, e.g. "add a changelog entry with the repo's changelog CLI for <scope>"]

## Commit Message
[Reference message - not used, micro commits kept]
```

**Note**: Items may be prefixed with "Refactor:" or "Chore:" to indicate their type, but the agent will analyze each item: a behavioral change is a test, a structural change is a refactor, and a PR-level artifact with no behavior and no test (changelog, CODEOWNERS, docs, regenerated files) is a chore.

## Workflow

### Phase 1: Analyze & Plan

**Step 1: Read slice requirements**
- Parse slice number, name, goal, and the Bundle section
- Extract list of test behaviors
- Note features to implement

Post "✅ Slice requirements parsed: [slice name]"

**Step 1b: Prepare the bundle branch**

Delegate to `commit-agent`: "prepare branch `<Branch>` at `<Expected tip>`". It creates the branch when it does not exist (HEAD must equal the expected tip), switches to it when it exists at that tip, and stops on any mismatch. If it stops, stop too and report the SHAs it returned; do not start a micro cycle on the wrong branch.

Post "✅ On branch [branch] at [tip]"

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
  - **Chore** (use micro-chore-agent): A PR-level artifact with no behavior and no test: changelog entry, CODEOWNERS line, docs, regenerated files
  - Items explicitly prefixed with "Refactor:" or "Chore:" carry their type, but also identify refactorings and chores without the prefix
- Ensure test behaviors are specific and atomic (one behavior per test)
- Ensure refactorings are specific and atomic (one structural change)
- If items are too broad, break them down further
- Create ordered list with type annotations (test/refactor/chore) and descriptions

Post "✅ Execution plan created: [N] items ([X] tests, [Y] refactors, [Z] chores)"

### Phase 2: Execute Micro Cycles

For each item in the execution plan:

**Step 1: Call appropriate agent**

Based on the execution plan's type annotation for this item:

**If item is a test behavior:**
Delegate to `micro-tdd-agent` with the test behavior description.

**If item is a refactoring:**
Delegate to `micro-refactor-agent` with the refactoring description (remove "Refactor:" prefix if present).

**If item is a chore:**
Delegate to `micro-chore-agent` with the chore instruction (remove "Chore:" prefix if present). It does the chore with the repo's tooling and stages it; it does not commit.

Track:
- Attempt number (1 or 2)
- Agent type used (micro-tdd, micro-refactor or micro-chore)
- Micro report path
- Commit hash created

**If agent fails:** Read `references/retry-logic.md` ("Micro Agent Retry" section) and follow it. Do not improvise.

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
Item type: [test/refactor/chore]

Micro report: [micro report path]
Commit: [commit hash]
```

Track:
- Validation attempt number (1 or 2)
- Validation report path
- Validation verdict (pass/fail)

**If validation fails:** Read `references/retry-logic.md` ("Validation Retry" section) and follow it. Do not improvise.

**If validation passes:**

Post "✅ Validation [N/Total] passed: [test name]"

**Step 4: Continue to next test behavior**

Repeat Steps 1-3 for each item in the execution plan.

### Phase 3: Boundary Validation

After the last micro cycle, delegate to `tdd-validation-agent` once more:

```
Boundary validation for slice [N]: [Slice Name]

Expected HEAD: [last commit hash]
Slice gate: [from the Bundle section, or "default"]
Tip gate: [from the Bundle section when Position is last or only; otherwise "none"]
```

It confirms HEAD and a clean tree before and after running the gates, and returns PASS or FAIL with the commands and exit codes. A tracked file rewritten by a gate is a FAIL. On FAIL: stop, report the slice as failed with the validation report, and do not retry the gate; the orchestrator decides (a repair item, a re-run, or a pause). The next bundle never starts on a failed tip.

Post "✅ Boundary validation passed: slice gate[, tip gate]"

### Phase 4: Final Report

After the boundary validation passes:

**Step 1: Collect report paths**
- Gather all micro-tdd-agent, micro-refactor-agent and micro-chore-agent report paths
- Gather all tdd-validation-agent report paths, including the boundary validation

**Step 2: Return the summary report**

Your final message is the report below. You have no `write` tool; the orchestrator binds your final message to a file with the dispatch's `output:` path.

```markdown
# TDD Slice Report - Slice [N]: [Slice Name]

## Slice Info
- Slice: [N] - [Name]
- Goal: [Goal from requirements]
- Bundle: [id], branch [name], position [first|middle|last|only]
- Items implemented: [Count] ([X] tests, [Y] refactors, [Z] chores)

## Execution Summary
[High-level summary of what was built]

## Micro Cycles
[For each cycle, include:]
- Cycle [N]: [Type: Test/Refactor/Chore] [Description]
  - Agent used: [micro-tdd-agent, micro-refactor-agent or micro-chore-agent]
  - Micro report: [path to micro report]
  - Validation report: [path to validation report]
  - Commit: [commit hash]
  - Status: ✅ Success

## Boundary Validation
- Slice gate: PASS
- Tip gate: PASS | n/a
- Validation report: [path]
- Slice tip: [last commit hash]

## Statistics
- Total cycles: [N]
- Tests: [X]
- Refactorings: [Y]
- Chores: [Z]
- Total commits: [N]
- Retries (micro): [N]
- Retries (validation): [N]
- All tests passing: ✅ Yes

## Status
✅ Slice complete
```

For detailed retry logic for micro agents and validation, see [references/retry-logic.md](references/retry-logic.md).

For the failure analysis report format, see [references/failure-report-format.md](references/failure-report-format.md).

## Quality Standards

All quality standards come from `~/.ai/rules/*` and are enforced by:
- micro-tdd-agent (during execution)
- tdd-validation-agent (after each cycle)

The tdd-slice skill's job is orchestration, not quality enforcement.

## Success Criteria

- ✅ Branch prepared before the first cycle; every commit is on the bundle branch
- ✅ All items from slice requirements implemented (tests + refactors + chores)
- ✅ Each micro cycle completed successfully with appropriate agent
- ✅ Each commit validated and passed
- ✅ Boundary validation passed (slice gate, and tip gate on the bundle's last slice)
- ✅ Summary report returned with child report references and the slice tip SHA
- ✅ All micro commits preserved in history
- ✅ Retries attempted when appropriate
- ✅ Clear failure analysis if stopped early

For a worked example session showing cycles with retries and fixes, see [examples/session.md](examples/session.md).

## Anti-Patterns to AVOID

**DO NOT**:

- Write tests or code directly (use micro agents)
- Run git yourself; every branch, commit, amend or reset is a `commit-agent` dispatch
- Skip validation steps, including the boundary validation
- Give up after first failure without retry
- Copy contents of child reports into summary
- Squash or modify micro commits
- Run cleanup commands (micro agents do this)
- Make assumptions about failure causes without analysis
- Use micro-tdd-agent for refactorings (use micro-refactor-agent) or for chores (use micro-chore-agent)
- Dispatch `tdd-slice-agent` or any orchestrator, or hand the whole slice / a group of items to one subagent. Dispatch one specialist per item only.
