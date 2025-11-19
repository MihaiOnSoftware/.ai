# Agent Report Scripts

Helper scripts for writing agent reports with proper naming conventions.

## Available Scripts

### write-agent-report.sh

Creates normal agent reports (for non-validation agents like tdd-agent).

**Usage:**
```bash
echo "# Report content" | write-agent-report.sh <agent_name> [agent_id] [date]
```

**Arguments:**
- `agent_name`: Name of the agent (e.g., "tdd-agent")
- `agent_id`: Optional unique identifier (default: auto-generated timestamp)
- `date`: Optional ISO date (default: today)

**Example:**
```bash
cat <<EOF | write-agent-report.sh tdd-agent
# TDD Agent Report - Slice 1

## Summary
Implemented basic functionality.

## Status
✅ Success
EOF
```

**Output:** Prints full path to created report file.

---

### write-validation-report.sh

Creates validation agent reports with pass/fail status.

**Usage:**
```bash
echo "# Validation content" | write-validation-report.sh <report_being_validated> <pass|fail> [date]
```

**Arguments:**
- `report_being_validated`: Path or filename of the report being validated
- `pass|fail`: Validation result ("pass" or "fail")
- `date`: Optional ISO date (default: today)

**Example:**
```bash
cat <<EOF | write-validation-report.sh 20250129_143022-2025-01-29.report.md pass
# Validation Report

## Final Verdict
PASS

## Reasoning
All checks passed successfully.
EOF
```

**Output:** Prints full path to created validation report file.

---

## Report Locations

Reports are organized in `~/.ai/wip/agent_reports/` by agent type:

```
~/.ai/wip/agent_reports/
├── tdd-agent/
│   └── 20250129_143022-2025-01-29.report.md
├── tdd-validation-agent/
│   ├── 20250129_143022-2025-01-29-2025-01-29.pass.md
│   └── 20250129_150000-2025-01-29-2025-01-29.fail.md
└── other-agent/
    └── ...
```

## Naming Conventions

**Normal agent reports:**
```
<agent_id>-<date>.report.md
```

**Validation reports:**
```
<report_base_name>-<date>.<pass|fail>.md
```

Where:
- `agent_id`: Timestamp format `YYYYMMDD_HHMMSS`
- `date`: ISO format `YYYY-MM-DD`
- `report_base_name`: Base name of the report being validated (without `.report.md` extension)
