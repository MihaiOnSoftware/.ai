# Retry Logic Details

This file owns the full retry algorithm for both the micro-agent step and the validation step in `SKILL.md` Phase 3. The SKILL.md blocks are pointer-only stubs — every decision lives here.

## Micro Agent Retry

Use this flow when the micro-tdd-agent or micro-refactor-agent invocation in Phase 3 Step 1 fails.

### First failure: retry once with context

1. Analyze the failure mode.
   - For micro-tdd: test didn't fail in the right way, tests not passing, agent stuck.
   - For micro-refactor: tests broken, refactoring incomplete, agent stuck.
2. Extract key information (error messages, test output, failing test names, what the agent reported).
3. Formulate helpful context. Examples for micro-tdd:
   - "Previous test failed to compile: [error]. Check syntax."
   - "Previous test passed when it should fail. Test may need a stronger assertion."
   - "Previous implementation broke existing tests: [failures]. Consider [approach]."

   Examples for micro-refactor:
   - "Previous refactoring broke tests: [failures]. Consider a smaller change."
   - "Previous attempt changed behavior. Refactoring must preserve behavior."
   - "Previous refactoring incomplete. Consider [approach]."
4. Delegate to the **same agent type** again with: original description + failure context.

### Second failure: stop and report

1. Analyze what went wrong across both attempts (errors, code state, test output).
2. Write a failure analysis report using the `write-agent-report` skill (format in `failure-report-format.md`, sibling to this file). Include:
   - Slice info
   - Failed item
   - Both attempts (prompts + outcomes)
   - Error details
   - Possible causes
3. Return the failure report path and **STOP**. Do not start a third attempt.

## Validation Retry

Use this flow when `tdd-validation-agent` fails in Phase 3 Step 3.

### First validation failure: categorize, then fix or reset

#### Step A: Categorize the issues

Read the validation report thoroughly and classify every issue.

**Trivial issues** (route to Step B, fix path):
- Commit message only (passive voice, process description, missing note)
- Comments that should be methods
- One-line code issues (unused variable, dead code)
- Simple duplication
- Formatting / whitespace

**Substantial issues** (route to Step C, reset path):
- Test quality (branching, multiple behaviors, weak assertions)
- Multi-line logic changes
- Coverage problems
- Behavior changes needed

If **any** substantial issue is present, go straight to Step C. Do not try to fix the trivial ones first.

#### Step B: Fix path (only when every issue is trivial)

**For commit message issues only:**
1. Soft reset: `git reset --soft HEAD~1`
2. Delegate to `commit-agent` to create a new commit.
3. Track the new commit hash.
4. Re-validate with the new commit hash (include the same slice context).
5. If validation passes → continue to Phase 3 Step 4.
6. If validation fails → fall through to Step C.

**For code issues (with or without commit message issues):**
1. Delegate to `micro-fix-agent` with the validation report path.
2. If `micro-fix-agent` succeeds:
   - Amend commit: `git commit --amend --no-edit`
   - Capture the new commit hash (`git rev-parse HEAD`) — `--amend` always creates a new SHA, even with `--no-edit`.
   - Re-validate with the **new** commit hash (include the same slice context).
   - If validation passes → continue.
   - If validation fails → fall through to Step C.
3. If `micro-fix-agent` fails → fall through to Step C.

#### Step C: Reset path (substantial issues OR fix failed)

1. Read the validation report to understand the issues.
2. Formulate context: `"Previous attempt didn't meet quality standards: [issues from validation report]"`.
3. Revert the commit: `git reset --hard HEAD~1`
4. Delegate to the **same agent type** (micro-tdd or micro-refactor) with: original description + validation feedback.
5. If the agent succeeds, call `commit-agent` to create a new commit.
6. Re-validate with the new commit hash (include the same slice context).

### Second validation failure: investigate and stop

#### Step A: Call investigator-agent

Delegate to `investigator-agent` with:
- Validation report path (from the second failure)
- Micro agent report path
- Commit hash

The investigator will:
- Apply problem-solving discipline
- Determine root cause
- Analyze what went wrong in both attempts
- Provide recommendations for what should have been done

#### Step B: Write failure analysis report

- Include: slice info, item description, both validation reports, quality issues, fix attempts.
- Include: investigator report path and key findings.
- Include: investigator's root cause analysis and recommendations.
- Write the report using the `write-agent-report` skill.
- Return the report path and **STOP**. Do not start a third validation cycle.
