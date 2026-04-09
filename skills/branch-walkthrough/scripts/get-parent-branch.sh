#!/bin/bash
# Get the parent branch for the current branch, using Graphite if available

set -euo pipefail

# Try to get parent branch from Graphite
if command -v gt &> /dev/null; then
  parent=$(gt parent 2>/dev/null || echo "")

  if [ -n "$parent" ]; then
    echo "$parent"
    exit 0
  fi
fi

# Fall back to the remote's default branch, then "main"
default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
echo "${default_branch:-main}"
