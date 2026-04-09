# Failure Analysis Report Format

When stopping due to repeated failures, use this format:

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
