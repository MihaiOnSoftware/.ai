#!/bin/bash
# Returns the merge-base SHA between HEAD and the PR base branch (or repo default).
set -euo pipefail

target="${1:-HEAD}"

git remote get-url origin >/dev/null 2>&1 || {
  echo "get-parent-branch: no origin remote; ask the user which branch to compare against" >&2
  exit 2
}

base=$(gh pr view ${1:+"$1"} --json baseRefName --jq '.baseRefName' 2>/dev/null) || \
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || \
  base="main"

git fetch origin "$base" --quiet
merge_base=$(git merge-base "$target" "origin/$base")

if [ "$merge_base" = "$(git rev-parse "$target")" ]; then
  echo "get-parent-branch: merge-base equals the tip of $target (on the base branch, nothing to diff); ask the user which branch to compare against" >&2
  exit 3
fi

echo "$merge_base"
