---
name: write-agent-report
description: Write an agent report with proper naming and location
license: MIT
compatibility: opencode
metadata:
  category: reporting
---

Write an agent report using the standard reporting script.

## What This Command Does

**Input**: Report content and agent metadata

**Output**: A properly formatted agent report file

**Creates report at**: `~/.ai/wip/agent_reports/<agent_name>/<agent_id>-<date>.report.md`

## Workflow

### Step 1: Gather Parameters

**Required**:
- `agent_name`: Name of the agent (e.g., "micro-tdd-agent", "task-extraction-agent")
- `report_content`: The markdown content of the report

**Optional**:
- `agent_id`: Unique identifier (default: auto-generated timestamp in YYYYMMDD_HHMMSS format)
- `date`: ISO date (default: today in YYYY-MM-DD format)

### Step 2: Write Report

Use the write-agent-report.sh script via Bash tool:

```bash
cat <<EOF | ~/.ai/scripts/generic/write-agent-report.sh <agent_name> [agent_id] [date]
<report_content>
EOF
```

The script will:
- Create the report directory if needed
- Generate agent_id and date if not provided
- Write the report with proper naming convention
- Return the full path to the created report

### Step 3: Return Report Path

Return the full path to the created report:

```
Report written: <full_path_to_report>
```

## Examples

### Auto-generate agent_id and date
```bash
cat <<EOF | ~/.ai/scripts/generic/write-agent-report.sh micro-tdd-agent
# Micro TDD Report - Test Name

## Status
✅ Success
EOF
```

### Specify agent_id
```bash
cat <<EOF | ~/.ai/scripts/generic/write-agent-report.sh micro-tdd-agent 20250129_143022
# Micro TDD Report - Test Name

## Status
✅ Success
EOF
```

### Specify agent_id and date
```bash
cat <<EOF | ~/.ai/scripts/generic/write-agent-report.sh micro-tdd-agent 20250129_143022 2025-01-29
# Micro TDD Report - Test Name

## Status
✅ Success
EOF
```

## Report Content Guidelines

The report content should be markdown and typically includes:

### For TDD Agents
- Test name and file
- Implementation details
- Verification steps
- Commit information
- Status (✅ Success or ❌ Failure)

### For Extraction Agents
- Task information
- Framework phases completed
- Files created/modified
- Commit information
- Status

### For Validation Agents
Use `/generic/write-validation-report` instead.

## Success Criteria

- ✅ Report written to correct location
- ✅ Proper naming convention used
- ✅ Full path returned
- ✅ Report content is valid markdown
