# Retry Logic Details

## Micro Agent Retry

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

## Validation Retry

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
