---
description: Write a validation report with pass/fail verdict
argument-hint: <report-filename> <pass|fail> [date]
---

Write a validation report using the standard validation reporting script.

## What This Command Does

**Input**: Validation report content and validation metadata

**Output**: A properly formatted validation report file

**Creates report at**: `~/.ai/wip/agent_reports/tdd-validation-agent/<report_base_name>-<date>.<pass|fail>.md`

## Workflow

### Step 1: Gather Parameters

**Required**:
- `report_being_validated`: Path or filename of the report being validated (e.g., "20250129_143022-2025-01-29.report.md")
- `pass_or_fail`: Either "pass" or "fail" based on validation result
- `report_content`: The markdown content of the validation report

**Optional**:
- `date`: ISO date (default: today in YYYY-MM-DD format)

### Step 2: Write Validation Report

Use the write-validation-report.sh script via Bash tool:

```bash
cat <<EOF | ~/.ai/scripts/generic/write-validation-report.sh <report_being_validated> <pass|fail> [date]
<report_content>
EOF
```

The script will:
- Extract the base name from the report being validated
- Create the validation report directory if needed
- Generate date if not provided
- Write the report with proper naming convention
- Return the full path to the created report

### Step 3: Return Report Path

Return the full path to the created validation report:

```
Validation report written: <full_path_to_report>
```

## Examples

### Pass validation (auto-generate date)
```bash
cat <<EOF | ~/.ai/scripts/generic/write-validation-report.sh 20250129_143022-2025-01-29.report.md pass
# Validation Report

## Verdict
✅ PASS

## Analysis
All requirements met.
EOF
```

### Fail validation with full path
```bash
cat <<EOF | ~/.ai/scripts/generic/write-validation-report.sh ~/.ai/wip/agent_reports/micro-tdd-agent/20250129_143022-2025-01-29.report.md fail
# Validation Report

## Verdict
❌ FAIL

## Issues Found
- Test has branching logic
- Missing verification step
EOF
```

### Specify date explicitly
```bash
cat <<EOF | ~/.ai/scripts/generic/write-validation-report.sh 20250129_143022-2025-01-29.report.md pass 2025-01-29
# Validation Report

## Verdict
✅ PASS
EOF
```

## Report Content Guidelines

The validation report content should be markdown and typically includes:

- **Verdict**: ✅ PASS or ❌ FAIL
- **Analysis**: Detailed validation findings
- **Issues Found**: List of problems (for failures)
- **Recommendations**: Suggested fixes (for failures)
- **Verification**: What was checked

## Naming Convention

The validation report filename is based on the report being validated:

- Input: `20250129_143022-2025-01-29.report.md`
- Output (pass): `20250129_143022-2025-01-29-2025-01-29.pass.md`
- Output (fail): `20250129_143022-2025-01-29-2025-01-29.fail.md`

The script automatically:
- Extracts the base name (removes path and `.report.md`)
- Adds validation date
- Adds `.pass.md` or `.fail.md` extension

## Success Criteria

- ✅ Validation report written to correct location
- ✅ Proper naming convention used
- ✅ Full path returned
- ✅ Report content is valid markdown
- ✅ Pass/fail correctly specified
