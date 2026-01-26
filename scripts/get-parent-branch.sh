#!/bin/bash
# Get the parent branch for a given branch, using Graphite if available

set -euo pipefail

branch_name="${1:-$(git branch --show-current)}"

# Try to get parent branch from Graphite
if command -v gt &> /dev/null; then
  # Use gt log to find parent branch
  # Format: branch_name (parent_name)
  parent=$(gt log short 2>/dev/null | grep "^${branch_name} " | sed 's/^[^ ]* (\([^)]*\)).*/\1/' || echo "")

  if [ -n "$parent" ]; then
    echo "$parent"
    exit 0
  fi
fi

# Fall back to main if no parent found
echo "main"
