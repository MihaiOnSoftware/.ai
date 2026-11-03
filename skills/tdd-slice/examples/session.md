# Example Session

**Input**: Slice 1 (bundle PR1, its only slice) with 2 test behaviors, 1 refactoring and 1 chore

**Execution**:
1. Parses requirements: Slice 1, 4 items, branch `feature/pr1` expected at `base123`
2. Delegates to `commit-agent` "prepare branch `feature/pr1` at `base123`, base `main`" → branch created, tip `base123`
3. Analyzes codebase
4. Creates execution plan: 2 tests, 1 refactor, 1 chore

**Cycle 1**: "Test loads config when it exists"
- Delegates to `micro-tdd-agent` → Success (report at path/to/report1.md)
- Delegates to `commit-agent` → commit abc123
- Delegates to `tdd-validation-agent` with slice context and "path/to/report1.md abc123" → Pass
- Posts: ✅ Cycle 1/4 complete

**Cycle 2**: "Extract duplicate file validation" (identified as refactoring)
- Delegates to `micro-refactor-agent` → Success (report at path/to/report2.md)
- Delegates to `commit-agent` → commit def456
- Delegates to `tdd-validation-agent` with slice context and "path/to/report2.md def456" → Fails (comment should be method)
- Categorizes as trivial issue
- Delegates to `micro-fix-agent` with validation report → Success (extracted method)
- Delegates to `commit-agent` "amend `def456` with the staged changes" → new commit def789
- Re-validates with slice context and "path/to/report2.md def789" → Pass
- Posts: ✅ Cycle 2/4 complete (1 fix)

**Cycle 3**: "Test saves config after run"
- Delegates to `micro-tdd-agent` → Fails (test has branching)
- Retries with context → Success (report at path/to/report3.md)
- Delegates to `commit-agent` → commit ghi789
- Delegates to `tdd-validation-agent` with slice context and "path/to/report3.md ghi789" → Fails (test still has issue)
- Delegates to `commit-agent` "reset `--hard` from `ghi789` to `def789`", retries with validation feedback → Success (report at path/to/report3b.md)
- Delegates to `commit-agent` → commit jkl012
- Delegates to `tdd-validation-agent` with slice context and "path/to/report3b.md jkl012" → Pass
- Posts: ✅ Cycle 3/4 complete (1 retry)

**Cycle 4**: "Chore: add the changelog entry for this bundle"
- Delegates to `micro-chore-agent` → Success (report at path/to/report4.md), changes staged
- Delegates to `commit-agent` → commit mno345
- Delegates to `tdd-validation-agent` with slice context and "path/to/report4.md mno345" → Pass
- Posts: ✅ Cycle 4/4 complete

**Boundary validation**: delegates to `tdd-validation-agent` with expected HEAD mno345, the slice gate and the PR1 tip gate (only slice of its bundle) → PASS, PASS

**Final**: returns the summary report as its final message, referencing all micro, chore and validation reports, with slice tip mno345.
