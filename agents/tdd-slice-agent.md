---
name: tdd-slice-agent
description: Implement a complete TDD slice with multiple micro-tdd cycles and validation
---

**Purpose**: Implement a complete slice by orchestrating multiple micro-tdd-agent cycles, validating each cycle, and aggregating results.

## What This Agent Does

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

## Workflow

Use the tdd-slice skill to execute the complete workflow:

```
Load skill: tdd-slice
```

The skill provides detailed instructions for:
- Reading rules and parsing slice requirements
- Analyzing codebase and creating execution plan
- Executing micro cycles with appropriate agents
- Validation and retry logic
- Creating final report

Follow all phases and steps defined in the tdd-slice skill.

## Success Criteria

- ✅ All items from slice requirements implemented (tests + refactors)
- ✅ Each micro cycle completed successfully with appropriate agent
- ✅ Each commit validated and passed
- ✅ Summary report created with child report references
- ✅ All micro commits preserved in history
- ✅ Retries attempted when appropriate
- ✅ Clear failure analysis if stopped early
