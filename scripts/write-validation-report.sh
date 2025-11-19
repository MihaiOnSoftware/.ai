#!/bin/bash

# Script to write validation agent reports with proper naming convention
# Usage: write-validation-report.sh <report_being_validated> <pass|fail> [date]
# Content is read from stdin

set -e

show_usage() {
    cat <<EOF
Usage: write-validation-report.sh <report_being_validated> <pass|fail> [date]

Creates a validation report with the naming convention:
  ~/.ai/wip/agent_reports/tdd-validation-agent/<report_base_name>-<date>.<pass|fail>.md

Arguments:
  report_being_validated    Path or filename of the report being validated
                           (e.g., "20250129_143022-2025-01-29.report.md" or full path)
  pass|fail                Either "pass" or "fail" based on validation result
  date                     ISO date (default: today in YYYY-MM-DD format)

The report content should be provided via stdin.

Examples:
  # Validate a report (auto-generate date)
  echo "# Validation Report" | write-validation-report.sh 20250129_143022-2025-01-29.report.md pass

  # With full path
  echo "# Validation Report" | write-validation-report.sh ~/.ai/wip/agent_reports/tdd-agent/20250129_143022-2025-01-29.report.md fail

  # Specify date
  echo "# Validation Report" | write-validation-report.sh 20250129_143022-2025-01-29.report.md pass 2025-01-29

  # From a file
  cat validation.md | write-validation-report.sh 20250129_143022-2025-01-29.report.md pass

Output:
  Prints the full path to the created validation report file.
EOF
}

# Check for help flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Check if report_being_validated is provided
if [[ -z "$1" ]]; then
    echo "Error: report_being_validated is required" >&2
    echo "" >&2
    show_usage
    exit 1
fi

# Check if pass/fail is provided
if [[ -z "$2" ]]; then
    echo "Error: pass/fail is required" >&2
    echo "" >&2
    show_usage
    exit 1
fi

# Validate pass/fail value
if [[ "$2" != "pass" && "$2" != "fail" ]]; then
    echo "Error: Second argument must be either 'pass' or 'fail'" >&2
    echo "" >&2
    show_usage
    exit 1
fi

REPORT_BEING_VALIDATED="$1"
PASS_OR_FAIL="$2"

# Extract base name (remove path and .report.md extension)
REPORT_BASE_NAME=$(basename "$REPORT_BEING_VALIDATED")
REPORT_BASE_NAME="${REPORT_BASE_NAME%.report.md}"

# Generate date if not provided (ISO format: YYYY-MM-DD)
if [[ -n "$3" ]]; then
    DATE="$3"
else
    DATE=$(date +"%Y-%m-%d")
fi

# Create directory structure
REPORT_DIR="$HOME/.ai/wip/agent_reports/tdd-validation-agent"
mkdir -p "$REPORT_DIR"

# Build filename
FILENAME="${REPORT_BASE_NAME}-${DATE}.${PASS_OR_FAIL}.md"
FILEPATH="$REPORT_DIR/$FILENAME"

# Read content from stdin and write to file
cat > "$FILEPATH"

# Print the filepath
echo "$FILEPATH"
