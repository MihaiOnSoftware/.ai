#!/bin/bash

# Script to write agent reports with proper naming convention
# Usage: write-agent-report.sh <agent_name> [agent_id] [date]
# Content is read from stdin

set -e

show_usage() {
    cat <<EOF
Usage: write-agent-report.sh <agent_name> [agent_id] [date]

Creates an agent report with the naming convention:
  ~/.ai/wip/agent_reports/<agent_name>/<agent_id>-<date>.report.md

Arguments:
  agent_name    Name of the agent (e.g., "tdd-agent")
  agent_id      Unique identifier (default: timestamp in YYYYMMDD_HHMMSS format)
  date          ISO date (default: today in YYYY-MM-DD format)

The report content should be provided via stdin.

Examples:
  # Auto-generate agent_id and date
  echo "# My Report" | write-agent-report.sh tdd-agent

  # Specify agent_id
  echo "# My Report" | write-agent-report.sh tdd-agent 20250129_143022

  # Specify agent_id and date
  echo "# My Report" | write-agent-report.sh tdd-agent 20250129_143022 2025-01-29

  # From a file
  cat report.md | write-agent-report.sh tdd-agent

Output:
  Prints the full path to the created report file.
EOF
}

# Check for help flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Check if agent_name is provided
if [[ -z "$1" ]]; then
    echo "Error: agent_name is required" >&2
    echo "" >&2
    show_usage
    exit 1
fi

AGENT_NAME="$1"

# Generate agent_id if not provided (timestamp format: YYYYMMDD_HHMMSS)
if [[ -n "$2" ]]; then
    AGENT_ID="$2"
else
    AGENT_ID=$(date +"%Y%m%d_%H%M%S")
fi

# Generate date if not provided (ISO format: YYYY-MM-DD)
if [[ -n "$3" ]]; then
    DATE="$3"
else
    DATE=$(date +"%Y-%m-%d")
fi

# Create directory structure
REPORT_DIR="$HOME/.ai/wip/agent_reports/$AGENT_NAME"
mkdir -p "$REPORT_DIR"

# Build filename
FILENAME="${AGENT_ID}-${DATE}.report.md"
FILEPATH="$REPORT_DIR/$FILENAME"

# Read content from stdin and write to file
cat > "$FILEPATH"

# Print the filepath
echo "$FILEPATH"
