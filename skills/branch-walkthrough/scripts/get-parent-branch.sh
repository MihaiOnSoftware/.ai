#!/bin/bash
# Returns the merge-base SHA between a target branch (default HEAD) and its PR base branch (or repo default).
set -euo pipefail

target="${1:-HEAD}"

git remote get-url origin >/dev/null 2>&1 || {
  echo "get-parent-branch: no origin remote; ask the user which branch to compare against" >&2
  exit 2
}

base=$(gh pr view ${1:+"$1"} --json baseRefName --jq '.baseRefName' 2>/dev/null) || \
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || \
  {
    echo "get-parent-branch: could not determine base branch; ask the user which branch to compare against" >&2
    exit 4
  }

git fetch origin "$base" --quiet 2>/dev/null || echo "get-parent-branch: warning: fetch failed for origin/$base; using local refs" >&2
merge_base=$(git merge-base "$target" "origin/$base")

if [ "$merge_base" = "$(git rev-parse "$target")" ]; then
  echo "get-parent-branch: merge-base equals the tip of $target (on the base branch, nothing to diff); ask the user which branch to compare against" >&2
  exit 3
fi

echo "$merge_base"
