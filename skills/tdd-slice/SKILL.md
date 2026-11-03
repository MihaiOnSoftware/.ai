---
name: tdd-slice
description: Implement a complete TDD slice on its PR bundle branch by orchestrating micro cycles (test, refactor, chore), validating each commit, and ending with a boundary validation of the slice and, on a bundle's last slice, of the bundle tip. Use when given a slice requirements document with several items; not for a single behaviour (micro-tdd) or a single refactor (micro-refactor).
metadata:
  category: tdd
---

Implement a complete slice by orchestrating specialist cycles, validating each commit, and aggregating results. You have no `bash` and no `write`: every git operation is a `commit-agent` dispatch, and your final message is the report.

## Subagents Used

- `micro-tdd-agent` - one test behavior
- `micro-refactor-agent` - one refactoring
- `micro-chore-agent` - one chore
- `commit-agent` - commits, and every branch, amend or reset
- `tdd-validation-agent` - per-commit validation and the boundary validation
- `micro-fix-agent` - trivial validation fixes
- `investigator-agent` - root cause after a second validation failure

**Input**: the slice requirements document below. **Output**: the tdd-slice report (Phase 4).

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
- Base: [the user-supplied base branch for the first bundle; the previous bundle's branch otherwise]
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
4. Chore: [administrative work this repo requires for a PR, e.g. "add the changelog entry for <scope> with the repo's tooling"]

## Commit Message
[Reference message - not used, micro commits kept]
```

## Workflow

### Phase 1: Analyze & Plan

**Step 1: Read slice requirements**
- Parse slice number, name, goal, and the Bundle section
- Extract list of test behaviors
- Note features to implement

Post "✅ Slice requirements parsed: [slice name]"

**Step 1b: Prepare the bundle branch**

Delegate to `commit-agent`: "prepare branch `<Branch>` at `<Expected tip>`, base `<Base>`". It creates the branch as the next stack layer when it does not exist (HEAD must equal the expected tip), checks it out when it exists at that tip, and stops on any mismatch. If it stops, stop too and report the SHAs it returned; do not start a micro cycle on the wrong branch.

Post "✅ On branch [branch] at [tip]"

**Step 2: Analyze codebase**
- Examine relevant test files and production code
- Understand existing patterns and conventions
- Identify dependencies and structure

Post "✅ Codebase analyzed"

**Step 3: Create execution plan**
- Review items from "Tests to Write" section
- Classify each item; a "Refactor:" or "Chore:" prefix states the type, but classify unprefixed items too:
  - **Test behavior** (micro-tdd-agent): adds or changes behavior, adds assertions about system behavior
  - **Refactoring** (micro-refactor-agent): improves structure without changing behavior (extract method, rename, reorganize)
  - **Chore** (micro-chore-agent): administrative work the repo requires for a PR, with no behavior and no test (e.g. changelogs, CODEOWNERS, docs, regenerated files)
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
Delegate to `micro-chore-agent` with the chore instruction (remove "Chore:" prefix if present). It stages; it does not commit.

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

### Phase 3: Boundary Validation

After the last micro cycle, delegate to `tdd-validation-agent` once more:

```
Boundary validation for slice [N]: [Slice Name]

Expected HEAD: [last commit hash]
Slice gate: [commands from the Bundle section, or "default": the repo's typecheck, lint and tests for the touched workspaces]
Tip gate: [commands from the Bundle section when Position is last or only; otherwise "none"]

Before running anything: confirm HEAD equals the expected SHA and `git status --porcelain` is empty; otherwise FAIL.
Run every gate command and record each command with its exit code.
After the gates: confirm HEAD is unchanged and the tree is still clean. Any tracked file a gate rewrote is a FAIL; list the files.
Verdict: PASS only when every command exited 0 and both checks held. Return the verdict, the command/exit-code list, and the report path.
```

On FAIL: stop, report the slice as failed with the validation report, and do not retry the gate; the orchestrator decides (a repair item, a re-run, or a pause).

Post "✅ Boundary validation passed: slice gate[, tip gate]"

### Phase 4: Final Report

After the boundary validation passes:

**Step 1: Collect report paths**
- Gather all micro-tdd-agent, micro-refactor-agent and micro-chore-agent report paths
- Gather all tdd-validation-agent report paths, including the boundary validation

**Step 2: Return the summary report**

Your final message is the report below.

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

For a worked example session showing cycles with retries and fixes, see [examples/session.md](examples/session.md).

## Anti-Patterns to AVOID

**DO NOT**:

- Skip validation steps, including the boundary validation
- Give up after first failure without retry
- Copy contents of child reports into summary
- Make assumptions about failure causes without analysis
- Dispatch `tdd-slice-agent` or any orchestrator, or hand the whole slice / a group of items to one subagent. Dispatch one specialist per item only.
