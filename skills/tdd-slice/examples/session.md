# Example Session

**Input**: Slice 1 with 2 test behaviors and 1 refactoring

**Execution**:
1. Reads rules
2. Parses requirements: Slice 1, 3 items
3. Analyzes codebase
4. Creates execution plan: 2 tests, 1 refactor

**Cycle 1**: "Test loads config when it exists"
- Uses Task tool (micro-tdd-agent) → Success (report at path/to/report1.md)
- Uses Task tool (commit-agent) → commit abc123
- Uses Task tool (validation-agent) with slice context and "path/to/report1.md abc123" → Pass
- Posts: ✅ Cycle 1/3 complete

**Cycle 2**: "Extract duplicate file validation" (identified as refactoring)
- Uses Task tool (micro-refactor-agent) → Success (report at path/to/report2.md)
- Uses Task tool (commit-agent) → commit def456
- Uses Task tool (validation-agent) with slice context and "path/to/report2.md def456" → Fails (comment should be method)
- Categorizes as trivial issue
- Uses Task tool (micro-fix-agent) with validation report → Success (extracted method)
- Amends commit def456
- Re-validates with slice context and "path/to/report2.md def456" → Pass
- Posts: ✅ Cycle 2/3 complete (1 fix)

**Cycle 3**: "Test saves config after run"
- Uses Task tool (micro-tdd-agent) → Fails (test has branching)
- Retries with context → Success (report at path/to/report3.md)
- Uses Task tool (commit-agent) → commit ghi789
- Uses Task tool (validation-agent) with slice context and "path/to/report3.md ghi789" → Fails (test still has issue)
- Reverts commit, retries with validation feedback → Success (report at path/to/report3b.md)
- Uses Task tool (commit-agent) → commit jkl012
- Uses Task tool (validation-agent) with slice context and "path/to/report3b.md jkl012" → Pass
- Posts: ✅ Cycle 3/3 complete (1 retry)

**Final**:
- Creates summary report with references to all micro reports (tdd + refactor) and validation reports
- Returns report path

**Output**:
```
~/.ai/wip/agent_reports/tdd-slice/20250119_150000-2025-01-19.report.md
```
